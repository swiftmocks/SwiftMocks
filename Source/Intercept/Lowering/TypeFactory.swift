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
//
// This source file contains code developed by Swift open source project,
// licensed under Apache License v2.0 with Runtime Library Exception. For
// licensing information, see https://swift.org/LICENSE.txt

import Foundation

enum TypeFactory {
    private static var cache = Cache()

    static func from(anyType: Any.Type) -> AType {
        from(metadata: Metadata.of(anyType))
    }

    static func from(metadata: Metadata) -> AType {
        if let cached = cache[metadata] {
            return cached
        }

        let ret: AType

        switch metadata {
        case let classMetadata as ClassMetadata:
            ret = getClassOrBoundGenericClassType(metadata: classMetadata)
        case let structMetadata as StructMetadata:
            ret = getStructOrBoundGenericStructType(metadata: structMetadata)
        case let enumMetadata as EnumMetadata:
            ret = getEnumOrBoundGenericEnumType(metadata: enumMetadata)
        case let optionalMetadata as OptionalMetadata:
            ret = getEnumOrBoundGenericEnumType(metadata: optionalMetadata)
        case let opaqueMetadata as OpaqueMetadata:
            if let known = BuiltinType.from(metadata: opaqueMetadata) {
                ret = known
            } else {
                LoweringError.unreachable("Unknown OpaqueMetadata kind: \(metadata)")
            }
        case let tupleMetadata as TupleTypeMetadata:
            let elements = tupleMetadata.elements.map {
                from(metadata: $0.metadata) // this will never lead to infinite recursion because tuples can't contain themselves
            }
            ret = TupleType._get(elements: elements)
        case let existentialMetadata as ExistentialTypeMetadata:
            if existentialMetadata.numberOfProtocols < 2 {
                ret = ProtocolType._get(metadata: existentialMetadata)
            } else {
                ret = ProtocolCompositionType._get(metadata: existentialMetadata)
            }
        case let metatypeMetadata as MetatypeMetadata:
            ret = MetatypeType._get(instanceType: from(metadata: metatypeMetadata.instanceType))
        case let existentialMetatypeMetadata as ExistentialMetatypeMetadata:
            ret = ExistentialMetatypeType._get(instanceType: from(metadata: existentialMetatypeMetadata.instanceType))
        case let functionTypeMetadata as FunctionTypeMetadata:
            ret = FunctionType._get(metadata: functionTypeMetadata)
        case is ForeignClassMetadata:
            LoweringError.notImplemented("foreign classes")
        case is ObjCClassWrapperMetadata:
            LoweringError.notImplemented("Obj-C wrapper classes")
        case is HeapLocalVariableMetadata:
            LoweringError.notImplemented("heap local variable type")
        default:
            switch metadata.kind {
            case .heapGenericLocalVariable:
                LoweringError.notImplemented("heap generic local variable type")
            case .errorObject:
                LoweringError.notImplemented("error object type")
            default:
                LoweringError.unreachable("unknown metadata kind: \(metadata.kind)")
            }
        }

        return cache.ensureUnique(ret, metadata: metadata)
    }

    static func getSILFunctionType(genericSig: GenericSignature?,
                                   extInfo: SILFunctionType.ExtInfo,
                                   coroutineKind: SILCoroutineKind,
                                   calleeConvention: ParameterConvention,
                                   params: [SILParameterInfo],
                                   yields: [SILYieldInfo],
                                   normalResults: [SILResultInfo],
                                   errorResult: SILResultInfo?,
                                   witnessMethodConformance: ProtocolConformanceRef?
    ) -> SILFunctionType {
        precondition(coroutineKind == .none || normalResults.isEmpty)
        precondition(coroutineKind != .none || yields.isEmpty)
        precondition(!extInfo.isPseudogeneric || genericSig != nil)

        var properties = RecursiveTypeProperties()
        for param in params {
            properties |= param.type~>.recursiveProperties
        }
        for yield in yields {
            properties |= yield.type~>.recursiveProperties
        }
        for result in normalResults {
            properties |= result.type~>.recursiveProperties
        }
        if let errorResult = errorResult {
            properties |= errorResult.type~>.recursiveProperties
        }

        if genericSig != nil {
            properties = properties.removingHasTypeParameter.removingHasDependentMember
        }

        let ret = SILFunctionType._get(genericSig: genericSig,
                                       extInfo: extInfo,
                                       coroutineKind: coroutineKind,
                                       calleeConvention: calleeConvention,
                                       params: params,
                                       yields: yields,
                                       normalResults: normalResults,
                                       errorResult: errorResult,
                                       properties: properties,
                                       witnessMethodConformance: witnessMethodConformance)
        return cache.ensureUnique(ret)
    }

    static func createReferenceStorageType(referentType: AType, referenceOwnership: ReferenceOwnership) -> AType {
        if referenceOwnership == .strong {
            return referentType
        }
        let ret = ReferenceStorageType._get(referentType: referentType, referenceOwnership: referenceOwnership)
        return cache.ensureUnique(ret)
    }

    static func createTupleType(elements: [AType]) -> TupleType {
        let ret = TupleType._get(elements: elements)
        return cache.ensureUnique(ret)
    }

    static func createOptionalType(objectType: AType) -> BoundGenericEnumType {
        let objectMetadata = convert(objectType)
        let objectAnyType = objectMetadata.asAnyType!
        let optionalObjectMetadata = Runtime.getGenericMetadata(descriptor: OptionalMetadata.descriptor, genericParams: [objectMetadata], conformanceWitnessTables: [])

        let fields: [CompositeTypeInfoHelper.RawFieldInfo] = [
            .init(type: objectAnyType, isIndirectEnumCase: false, referenceOwnership: .strong),
            .init(type: nil, isIndirectEnumCase: false, referenceOwnership: .strong)
        ]
        let typeInfoHelper = CompositeTypeInfoHelper(size: optionalObjectMetadata.valueWitnesses.size, alignment: optionalObjectMetadata.valueWitnesses.alignmentMask + 1, fields: fields, fieldOffsets: nil)

        let ret = BoundGenericEnumType._get(typeInfoHelper: typeInfoHelper, typeContextDescriptor: EnumDescriptor.optionalTypeDescriptor, genericParams: [objectType], genericArguments: nil)

        return cache.ensureUnique(ret)
    }

    static func createMetatype(instanceType: AType, representation: MetatypeRepresentation? = nil) -> MetatypeType {
        let ret = MetatypeType._get(instanceType: instanceType, representation: representation)
        return cache.ensureUnique(ret)
    }

    static func metatypeType(_ type: MetatypeType, with representation: MetatypeRepresentation) -> MetatypeType {
        let ret = MetatypeType._with(type: type, representation: representation)
        return cache.ensureUnique(ret)
    }

    static func existentialMetatypeType(_ type: ExistentialMetatypeType, with representation: MetatypeRepresentation) -> ExistentialMetatypeType {
        let ret = ExistentialMetatypeType._with(type: type, representation: representation)
        return cache.ensureUnique(ret)
    }

    static func createAnyFunctionType(params: [FunctionType.Param], result: AType, extInfo: FunctionType.ExtInfo = FunctionType.ExtInfo(representation: .swift, isNoEscape: false, throws: false), genericSignature: GenericSignature? = nil) -> AnyFunctionType {
        let ret = AnyFunctionType._get(params: params, result: result, extInfo: extInfo, genericSignature: genericSignature)
        return cache.ensureUnique(ret)
    }

    static func functionType<T: AnyFunctionType>(_ type: T, with silRepresentation: SILFunctionTypeRepresentation) -> T {
        let ret = type._settingRepresentation(silRepresentation)
        return cache.ensureUnique(ret) as! T
    }

    static func createDynamicSelfType(metadata: Metadata) -> DynamicSelfType {
        let ret = DynamicSelfType._get(selfType: TypeFactory.from(metadata: metadata))
        return cache.ensureUnique(ret)
    }

    static func createDynamicSelfType(selfType: AType) -> DynamicSelfType {
        let ret = DynamicSelfType._get(selfType: selfType)
        return cache.ensureUnique(ret)
    }

    static func createInOutType(metadata: Metadata) -> InOutType {
        let ret = InOutType._get(objectType: TypeFactory.from(metadata: metadata))
        return cache.ensureUnique(ret)
    }

    static var void: TupleType {
        let ret = TupleType._get(elements: [])
        return cache.ensureUnique(ret)
    }

    private static func getEnumOrBoundGenericEnumType(metadata: EnumMetadata) -> AType {
        let typeInfoHelper = CompositeTypeInfoHelper(metadata: metadata)

        if !metadata.typeContextDescriptor.isGeneric {
            return EnumType._get(typeInfoHelper: typeInfoHelper, metadata: metadata)
        }

        let genericParams = metadata.genericParameters.map { TypeFactory.from(metadata: $0) }
        return BoundGenericEnumType._get(typeInfoHelper: typeInfoHelper, typeContextDescriptor: metadata.typeContextDescriptor, genericParams: genericParams, genericArguments: metadata.genericArgumentsPointer)
    }

    fileprivate static func getStructOrBoundGenericStructType(metadata: StructMetadata) -> AType {
        let typeInfoHelper = CompositeTypeInfoHelper(metadata: metadata)

        if !metadata.typeContextDescriptor.isGeneric {
            return StructType._get(typeInfoHelper: typeInfoHelper, metadata: metadata)
        }

        let genericParams = metadata.genericParameters.map { TypeFactory.from(metadata: $0) }
        return BoundGenericStructType._get(typeInfoHelper: typeInfoHelper, typeContextDescriptor: metadata.typeContextDescriptor, genericParams: genericParams, genericArguments: metadata.genericArgumentsPointer)
    }

    fileprivate static func getClassOrBoundGenericClassType(metadata: ClassMetadata) -> AType {
        let typeInfoHelper = CompositeTypeInfoHelper(metadata: metadata)

        if !metadata.typeContextDescriptor.isGeneric {
            return ClassType._get(typeInfoHelper: typeInfoHelper, metadata: metadata)
        }

        let genericParams = metadata.genericParameters.map { TypeFactory.from(metadata: $0) }
        return BoundGenericClassType._get(typeInfoHelper: typeInfoHelper, typeContextDescriptor: metadata.typeContextDescriptor, genericParams: genericParams, genericArguments: metadata.genericArgumentsPointer)
    }
}

extension TypeFactory {
    static func convert(_ type: AType) -> Metadata {
        if let cached = cache[type] {
            return cached
        }

        let ret: Metadata
        switch type {
        case let ty as AlwaysHasMetadata:
            ret = ty.metadata
        case let ty as CanComputeMetadata2:
            ret = ty.computedMetadata2
        case let ty as CanComputeMetadata:
            ret = ty.computedMetadata
        default:
            LoweringError.unreachable("cannot convert type to metadata: \(type)")
        }

        cache[type] = ret

        return ret
    }

    static func convert(_ tupleType: TupleType) -> TupleTypeMetadata {
        convert(tupleType as AType) as! TupleTypeMetadata
    }
}

private protocol CanComputeMetadata2 {
    var computedMetadata2: Metadata { get }
}

extension SILFunctionType: CanComputeMetadata2 {
    var computedMetadata2: Metadata {
        extInfo.representation == .thick ? Metadata.of((() -> ()).self) : Metadata.of((@convention(c) () -> ()).self)
    }
}

extension AnyFunctionType: CanComputeMetadata2 {
    var computedMetadata2: Metadata {
        extInfo.silRepresentation == .thick ? Metadata.of((() -> ()).self) : Metadata.of((@convention(c) () -> ()).self)
    }
}

extension BoundGenericType: CanComputeMetadata2 {
    var computedMetadata2: Metadata {
        if let genericArgumentsPtr = genericArguments {
            return Runtime.getGenericMetadata(descriptor: typeContextDescriptor, genericArguments: genericArgumentsPtr)
        } else {
            // the only exception where we don't keep pre-made genericArgumentsPtr is for optionals, since they can be dynamically created during lowering
            assert(typeContextDescriptor == EnumDescriptor.optionalTypeDescriptor)
            return Runtime.getGenericMetadata(descriptor: typeContextDescriptor, genericParams: genericParams.map { TypeFactory.convert($0) }, conformanceWitnessTables: [])
        }
    }
}

extension AnyMetatypeType: CanComputeMetadata2 {
    var computedMetadata2: Metadata {
        Runtime.getMetatypeMetadata(instanceType: TypeFactory.convert(instanceType))
    }
}

extension TupleType: CanComputeMetadata2 {
    var computedMetadata2: Metadata {
        Runtime.getTupleTypeMetadata(elements: elements.map { TypeFactory.convert($0) })
    }
}

extension ReferenceStorageType: CanComputeMetadata2 {
    var computedMetadata2: Metadata {
        TypeFactory.convert(referentType)
    }
}

extension InOutType: CanComputeMetadata2 {
    var computedMetadata2: Metadata {
        TypeFactory.convert(objectType)
    }
}

extension DynamicSelfType: CanComputeMetadata2 {
    var computedMetadata2: Metadata {
        TypeFactory.convert(selfType)
    }
}

extension TypeFactory {
    fileprivate struct Cache {
        private var metadataToType = [Metadata: AType]()
        private var typeToMetadata = [AType: Metadata]()
        private var allTypes = Set<AType>()

        mutating func ensureUnique<T: AType>(_ type: T, metadata: Metadata? = nil) -> T {
            if let existing = allTypes.first(where: { AType.equal(lhs: type, rhs: $0) } ) {
                return existing as! T
            }

            allTypes.insert(type)
            if let metadata = metadata, !(type is AnyFunctionType) && !(type is SILFunctionType) /* those have non-unique metadata */ {
                metadataToType[metadata] = type
                typeToMetadata[type] = metadata
            }

            return type
        }

        subscript(_ metadata: Metadata) -> AType? {
            metadataToType[metadata]
        }

        subscript(_ type: AType) -> Metadata? {
            get {
                typeToMetadata[type]
            }
            set {
                typeToMetadata[type] = newValue
            }
        }
    }
}
