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

private extension AType {
    /// Retrieve the superclass of this type.
    /// - Parameter useArchetypes: Whether to use context archetypes for outer generic parameters if the class is nested inside a generic function.
    /// - Returns: The superclass of this type, or a null type if it has no superclass.
    func getSuperclass(useArchetypes: Bool) -> AType? {
        fatalError("SIL+Unused")
    }

    func isExactSuperclassOf(_ Ty: CanType) -> Bool { fatalError("SIL+Unused") }
    func isBindableToSuperclassOf(_ Ty: CanType) -> Bool { fatalError("SIL+Unused") }
}

private struct SILFunction {
    let module: SILModule
    let loweredType: SILFunctionType
}

private extension SILType {
    // var isNull: Bool { value.type == nil }
    
    /// Returns the `Category` variant of this type.
    func getCategoryType(category: SILValueCategory) -> SILType {
        SILType(canType: getASTType(), category: category)
    }
    
    /// Returns the variant of this type that matches `Ty.getCategory()`
    func copyCategory(type: SILType) -> SILType {
        getCategoryType(category: category)
    }
    
    /// Returns the address variant of this type.  Instructions which manipulate memory will generally work with object addresses.
    func getAddressType() -> SILType {
        SILType(canType: getASTType(), category: .address)
    }
    
    /// Returns the object variant of this type.  Note that address-only types are not legal to manipulate directly as objects in SIL.
    func getObjectType() -> SILType {
        return SILType(canType: getASTType(), category: .object);
    }
    /// Returns the AbstractCC of a function type. The SILType must refer to a function type.
    func getFunctionRepresentation() -> SILFunctionTypeRepresentation {
        guard let function = getASTType().type as? SILFunctionType else {
            preconditionFailure("Not a SILFunctionType")
        }
        return function.representation
    }
    
    var isVoid: Bool {
        type.isVoid == true
    }
    
    /// True if the type is an address type.
    var isAddress: Bool {
        category == .address
    }
    /// True if the type, or the referenced type of an address type, is loadable. This is the opposite of isAddressOnly.
    var isLoadable: Bool {
        return !isAddressOnly
    }
    
    /// True if either:
    /// 1) The type, or the referenced type of an address type, is loadable.
    /// 2) The SIL Module conventions uses lowered addresses
    var isLoadableOrOpaque: Bool { fatalError("SIL+Unused") }
    
    /// True if the type, or the referenced type of an address type, is address-only. This is the opposite of isLoadable.
    var isAddressOnly: Bool { fatalError("SIL+Unused") }
    
    /// True if the type, or the referenced type of an address type, is known to be a scalar reference-counted type. If this is false, then some part of the type may be opaque. It may become reference counted later after specialization.
    var isReferenceCounted: Bool { fatalError("SIL+Unused") }
    
    /// Returns true if the referenced type is a function type that never returns.
    var isNoReturnFunction: Bool { fatalError("SIL+Unused") }
    
    /// Returns true if the referenced type has reference semantics.
    var hasReferenceSemantics: Bool {
        getASTType().hasReferenceSemantics
    }
    
    /// Returns true if the referenced type is any sort of class-reference type, meaning anything with reference semantics that is not a function type.
    var isAnyClassReferenceType: Bool {
        getASTType().isAnyClassReferenceType
    }
    
    /// Returns true if the referenced type is guaranteed to have a single-retainable-pointer representation.
    var hasRetainablePointerRepresentation: Bool {
        getASTType()~>.hasRetainablePointerRepresentation
    }
    /// Returns true if the referenced type is any kind of existential type.
    var isAnyExistentialType: Bool {
        getASTType().isAnyExistentialType
    }
    /// Returns true if the referenced type is a class existential type.
    var isClassExistentialType: Bool {
        getASTType()~>.isClassExistentialType
    }
    
    /// Returns true if the referenced type is an opened existential type (which is actually a kind of archetype).
    var isOpenedExistential: Bool {
        getASTType()~>.isOpenedExistential
    }
    
    /// Returns true if the referenced type is expressed in terms of one or more opened existential types.
    var hasOpenedExistential: Bool {
        getASTType()~>.hasOpenedExistential
    }
    //    /// Returns true if the existential type can use operations for the given existential representation when working with values of the given type, or when working with an unknown type if containedType is null.
    func canUseExistentialRepresentation(_ representation: SILExistentialRepresentation, containedType: AType?) -> Bool { fatalError("SIL+Unused") }
    
    /// True if the type contains a type parameter.
    var hasTypeParameter: Bool {
        getASTType()~>.hasTypeParameter
    }
    
    /// True if the type is bridgeable to an ObjC object pointer type.
    var isBridgeableObjectType: Bool {
        getASTType()~>.isBridgeableObjectType
    }
    
    static func isClassOrClassMetatype(_ t: AType) -> Bool {
        if let meta = t as? AnyMetatypeType {
            return meta.instanceType.canonicalType~>.isClassOrBoundGenericClass
        }
        
        return t.isClassOrBoundGenericClass
    }
    
    /// True if the type is a class type or class metatype type.
    var isClassOrClassMetatype: Bool {
        isObject && SILType.isClassOrClassMetatype(getASTType().type)
    }
    
    /// True if the type involves any archetypes.
    var hasArchetype: Bool {
        getASTType()~>.hasArchetype
    }
    
    // /// Returns the ASTContext for the referenced Swift type.
    // ASTContext &getASTContext() const {
    //   return getASTType()->getASTContext();
    // }
    
    /// True if the given type has at least the size and alignment of a native pointer.
    var isPointerSizeAndAligned: Bool { fatalError("SIL+Unused") }
    
    /// True if `operTy` can be cast by single-reference value into `resultTy`.
    // static bool canRefCast(SILType operTy, SILType resultTy, SILModule &M);
    
    /// True if the type is block-pointer-compatible, meaning it either is a block or is an Optional with a block payload.
    var isBlockPointerCompatible: Bool {
        fatalError("SIL+Unused")
        /*
         // Look through one level of optionality.
         SILType ty = *this;
         if (auto optPayload = ty.getOptionalObjectType()) {
         ty = optPayload;
         }
         
         auto fTy = ty.getAs<SILFunctionType>();
         if (!fTy)
         return false;
         return fTy->getRepresentation() == SILFunctionType::Representation::Block;
         */
    }
    
    /// Given that this is a nominal type, return the lowered type of
    /// the given field.  Applies substitutions as necessary.  The
    /// result will be an address type if the base type is an address
    /// type or a class.
    // SILType getFieldType(VarDecl *field, SILModule &M) const;
    
    /// Given that this is an enum type, return the lowered type of the
    /// data for the given element.  Applies substitutions as necessary.
    /// The result will have the same value category as the base type.
    // SILType getEnumElementType(EnumElementDecl *elt, SILModule &M) const;
    
    /// Given that this is a tuple type, return the lowered type of the
    /// given tuple element.  The result will have the same value
    /// category as the base type.
    // SILType getTupleElementType(unsigned index) const {
    //   return SILType(castTo<TupleType>().getElementType(index), getCategory());
    // }
    
    /// Return the immediate superclass type of this type, or null if it's the most-derived type.
    var getSuperclass: SILType? {
        guard let superclass = getASTType()~>.getSuperclass(useArchetypes: true) else {
            return nil
        }
        return SILType.getPrimitiveObjectType(superclass.canonicalType)
    }
    
    /// Return true if Ty is a subtype of this exact SILType, or false otherwise.
    func isExactSuperclassOf(_ Ty: SILType) -> Bool {
        getASTType()~>.isExactSuperclassOf(Ty.getASTType())
    }
    
    /// Return true if Ty is a subtype of this SILType, or if this SILType contains archetypes that can be found to form a supertype of Ty, or false otherwise.
    func isBindableToSuperclassOf(_ Ty: SILType) -> Bool {
        getASTType()~>.isBindableToSuperclassOf(Ty.getASTType())
    }
    
    /// Return true if this type references a "ref" type that has a single pointer representation. Class existentials do not always qualify.
    var isHeapObjectReferenceType: Bool { fatalError("SIL+Unused") }
    
    /// Returns true if this SILType is an aggregate that contains \p Ty
    func aggregateContainsRecord(_ Ty: SILType) -> Bool { fatalError("SIL+Unused") }
    
    /// Returns true if this SILType is an aggregate with unreferenceable storage, meaning it cannot be fully destructured in SIL.
    var aggregateHasUnreferenceableStorage: Bool { fatalError("SIL+Unused") }
    
    /// Returns the lowered type for T if this type is Optional<T>; otherwise, return the null type.
    var getOptionalObjectType: SILType { fatalError("SIL+Unused") }
    
    /// Unwraps one level of optional type. Returns the lowered T if the given type is Optional<T>. Otherwise directly returns the given type.
    var unwrapOptionalType: SILType { fatalError("SIL+Unused") }
    
    /// Returns true if this is the AnyObject SILType;
    var isAnyObject: Bool {
        getASTType()~>.isAnyObject
    }
    
    /// Returns a SILType with any archetypes mapped out of context.
    func mapTypeOutOfContext() -> SILType { fatalError("SIL+Unused") }
    
    /// Given two SIL types which are representations of the same type, check whether they have an abstraction difference.
    func hasAbstractionDifference(_ rep: SILFunctionTypeRepresentation, _ type2: SILType) -> Bool { fatalError("SIL+Unused") }
    
    /// Returns true if this SILType could be potentially a lowering of the given formal type. Meant for verification purposes/assertions.
    func isLoweringOf(formalType: CanType) -> Bool { fatalError("SIL+Unused") }
    
    /// Like isLoadable(SILModule), but specific to a function.
    ///
    /// This takes the resilience expansion of the function into account. If the type is not loadable in general (because it's resilient), it still might be loadable inside a resilient function in the module.
    /// In other words: isLoadable(SILModule) is the conservative default, whereas isLoadable(SILFunction) might give a more optimistic result.
    func isLoadable(_ F: SILFunction) -> Bool {
        !isAddressOnly(F)
    }
    
    /// Like isLoadableOrOpaque(SILModule), but takes the resilience expansion of `F` into account (see isLoadable(SILFunction)).
    func isLoadableOrOpaque(_ F: SILFunction) -> Bool { fatalError("SIL+Unused") }
    
    /// Like isAddressOnly(SILModule), but takes the resilience expansion of `F` into account (see isLoadable(SILFunction)).
    func isAddressOnly(_ F: SILFunction) -> Bool { fatalError("SIL+Unused") }
    
    /// True if the type, or the referenced type of an address type, is trivial, meaning it is loadable and can be trivially copied, moved or detroyed.
    func isTrivial(_ F: SILFunction) -> Bool { fatalError("SIL+Unused") }
    
    /// Get the NativeObject type as a SILType.
    static func getNativeObjectType() -> SILType { fatalError("SIL+Unused") }
    /// Get the UnknownObject type as a SILType.
    static func getUnknownObjectType() -> SILType { fatalError("SIL+Unused") }
    /// Get the BridgeObject type as a SILType.
    static func getBridgeObjectType() -> SILType { fatalError("SIL+Unused") }
    /// Get the RawPointer type as a SILType.
    static func getRawPointerType() -> SILType { fatalError("SIL+Unused") }
    /// Get a builtin integer type as a SILType.
    static func getBuiltinIntegerType(bitWidth: Int) -> SILType { fatalError("SIL+Unused") }
    /// Get the IntegerLiteral type as a SILType.
    static func getBuiltinIntegerLiteralType() -> SILType { fatalError("SIL+Unused") }
    /// Get a builtin floating-point type as a SILType.
    static func getBuiltinFloatType(_ kind: BuiltinFloatType.FPKind) -> SILType { fatalError("SIL+Unused") }
    /// Get the builtin word type as a SILType;
    static func getBuiltinWordType() -> SILType { fatalError("SIL+Unused") }
    
    /// Given a value type, return an optional type wrapping it.
    static func getOptionalType(valueType: SILType) -> SILType { fatalError("SIL+Unused") }
    
    /// Get the SIL token type.
    static func getSILTokenType() -> SILType { fatalError("SIL+Unused") }
    
}


private struct SILTypeLowering {}


/// Different ways in which a function can capture context.
private enum SILCaptureKind {
    /// No context arguments are necessary.
    case none
    /// A local value captured as a mutable box.
    case box
    /// A local value captured as a single pointer to storage (formed with
    /// @noescape closures).
    case storageAddress
    /// A local value captured as a constant.
    case constant
};

private struct SILTypeConverter2: Hashable {
    struct TypeKey: Hashable {
        /// An unsubstituted version of a type, dictating its abstraction patterns.
        let origType: AbstractionPattern
        /// The substituted version of the type, dictating the types that
        /// should be used in the lowered type.
        let substType: CanType
        
        var isDependent: Bool { fatalError("SIL+Unused") }
    }
    
    static func typeLoweringForLoweredType(key: TypeKey, for expansion: ResilienceExpansion) -> SILTypeLowering { fatalError("SIL+Unused") }
    static func typeLoweringForExpansion(key: TypeKey, for expansion: ResilienceExpansion, lowering: SILTypeLowering) -> SILTypeLowering { fatalError("SIL+Unused") }
    
    static var mostGeneralAbstraction: AbstractionPattern { AbstractionPattern.opaque() }
    static var protocolWitnessRepresentation: SILFunctionTypeRepresentation { .witnessMethod /* no objc */ }
    static func countNumberOfFields(type: SILType, expansion: ResilienceExpansion) -> Int { fatalError("SIL+Unused") }
    
    /// True if a type is passed indirectly at +0 when used as the "self" parameter of its own methods.
    static func isIndirectPlusZeroSelfParameter(type: AType) {
        // Calls through opaque protocols can be done with +0 rvalues.  This allows
        // us to avoid materializing copies of existentials.
        // return !T->hasReferenceSemantics() && (T->isExistentialType() || T->is<ArchetypeType>());
        fatalError("SIL+Unused")
    }
    
    /// True if a type is passed indirectly at +0 when used as the "self" parameter of its own methods.
    static func isIndirectPlusZeroSelfParameter(type: SILType) {
        // Calls through opaque protocols can be done with +0 rvalues.  This allows
        // us to avoid materializing copies of existentials.
        // return !T->hasReferenceSemantics() && (T->isExistentialType() || T->is<ArchetypeType>());
        fatalError("SIL+Unused")
    }
}

private struct SILField {}

private struct SILLayout {}

/// A stage of SIL processing.
private enum SILStage {
    /// "Raw" SIL, emitted by SILGen, but not yet run through guaranteed
    /// optimization and diagnostic passes.
    ///
    /// Raw SIL does not have fully-constructed SSA and may contain undiagnosed
    /// dataflow errors.
    case raw
    
    /// Canonical SIL, which has been run through at least the guaranteed
    /// optimization and diagnostic passes.
    ///
    /// Canonical SIL has stricter invariants than raw SIL. It must not contain
    /// dataflow errors, and some instructions must be canonicalized to simpler
    /// forms.
    case canonical
    
    /// Lowered SIL, which has been prepared for IRGen and will no longer
    /// be passed to canonical SIL transform passes.
    ///
    /// In lowered SIL, the SILType of all SILValues is its SIL storage
    /// type. Explicit storage is required for all address-only and resilient
    /// types.
    ///
    /// Generating the initial Raw SIL is typically referred to as lowering (from
    /// the AST). To disambiguate, refer to the process of generating the lowered
    /// stage of SIL as "address lowering".
    case lowered
}

private extension SILFunctionTypeRepresentation {
    
    var asFunctionTypeRepresentation: FunctionTypeRepresentation? {
        switch self {
        case .thick: return .swift
        case .thin: return .thin
        default: return nil
        }
    }
}
