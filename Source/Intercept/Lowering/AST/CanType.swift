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

postfix operator ~>

struct CanType: Hashable {
    let type: AType

    var hasReferenceSemantics: Bool {
        CanType.isReferenceTypeImpl(canType: self, functionsCount: true)
    }

    /// Are values of this type essentially just class references, possibly with some extra metadata?
    ///   - any of the builtin reference types
    ///   - a class type
    ///   - a bound generic class type
    ///   - a class-bounded archetype type
    ///   - a class-bounded existential type
    ///   - a dynamic Self type
    var isAnyClassReferenceType: Bool {
        CanType.isReferenceTypeImpl(canType: self, functionsCount: false)
    }

    var isExistentialType: Bool {
        type is ProtocolType || type is ProtocolCompositionType
    }

    var isAnyExistentialType: Bool {
        isExistentialType || type is ExistentialMetatypeType
    }

    var isObjCExistentialType: Bool {
        CanType.isObjCExistentialTypeImpl(canType: self)
    }

    var optionalObjectType: CanType? {
        .getOptionalObjectTypeImpl(canType: self)
    }

    var isClassOrBoundGenericClass: Bool {
        type is ClassType || type is BoundGenericClassType
    }

    var existentialLayout: ExistentialLayout {
        precondition(isExistentialType)
        if let proto = type as? ProtocolType {
            return ExistentialLayout(proto: proto)
        } else if let protoComp = type as? ProtocolCompositionType {
            return ExistentialLayout(protoComp: protoComp)
        }
        LoweringError.unreachable("asking for existential layout for a non-existential type")
    }

    var referenceStorageReferent: CanType {
        if let type = type as? ReferenceStorageType {
            return CanType(type: type.referentType)
        }
        return CanType(type: type)
    }

    func tupleElementType(index: Int) -> CanType {
        if let tuple = type as? TupleType {
            return CanType(type: tuple.elements[index])
        }

        assert(index == 0)
        return self
    }

    private static func isObjCExistentialTypeImpl(canType: CanType) -> Bool {
        if !canType.isExistentialType {
            return false
        }
        return canType.existentialLayout.isObjC
    }

    private static func getOptionalObjectTypeImpl(canType: CanType) -> CanType? {
        guard let enumType = canType.type as? BoundGenericEnumType,
            let optionalObjectType = enumType.optionalObjectType else {
                return nil
        }
        return CanType(type: optionalObjectType) // ??? or optionalObjectType.canonicalType
    }

    static func isReferenceTypeImpl(canType: CanType, functionsCount: Bool) -> Bool {
        isReferenceTypeImpl(type: canType.type, functionsCount: functionsCount)
    }

    static func isReferenceTypeImpl(type: AType, functionsCount: Bool) -> Bool  {
        switch type.kind {
        // These types are always class references.
        case .builtinUnknownObject,
             .builtinNativeObject,
             .builtinBridgeObject,
             .class,
             .boundGenericClass,
             .silBox:
            return true

        // For Self types, recur on the underlying type.
        case .dynamicSelf:
            let selfType = CanType(type: (type as! DynamicSelfType).selfType)
            return isReferenceTypeImpl(canType: selfType, functionsCount: functionsCount)

        // Archetypes and existentials are only class references if class-bounded.
        case .primaryArchetype,
             .openedArchetype,
             .nestedArchetype,
             .opaqueTypeArchetype:
            return (type as! ArchetypeType).requiresClass

        case .protocol:
            return (type as! ProtocolType).requiresClass

        case .protocolComposition:
            return (type as! ProtocolCompositionType).requiresClass

        // Functions have reference semantics, but are not class references.
        case .function,
             .genericFunction,
             .silFunction:
            return functionsCount

        // Nothing else is statically just a class reference.
        case .silBlockStorage,
             .error,
             .builtinInteger,
             .builtinIntegerLiteral,
             .builtinFloat,
             .builtinRawPointer,
             .builtinUnsafeValueBuffer,
             .builtinVector,
             .tuple,
             .enum,
             .struct,
             .metatype,
             .existentialMetatype,
             .module,
             .lvalue,
             .inOut,
             .boundGenericEnum,
             .boundGenericStruct,
             .silToken:
            fallthrough
        case .weakStorage,
             .unownedStorage,
             .unmanagedStorage:
            return false

        case .genericTypeParam, .dependentMember:
          LoweringError.unreachable("Dependent types can't answer reference-semantics query");
        }
    }

    var isNominalOrBoundGenericNominal: Bool {
        type is NominalOrBoundGenericNominalType
    }

    static postfix func ~> (this: Self) -> AType {
        return this.type
    }
}

extension CanType {
    static func from(metadata: Metadata) -> CanType {
        CanType(type: TypeFactory.from(metadata: metadata))
    }

    static func from(anyType: Any.Type) -> CanType {
        CanType(type: TypeFactory.from(anyType: anyType))
    }
}

extension CanType {
    // Builtin type and simple types that are used frequently.

    /// This is '()', aka Void
    static var TheEmptyTupleType: CanType = CanType.from(anyType: Void.self)

    /// This is 'Any', the empty protocol composition
    static var TheAnyType: CanType = CanType.from(anyType: Any.self)
    /// Builtin.NativeObject
    static var TheNativeObjectType: CanType = CanType.from(metadata: OpaqueMetadata.Builtin.NativeObject)
    /// Builtin.BridgeObject
    static var TheBridgeObjectType: CanType = CanType.from(metadata: OpaqueMetadata.Builtin.BridgeObject)
    /// Builtin.UnknownObject
    static var TheUnknownObjectType: CanType = CanType.from(metadata: OpaqueMetadata.Builtin.UnknownObject)
    /// Builtin.RawPointer
    static var TheRawPointerType: CanType = CanType.from(metadata: OpaqueMetadata.Builtin.RawPointer)
    /// Builtin.UnsafeValueBuffer
    static var TheUnsafeValueBufferType: CanType = CanType.from(metadata: OpaqueMetadata.Builtin.UnsafeValueBuffer)

    /// 32-bit IEEE floating point
    static var TheIEEE32Type: CanType = CanType.from(metadata: OpaqueMetadata.Builtin.FPIEEE32)
    /// 64-bit IEEE floating point
    static var TheIEEE64Type: CanType = CanType.from(metadata: OpaqueMetadata.Builtin.FPIEEE64)

    // Target specific types — all unimplemented, because we don't support any of them in IR
    /// 16-bit IEEE floating point
    static var TheIEEE16Type: CanType = { CanType.from(metadata: OpaqueMetadata.Builtin.FPIEEE16) }()
    /// 80-bit IEEE floating point
    static var TheIEEE80Type: CanType = { CanType.from(metadata: OpaqueMetadata.Builtin.FPIEEE80) }()
    /// 128-bit IEEE floating point
    static var TheIEEE128Type: CanType = { CanType.from(metadata: OpaqueMetadata.Builtin.FPIEEE128) }()
}

extension CanType {
    static func == (lhs: CanType, rhs: CanType) -> Bool {
        lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        type.hash(into: &hasher)
    }
}
