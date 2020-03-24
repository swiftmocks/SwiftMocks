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

struct SignatureExpansion {
    let igm: IRGenModule
    let fnType: SILFunctionType

    private(set) var callingConvention: LLVMCallingConvID
    private(set) var paramIRTypes: [LLVMType] = [LLVMType]()
    private(set) var resultIRType: LLVMType = .void

    private(set) var mappings = [IRSignature.Mapping]()
    private(set) var resultMapping: IRSignature.ResultMapping = (requiresIndirect: false, ranges: [])

    private var canUseSelf = true
    private var canUseError = true
    private var canUseSRet = true
    private var functionAttrs = Set<String>()
    private var resultAttrs = Set<String>()
    private var parametersAttrs = [Int: Set<String>]()

    private var silFuncConventions: SILFunctionConventions { SILFunctionConventions(fnType) }

    var signature: IRSignature {
        let llvmType = LLVMFunctionType(result: resultIRType, params: paramIRTypes, isVarArgs: false)
        let attrs = LLVMAttributeList(functionAttributes: functionAttrs, resultAttributes: resultAttrs, parameterAttributes: parametersAttrs)

        return IRSignature(type: llvmType, attributes: attrs, mappings: mappings, resultMapping: resultMapping)
    }

    init(igm: IRGenModule, fnType: SILFunctionType) {
        precondition(fnType.language == .swift)

        self.igm = igm
        self.fnType = fnType
        self.callingConvention = expandCallingConv(igm: igm, convention: fnType.representation)

        igm.types.pushGenericContext(fnType.genericSig)
        defer {
            igm.types.popGenericContext(fnType.genericSig)
        }

        expandResult()
        expandParameters()

        assert(mappings.count == fnType.parameters.count, "The number of mappings must match the number of SIL parameters")
    }

    private mutating func addIndirectResultAttributes(index: Int, sret: Bool) {
        guard sret else {
            return
        }
        var attrs = parametersAttrs[index] ?? Set<String>()
        attrs.insert("sret")
        parametersAttrs[index] = attrs
    }

    private mutating func addSwiftErrorAttributes(index: Int) {
        var attrs = parametersAttrs[index] ?? Set<String>()
        attrs.insert("swifterror")
        parametersAttrs[index] = attrs
    }

    private mutating func addSwiftSelfAttributes(index: Int) {
        var attrs = parametersAttrs[index] ?? Set<String>()
        attrs.insert("swiftself")
        parametersAttrs[index] = attrs
    }

    private mutating func expandResult() {
        if fnType.isCoroutine {
            // This should be easy enough to support if we need to: use the same algorithm but add the direct results to the results as if they were unioned in.
            return expandCoroutineResult(forContinuation: false)
        }
        // Disable the use of sret if we have multiple indirect results.
        if silFuncConventions.numberOfIndirectSILResults > 1 {
            canUseSRet = false
        }

        // Expand the direct result.
        resultIRType = expandDirectResult()

        // Expand the indirect results.
        for indirectResultType in silFuncConventions.indirectSILResultTypes {
            addIndirectResultAttributes(index: paramIRTypes.count, sret: claimSRet())
            addPointerParameter(igm.getStorageType(indirectResultType))
        }
    }

    /// Expand the abstract parameters of a SIL function type into the physical parameters of an LLVM function type (results have already been expanded).
    private mutating func expandParameters() {
        // First, if this is a coroutine, add the coroutine-context parameter.
        switch fnType.coroutineKind {
        case .yieldOnce, .yieldMany:
            addCoroutineContextParameter()
        default:
            break
        }

        // Next, the formal parameters.  But 'self' is treated as the context if it has pointer representation.
        var params = fnType.parameters
        var hasSelfContext = false
        if hasSelfContextParameter(fnType) {
            hasSelfContext = true
            params = params.dropLast()
        }

        for param in params {
            let savedParameterCount = paramIRTypes.count
            let requiresIndirect = expand(param)
            mappings.append((requiresIndirect: requiresIndirect, range: savedParameterCount..<paramIRTypes.count))
        }

        if hasPolymorphicParameters(fnType) {
            paramIRTypes += expandPolymorphicSignature(igm, fnType)
        }

        if hasSelfContext {
            if claimSelf() {
                addSwiftSelfAttributes(index: paramIRTypes.count)
            }
            let savedParameterCount = paramIRTypes.count
            let requiresIndirect = expand(fnType.selfParameter)
            mappings.append((requiresIndirect: requiresIndirect, range: savedParameterCount..<paramIRTypes.count))
        } else {
            func needsContext() -> Bool {
                switch fnType.representation {
                // Always leave space for a context argument if we have an error result.
                case .method, .witnessMethod, .thin, .closure:
                    return fnType.errorResult != nil

                case .thick:
                    return true
                }
            }
            if needsContext() {
                if claimSelf() {
                    addSwiftSelfAttributes(index: paramIRTypes.count)
                }
                paramIRTypes.append(.pointer)
            }
        }

        // Error results are last. We always pass them as a pointer to the formal error type; LLVM will magically turn this into a non-pointer if we set the right attribute.
        if fnType.errorResult != nil {
            if claimError() {
                addSwiftErrorAttributes(index: paramIRTypes.count)
            }
            paramIRTypes.append(.pointer)
        }

        // Witness methods have some extra parameter types.
        if fnType.representation == .witnessMethod {
            expandTrailingWitnessSignature(igm, fnType, &paramIRTypes)
        }
    }

    private mutating func addCoroutineContextParameter() {
        paramIRTypes.append(igm.int8PtrTy)
    }

    mutating func expandCoroutineResult(forContinuation: Bool) {
        assert(fnType.numberOfResults == 0, "having both normal and yield results is currently unsupported")

        // The return type may be different for the ramp function vs. the continuations.
        if (forContinuation) {
            switch fnType.coroutineKind {
            case .none:
                LoweringError.unreachable("should have been filtered out before here")

            // Yield-once coroutines just return void from the continuation.
            case .yieldOnce:
                resultIRType = igm.voidTy
                return

            // Yield-many coroutines yield the same types from the continuation as they do from the ramp function.
            case .yieldMany:
                break
            }
        }

        var components = [LLVMType]()

        // The continuation pointer.
        components.append(igm.int8PtrTy)

        for yield in fnType.yields {
            let schema = YieldSchema(igm: igm, fnConv: silFuncConventions, yield: yield)
            if schema.isIndirect {
                components.append(schema.indirectPointerType)
                continue
            }

            guard let nativeSchema = schema.nativeSchema else {
                LoweringError.unreachable("no \(YieldSchema.self) for direct parameter")
            }

            components += nativeSchema.asArray
        }

        // Find the maximal sequence of the component types that we can convince the ABI to pass directly. When counting components, ignore the continuation pointer.
        var numDirectComponents = components.count - 1
        var overflowTypes = [LLVMType]()
        while LLVMSwiftABIInfo.shouldPassIndirectlyForSwift(components, asReturnValue: true) {
            // If we added a pointer to the end of components, remove it.
            if !overflowTypes.isEmpty {
                components.removeLast()
            }

            // Remove the last component and add it as an overflow type.
            overflowTypes.append(components.popLast()!)
            numDirectComponents -= 1

            // Add a pointer to the end of components.
            components.append(igm.int8PtrTy)
        }

        // We'd better have been able to pass at least two pointers.
        assert(components.count >= 2 || overflowTypes.isEmpty)

        // Replace the pointer type we added to components with the real pointer-to-overflow type.
        if !overflowTypes.isEmpty {
            overflowTypes.reverse()

            // TODO: should we use some sort of real layout here instead of trusting LLVM's?
            components[components.count - 1] = .pointer
        }

        resultIRType = components.count == 1 ? components[0] : .struct(components)
    }

    private mutating func expandCoroutineContinuationParameters() {
        // The coroutine context.
        addCoroutineContextParameter()

        // Whether this is an unwind resumption.
        paramIRTypes.append(igm.int1Ty)
    }

    /// - returns: `true` if this parameter will be passed indirectly according to Swift CC
    private mutating func expand(_ param: SILParameterInfo) -> Bool {
        let paramSILType = silFuncConventions.getSILType(param)
        switch param.convention {
        case .indirectIn, .indirectInConstant, .indirectInGuaranteed:
            addPointerParameter(/* igm.getStorageType(silFuncConventions.getSILType(param)) */)
            return false

        case .indirectInout, .indirectInoutAliasable:
            addPointerParameter(/* igm.getStorageType(silFuncConventions.getSILType(param)) */)
            return false

        case .directOwned, .directUnowned, .directGuaranteed:
            guard fnType.language == .swift else {
                LoweringError.unreachable("Unexpected non-swift method in parameter expansion!")
            }
            let ti = igm.getTypeInfo(paramSILType)
            let nativeSchema = ti.nativeParameterValueSchema(igm)
            if nativeSchema.requiresIndirect {
                paramIRTypes.append(.pointer)
                return true
            }
            if nativeSchema.isEmpty {
                // assert(ti.getSchema().isEmpty())
                return false
            }
            let expandedTy = nativeSchema.getExpandedType(igm)
            let expandedTysArray = expandScalarOrStructTypeToArray(expandedTy)
            for type in expandedTysArray {
                paramIRTypes.append(type)
            }
            return false
        }
    }

    private mutating func expandDirectResult() -> LLVMType {
        // Handle the direct result type, checking for supposedly scalar result types that we actually want to return indirectly.
        let resultType = silFuncConventions.silResultType

        // Fast-path the empty tuple type.
        if let tuple = resultType.getASTType().type as? TupleType {
            if tuple.isVoid {
                return igm.voidTy
            }
        }

        switch fnType.language {
        case .c:
            LoweringError.unreachable("Expanding C/ObjC parameters in the wrong place!");
        case .swift:
            let ti = igm.getTypeInfo(resultType)
            let native = ti.nativeReturnValueSchema(igm)
            if native.requiresIndirect {
                return addIndirectResult()
            }

            // Disable the use of sret if we have a non-trivial direct result.
            if !native.isEmpty {
                canUseSRet = false
            }
            return native.getExpandedType(igm)
        }
    }

    private mutating func addIndirectResult() -> LLVMType {
        resultMapping.requiresIndirect = true
        let resultType = silFuncConventions.silResultType
        let resultTI = igm.getTypeInfo(resultType)
        addIndirectResultAttributes(index: paramIRTypes.count, sret: claimSRet())
        addPointerParameter(resultTI.storageType)
        return igm.voidTy
    }

    mutating private func addPointerParameter(_ storageType: LLVMType = .void /* it doesn't matter */) {
        paramIRTypes.append(storageType.pointerTo)
    }

    mutating private func claimSelf() -> Bool {
        let ret = canUseSelf
        precondition(canUseSelf, "Multiple self parameters?")
        canUseSelf = false
        return ret
    }

    mutating private func claimError() -> Bool {
        let ret = canUseError
        precondition(canUseError, "Multiple error parameters?")
        canUseError = false
        return ret
    }

    mutating private func claimSRet() -> Bool {
        let result = canUseSRet
        canUseSRet = false
        return result
    }
}

private struct YieldSchema {
    let yieldTy: SILType
    let yieldTI: TypeInfo
    let nativeSchema: NativeConventionSchema?
    /// Should the yielded value be yielded as a pointer?
    let isIndirect: Bool

    /// Is the yielded value formally indirect?
    var isFormalIndirect: Bool {
        yieldTy.category == .address
    }

    init(igm: IRGenModule, fnConv: SILFunctionConventions, yield: SILYieldInfo) {
        let yieldTy: SILType = fnConv.getSILType(yield)
        self.yieldTy = yieldTy
        let yieldTI: TypeInfo = igm.getTypeInfo(yieldTy)
        self.yieldTI = yieldTI
        if yieldTy.category == .address {
            isIndirect = true
            self.nativeSchema = nil
        } else {
            let nativeSchema = NativeConventionSchema(igm: igm, ti: yieldTI, isResult: true)
            isIndirect = nativeSchema.requiresIndirect
            self.nativeSchema = nativeSchema
        }
    }

    var indirectPointerType: LLVMType {
        .pointer
    }
}

/// Does the given function type have a self parameter that should be given the special treatment for self parameters?
///
/// It's important that this only return true for things that are passed as a single pointer.
private func hasSelfContextParameter(_ fnType: SILFunctionType) -> Bool {
    if !fnType.hasSelfParam {
        return false
    }

    let param = fnType.selfParameter

    // All the indirect conventions pass a single pointer.
    if param.isFormalIndirect {
        return true
    }

    // Direct conventions depend on the type.
    let type = param.type

    // Thick or @objc metatypes (but not existential metatypes).
    if let metatype = type.type as? MetatypeType {
        return metatype.representation != .thin;
    }

    // Classes and class-bounded archetypes or ObjC existentials.
    // No need to apply this to existentials.
    // The direct check for ASTSubstitutableType works because only class-bounded generic types can be passed directly.
    if type~>.mayHaveSuperclass || type.type is SubstitutableType || type~>.isObjCExistentialType {
        return true
    }

    return false
}

/// True if a function's signature in LLVM carries polymorphic parameters.
/// Generic functions and protocol witnesses carry polymorphic parameters.
private func hasPolymorphicParameters(_ ty: SILFunctionType) -> Bool {
    switch ty.representation {
    case .thick, .thin, .method, .closure:
        return ty.isPolymorphic

    case .witnessMethod:
        // Always carries polymorphic parameters for the Self type.
        return true
    }
}

private func expandTrailingWitnessSignature(_ igm: IRGenModule, _ polyFn: SILFunctionType, _ out: inout [LLVMType]) {
    precondition(polyFn.representation == .witnessMethod)
    // for simple protocol conformances, we just add %swift.type* %Self and i8** %SelfWitnessTable

    // A witness method always provides Self.
    // out.push_back(IGM.TypeMetadataPtrTy);
    out.append(.pointer)


    // A witness method always provides the witness table for Self.
    // out.push_back(IGM.WitnessTablePtrTy);
    out.append(.pointer)
}

private func expandScalarOrStructTypeToArray(_ ty: LLVMType) -> [LLVMType] {
    if case let .struct(types) = ty {
        return types
    }

    return [ty]
}

/// Expand the requirements of the given abstract calling convention into a "physical" calling convention.
private func expandCallingConv(igm: IRGenModule, convention: SILFunctionTypeRepresentation) -> LLVMCallingConvID {
    switch convention {
    case .method,
         .witnessMethod,
         .closure,
         .thin,
         .thick:
        return .swift
    }
}
