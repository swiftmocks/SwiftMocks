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

class TypeLowering {
    struct RecursiveProperties {
        let isTrivial: Bool
        let isFixedABI: Bool
        let isAddressOnly: Bool
        let isResilient: Bool

        init(isTrivial: Bool = true, isFixedABI: Bool = true, isAddressOnly: Bool = false, isResilient: Bool = false) {
            self.isTrivial = isTrivial
            self.isFixedABI = isFixedABI
            self.isAddressOnly = isAddressOnly
            self.isResilient = isResilient
        }

        func addingSubobject(_ other: RecursiveProperties) -> RecursiveProperties {
            .init(isTrivial: isTrivial && other.isTrivial, isFixedABI: isFixedABI && other.isFixedABI, isAddressOnly: isAddressOnly || other.isAddressOnly, isResilient: isResilient || other.isResilient)
        }

        func makingNonTrivial() -> RecursiveProperties {
            .init(isTrivial: false, isFixedABI: isFixedABI, isAddressOnly: isAddressOnly, isResilient: isResilient)
        }

        static func forTrivial() -> RecursiveProperties {
            .init(isTrivial: true, isFixedABI: true, isAddressOnly: false, isResilient: false)
        }

        static func forReference() -> RecursiveProperties {
            .init(isTrivial: false, isFixedABI: true, isAddressOnly: false, isResilient: false)
        }

        static func forOpaque() -> RecursiveProperties {
            .init(isTrivial: false, isFixedABI: false, isAddressOnly: true, isResilient: false)
        }

        static func forResilient() -> RecursiveProperties {
            .init(isTrivial: true, isFixedABI: true, isAddressOnly: false, isResilient: true)
        }
    }

    fileprivate let properties: RecursiveProperties
    let loweredType: SILType
    let isReferenceCounted: Bool
    let expansion: ResilienceExpansion

    var isTrivial: Bool { properties.isTrivial }
    var isFixedABI: Bool { properties.isFixedABI }
    var isAddressOnly: Bool { properties.isAddressOnly }
    var isLoadable: Bool { !properties.isAddressOnly }
    var isResilient: Bool { properties.isResilient }

    /// Are r-values of this type passed as arguments indirectly by formal convention? This is independent of whether the SIL argument is address type.
    var isFormallyPassedIndirectly: Bool {
        precondition(!isResilient || expansion == .minimal, "calling convention uses minimal resilience expansion")
        return isAddressOnly
    }

    /// Are r-values of this type returned indirectly by formal convention? This is independent of whether the SIL result is address type.
    var isFormallyReturnedIndirectly: Bool {
        precondition(!isResilient || expansion == .minimal, "calling convention uses minimal resilience expansion")
        return isAddressOnly
    }

    init(_ type: SILType, properties: RecursiveProperties, isReferenceCounted: Bool, expansion: ResilienceExpansion) {
        self.loweredType = type
        self.properties = properties
        self.isReferenceCounted = isReferenceCounted
        self.expansion = expansion
    }

    fileprivate class Loadable: TypeLowering {}

    fileprivate class Trivial: Loadable {
        init(_ type: SILType, properties: TypeLowering.RecursiveProperties, expansion: ResilienceExpansion) {
            precondition(properties.isFixedABI && properties.isTrivial && !properties.isAddressOnly)
            super.init(type, properties: properties, isReferenceCounted: false, expansion: expansion)
        }
    }

    fileprivate class NonTrivialLoadable: Loadable {
        override init(_ type: SILType, properties: TypeLowering.RecursiveProperties, isReferenceCounted: Bool, expansion: ResilienceExpansion) {
            precondition(!properties.isTrivial)
            super.init(type, properties: properties, isReferenceCounted: isReferenceCounted, expansion: expansion)
        }
    }

    fileprivate class LoadableAgg: NonTrivialLoadable {
        init(_ type: AType, properties: TypeLowering.RecursiveProperties, expansion: ResilienceExpansion) {
            super.init(SILType.getPrimitiveObjectType(type.canonicalType), properties: properties, isReferenceCounted: false, expansion: expansion)
        }
    }

    fileprivate class LoadableTuple: LoadableAgg {}

    fileprivate class LoadableStruct: LoadableAgg {}

    fileprivate class LoadableEnum: NonTrivialLoadable {
        init(_ type: AType, properties: RecursiveProperties, expansion: ResilienceExpansion) {
            super.init(SILType.getPrimitiveObjectType(CanType(type: type)), properties: properties, isReferenceCounted: false, expansion: expansion)
        }
    }

    fileprivate class LeafLoadable: NonTrivialLoadable {}

    fileprivate class Reference: LeafLoadable {
        init(_ type: SILType, expansion: ResilienceExpansion) {
            super.init(type, properties: .forReference(), isReferenceCounted: true, expansion: expansion)
        }
    }

    fileprivate class LoadableUnowned: LeafLoadable {
        init(_ type: SILType, expansion: ResilienceExpansion) {
            super.init(type, properties: .forReference(), isReferenceCounted: true, expansion: expansion)
        }
    }

    fileprivate class AddressOnly: TypeLowering {
        init(_ type: SILType, properties: RecursiveProperties, expansion: ResilienceExpansion) {
            super.init(type, properties: properties, isReferenceCounted: false, expansion: expansion)
        }
    }

    fileprivate class UnsafeValueBuffer: AddressOnly {
        init(_ type: SILType, expansion: ResilienceExpansion) {
            super.init(type, properties: .init(isTrivial: false, isFixedABI: true, isAddressOnly: true, isResilient: false), expansion: expansion)
        }
    }

    fileprivate class OpaqueValue: LeafLoadable {
        init(_ type: SILType, properties: RecursiveProperties, expansion: ResilienceExpansion) {
            super.init(type, properties: properties, isReferenceCounted: false, expansion: expansion)
        }
    }
}

/// Type and lowering information about a constant function.
struct SILConstantInfo {
    /// The formal type of the constant, still curried.  For a normal function, this is just its declared type; for a getter or setter, computing this can be more involved.
    let formalType: AnyFunctionType

    /// The abstraction pattern of the constant.  Its type structure matches the formal type, but with types replaced with their bridged equivalents.
    let formalPattern: AbstractionPattern

    /// The uncurried and bridged type of the constant.
    let loweredType: AnyFunctionType

    /// The SIL function type of the constant.
    let silFnType: SILFunctionType

    let silParameterRanges: [SILParameterRange]
}

class SILTypeConverter {
    unowned var module: SILModule!
    private var genericContexts = [GenericSignature]()
    var currentGenericContext: GenericSignature? {
        genericContexts.last
    }

    /// The main entry point for obtaining `SILFunctionType`s. The names and (mostly) callee graph are preserved to ease debugging, even if it means that some methods, being stripped of all complexity related to captures, foreign functions/bridging and generics, now only contain trivial code.
    ///
    /// `SILDeclRef` has a similar role to that of `SILDeclRef`.
    func getConstantInfo(constant: SILDeclRef) throws -> SILConstantInfo {
        precondition(constant.kind == .func) // other kinds are not implemented
        let representation = getDeclRefRepresentation(constant: constant)
        let formalInterfaceType = TypeFactory.functionType(makeConstantInterfaceType(constant: constant), with: representation)

        let bridgedTypes = getLoweredFormalTypes(constant: constant, fnType: formalInterfaceType)
        let loweredInterfaceType = bridgedTypes.uncurried

        var witnessMethodConformance: ProtocolConformanceRef? = nil
        if loweredInterfaceType.extInfo.silRepresentation == .witnessMethod {
            guard let selfProtocolDecl = constant.decl.declContext.selfProtocolDecl else {
                LoweringError.unreachable("witness method, but no protocol context")
            }
            witnessMethodConformance = ProtocolConformanceRef(proto: selfProtocolDecl.proto)
        }

        let (silFunctionType, silParameterRanges) = getNativeSILFunctionType(
            module: module,
            origType: AbstractionPattern(origType: loweredInterfaceType.canonicalType),
            substInterfaceType: loweredInterfaceType,
            extInfo: loweredInterfaceType.extInfo,
            origConstant: constant,
            constant: constant,
            reqtSubs: nil,
            witnessMethodConformance: witnessMethodConformance
        )

        let ret = SILConstantInfo(formalType: formalInterfaceType, formalPattern: bridgedTypes.pattern, loweredType: loweredInterfaceType, silFnType: silFunctionType, silParameterRanges: silParameterRanges)
        return ret
    }

    private func getLoweredFormalTypes(constant: SILDeclRef, fnType: AnyFunctionType) -> (uncurried: AnyFunctionType, pattern: AbstractionPattern) {

        let abstractionPattern = getAbstractionPatternForConstant(constant: constant, fnType: fnType)

        let numberOfParameterLists = constant.parameterListCount
        if numberOfParameterLists == 1 {
            // nothing to do
            return (fnType, abstractionPattern)
        }

        var extInfo = fnType.extInfo
        let genericSig = fnType.genericSignature

        // uncurry the self parameter
        precondition(fnType.params.count == 1)
        let selfParam = fnType.params[0]

        let innerFnType = fnType.resultType as! AnyFunctionType
        let innerFnThrows = innerFnType.extInfo.throws
        let resultType = innerFnType.resultType
        let bridgedParams = innerFnType.params + [selfParam]

        if innerFnThrows {
            extInfo = extInfo.setting(throws: true)
        }

        let uncurried = TypeFactory.createAnyFunctionType(params: bridgedParams, result: resultType, extInfo: extInfo, genericSignature: genericSig)
        return (uncurried, abstractionPattern)
    }

    private func makeConstantInterfaceType(constant: SILDeclRef) -> AnyFunctionType {
        switch constant.kind {
        case .func:
            guard let funcDecl = constant.decl as? FuncDecl else {
                LoweringError.unreachable("bad decl in SILDeclRef of kind \(constant.kind)")
            }

            let funcTy = funcDecl.interfaceType

            // trivial since we don't support captures or any other SILDeclRef.Kind's
            return getFunctionInterfaceTypeWithCaptures(funcType: funcTy, theClosure: funcDecl)
        default:
            LoweringError.notImplemented("SILDeclRef of kind \(constant.kind)")
        }
    }

    private func getFunctionInterfaceTypeWithCaptures(funcType: AnyFunctionType, theClosure: AbstractFunctionDecl) -> AnyFunctionType {
        funcType // we don't support captures of any kind yet
    }

    private func getDeclRefRepresentation(constant: SILDeclRef) -> SILFunctionTypeRepresentation {
        // Currying thunks always have freestanding CC.
        if constant.isCurried {
            return .thin
        }

        precondition(!constant.isForeign)

        if case let .genericTypeContext(nominalTypeDecl) = constant.decl.declContext, let proto = nominalTypeDecl as? ProtocolDecl {
            precondition(!proto.isObjC)
            return .witnessMethod
        }

        switch constant.kind {
        case .globalAccessor,
             .defaultArgGenerator,
             .storedPropertyInitializer:
            return .thin

        case .func:
            return constant.decl.declContext.isTypeContext ? .method : .thin

        case .allocator,
             .initializer,
             .enumElement,
             .destroyer,
             .deallocator,
             .ivarInitializer,
             .ivarDestroyer:
            return .method
        }
    }

    func pushGenericContext(_ sig: GenericSignature?) {
        guard let sig = sig else {
            return
        }
        genericContexts.append(sig)
    }

    func popGenericContext(_ sig: GenericSignature?) {
        guard sig != nil else {
            return
        }
        _ = genericContexts.popLast()
    }

    func getTypeLowering(_ type: AType, expansion: ResilienceExpansion) -> TypeLowering {
        let pattern = AbstractionPattern(origType: type.canonicalType, signature: currentGenericContext)
        return getTypeLowering(origType: pattern, substType: type, forExpansion: expansion)
    }

    /// Lowers a Swift type to a SILType according to the abstraction patterns of the given original type.
    func getTypeLowering(origType: AbstractionPattern, substType: AType, forExpansion: ResilienceExpansion) -> TypeLowering {
        // Lower the type.
        let loweredSubstType = computeLoweredRValueType(origType: origType, substType: substType)

        let lowerType: LowerType = LowerType(typeConverter: self, genericSignature: nil, resilienceExpansion: forExpansion, isDependent: substType.hasTypeParameter)
        let ret = lowerType.visit(loweredSubstType)
        return ret
    }

    func computeLoweredRValueType(origType: AbstractionPattern, substType: AType) -> AType {
        // AST function types are turned into SIL function types:
        //   - the type is uncurried as desired
        //   - types are turned into their unbridged equivalents, depending
        //     on the abstract CC
        //   - ownership conventions are deduced
        if let substFnType = substType as? AnyFunctionType {
            let extInfo = substFnType.extInfo
            guard extInfo.silRepresentation.silFunctionLanguage == .swift else {
                LoweringError.notImplemented("C function")
            }

            return getNativeSILFunctionType(module: module, origType: origType, substType: substFnType)
        }

        // Ignore dynamic self types.
        if let selfType = substType as? DynamicSelfType {
            return selfType.selfType
        }

        // Static metatypes are unitary and can optimized to a "thin" empty representation if the type also appears as a static metatype in the original abstraction pattern.
        if let substMeta = substType as? MetatypeType {
            // If the metatype has already been lowered, it will already carry its representation.
            if substMeta.representation != nil {
                return substMeta
            }

            let repr: MetatypeRepresentation

            if let origMeta: MetatypeType = origType.getAs() {
                // Otherwise, we're thin if the metatype is thinnable both substituted and in the abstraction pattern.
                if hasSingletonMetatype(substMeta.instanceType) && hasSingletonMetatype(origMeta.instanceType) {
                    repr = .thin
                } else {
                    repr = .thick
                }
            } else {
                // If the metatype matches a dependent type, it must be thick.
                assert(origType.isTypeParameter)
                repr = .thick
            }
            return TypeFactory.metatypeType(substMeta, with: repr)
        }

        // Give existential metatypes @thick representation by default.
        if let existMetatype = substType as? ExistentialMetatypeType {
            if existMetatype.representation != nil {
                return existMetatype
            }

            return TypeFactory.existentialMetatypeType(existMetatype, with: .thick)
        }

        // Lower tuple element types.
        if let substTupleType = substType as? TupleType {
            return computeLoweredTupleType(origType: origType, substType: substTupleType)
        }

        if let substType = substType as? ReferenceStorageType {
            return computeLoweredReferenceStorageType(origType: origType, substType: substType)
        }

        // Lower the object type of optional types.
        if let substObjectType = substType.optionalObjectType {
            return computeLoweredOptionalType(origType: origType, substType: substType, substObjectType: substObjectType)
        }

        return substType
    }

    private func getAbstractionPatternForConstant(constant: SILDeclRef, fnType: AnyFunctionType) -> AbstractionPattern {
        precondition(!constant.isForeign)
        return AbstractionPattern(origType: CanType(type: fnType))
    }

    private func hasSingletonMetatype(_ instanceType: AType) -> Bool {
        HasSingletonMetatype().visit(instanceType)
    }

    private func computeLoweredReferenceStorageType(origType: AbstractionPattern, substType: ReferenceStorageType) -> ReferenceStorageType {
        let loweredReferentType = getLoweredRValueType(origType: origType.referenceStorageReferentType, substType: substType.referentType)

        if loweredReferentType == substType.referentType {
            return substType
        }

        return TypeFactory.createReferenceStorageType(referentType: loweredReferentType, referenceOwnership: substType.ownership) as! /* hm... */ ReferenceStorageType
    }

    /// Lower each of the elements of the substituted type according to the abstraction pattern of the given original type.
    private func computeLoweredTupleType(origType: AbstractionPattern, substType: TupleType) -> TupleType {
        // Does the lowered tuple type differ from the substituted type in any interesting way?
        var changed = false
        var loweredElts = [AType]()

        for i in substType.elements.indices {
            let origEltType = origType.tupleElementType(at: i)
            let substEltType = substType.elements[i]

            let parameterFlags = substType.parameterTypeFlags
            // Make sure we don't have something non-materializable.
            let flags = parameterFlags[i]
            assert(flags.valueOwnership == .default)
            assert(!flags.isVariadic)

            let loweredSubstEltType = getLoweredRValueType(origType: origEltType, substType: substEltType)
            changed = (changed || substEltType != loweredSubstEltType || !flags.isNone)

            loweredElts.append(loweredSubstEltType)
        }

        if !changed {
            return substType
        }

        // The cast should succeed, because if we end up with a one-element tuple type here, it must have a label.
        return TypeFactory.createTupleType(elements: loweredElts)
    }

    private func computeLoweredOptionalType(origType: AbstractionPattern, substType: AType, substObjectType: AType) -> AType {
        precondition(substType.optionalObjectType == substObjectType)

        let loweredObjectType = getLoweredRValueType(origType: origType.optionalObjectType, substType: substObjectType)

        // If the object type didn't change, we don't have to rebuild anything.
        if loweredObjectType == substObjectType {
            return substType
        }

        return TypeFactory.createOptionalType(objectType: loweredObjectType)
    }

    func getLoweredRValueType(origType: AbstractionPattern, substType: AType) -> AType {
        // We're ignoring the category (object vs address), so the resilience expansion does not matter.
        return getLoweredType(origType: origType, substType: substType, expansion: .minimal).getASTType().type
    }

    // Returns the lowered SIL type for a Swift type.
    private func getLoweredType(origType: AbstractionPattern, substType: AType, expansion: ResilienceExpansion) -> SILType {
        getTypeLowering(origType: origType, substType: substType, forExpansion: expansion).loweredType
    }
}

extension SILType {
    /// True if the type, or the referenced type of an address type, is address-only.  For example, it could be a resilient struct or something of unknown size.
    /// This is equivalent to, but possibly faster than, calling M.Types.getTypeLowering(type).isAddressOnly().
    static func isAddressOnly(type: CanType, module: SILModule, signature: GenericSignature?, expansion: ResilienceExpansion) -> Bool {
        TypeClassifier(module: module, genericSignature: signature, expansion: expansion).visit(type.type).isAddressOnly
    }

    /// Return true if this type must be returned indirectly.
    /// This is equivalent to, but possibly faster than, calling M.Types.getTypeLowering(type).isReturnedIndirectly().
    static func isFormallyReturnedIndirectly(type: CanType, module: SILModule, signature: GenericSignature?) -> Bool {
        isAddressOnly(type: type, module: module, signature: signature, expansion: .minimal)
    }

    /// Return true if this type must be passed indirectly.
    /// This is equivalent to, but possibly faster than, calling  M.Types.getTypeLowering(type).isPassedIndirectly().
    static func isFormallyPassedIndirectly(type: CanType, module: SILModule, signature: GenericSignature?) -> Bool {
        isAddressOnly(type: type, module: module, signature: signature, expansion: .minimal)
    }
}

private class LowerType: TypeClassifierBase<LowerType, TypeLowering> {
    typealias RecursiveProperties = TypeLowering.RecursiveProperties
    let typeConverter: SILTypeConverter
    let isDependent: Bool

    init(typeConverter: SILTypeConverter, genericSignature: GenericSignature?, resilienceExpansion expansion: ResilienceExpansion, isDependent: Bool) {
        self.typeConverter = typeConverter
        self.isDependent = isDependent
        super.init(module: typeConverter.module, genericSignature: genericSignature, expansion: expansion)
    }

    override func handleTrivial(_ type: AType) -> TypeLowering {
        handleTrivial(type, properties: .forTrivial())
    }

    override func handleTrivial(_ type: AType, properties: RecursiveProperties) -> TypeLowering {
        let silType = SILType.getPrimitiveObjectType(CanType(type: type))
        return TypeLowering.Trivial(silType, properties: properties, expansion: expansion)
    }

    override func handleReference(_ type: AType) -> TypeLowering {
        let silType = SILType.getPrimitiveObjectType(CanType(type: type))
        return TypeLowering.Reference(silType, expansion: expansion)
    }

    override func handleAddressOnly(_ type: AType, properties: RecursiveProperties) -> TypeLowering {
        if SILModuleConventions().loweredAddresses {
            let silType = SILType.getPrimitiveAddressType(CanType(type: type))
            return TypeLowering.AddressOnly(silType, properties: properties, expansion: expansion)
        }
        let silType = SILType.getPrimitiveObjectType(CanType(type: type))
        return TypeLowering.OpaqueValue(silType, properties: properties, expansion: expansion)
    }

    override func visitLoadableUnownedStorageType(_ type: ReferenceStorageType) -> TypeLowering {
        TypeLowering.LoadableUnowned(SILType.getPrimitiveObjectType(CanType(type: type)), expansion: expansion)
    }

    override func visit(builtinUnsafeValueBuffer type: BuiltinUnsafeValueBufferType) -> TypeLowering {
        let silType = SILType.getPrimitiveAddressType(type.canonicalType)
        return TypeLowering.UnsafeValueBuffer(silType, expansion: expansion)
    }

    override func visit(tuple type: TupleType) -> TypeLowering {
        var properties = RecursiveProperties()
        for eltType in type.elements {
            let lowering = typeConverter.getTypeLowering(eltType, expansion: expansion)
            properties = properties.addingSubobject(lowering.properties)
        }

        func _handleAggregateByProperties(_ type: AType, props: RecursiveProperties) -> TypeLowering {
            if props.isAddressOnly {
                return handleAddressOnly(type, properties: props)
            }
            assert(props.isFixedABI)
            if props.isTrivial {
                return handleTrivial(type, properties: props)
            }
            return TypeLowering.LoadableTuple(type, properties: props, expansion: expansion)
        }

        return _handleAggregateByProperties(type, props: properties)
    }

    private func handleResilience(_ type: AType, properties: inout RecursiveProperties) -> Bool {
        guard let type = type as? NominalOrBoundGenericNominalType else {
            LoweringError.unreachable("bad type")
        }
        if type.isResilient {
            LoweringError.notImplemented("resilient types")
        }
        return false
    }

    override func handleAnyStructType(_ type: AType) -> TypeLowering {
        var properties = RecursiveProperties()

        if (handleResilience(type, properties: &properties)) {
            return handleAddressOnly(type, properties: properties)
        }

        func _handleAggregateByProperties(_ type: AType, properties: RecursiveProperties) -> TypeLowering {
            if properties.isAddressOnly {
                return handleAddressOnly(type, properties: properties)
            }
            assert(properties.isFixedABI)
            if properties.isTrivial {
                return handleTrivial(type, properties: properties)
            }
            return TypeLowering.LoadableStruct(type, properties: properties, expansion: expansion)
        }

        let fieldsTypes: [CompositeTypeInfoHelper.FieldInfo]
        if let structType = type as? StructType {
            fieldsTypes = structType.typeInfoHelper.fields
        } else if let boundGenericStructType = type as? BoundGenericStructType {
            fieldsTypes = boundGenericStructType.typeInfoHelper.fields
        } else {
            preconditionFailure("Expected \(StructType.self) or \(BoundGenericStructType.self), got: \(Swift.type(of: type))")
        }

        for fieldInfo in fieldsTypes {
            guard let fieldType = fieldInfo.type else {
                LoweringError.unreachable("no type for a struct field?")
            }
            properties = properties.addingSubobject(classifyType(type: fieldType, module: module, genericSignature: genericSignature, expansion: expansion))
        }

        return _handleAggregateByProperties(type, properties: properties)
    }

    override func handleAnyEnumType(_ type: AType) -> TypeLowering {
        var properties = RecursiveProperties()

        if (handleResilience(type, properties: &properties)) {
            return handleAddressOnly(type, properties: properties)
        }

        func _handleAggregateByProperties(_ type: AType, props: RecursiveProperties) -> TypeLowering {
            if props.isAddressOnly {
                return handleAddressOnly(type, properties: props)
            }
            assert(props.isFixedABI)
            if props.isTrivial {
                return handleTrivial(type, properties: props)
            }
            return TypeLowering.LoadableEnum(type, properties: props, expansion: expansion)
        }

        let fieldsTypes: [CompositeTypeInfoHelper.FieldInfo]
        if let enumTy = type as? EnumType {
            fieldsTypes = enumTy.typeInfoHelper.fields
        } else if let boundGenericEnumTy = type as? BoundGenericEnumType {
            fieldsTypes = boundGenericEnumTy.typeInfoHelper.fields
        } else {
            preconditionFailure("Expected \(EnumType.self) or \(BoundGenericEnumType.self), got: \(Swift.type(of: type))")
        }

        // If the whole enum is indirect, we lower it as if all payload cases were indirect. This means a fixed-layout indirect enum is always loadable and nontrivial.
        // A resilient indirect enum is still address only, because we don't know how many bits are used for the discriminator, and new non-indirect cases may be added resiliently later.
        // SMNOTE: for payload enums this code does the same that the loop below would've done (mark the type as non-trivial). For no-payload enums, it's supposed to make indirect no-payload enums non-trivial by looking at the enum's isIndirect property — which we don't have. So we can't distinguish indirect and direct no-payload enums. See Tests-Failing for more details, but the short story is that it doesn't matter :)
        let isIndirect = fieldsTypes.first { !$0.isIndirectEnumCase } == nil
        if isIndirect {
            properties = properties.makingNonTrivial()
            return TypeLowering.LoadableEnum(type, properties: properties, expansion: expansion)
        }

        for elt in fieldsTypes {
            // No-payload elements do not affect any recursive properties.
            guard let substEltType = elt.type else {
                continue
            }

            // Indirect elements only make the type nontrivial.
            if elt.isIndirectEnumCase {
                properties = properties.makingNonTrivial()
                continue
            }

            properties = properties.addingSubobject(classifyType(type: substEltType, module: module, genericSignature: genericSignature, expansion: expansion))
        }

        return _handleAggregateByProperties(type, props: properties)
    }
}

private func classifyType(type: AType, module: SILModule, genericSignature: GenericSignature?, expansion: ResilienceExpansion) -> TypeLowering.RecursiveProperties {
    TypeClassifier(module: module, genericSignature: genericSignature, expansion: expansion).visit(type)
}

private class TypeClassifier: TypeClassifierBase<TypeClassifier, TypeLowering.RecursiveProperties> {
    override func handle(_ type: AType, properties: TypeLowering.RecursiveProperties) -> TypeLowering.RecursiveProperties {
        properties
    }

    override func handleAnyEnumType(_ type: AType) -> TypeLowering.RecursiveProperties {
        var type = type

        if let optionalReferentType = type.optionalObjectType {
            return visit(optionalReferentType)
        }

        type = getSubstitutedTypeForTypeLowering(type)
        let lowering = module.types.getTypeLowering(type, expansion: expansion)
        return handleClassificationFromLowering(type, lowering: lowering)
    }

    override func handleAnyStructType(_ type: AType) -> TypeLowering.RecursiveProperties {
        let type = getSubstitutedTypeForTypeLowering(type)
        let lowering = module.types.getTypeLowering(type, expansion: expansion)
        return handleClassificationFromLowering(type, lowering: lowering)
    }

    private func getSubstitutedTypeForTypeLowering(_ type: AType) -> AType {
        // If we're using a generic signature different from M.Types.getCurGenericContext(), we have to map the type into context before asking for a type lowering because the rest of type lowering doesn't have a generic signature plumbed through.
        if let _ = genericSignature, type.hasTypeParameter {
            LoweringError.notImplemented("generics")
        }

        return type
    }

    func handleClassificationFromLowering(_ type: AType, lowering: TypeLowering) -> TypeLowering.RecursiveProperties {
        handle(type, properties: lowering.properties)
    }
}

private class TypeClassifierBase<Impl, R>: CanTypeVisitor {
    typealias Ret = R
    typealias RecursiveProperties = TypeLowering.RecursiveProperties

    let module: SILModule
    let genericSignature: GenericSignature?
    let expansion: ResilienceExpansion

    init(module: SILModule, genericSignature: GenericSignature?, expansion: ResilienceExpansion) {
        self.module = module
        self.genericSignature = genericSignature
        self.expansion = expansion
    }

    // The subclass should implement:
    //   // Trivial, fixed-layout, and non-address-only.
    //   RetTy handleTrivial(CanType);
    //   RetTy handleTrivial(CanType. RecursiveProperties properties);
    //   // A reference type.
    //   RetTy handleReference(CanType);
    //   // Non-trivial and address-only.
    //   RetTy handleAddressOnly(CanType, RecursiveProperties properties);
    // and, if it doesn't override handleTupleType,
    //   // An aggregate type that's non-trivial.
    //   RetTy handleNonTrivialAggregate(CanType, RecursiveProperties properties);
    //
    // Additionally!
    // handleAnyStructType (orig: visitAnyStructType)
    // handleAnyEnumType (orig: visitAnyEnumType)

    func handleTrivial(_ type: AType, properties: RecursiveProperties) -> R {
        handle(type, properties: properties)
    }

    func handleAddressOnly(_ type: AType, properties: RecursiveProperties) -> R {
        handle(type, properties: properties)
    }

    func handleNonTrivialAggregate(_ type: AType, properties: RecursiveProperties) -> R {
        handle(type, properties: properties)
    }

    func handleTrivial(_ type: AType) -> R {
        handleTrivial(type, properties: RecursiveProperties.forTrivial())
    }

    func handleReference(_ type: AType) -> R {
        handleTrivial(type, properties: RecursiveProperties.forReference())
    }

    func handleAnyEnumType(_ type: AType) -> R {
        LoweringError.abstract()
    }

    func handleAnyStructType(_ type: AType) -> R {
        LoweringError.abstract()
    }

    func handle(_ type: AType, properties: RecursiveProperties) -> R {
        LoweringError.abstract()
    }

    // visit

    func visit(builtinInteger type: BuiltinIntegerType) -> R {
        handleTrivial(type)
    }

    func visit(builtinFloat type: BuiltinFloatType) -> R {
        handleTrivial(type)
    }

    func visit(builtinRawPointer type: BuiltinRawPointerType) -> R {
        handleTrivial(type)
    }

    func visit(builtinNativeObject type: BuiltinNativeObjectType) -> R {
        handleReference(type)
    }

    func visit(builtinBridgeObject type: BuiltinBridgeObjectType) -> R {
        handleReference(type)
    }

    func visit(builtinUnknownObject type: BuiltinUnknownObjectType) -> R {
        handleReference(type)
    }

    func visit(builtinVector type: BuiltinVectorType) -> R {
        handleTrivial(type)
    }

    func visit(silToken type: SILTokenType) -> R {
        handleTrivial(type)
    }

    func visit(class type: ClassType) -> R {
        handleReference(type)
    }

    func visit(boundGenericClass type: BoundGenericClassType) -> R {
        handleReference(type)
    }

    func visit(anyMetatype type: AnyMetatypeType) -> R {
        handleTrivial(type)
    }

    func visit(module type: ModuleType) -> R {
        handleTrivial(type)
    }

    func visit(builtinUnsafeValueBuffer type: BuiltinUnsafeValueBufferType) -> R {
        handleAddressOnly(type, properties: RecursiveProperties(isTrivial: false, isFixedABI: true, isAddressOnly: true, isResilient: false))
    }

    func visit(anyFunction type: AnyFunctionType) -> R {
        switch type.representation {
        case .swift:
            return handleReference(type)
        case .thin:
            return handleTrivial(type)
        }
    }

    func visit(silFunction type: SILFunctionType) -> R {
        // Only escaping closures are references.
        let isSwiftEscaping = type.extInfo.isNoEscape && type.extInfo.representation == .thick
        if type.extInfo.hasContext && !isSwiftEscaping {
            return handleReference(type)
        }
        // No escaping closures are trivial types.
        return handleTrivial(type)
    }

    private func getGenericSignature() -> GenericSignature? {
        if let signature = genericSignature {
            return signature
        }
        return module.types.currentGenericContext
    }

    private func visitAbstractTypeParamType(_ type: AType) -> R {
        guard let genericSig = getGenericSignature() else {
            preconditionFailure("should have substituted dependent type into context")
        }
        if genericSig.requiresClass(type) {
            return handleReference(type)
        } else if let concreteType = genericSig.getConcreteType(type) {
            return visit(concreteType.canonicalType.type)
        }
        return handleAddressOnly(type, properties: RecursiveProperties.forOpaque())
    }

    func visit(genericTypeParam type: GenericTypeParamType) -> R {
        visitAbstractTypeParamType(type)
    }

    func visit(dependentMember type: DependentMemberType) -> R {
        visitAbstractTypeParamType(type)
    }

    private func getConcreteReferenceStorageReferent(_ type: AType) -> AType {
        guard type.isTypeParameter else {
            return type
        }

        guard let signature = getGenericSignature() else {
            preconditionFailure("dependent type without generic signature?!")
        }

        if let concreteType = signature.getConcreteType(type) {
            return concreteType.canonicalType.type
        }

        assert(signature.requiresClass(type))

        // If we have a superclass bound, recurse on that.  This should always terminate: even if we allow
        //   <T, U: T, V: U, ...>
        // at some point the type-checker should prove acyclic-ness.
        if let bound = signature.getSuperclassBound(type) {
            return getConcreteReferenceStorageReferent(bound.canonicalType.type)
        }

        return CanType.TheUnknownObjectType.type
    }

    func visit(weakStorage type: WeakStorageType) -> R {
        handleAddressOnly(type, properties: RecursiveProperties(isTrivial: false, isFixedABI: true, isAddressOnly: true, isResilient: false))
    }

    func visitLoadableUnownedStorageType(_ type: ReferenceStorageType) -> R {
        handleReference(type)
    }

    private func visitAddressOnlyUnownedStorageType(_ type: ReferenceStorageType) -> R {
        handleAddressOnly(type, properties: RecursiveProperties(isTrivial: false, isFixedABI: true, isAddressOnly: true, isResilient: false))
    }

    func visit(unownedStorage type: UnownedStorageType) -> R {
        let referentType = type.referentType
        let concreteType = getConcreteReferenceStorageReferent(referentType)
        let unownedStorage = TypeFactory.createReferenceStorageType(referentType: concreteType, referenceOwnership: .unowned) as! UnownedStorageType
        if unownedStorage.isLoadable(expansion: expansion) {
            return visitLoadableUnownedStorageType(type)
        } else {
            return visitAddressOnlyUnownedStorageType(type)
        }
    }

    func visit(unmanagedStorage type: UnmanagedStorageType) -> R {
        handleTrivial(type)
    }

    func visit(archetype type: ArchetypeType) -> R {
        if type.requiresClass {
            return handleReference(type)
        }
        LoweringError.notImplemented("archetypes")
    }

    private func visitExistentialType(_ type: AType) -> R {
        let repr = SILType.getPrimitiveObjectType(CanType(type: type)).getPreferredExistentialRepresentation(module: module)
        switch repr {
        case .none:
            LoweringError.unreachable("not an existential type?!");
        // Opaque existentials are address-only.
        case .opaque:
            return handleAddressOnly(type, properties: RecursiveProperties(isTrivial: false, isFixedABI: true, isAddressOnly: true, isResilient: false))
        // Class-constrained and boxed existentials are refcounted.
        case .class,
             .boxed:
            return handleReference(type)
        case .metatype:
            return handleTrivial(type)
        }
    }

    func visit(protocol type: ProtocolType) -> R {
        return visitExistentialType(type)
    }

    func visit(protocolComposition type: ProtocolCompositionType) -> R {
        return visitExistentialType(type)
    }

    func visit(enum type: EnumType) -> R {
        handleAnyEnumType(type)
    }

    func visit(boundGenericEnum type: BoundGenericEnumType) -> R {
        handleAnyEnumType(type)
    }

    func visit(struct type: StructType) -> R {
        handleAnyStructType(type)
    }

    func visit(boundGenericStruct type: BoundGenericStructType) -> R {
        handleAnyStructType(type)
    }

    func visit(tuple type: TupleType) -> R {
        var props = RecursiveProperties()
        for elementType in type.elements {
            props = props.addingSubobject(classifyType(type: elementType, module: module, genericSignature: genericSignature, expansion: expansion))
        }
        return handleAggregateByProperties(type, props: props)
    }

    func visit(dynamicSelf type: DynamicSelfType) -> R {
        visit(type.selfType)
    }

    func visit(silBlockStorage type: SILBlockStorageType) -> R {
        handleAddressOnly(type, properties: RecursiveProperties(isTrivial: false, isFixedABI: true, isAddressOnly: true, isResilient: false))
    }

    func visit(silBox type: SILBoxType) -> R {
        handleReference(type)
    }

    func handleAggregateByProperties(_ type: AType, props: RecursiveProperties) -> R {
        if props.isAddressOnly {
            return handleAddressOnly(type, properties: props)
        }
        precondition(props.isFixedABI, "unsupported combination for now")
        if props.isTrivial {
            return handleTrivial(type)
        }
        return handleNonTrivialAggregate(type, properties: props)
    }
}

/// A type visitor for deciding whether the metatype for a type is a singleton type, i.e. whether there can only ever be one such value.
private struct HasSingletonMetatype: CanTypeVisitor {
    typealias Ret = Bool

    /// Class metatypes have non-trivial representation due to the possibility of subclassing.
    func visit(class type: ClassType) -> Bool {
        false
    }

    func visit(boundGenericClass type: BoundGenericClassType) -> Bool {
        false
    }

    func visit(dynamicSelf type: DynamicSelfType) -> Bool {
        false
    }

    /// Dependent types have non-trivial representation in case they instantiate to a class metatype.
    func visit(genericTypeParam type: GenericTypeParamType) -> Bool {
        false
    }

    /// Archetype metatypes have non-trivial representation in case they instantiate to a class metatype.
    func visit(archetype type: ArchetypeType) -> Bool {
        false
    }

    /// All levels of class metatypes support subtyping.
    func visit(metatype type: MetatypeType) -> Bool {
        visit(type.instanceType)
    }

    /// Everything else is trivial.  Note that ordinary metatypes of existential types are still singleton.
    func visit(anyType: AType) -> Bool {
        true
    }
}
