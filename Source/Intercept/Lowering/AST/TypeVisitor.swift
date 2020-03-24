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

protocol CanTypeVisitorRetDefaultConstructible {
    static func `default`() -> Self
}

protocol CanTypeVisitor {
    associatedtype Ret // : CanTypeVisitorRetDefaultConstructible

    func visit(_ type: AType) -> Ret

    func visit(error type: ErrorType) -> Ret
    func visit(builtinInteger type: BuiltinIntegerType) -> Ret
    func visit(builtinFloat type: BuiltinFloatType) -> Ret
    func visit(builtinRawPointer type: BuiltinRawPointerType) -> Ret
    func visit(builtinNativeObject type: BuiltinNativeObjectType) -> Ret
    func visit(builtinBridgeObject type: BuiltinBridgeObjectType) -> Ret
    func visit(builtinUnknownObject type: BuiltinUnknownObjectType) -> Ret
    func visit(builtinUnsafeValueBuffer type: BuiltinUnsafeValueBufferType) -> Ret
    func visit(builtinVector type: BuiltinVectorType) -> Ret
    func visit(tuple type: TupleType) -> Ret
    func visit(weakStorage type: WeakStorageType) -> Ret
    func visit(unownedStorage type: UnownedStorageType) -> Ret
    func visit(unmanagedStorage type: UnmanagedStorageType) -> Ret
    func visit(enum type: EnumType) -> Ret
    func visit(struct type: StructType) -> Ret
    func visit(class type: ClassType) -> Ret
    func visit(protocol type: ProtocolType) -> Ret
    func visit(boundGenericClass type: BoundGenericClassType) -> Ret
    func visit(boundGenericEnum type: BoundGenericEnumType) -> Ret
    func visit(boundGenericStruct type: BoundGenericStructType) -> Ret
    func visit(metatype type: MetatypeType) -> Ret
    func visit(existentialMetatype type: ExistentialMetatypeType) -> Ret
    func visit(module type: ModuleType) -> Ret
    func visit(dynamicSelf type: DynamicSelfType) -> Ret
    func visit(primaryArchetype type: PrimaryArchetypeType) -> Ret
    func visit(opaqueTypeArchetype type: OpaqueTypeArchetypeType) -> Ret
    func visit(openedArchetype type: OpenedArchetypeType) -> Ret
    func visit(nestedArchetype type: NestedArchetypeType) -> Ret
    func visit(genericTypeParam type: GenericTypeParamType) -> Ret
    func visit(dependentMember type: DependentMemberType) -> Ret
    func visit(function type: FunctionType) -> Ret
    func visit(genericFunction type: GenericFunctionType) -> Ret
    func visit(silFunction type: SILFunctionType) -> Ret
    func visit(silBlockStorage type: SILBlockStorageType) -> Ret
    func visit(silBox type: SILBoxType) -> Ret
    func visit(silToken type: SILTokenType) -> Ret
    func visit(protocolComposition type: ProtocolCompositionType) -> Ret
    func visit(lvalue type: LValueType) -> Ret
    func visit(inOut type: InOutType) -> Ret

    // abstract ones
    func visit(anyBuiltinInteger type: AnyBuiltinIntegerType) -> Ret
    func visit(builtin type: BuiltinType) -> Ret
    func visit(referenceStorage type: ReferenceStorageType) -> Ret
    func visit(anyGeneric type: AnyGenericType) -> Ret
    func visit(nominalOrBoundGenericNominal type: NominalOrBoundGenericNominalType) -> Ret
    func visit(nominal type: NominalType) -> Ret
    func visit(boundGeneric type: BoundGenericType) -> Ret
    func visit(anyMetatype type: AnyMetatypeType) -> Ret
    func visit(substitutable type: SubstitutableType) -> Ret
    func visit(archetype type: ArchetypeType) -> Ret
    func visit(anyFunction: AnyFunctionType) -> Ret

    // default catch all
    func visit(anyType: AType) -> Ret
}

extension CanTypeVisitor {
    func visit(error type: ErrorType) -> Ret {
        visit(anyType: type)
    }

    func visit(builtinInteger type: BuiltinIntegerType) -> Ret {
        visit(anyBuiltinInteger: type)
    }

    func visit(builtinFloat type: BuiltinFloatType) -> Ret {
        visit(builtin: type)
    }

    func visit(builtinRawPointer type: BuiltinRawPointerType) -> Ret {
        visit(builtin: type)
    }

    func visit(builtinNativeObject type: BuiltinNativeObjectType) -> Ret {
        visit(builtin: type)
    }

    func visit(builtinBridgeObject type: BuiltinBridgeObjectType) -> Ret {
        visit(builtin: type)
    }

    func visit(builtinUnknownObject type: BuiltinUnknownObjectType) -> Ret {
        visit(builtin: type)
    }

    func visit(builtinUnsafeValueBuffer type: BuiltinUnsafeValueBufferType) -> Ret {
        visit(builtin: type)
    }

    func visit(builtinVector type: BuiltinVectorType) -> Ret {
        visit(builtin: type)
    }

    func visit(tuple type: TupleType) -> Ret {
        visit(anyType: type)
    }

    func visit(weakStorage type: WeakStorageType) -> Ret {
        visit(referenceStorage: type)
    }

    func visit(unownedStorage type: UnownedStorageType) -> Ret {
        visit(referenceStorage: type)
    }

    func visit(unmanagedStorage type: UnmanagedStorageType) -> Ret {
        visit(referenceStorage: type)
    }

    func visit(enum type: EnumType) -> Ret {
        visit(nominal: type)
    }

    func visit(struct type: StructType) -> Ret {
        visit(nominal: type)
    }

    func visit(class type: ClassType) -> Ret {
        visit(nominal: type)
    }

    func visit(protocol type: ProtocolType) -> Ret {
        visit(nominal: type)
    }

    func visit(boundGenericClass type: BoundGenericClassType) -> Ret {
        visit(boundGeneric: type)
    }

    func visit(boundGenericEnum type: BoundGenericEnumType) -> Ret {
        visit(boundGeneric: type)
    }

    func visit(boundGenericStruct type: BoundGenericStructType) -> Ret {
        visit(boundGeneric: type)
    }

    func visit(metatype type: MetatypeType) -> Ret {
        visit(anyMetatype: type)
    }

    func visit(existentialMetatype type: ExistentialMetatypeType) -> Ret {
        visit(anyMetatype: type)
    }

    func visit(module type: ModuleType) -> Ret {
        visit(anyType: type)
    }

    func visit(dynamicSelf type: DynamicSelfType) -> Ret {
        visit(anyType: type)
    }

    func visit(primaryArchetype type: PrimaryArchetypeType) -> Ret {
        visit(archetype: type)
    }

    func visit(opaqueTypeArchetype type: OpaqueTypeArchetypeType) -> Ret {
        visit(archetype: type)
    }

    func visit(openedArchetype type: OpenedArchetypeType) -> Ret {
        visit(archetype: type)
    }

    func visit(nestedArchetype type: NestedArchetypeType) -> Ret {
        visit(archetype: type)
    }

    func visit(genericTypeParam type: GenericTypeParamType) -> Ret {
        visit(substitutable: type)
    }

    func visit(dependentMember type: DependentMemberType) -> Ret {
        visit(anyType: type)
    }

    func visit(function type: FunctionType) -> Ret {
        visit(anyFunction: type)
    }

    func visit(genericFunction type: GenericFunctionType) -> Ret {
        visit(anyFunction: type)
    }

    func visit(silFunction type: SILFunctionType) -> Ret {
        visit(anyType: type)
    }

    func visit(silBlockStorage type: SILBlockStorageType) -> Ret {
        visit(anyType: type)
    }

    func visit(silBox type: SILBoxType) -> Ret {
        visit(anyType: type)
    }

    func visit(silToken type: SILTokenType) -> Ret {
        visit(anyType: type)
    }

    func visit(protocolComposition type: ProtocolCompositionType) -> Ret {
        visit(anyType: type)
    }

    func visit(lvalue type: LValueType) -> Ret {
        visit(anyType: type)
    }

    func visit(inOut type: InOutType) -> Ret {
        visit(anyType: type)
    }

    // abstract ones
    func visit(anyBuiltinInteger type: AnyBuiltinIntegerType) -> Ret {
        visit(builtin: type)
    }

    func visit(builtin type: BuiltinType) -> Ret {
        visit(anyType: type)
    }

    func visit(referenceStorage type: ReferenceStorageType) -> Ret {
        visit(anyType: type)
    }

    func visit(anyGeneric type: AnyGenericType) -> Ret {
        visit(anyType: type)
    }

    func visit(nominalOrBoundGenericNominal type: NominalOrBoundGenericNominalType) -> Ret {
        visit(anyGeneric: type)
    }

    func visit(nominal type: NominalType) -> Ret {
        visit(nominalOrBoundGenericNominal: type)
    }

    func visit(boundGeneric type: BoundGenericType) -> Ret {
        visit(nominalOrBoundGenericNominal: type)
    }

    func visit(anyMetatype type: AnyMetatypeType) -> Ret {
        visit(anyType: type)
    }

    func visit(substitutable type: SubstitutableType) -> Ret {
        visit(anyType: type)
    }

    func visit(archetype type: ArchetypeType) -> Ret {
        visit(substitutable: type)
    }

    func visit(anyFunction type: AnyFunctionType) -> Ret {
        visit(anyType: type)
    }

    // default catch all

    func visit(anyType: AType) -> Ret {
        LoweringError.unreachable("\(#function)") // being here indicates a bug in the cases coverage
    }
}

extension CanTypeVisitor {
    func visit(_ type: AType) -> Ret {
        switch type {
        case let type as ErrorType:
            return visit(error: type)
        case let type as BuiltinIntegerType:
            return visit(builtinInteger: type)
        case let type as BuiltinFloatType:
            return visit(builtinFloat: type)
        case let type as BuiltinRawPointerType:
            return visit(builtinRawPointer: type)
        case let type as BuiltinNativeObjectType:
            return visit(builtinNativeObject: type)
        case let type as BuiltinBridgeObjectType:
            return visit(builtinBridgeObject: type)
        case let type as BuiltinUnknownObjectType:
            return visit(builtinUnknownObject: type)
        case let type as BuiltinUnsafeValueBufferType:
            return visit(builtinUnsafeValueBuffer: type)
        case let type as BuiltinVectorType:
            return visit(builtinVector: type)
        case let type as TupleType:
            return visit(tuple: type)
        case let type as WeakStorageType:
            return visit(weakStorage: type)
        case let type as UnownedStorageType:
            return visit(unownedStorage: type)
        case let type as UnmanagedStorageType:
            return visit(unmanagedStorage: type)
        case let type as EnumType:
            return visit(enum: type)
        case let type as StructType:
            return visit(struct: type)
        case let type as ClassType:
            return visit(class: type)
        case let type as ProtocolType:
            return visit(protocol: type)
        case let type as BoundGenericClassType:
            return visit(boundGenericClass: type)
        case let type as BoundGenericEnumType:
            return visit(boundGenericEnum: type)
        case let type as BoundGenericStructType:
            return visit(boundGenericStruct: type)
        case let type as MetatypeType:
            return visit(metatype: type)
        case let type as ExistentialMetatypeType:
            return visit(existentialMetatype: type)
        case let type as ModuleType:
            return visit(module: type)
        case let type as DynamicSelfType:
            return visit(dynamicSelf: type)
        case let type as PrimaryArchetypeType:
            return visit(primaryArchetype: type)
        case let type as OpaqueTypeArchetypeType:
            return visit(opaqueTypeArchetype: type)
        case let type as OpenedArchetypeType:
            return visit(openedArchetype: type)
        case let type as NestedArchetypeType:
            return visit(nestedArchetype: type)
        case let type as GenericTypeParamType:
            return visit(genericTypeParam: type)
        case let type as DependentMemberType:
            return visit(dependentMember: type)
        case let type as FunctionType:
            return visit(function: type)
        case let type as GenericFunctionType:
            return visit(genericFunction: type)
        case let type as SILFunctionType:
            return visit(silFunction: type)
        case let type as SILBlockStorageType:
            return visit(silBlockStorage: type)
        case let type as SILBoxType:
            return visit(silBox: type)
        case let type as SILTokenType:
            return visit(silToken: type)
        case let type as ProtocolCompositionType:
            return visit(protocolComposition: type)
        case let type as LValueType:
            return visit(lvalue: type)
        case let type as InOutType:
            return visit(inOut: type )
        default:
            LoweringError.unreachable("unknown type: \(type)")
        }
    }
}
