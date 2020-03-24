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

/// A protocol for custom equality checks for `AType` subclasses. Most subclasses are only a facade for the existing runtime metadata, and comparing them is easy — just compare the metadatas (which is really just comparing the pointers). Such fast path comparison is implemented by the custom `==` operator.
/// A few subclasses, however, do not have a backing metadata, and therefore this fast path won't work for them. Those subclasses need to adopt `ATypeEquatable` interface, and implement equality checking themselves.
protocol ATypeEquatable {
    func isEqual(to other: AType) -> Bool
}

protocol CanComputeMetadata {
    var computedMetadata: Metadata { get }
}

protocol AlwaysHasMetadata: ATypeEquatable {
    var metadata: Metadata { get }
}

extension AlwaysHasMetadata {
    func isEqual(to other: AType) -> Bool {
        guard let other = other as? AlwaysHasMetadata else {
            return false
        }
        return metadata == other.metadata
    }
}

/// Base class for all AST types. In the compiler all types are represented with `TypeBase` and box type `Type`. Here they are combined into one.
class AType: Hashable {
    let kind: TypeKind
    let recursiveProperties: RecursiveTypeProperties = .init() // these are only used when dealing with generics, so leaving them blank

    init(kind: TypeKind) {
        self.kind = kind
    }

    var isCanonical: Bool {
        true
    }

    var canonicalType: CanType {
        return CanType(type: self)
    }

    /// Do objects of this type have reference semantics?
    var hasReferenceSemantics: Bool {
        canonicalType.hasReferenceSemantics
    }

    var anyNominal: NominalTypeDecl? {
        guard let nominal = self as? NominalType else {
            return nil
        }
        switch self {
        case let strct as StructType:
            return StructDecl(type: strct)
        case let clss as ClassType:
            return ClassDecl(type: clss)
        case let enm as EnumType:
            return EnumDecl(type: enm)
        case let proto as ProtocolType:
            return ProtocolDecl(proto: proto)
        default:
            LoweringError.unreachable("unknown nominal type subclass: \(type(of: self))")
        }
    }

    /// Is this a nominally uninhabited type, such as 'Never'?
    var isUninhabited: Bool {
        if let ty = self as? EnumType {
            return ty.numberOfElements == 0
        } else if let ty = self as? BoundGenericEnumType {
            return ty.numberOfElements == 0
        }
        return false
    }

    /// Is this an uninhabited type, such as 'Never' or '(Never, Int)'?
    var isStructurallyUninhabited: Bool {
        if isUninhabited {
            return true
        }
        guard let tupleType = canonicalType.type as? TupleType else {
            return false
        }
        return tupleType.elements.contains { $0.isStructurallyUninhabited }
    }

    var isAny: Bool {
        self == CanType.TheAnyType.type
    }

    /// Are values of this type essentially just class references,
    /// possibly with some sort of additional information?
    ///
    ///   - any of the builtin reference types
    ///   - a class type
    ///   - a bound generic class type
    ///   - a class-bounded archetype type
    ///   - a class-bounded existential type
    ///   - a dynamic Self type
    var isAnyClassReferenceType: Bool {
        canonicalType.isAnyClassReferenceType
    }

    /// Are variables of this type permitted to have ownership attributes? This includes:
    ///   - class types, generic or not
    ///   - archetypes with class or class protocol bounds
    ///   - existentials with class or class protocol bounds
    /// But not:
    ///   - function types
    var allowsOwnership: Bool {
        canonicalType.isAnyClassReferenceType
    }

    // skipped a lot of methods that don't seem relevant at this point

    /// Determines whether this type is an existential type, whose real (runtime) type is unknown but which is known to conform to some set of protocols. Protocol and protocol-conformance types are existential types.
    var isExistentialType: Bool {
        canonicalType.isExistentialType
    }

    /// Determines whether this type is any kind of existential type: a protocol type, a protocol composition type, or an existential metatype.
    var isAnyExistentialType: Bool {
        canonicalType.isAnyExistentialType
    }

    /// Determines whether this type is an class-bounded existential type whose required conformances are all @objc.  Such types are compatible with ObjC.
    var isObjCExistentialType: Bool {
        canonicalType.isObjCExistentialType
    }

    /// Determines whether this type is an existential type with a class protocol bound.
    var isClassExistentialType: Bool {
        if let proto = canonicalType.type as? ProtocolType {
            return proto.requiresClass
        }
        if let protoComposition = canonicalType.type as? ProtocolCompositionType {
            return protoComposition.requiresClass
        }
        return false
    }

    var existentialLayout: ExistentialLayout {
        canonicalType.existentialLayout
    }

    var isVoid: Bool {
        (canonicalType.type as? TupleType)?.elements.count == 0
    }

    // bool isBool();
    // bool isBuiltinIntegerType(unsigned bitWidth);
    // ClassDecl *getClassOrBoundGenericClass();
    var isClassOrBoundGenericClass: Bool {
        canonicalType.isClassOrBoundGenericClass
    }
    // StructDecl *getStructOrBoundGenericStruct();
    // EnumDecl *getEnumOrBoundGenericEnum();

    /// Determine whether this type may have a superclass, which holds for classes, bound generic classes, and archetypes that are only instantiable with a class type.
    var mayHaveSuperclass: Bool {
        if isClassOrBoundGenericClass {
            return true
        }
        if let archetype = self as? ArchetypeType {
            return archetype.requiresClass
        }
        return self is DynamicSelfType
    }

    /// Determine whether this type satisfies a class layout constraint, written `T: AnyObject` in the source.
    /// A class layout constraint is satisfied when we have a single retainable pointer as the representation, which includes:
    /// - @objc existentials
    /// - class constrained archetypes
    /// - classes
    var satisfiesClassConstraint: Bool {
        mayHaveSuperclass || isObjCExistentialType
    }

    // bool mayHaveMembers()

    /// Determines whether this type has a retainable pointer representation, i.e. whether it is representable as a single, possibly nil pointer that can be unknown-retained and unknown-released.
    var hasRetainablePointerRepresentation: Bool {
        AType.hasRetainablePointerRepresentation(canType: canonicalType)
    }

    private static func hasRetainablePointerRepresentation(canType: CanType) -> Bool {
        var canType = canType
        if let unwrapped = canType.optionalObjectType {
            canType = unwrapped
        }
        return isBridgeableObjectType(canType: canType)
    }

    // ReferenceCounting getReferenceCounting();

    var isBridgeableObjectType: Bool {
        AType.isBridgeableObjectType(canType: canonicalType)
    }

    private static func isBridgeableObjectType(canType: CanType) -> Bool {
        if let metaTy = canType.type as? AnyMetatypeType {
            if metaTy.representation == nil {
                return false
            }
            if metaTy.representation != .objc {
                return false
            }
            if let metatype = metaTy as? MetatypeType {
                let instanceType = metatype.instanceType.canonicalType
                return instanceType~>.mayHaveSuperclass
            }
            if let metatype = metaTy as? ExistentialMetatypeType {
                let instanceType = metatype.instanceType.canonicalType
                return instanceType~>.isObjCExistentialType
            }
        }

        if canType~>.mayHaveSuperclass {
            return true
        }

        if canType.isObjCExistentialType {
            return true
        }

        return false
    }

    // bool isPotentiallyBridgedValueType();
    // NominalTypeDecl *getNominalOrBoundGenericNominal();
    // NominalTypeDecl *getAnyNominal();
    // ...

    var isAnyObject: Bool {
        if !canonicalType.isExistentialType {
            return false
        }
        return canonicalType.existentialLayout.isAnyObject
    }

    // bool isExistentialWithError();

    /// Determine whether this type is a type parameter, which is either a GenericTypeParamType or a DependentMemberType.
    /// Note that this routine will return `false` for types that include type parameters in nested positions, e.g, `T` is a type parameter but  `X<T>` is not a type parameter. Use `hasTypeParameter` to determine whether a type parameter exists at any position.
    var isTypeParameter: Bool {
        if self is GenericTypeParamType {
            return true
        }

        if let depMemTy = self as? DependentMemberType {
            return depMemTy.base.isTypeParameter
        }

        return false
    }

    var optionalObjectType: AType? { nil } // overridden by BoundGenericEnumType

    var referenceCounting: ReferenceCounting {
        switch canonicalType.type.kind {
        case .builtinNativeObject,
             .silBox:
            return .native
        case .builtinBridgeObject:
            return .bridge
        case .builtinUnknownObject:
            return .unknown
        case .class:
            // (theClass->checkAncestry(AncestryFlags::ClangImported) ? ReferenceCounting::ObjC : ReferenceCounting::Native)
            return .native
        case .boundGenericClass:
            // (theClass->checkAncestry(AncestryFlags::ClangImported) ? ReferenceCounting::ObjC : ReferenceCounting::Native)
            return .native
        case .dynamicSelf:
            return (self as! DynamicSelfType).selfType.referenceCounting
        case .primaryArchetype,
             .openedArchetype,
             .nestedArchetype,
             .opaqueTypeArchetype:
            LoweringError.notImplemented("archetypes")
        case .protocol,
             .protocolComposition:
            let layout = existentialLayout
            assert(layout.requiresClass, "Opaque existentials don't use refcounting")
            if let superclass = layout.superclass {
                return superclass.referenceCounting
            }
            return .unknown
        default:
            LoweringError.unreachable("asking for reference counting for \(canonicalType.type.kind)")
        }
    }

    private func abstract(function: StaticString = #function) -> Never {
        LoweringError.unreachable("\(function) must be implemented in \(Self.self)")
    }
}

extension AType {
    static func equal(lhs: AType, rhs: AType) -> Bool {
        if let equatableType = lhs as? ATypeEquatable {
            return equatableType.isEqual(to: rhs)
        }

        if let equatableType = rhs as? ATypeEquatable {
            return equatableType.isEqual(to: lhs)
        }

        return false
    }
}

extension AType {
    static func ==(lhs: AType, rhs: AType) -> Bool {
        Unmanaged.passUnretained(lhs).toOpaque() == Unmanaged.passUnretained(rhs).toOpaque()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(Unmanaged.passUnretained(self).toOpaque())
    }
}

extension AType {
    var isOpenedExistentialWithError: Bool { false }
    var isOpenedExistential: Bool { false }
    var hasOpenedExistential: Bool { false }
    var hasTypeParameter: Bool { false }
    var hasArchetype: Bool { false }
}

/// The kind of reference counting implementation a heap object uses.
enum ReferenceCounting {
      /// The object uses native Swift reference counting.
      case native

      /// The object uses ObjC reference counting.
      /// When ObjC interop is enabled, native Swift class objects are also ObjC reference counting compatible. Swift non-class heap objects are never ObjC reference counting compatible. Blocks are always ObjC reference counting compatible.
      case objC

      /// The object uses `_Block_copy`/`_Block_release` reference counting.
      /// This is a strict subset of ObjC; all blocks are also ObjC reference counting compatible. The block is assumed to have already been moved to the heap so that `_Block_copy` returns the same object back.
      case block

      /// The object has an unknown reference counting implementation.
      /// This uses maximally-compatible reference counting entry points in the runtime.
      case unknown

      /// Cases prior to this one are binary-compatible with Unknown reference counting.
      // LastUnknownCompatible = Unknown,

      /// The object has an unknown reference counting implementation and the reference value may contain extra bits that need to be masked.
      /// This uses maximally-compatible reference counting entry points in the runtime, with a masking layer on top. A bit inside the pointer is used to signal native Swift refcounting.
      case bridge

      /// The object uses `ErrorType`'s reference counting entry points.
      case error
}

struct ParameterTypeFlags: Hashable {
    let isVariadic: Bool
    let isAutoclosure: Bool
    let valueOwnership: ValueOwnership

    var isNone: Bool {
        !isVariadic && !isAutoclosure && valueOwnership == .default
    }

    init(isVariadic: Bool = false, isAutoclosure: Bool = false, valueOwnership: ValueOwnership = .default) {
        self.isVariadic = isVariadic
        self.isAutoclosure = isAutoclosure
        self.valueOwnership = valueOwnership
    }
}
