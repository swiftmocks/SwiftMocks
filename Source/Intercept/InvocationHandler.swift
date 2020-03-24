// This source file is part of SwiftMocks open source project.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// Copyright © 2019-2020, Sergiy Drapiko
// Copyright © 2020, SwiftMocks project contributors

import Foundation

class InvocationHandler {
    private let parameterSchemas: [ParameterSchema]
    private var extractedParametersCache: [Any]?

    let snapshot: InvocationSnapshot
    let descriptor: InvocationDescriptor

    lazy var coroBuffer: RawPointer? = {
        guard descriptor.silFunctionType.isCoroutine else {
            return nil
        }
        // coroutine context is always the very first IR param
        var contextParamIter = snapshot.begin()
        let ret = contextParamIter.consume(.pointer).reinterpret(RawPointer.self).pointee
        return ret
    }()

    init(descriptor: InvocationDescriptor, snapshot: InvocationSnapshot) {
        self.descriptor = descriptor
        self.snapshot = snapshot

        self.parameterSchemas = ParameterSchema.from(descriptor: descriptor)
    }

    func extractParameters() throws -> [Any] {
        try tryLoweringThrowing {
            if let cached = extractedParametersCache {
                return cached
            }
            let ret = parameterSchemas.map { explosion -> Any in
                var materialise = MaterialiseArgument(parameterExplosionSchema: explosion, invocationSnapshot: snapshot)
                let ret = materialise.materialise()
                return ret
            }
            extractedParametersCache = ret
            return ret
        }
    }

    func extractSelfParameter() throws -> Any? {
        let params = try extractParameters()
        guard descriptor.silFunctionType.hasSelfParam else {
            return nil
        }
        return params[descriptor.loweredInterfaceType.params.count - 1]
    }

    func inject(error value: Error) {
        Runtime.errorRetain(value)
        snapshot.r12 = unsafeBitCast(value, to: UInt.self)
    }

    func inject(result value: Any) throws {
        try tryLoweringThrowing {
            let silFunctionType = descriptor.silFunctionType

            var flattener = ExplodeTuple()
            let flattened = flattener.flatten(value)
            assert(flattened.count == silFunctionType.results.count)
            let formalDirectResults = zip(silFunctionType.results, flattened).filter { $0.0.isFormalDirect }.map { $0.1 }
            let imploder = ImplodeTuple()
            let formalDirectResultType = silFunctionType.directFormalResultsType.getASTType().type
            let formalDirectResult = imploder.implode(formalDirectResults, type: formalDirectResultType)
            let formalIndirectResults = zip(silFunctionType.results, flattened).filter { $0.0.isFormalIndirect }

            let canUseSret = silFunctionType.numberOfIndirectFormalResults < 2
            let directResultConsumesSret = canUseSret && descriptor.irSignature.requiresIndirectResult
            var paramIteratorForIndirectResults = snapshot.begin()
            if !directResultConsumesSret && descriptor.irSignature.requiresIndirectResult {
                // if direct result requires sret but it's not allowed due to too many indirect results, then it will consume the first IR param
                paramIteratorForIndirectResults.skip(.pointer)
            }

            if silFunctionType.hasIndirectFormalResults {
                inject(formalIndirectResult: formalIndirectResults, snapshot: snapshot, canUseSret: canUseSret && !directResultConsumesSret, iterator: paramIteratorForIndirectResults)
            }

            inject(formalDirectResult: formalDirectResult, type: formalDirectResultType, snapshot: snapshot, canUseSret: canUseSret)
        }
    }

    func inject(yield: RawPointer, box: RawPointer) {
        let coroContinuation: @convention(c) (RawPointer) -> () = { coroBuffer in
            Runtime.release(coroBuffer.reinterpret(RawPointer.self).pointee)
        }
        let resume = unsafeBitCast(coroContinuation, to: RawPointer.self)
        struct YieldOnceResult {
            let continuation: RawPointer
            let yieldInOut: RawPointer
        }
        var result = YieldOnceResult(continuation: resume, yieldInOut: yield)
        snapshot.injectResults([.pointer, .pointer], storage: &result)
        guard let coroBuffer = coroBuffer else {
            LoweringError.unreachable("not a coro?")
        }
        coroBuffer.reinterpret(RawPointer.self).pointee = box
    }

    private func inject(formalDirectResult: Any?, type: AType, snapshot: InvocationSnapshot, canUseSret: Bool) {
        guard var formalDirectResult = formalDirectResult else {
            return // nothing to inject, void
        }

        let metadata = TypeFactory.convert(type)

        if descriptor.irSignature.requiresIndirectResult {
            let storage: RawPointer
            if canUseSret {
                assert(descriptor.irSignature.attributes.parameterAttributes[0]?.contains("sret") == true)
                storage = RawPointer(bitPattern: snapshot.rax)!
            } else {
                // consume the first parameter
                var iterator = snapshot.begin()
                storage = iterator.consume(.pointer).reinterpret(RawPointer.self).pointee
            }
            metadata.initialize(storage, withCopyOf: formalDirectResult)
            return
        }

        // create a temp buffer where the value can be +1-copied before being chopped ~to death~ into registers
        let storage = RawPointer.allocateWithZeroFill(size: metadata.valueWitnesses.size + 128, alignment: metadata.valueWitnesses.alignmentMask + 1)
        defer {
            storage.deallocate()
        }
        metadata.initialize(storage, withCopyOf: formalDirectResult)

        let explosion: [LLVMType]
        if case let .struct(types) = descriptor.irSignature.type.result {
            explosion = types
        } else {
            explosion = [descriptor.irSignature.type.result]
        }
        snapshot.injectResults(explosion, storage: storage)
        return
    }

    private func inject(formalIndirectResult: [(info: SILResultInfo, value: Any)], snapshot: InvocationSnapshot, canUseSret: Bool, iterator: InvocationSnapshot.Iterator) {
        var iterator = iterator
        var canUseSret = canUseSret
        for (info, value) in formalIndirectResult {
            let p: RawPointer
            if canUseSret {
                p = RawPointer(bitPattern: snapshot.rax)!
                canUseSret = false
            } else {
                p = iterator.consume(.pointer).reinterpret(RawPointer.self).pointee
            }
            let metadata = TypeFactory.convert(info.type.type)
            metadata.initialize(p, withCopyOf: value)
        }
    }
}

// MARK: - Private implementation

/// End-to-end mapping of a formal parameter to SIL to LLVM types
private struct ParameterSchema {
    let type: AType
    let flags: ParameterTypeFlags
    // a formal Swift parameter may be lowered to zero SIL parameters (Void or thin metatype), one (most types) or several (tuple).
    let silSchemas: [SILSchema]

    struct SILSchema {
        let type: AType
        let convention: ParameterConvention
        /// `true` if this parameter is required to be indirect by IR lowering (i.e., the resulting aggregate is too big to pass via registers)
        let swiftRequiresIndirect: Bool
        /// `true` if this parameter has `swiftself` attribute
        let swiftSelf: Bool
        /// Index into the IR function parameters
        let index: InvocationSnapshot.Index
        /// Explosion [schema] of this SIL parameter
        let explosion: [LLVMType]
    }

    static func from(descriptor: InvocationDescriptor) -> [ParameterSchema] {
        precondition(descriptor.loweredInterfaceType.params.count == descriptor.formalParameterRanges.count)
        let invocationSnapshot = InvocationSnapshot.makeEmpty()
        var iterator = invocationSnapshot.begin()

        var ret = [ParameterSchema]()
        for (formalParamIndex, formalParam) in descriptor.loweredInterfaceType.params.enumerated() {
            // FIXME: τ_0_0 under <τ_0_0 where τ_0_0 : ProtocolWithDefaultImplementation> with ProtocolWithDefaultImplementation not being class-bound lowers to @guaranteed - should it not be @in_guaranteed?

            let type = formalParam.type
            let flags = formalParam.flags

            let range = descriptor.formalParameterRanges[formalParamIndex]

            let schemas: [SILSchema] = zip(range, descriptor.silFunctionType.parameters[range]).map { (silParameterIndex: Int, silParameterInfo: SILParameterInfo) -> SILSchema in
                let type = silParameterInfo.type.type
                let convention = silParameterInfo.convention

                let swiftRequiresIndirect = descriptor.irSignature.requiresIndirect(for: silParameterIndex)
                let range: IRSignature.Range = descriptor.irSignature.rangeOfIRParameters(for: silParameterIndex)
                let explosion = Array(descriptor.irSignature.type.params[range])
                let swiftSelf = range.count == 1 && descriptor.irSignature.attributes.attributes(for: range.lowerBound).contains("swiftself")

                let silParameterSchema = SILSchema(type: type,
                                                   convention: convention,
                                                   swiftRequiresIndirect: swiftRequiresIndirect,
                                                   swiftSelf: swiftSelf,
                                                   index: iterator - invocationSnapshot.begin(),
                                                   explosion: explosion)

                for ty in explosion {
                    iterator.skip(ty)
                }

                return silParameterSchema
            }

            ret.append(ParameterSchema(type: type, flags: flags, silSchemas: schemas))
        }
        return ret
    }
}

/// End-to-end mapping of a formal parameter to SIL to LLVM types
private struct ResultSchema {
    let type: AType
    let silSchemas: [SILSchema]

    struct SILSchema {
        let type: AType
        let convention: ResultConvention
        /// `true` if this parameter is required to be indirect by IR lowering (i.e., the resulting aggregate is too big to pass via registers)
        let swiftRequiresIndirect: Bool
        /// An index into the IR function parameters
        let index: InvocationSnapshot.Index
        /// An explosion [schema] of this SIL parameter
        let explosion: [LLVMType]
    }
}
/// Visitor to materialise (copy out of invocation arguments) a single formal argument of a Swift function. For non-tuple args, this method simply materialises the corresponding parameter, and for tuples, it reassembles them from individual SIL parameters produced by `DestructureInputs`.
private struct MaterialiseArgument {
    let parameterExplosionSchema: ParameterSchema
    let invocationSnapshot: InvocationSnapshot

    init(parameterExplosionSchema: ParameterSchema, invocationSnapshot: InvocationSnapshot) {
        self.parameterExplosionSchema = parameterExplosionSchema
        self.invocationSnapshot = invocationSnapshot
    }

    mutating func materialise() -> Any {
        var silParameterSchemas = parameterExplosionSchema.silSchemas
        var snapshotIterator: InvocationSnapshot.Iterator
        if parameterExplosionSchema.silSchemas.isEmpty {
            snapshotIterator = invocationSnapshot.begin() // the exact value doesn't matter in this case as the type is empty and won't consume any arguments
        } else {
            snapshotIterator = invocationSnapshot[parameterExplosionSchema.silSchemas[0].index]
        }
        let ret = visit(type: parameterExplosionSchema.type, silParameterSchemas: &silParameterSchemas, snapshotIterator: &snapshotIterator).value
        assert(silParameterSchemas.isEmpty) // we should have consumed all
        // FIXME: change all asserts and preconditions to LoweringError.unreachable()
        return ret
    }

    private mutating func visit(type: AType, silParameterSchemas: inout [ParameterSchema.SILSchema], snapshotIterator: inout InvocationSnapshot.Iterator) -> (value: Any, metadata: Metadata) {

        if let tupleType = type as? TupleType {
            let metadata = TypeFactory.convert(tupleType)

            var elts = [(value: Any, metadata: Metadata)]()
            for eltTy in tupleType.elements {
                let elt = visit(type: eltTy, silParameterSchemas: &silParameterSchemas, snapshotIterator: &snapshotIterator)
                elts.append(elt)
            }
            let storage = RawPointer.allocateWithZeroFill(size: metadata.valueWitnesses.size, alignment: 16)
            defer {
                storage.deallocate()
            }
            for (index, elt) in metadata.elements.enumerated() {
                elt.metadata.initialize(storage + elt.offset, withCopyOf: elts[index].value)
            }
            let value = metadata.copy(from: storage)
            return (value, metadata)
        }

        // consume one sil parameter per actual type we are instantiating
        let silParameterSchema = silParameterSchemas.removeFirst()

        // let metadata = TypeFactory.convert(type)
        // TODO: should we be materialising parameter type, or parameterExplosionSchema type 🤔
        let metadata = TypeFactory.convert(silParameterSchema.type)

        if metadata.valueWitnesses.size == 0 {
            var a = 0 // just give it a random chunk of memory, it's not going to read from it anyway
            let value = metadata.copy(from: &a)
            return (value, metadata)
        }

        let storage = RawPointer.allocateWithZeroFill(size: metadata.valueWitnesses.size, alignment: 16) // XXX: we don't actuall use the allocated memory
        defer {
            storage.deallocate()
        }

        let source: RawPointer
        let isIndirect: Bool = silParameterSchema.convention.isIndirectFormalParameter || silParameterSchema.swiftRequiresIndirect
        if silParameterSchema.swiftSelf {
            source = isIndirect ? invocationSnapshot.pr13.reinterpret(RawPointer.self).pointee : invocationSnapshot.pr13
        } else {

            if let metatype = silParameterSchema.type as? AnyMetatypeType, metatype.representation == .thin {
                // TODO: I don't like this specific case handling in the middle of nowhere
                let metadata = TypeFactory.convert(metatype.instanceType)
                return (metadata.asAnyType!, metadata)
            } else {
                _ = materialiseSwiftAggregate(from: &snapshotIterator, with: silParameterSchema.explosion, into: storage)

                if isIndirect {
                    source = storage.reinterpret(RawPointer.self).pointee
                } else {
                    source = storage
                }
            }
        }

        let value = metadata.copy(from: source)
        return (value, metadata)
    }
}

private struct ExplodeTuple {
    mutating func flatten(_ value: Any) -> [Any] {
        var value = value
        let box = AnyExistentialBox(&value)
        let projected = box.container.projected
        var ret = [Any]()
        let ty = TypeFactory.from(anyType: type(of: value))
        flatten(projected, of: ty, result: &ret)
        return ret
    }

    private mutating func flatten(_ p: RawPointer, of ty: AType, result: inout [Any]) {
        if let tupleTy = ty as? TupleType {
            let tupleMetadata = TypeFactory.convert(tupleTy)
            for (offset, eltMeta) in tupleMetadata.elements.map({ ($0.offset, $0.metadata) })  {
                flatten(p + offset, of: TypeFactory.from(metadata: eltMeta), result: &result)
            }

            return
        }

        let metadata = TypeFactory.convert(ty)

        guard metadata.valueWitnesses.size > 0 else {
            return
        }

        let value = metadata.copy(from: p)
        result.append(value)
    }
}

private struct ImplodeTuple {
    func implode(_ elts: [Any], type: AType) -> Any? {
        guard let tupleType = type as? TupleType else {
            precondition(elts.count < 2)
            return elts.first
        }
        let metadata: TupleTypeMetadata = TypeFactory.convert(tupleType)
        let storage = RawPointer.allocateWithZeroFill(size: metadata.valueWitnesses.size, alignment: 16)
        defer {
            storage.deallocate()
        }
        for (index, elementMetadata) in metadata.elements.enumerated() {
            elementMetadata.metadata.initialize(storage + elementMetadata.offset, withCopyOf: elts[index])
        }
        let ret = metadata.copy(from: storage)
        return ret
    }
}

private func materialiseSwiftAggregate(from iterator: inout InvocationSnapshot.Iterator, with types: [LLVMType], into: RawPointer) -> RawPointer {
    var runningOffset = 0
    for type in types {
        runningOffset = runningOffset.aligned(type.alignment)
        let curp: RawPointer = into + runningOffset
        switch type {
        case .void,
             .i1,
             .i8,
             .i16,
             .i32,
             .i64,
             .pointer:
            let claimed: RawPointer = iterator.consume(.gpr)
            curp.copyMemory(from: claimed, byteCount: type.size)
        case .float,
             .double:
            let claimed: RawPointer = iterator.consume(.xmm)
            curp.copyMemory(from: claimed, byteCount: type.size)
        case .x86_fp80:
            LoweringError.notImplemented("x86_fp80")
        case .array(_, _):
            LoweringError.unreachable("array in IR function signature?")
        case .struct(_):
            LoweringError.unreachable("struct in IR function signature?")
        }
        runningOffset += type.size
    }
    return into + runningOffset
}

extension ParameterSchema: CustomStringConvertible {
    var description: String {
        "\(type): " + (silSchemas.isEmpty ? "<empty>" : silSchemas.map { "\n  |-- \($0)" }.joined())
    }
}

extension ParameterSchema.SILSchema: CustomStringConvertible {
    var description: String {
        var convention = self.convention.description
        convention = convention.isEmpty ? "" : convention + " "
        let name = "\(type)"// FIXME .computedMetadata.silDescription
        let llvmTypes = explosion.map { $0.description }.joined(separator: ", ")
        let indirect = swiftRequiresIndirect ? "indirect " : ""
        return "\(convention)\(name) -> \(indirect)\(llvmTypes)"
    }
}
