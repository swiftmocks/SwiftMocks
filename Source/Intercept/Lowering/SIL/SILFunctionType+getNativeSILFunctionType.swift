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

func getNativeSILFunctionType(
    module: SILModule,
    origType: AbstractionPattern,
    substType: AnyFunctionType
) -> SILFunctionType {
    let extInfo: AnyFunctionType.ExtInfo

    // Preserve type information from the original type if possible.
    if let origFnType = origType.originalType.type as? AnyFunctionType {
        extInfo = origFnType.extInfo
        // Otherwise, preserve function type attributes from the substituted type.
    } else {
        extInfo = substType.extInfo
    }

    return getNativeSILFunctionType(module: module, origType: origType, substInterfaceType: substType, extInfo: extInfo, origConstant: nil, constant: nil, reqtSubs: nil, witnessMethodConformance: nil).silFunctionType
}

typealias SILParameterRange = Range<Array<SILParameterInfo>.Index> // TODO: get rid of this. we should be able to reconstruct this info in the handler

func getNativeSILFunctionType(
    module: SILModule,
    origType: AbstractionPattern,
    substInterfaceType: AnyFunctionType,
    extInfo: AnyFunctionType.ExtInfo,
    origConstant: SILDeclRef?,
    constant: SILDeclRef?,
    reqtSubs: Void?,
    witnessMethodConformance: ProtocolConformanceRef?
) -> (silFunctionType: SILFunctionType, silParameterRanges: [SILParameterRange]) {
    precondition((origConstant != nil) == (constant != nil))
    switch extInfo.silRepresentation {
    case .thin, .thick, .method, .closure, .witnessMethod:
        let kind = constant?.kind ?? .func
        switch kind {
        case .initializer,
             .enumElement:
            return getSILFunctionType(module: module,
                                      origType: origType,
                                      substFnInterfaceType: substInterfaceType,
                                      extInfo: extInfo,
                                      conventions: DefaultInitializerConventions(),
                                      origConstant: origConstant,
                                      constant: constant,
                                      reqtSubs: reqtSubs,
                                      witnessMethodConformance: witnessMethodConformance)
        case .allocator:
            return getSILFunctionType(module: module,
                                      origType: origType,
                                      substFnInterfaceType: substInterfaceType,
                                      extInfo: extInfo,
                                      conventions: DefaultAllocatorConventions(),
                                      origConstant: origConstant,
                                      constant: constant,
                                      reqtSubs: reqtSubs,
                                      witnessMethodConformance: witnessMethodConformance)
        case .func:
            // If we have a setter, use the special setter convention. This ensures that we take normal parameters at +1.
            if let constant = constant, constant.isSetter {
                return getSILFunctionType(module: module,
                                          origType: origType,
                                          substFnInterfaceType: substInterfaceType,
                                          extInfo: extInfo,
                                          conventions: DefaultSetterConventions(),
                                          origConstant: origConstant,
                                          constant: constant,
                                          reqtSubs: reqtSubs,
                                          witnessMethodConformance: witnessMethodConformance)
            }
            fallthrough
        case .destroyer,
             .globalAccessor,
             .defaultArgGenerator,
             .storedPropertyInitializer,
             .ivarInitializer,
             .ivarDestroyer:
            let conv = DefaultConventions(normalParameterConvention: .guaranteed)
            return getSILFunctionType(module: module,
                                      origType: origType,
                                      substFnInterfaceType: substInterfaceType,
                                      extInfo: extInfo,
                                      conventions: conv,
                                      origConstant: origConstant,
                                      constant: constant,
                                      reqtSubs: reqtSubs,
                                      witnessMethodConformance: witnessMethodConformance)
        case .deallocator:
            return getSILFunctionType(module: module,
                                      origType: origType,
                                      substFnInterfaceType: substInterfaceType,
                                      extInfo: extInfo,
                                      conventions: DeallocatorConventions(),
                                      origConstant: origConstant,
                                      constant: constant,
                                      reqtSubs: reqtSubs,
                                      witnessMethodConformance: witnessMethodConformance)
        }
    }
}

private enum ConventionsKind {
    case `default`
    case defaultBlock
    case objCMethod
    case cfunctionType
    case cfunction
    case objcSelectorFamily
    case deallocator
    case capture
}

private protocol Conventions {
    var kind: ConventionsKind { get }

    func getIndirectParameter(index: Int, type: AbstractionPattern, substTL: TypeLowering) -> ParameterConvention

    func getDirectParameter(index: Int, type: AbstractionPattern, substTL: TypeLowering) -> ParameterConvention

    func getCallee() -> ParameterConvention

    func getResult(typeLowering: TypeLowering) -> ResultConvention

    func getIndirectSelfParameter(type: AbstractionPattern) -> ParameterConvention

    func getDirectSelfParameter(type: AbstractionPattern) -> ParameterConvention
}

private extension Conventions {
    // Helpers that branch based on a value ownership.
    func getIndirect(ownership: ValueOwnership, forSelf: Bool, index: Int, type: AbstractionPattern, substTL: TypeLowering) -> ParameterConvention {
        switch ownership {
        case .default:
            if forSelf {
                return getIndirectSelfParameter(type: type)
            }
            return getIndirectParameter(index: index, type: type, substTL: substTL)
        case .inOut:
            return .indirectInout
        case .shared:
            return .indirectInGuaranteed
        case .owned:
            return .indirectIn
        }
    }

    func getDirect(ownership: ValueOwnership, forSelf: Bool, index: Int, type: AbstractionPattern, substTL: TypeLowering) -> ParameterConvention {
        switch ownership {
        case .default:
            if forSelf {
                return getDirectSelfParameter(type: type)
            }
            return getDirectParameter(index: index, type: type, substTL: substTL)
        case .inOut:
            return .indirectInout
        case .shared:
            return .directGuaranteed
        case .owned:
            return .directOwned
        }
    }
}

private enum NormalParameterConvention {
    case owned
    case guaranteed
}

private let defaultThickCalleeConvention: ParameterConvention = .directGuaranteed

/// The default Swift conventions.
private class DefaultConventions: Conventions {
    let kind: ConventionsKind = .default
    let normalParameterConvention: NormalParameterConvention

    init(normalParameterConvention: NormalParameterConvention) {
        self.normalParameterConvention = normalParameterConvention
    }

    var isNormalParameterConventionGuaranteed: Bool {
        normalParameterConvention == .guaranteed
    }

    func getIndirectParameter(index: Int, type: AbstractionPattern, substTL: TypeLowering) -> ParameterConvention {
        isNormalParameterConventionGuaranteed ? .indirectInGuaranteed : .indirectIn
    }

    func getDirectParameter(index: Int, type: AbstractionPattern, substTL: TypeLowering) -> ParameterConvention {
        isNormalParameterConventionGuaranteed ? .directGuaranteed : .directOwned
    }

    func getCallee() -> ParameterConvention {
        defaultThickCalleeConvention
    }

    func getResult(typeLowering: TypeLowering) -> ResultConvention {
        .owned
    }

    func getDirectSelfParameter(type: AbstractionPattern) -> ParameterConvention {
        .directGuaranteed
    }

    func getIndirectSelfParameter(type: AbstractionPattern) -> ParameterConvention {
        .indirectInGuaranteed
    }
}

/// The default conventions for Swift initializing constructors.
///
/// Initializing constructors take all parameters (including) self at +1. This
/// is because:
///
/// 1. We are likely to be initializing fields of self implying that the
///    parameters are likely to be forwarded into memory without further
///    copies.
/// 2. Initializers must take 'self' at +1, since they will return it back
///    at +1, and may chain onto Objective-C initializers that replace the
///    instance.
private class DefaultInitializerConventions : DefaultConventions {
    init() {
        super.init(normalParameterConvention: .owned)
    }

    /// Initializers must take 'self' at +1, since they will return it back at +1,
    /// and may chain onto Objective-C initializers that replace the instance.
    override func getDirectSelfParameter(type: AbstractionPattern) -> ParameterConvention {
        .directOwned
    }

    override func getIndirectSelfParameter(type: AbstractionPattern) -> ParameterConvention {
        .indirectIn
    }
}

/// The convention used for allocating inits. Allocating inits take their normal parameters at +1 and do not have a self parameter.
private class DefaultAllocatorConventions : DefaultConventions {
    init() {
        super.init(normalParameterConvention: .owned)
    }

    override func getDirectSelfParameter(type: AbstractionPattern) -> ParameterConvention {
        LoweringError.unreachable("Allocating inits do not have self parameters")
    }

    override func getIndirectSelfParameter(type: AbstractionPattern) -> ParameterConvention {
        LoweringError.unreachable("Allocating inits do not have self parameters")
    }
}

/// The default conventions for Swift setter acccessors.
///
/// These take self at +0, but all other parameters at +1. This is because we
/// assume that setter parameters are likely to be values to be forwarded into
/// memory. Thus by passing in the +1 value, we avoid a potential copy in that
/// case.
private class DefaultSetterConventions : DefaultConventions {
    init() {
        super.init(normalParameterConvention: .owned)
    }
}

/// The default conventions for ObjC blocks.
private class DefaultBlockConventions : Conventions {
    let kind: ConventionsKind = .defaultBlock

    func getIndirectParameter(index: Int, type: AbstractionPattern, substTL: TypeLowering) -> ParameterConvention {
        LoweringError.unreachable("indirect block parameters unsupported")
    }

    func getDirectParameter(index: Int, type: AbstractionPattern, substTL: TypeLowering) -> ParameterConvention {
        .directUnowned
    }

    func getCallee() -> ParameterConvention {
        .directUnowned
    }

    func getResult(typeLowering: TypeLowering) -> ResultConvention {
        .autoreleased
    }

    func getDirectSelfParameter(type: AbstractionPattern) -> ParameterConvention {
        LoweringError.unreachable("objc blocks do not have a self parameter")
    }

    func getIndirectSelfParameter(type: AbstractionPattern) -> ParameterConvention {
        LoweringError.unreachable("objc blocks do not have a self parameter")
    }
}

// The convention for general deallocators.
private class DeallocatorConventions: Conventions {
    let kind: ConventionsKind = .deallocator

    func getIndirectParameter(index: Int, type: AbstractionPattern, substTL: TypeLowering) -> ParameterConvention {
        LoweringError.unreachable("Deallocators do not have indirect parameters")
    }

    func getDirectParameter(index: Int, type: AbstractionPattern, substTL: TypeLowering) -> ParameterConvention {
        LoweringError.unreachable("Deallocators do not have non-self direct parameters")
    }

    func getCallee() -> ParameterConvention {
        LoweringError.unreachable("Deallocators do not have callees")
    }

    func getResult(typeLowering: TypeLowering) -> ResultConvention {
        .owned
    }

    func getDirectSelfParameter(type: AbstractionPattern) -> ParameterConvention {
        .directOwned
    }

    func getIndirectSelfParameter(type: AbstractionPattern) -> ParameterConvention {
        LoweringError.unreachable("Deallocators do not have indirect self parameters")
    }
}

/// Create the appropriate SIL function type for the given formal type
/// and conventions.
///
/// The lowering of function types is generally sensitive to the
/// declared abstraction pattern.  We want to be able to take
/// advantage of declared type information in order to, say, pass
/// arguments separately and directly; but we also want to be able to
/// call functions from generic code without completely embarrassing
/// performance.  Therefore, different abstraction patterns induce
/// different argument-passing conventions, and we must introduce
/// implicit reabstracting conversions where necessary to map one
/// convention to another.
///
/// However, we actually can't reabstract arbitrary thin function
/// values while still leaving them thin, at least without costly
/// page-mapping tricks. Therefore, the representation must remain
/// consistent across all abstraction patterns.
///
/// We could reabstract block functions in theory, but (1) we don't
/// really need to and (2) doing so would be problematic because
/// stuffing something in an Optional currently forces it to be
/// reabstracted to the most general type, which means that we'd
/// expect the wrong abstraction conventions on bridged block function
/// types.
///
/// Therefore, we only honor abstraction patterns on thick or
/// polymorphic functions.
///
/// - parameter conventions: - conventions as expressed for the original type
private func getSILFunctionType(
    module: SILModule,
    origType: AbstractionPattern,
    substFnInterfaceType: AnyFunctionType,
    extInfo: AnyFunctionType.ExtInfo,
    conventions: Conventions,
    origConstant: SILDeclRef?,
    constant: SILDeclRef?,
    reqtSubs: Void?,
    witnessMethodConformance: ProtocolConformanceRef?
) -> (SILFunctionType, [SILParameterRange]) {
    var origType = origType
    // Per above, only fully honor opaqueness in the abstraction pattern for thick or polymorphic functions.  We don't need to worry about non-opaque patterns because the type-checker forbids non-thick function types from having generic parameters or results.
    if origType.isTypeParameter && substFnInterfaceType.extInfo.silRepresentation != .thick, let _ = substFnInterfaceType as? FunctionType {
        origType = AbstractionPattern(origType: CanType(type: substFnInterfaceType), signature: module.types.currentGenericContext)
    }

    // Find the generic parameters.
    let genericSig = substFnInterfaceType.genericSignature

    // Lower the interface type in a generic context.
    module.types.pushGenericContext(genericSig)
    defer {
        module.types.popGenericContext(genericSig)
    }

    // Map 'throws' to the appropriate error convention.
    var errorResult: SILResultInfo?
    if substFnInterfaceType.extInfo.throws {
        let exnType: SILType = SILType.getExceptionType()
        assert(exnType.isObject)
        errorResult = SILResultInfo(type: exnType.getASTType(), convention: .owned)
    }

    // Lower the result type.
    let origResultType: AbstractionPattern = origType.functionResultType
    let substFormalResultType: CanType = CanType(type: substFnInterfaceType.resultType)

    // Destructure the result tuple type.
    var resultDestructurer = DestructureResults(module: module, conventions: conventions)
    resultDestructurer.destructure(origType: origResultType, substType: substFormalResultType)
    let results = resultDestructurer.results

    // Destructure the input tuple type.
    var paramsDestructurer = DestructureInputs(module: module, conventions: conventions)
    paramsDestructurer.destructure(origType: origType, params: substFnInterfaceType.params, extInfo: extInfo)
    let params = paramsDestructurer.parameters

    let (yields, coroutineKind) = destructureYieldsForCoroutine(module: module, origConstant: origConstant, constant: constant, reqtSubs: nil)

    let calleeConvention: ParameterConvention = extInfo.hasContext ? conventions.getCallee() : .directUnowned

    let silExtInfo = SILFunctionType.ExtInfo(representation: extInfo.silRepresentation, isPseudogeneric: false, isNoEscape: extInfo.isNoEscape)

    let silFunctionType = TypeFactory.getSILFunctionType(genericSig: genericSig,
                                                         extInfo: silExtInfo,
                                                         coroutineKind: coroutineKind,
                                                         calleeConvention: calleeConvention,
                                                         params: params,
                                                         yields: yields,
                                                         normalResults: results,
                                                         errorResult: errorResult,
                                                         witnessMethodConformance: witnessMethodConformance)

    return (silFunctionType, paramsDestructurer.ranges)
}

func destructureYieldsForCoroutine(module: SILModule, origConstant: SILDeclRef?, constant: SILDeclRef?, reqtSubs: /*SubstitutionMap*/Void?) -> (yiels: [SILYieldInfo], coroutineKind: SILCoroutineKind) {
    var yields = [SILYieldInfo]()
    let coroutineKind: SILCoroutineKind

    precondition((constant != nil && origConstant != nil) || (constant == nil && origConstant == nil))

    guard let constant = constant, let origConstant = origConstant else {
        return ([], .none)
    }

    guard let accessor = constant.decl as? AccessorDecl, accessor.isCoroutine, let origAccessor = origConstant.decl as? AccessorDecl else {
        return ([], .none)
    }

    // Coroutine accessors are implicitly yield-once coroutines, despite their function type.
    coroutineKind = .yieldOnce

    // Coroutine accessors are always native, so fetch the native abstraction pattern.
    // auto origStorage = origAccessor->getStorage(); auto origType = M.Types.getAbstractionPattern(origStorage, /*nonobjc*/ true) .getReferenceStorageReferentType();
    let origValueType = origAccessor.storageType
    let origType = AbstractionPattern(origType: CanType(type: origValueType), signature: nil)

    let valueType = accessor.storageType
    if reqtSubs != nil {
        LoweringError.notImplemented("generic substitutions")
        // valueType = valueType.subst(*reqtSubs);
    }

    let canValueType = valueType // ->getCanonicalType(accessor->getGenericSignature())

    // 'modify' yields an inout of the target type.
    if accessor.kind == .modify {
        let loweredValueTy = module.types.getLoweredRValueType(origType: origType, substType: canValueType)
        yields.append(SILYieldInfo(type: loweredValueTy, convention: .indirectInout))
        return (yields, coroutineKind)
    }

    LoweringError.notImplemented("_read coroutine")
    //
    //  // 'read' yields a borrowed value of the target type, destructuring
    //  // tuples as necessary.
    //  assert(accessor->getAccessorKind() == AccessorKind::Read);
    //  destructureYieldsForReadAccessor(M, origType, canValueType, yields);
}


/// A visitor for turning formal input types into SILParameterInfos, matching the abstraction patterns of the original type.
/// If the original abstraction pattern is fully opaque, we must pass the function's parameters and results indirectly, as if the original type were the most general function signature (expressed entirely in generic parameters) which can be substituted to equal the given signature. See  AbstractionPattern for details.
private struct DestructureInputs {
    let module: SILModule
    let conventions: Conventions

    private(set) var parameters = [SILParameterInfo]()
    private var nextOrigParamIndex = 0
    private(set) var ranges = [SILParameterRange]()

    init(module: SILModule, conventions: Conventions) {
        self.module = module
        self.conventions = conventions
    }

    mutating func destructure(origType: AbstractionPattern,
                              params: [AnyFunctionType.Param],
                              extInfo: AnyFunctionType.ExtInfo) {
        visitTopLevelParams(origType: origType, params: params, extInfo: extInfo)
    }

    /// Query whether the original type is address-only given complete lowering information about its substitution.
    func isFormallyPassedIndirectly(origType: AbstractionPattern,
                                    substType: CanType,
                                    substTL: TypeLowering) -> Bool {
        SwiftMocks.isFormallyPassedIndirectly(module: module, origType: origType, substType: substType, substTL: substTL)
    }

    private mutating func visitTopLevelParams(origType: AbstractionPattern,
                                      params: [AnyFunctionType.Param],
                                      extInfo: AnyFunctionType.ExtInfo) {
        let numEltTypes = params.count

        let hasSelf = extInfo.hasSelfParam
        let numNonSelfParams = hasSelf ? numEltTypes - 1 : numEltTypes

        let silRepresentation = extInfo.silRepresentation

        // Process all the non-self parameters.
        for i in 0..<numNonSelfParams {
            let ty = CanType(type: params[i].getParameterType(forCanonical: true))
            let eltPattern = origType.functionParamType(i)
            let flags = params[i].flags

            let savedNumberOfParameters = parameters.count
            visit(ownership: flags.valueOwnership, forSelf: false, origType: eltPattern, substType: ty, representation: silRepresentation)
            ranges.append(savedNumberOfParameters..<parameters.count)
        }

        if hasSelf {
            let selfParam = params[numNonSelfParams]
            let ty = CanType(type: selfParam.getParameterType(forCanonical: true))
            let eltPattern = origType.functionParamType(numNonSelfParams)
            let flags = selfParam.flags

            let savedNumberOfParameters = parameters.count
            visit(ownership: flags.valueOwnership, forSelf: true, origType: eltPattern, substType: ty, representation: silRepresentation)
            ranges.append(savedNumberOfParameters..<parameters.count)
        }

        assert(ranges.count == params.count, "The number of ranges must match the number of formal parameters")
    }

    /// - returns: `true` if the parameter is indirect
    private mutating func visit(ownership: ValueOwnership, forSelf: Bool, origType: AbstractionPattern, substType: CanType, representation: SILFunctionTypeRepresentation) {
        precondition(!(substType.type is InOutType))

        // Tuples get handled specially, in some cases:
        if let substTupleTy = substType.type as? TupleType, !origType.isTypeParameter {
            precondition(origType.numberOfTupleElements == substTupleTy.elements.count)
            switch (ownership) {
            case .default, .owned, .shared:
                // Expand the tuple.
                for (i, elt) in substTupleTy.elements.enumerated() {
                    let ownership: ValueOwnership = substTupleTy.parameterTypeFlags[i].valueOwnership
                    visit(ownership: ownership,
                          forSelf: forSelf,
                          origType: origType.tupleElementType(at: i),
                          substType: CanType(type: elt /*.getRawType() FIXME */),
                          representation: representation)
                }
                return
            case .inOut:
                // handled below
                break
            }
        }

        let origParamIndex = nextOrigParamIndex
        nextOrigParamIndex += 1

        let substTL = module.types.getTypeLowering(origType: origType, substType: substType.type, forExpansion: .minimal)
        let convention: ParameterConvention
        if ownership == .inOut {
            convention = .indirectInout
        } else if (isFormallyPassedIndirectly(origType: origType, substType: substType, substTL: substTL)) {
            convention = conventions.getIndirect(ownership: ownership, forSelf: forSelf, index: origParamIndex, type: origType, substTL: substTL)
            assert(convention.isIndirectFormalParameter)
        } else if substTL.isTrivial {
            convention = .directUnowned
        } else {
            convention = conventions.getDirect(ownership: ownership, forSelf: forSelf, index: origParamIndex, type: origType, substTL: substTL)
            assert(!convention.isIndirectFormalParameter)
        }
        let loweredType = substTL.loweredType.getASTType()

        parameters.append(SILParameterInfo(type: loweredType, convention: convention))
    }
}

/// A visitor for breaking down formal result types into a SILResultInfo and possibly some number of indirect-out SILParameterInfos, matching the abstraction patterns of the original type.
private struct DestructureResults {
    let module: SILModule
    let conventions: Conventions
    private(set) var results = [SILResultInfo]()
    private(set) var mapping = [Int]()

    mutating func destructure(origType: AbstractionPattern, substType: CanType) {
        // Recurse into tuples.
        if origType.isTuple {
            let substTupleType = substType.type as! TupleType
            for (index, substEltType) in substTupleType.elements.enumerated() {
                let origEltType: AbstractionPattern = origType.tupleElementType(at: index)
                destructure(origType: origEltType, substType: CanType(type: substEltType))
            }
            return
        }

        let substResultTL = module.types.getTypeLowering(origType: origType, substType: substType.type, forExpansion: .minimal)

        // Determine the result convention.
        var convention: ResultConvention
        if isFormallyReturnedIndirectly(module: module, origType: origType, substType: substType, substTL: substResultTL) {
            convention = .indirect
        } else {
            convention = conventions.getResult(typeLowering: substResultTL)

            // Reduce conventions for trivial types to an unowned convention.
            if substResultTL.isTrivial {
                switch convention {
                case .indirect,
                     .unowned,
                     .unownedInnerPointer:
                    // Leave these as-is.
                    break
                case .autoreleased, .owned:
                    // These aren't distinguishable from unowned for trivial types.
                    convention = .unowned
                }
            }
        }

        let result = SILResultInfo(type: substResultTL.loweredType.getASTType(), convention: convention)
        results.append(result)
    }
}

private func isFormallyPassedIndirectly(module: SILModule, origType: AbstractionPattern, substType: CanType, substTL: TypeLowering) -> Bool {
    // If the substituted type is passed indirectly, so must the unsubstituted type.
    if origType.isTypeParameter && !origType.isConcreteType && !origType.requiresClass || substTL.isAddressOnly {
        return true
        // If the substitution didn't change the type, then a negative response to the above is determinative as well.
    } else if origType.originalType == substType && !origType.originalType~>.hasTypeParameter {
        return false
    }

    // Otherwise, query specifically for the original type.
    return SILType.isFormallyPassedIndirectly(type: origType.originalType, module: module, signature: origType.genericSignature)
}

/// Query whether the original type is returned indirectly for the purpose of reabstraction given complete lowering information about its substitution.
private func isFormallyReturnedIndirectly(module: SILModule, origType: AbstractionPattern, substType: CanType, substTL: TypeLowering) -> Bool {
    // If the substituted type is returned indirectly, so must the
    // unsubstituted type.
    if (origType.isTypeParameter && !origType.isConcreteType && !origType.requiresClass) || substTL.isAddressOnly {
        return true
        // If the substitution didn't change the type, then a negative
        // response to the above is determinative as well.
    } else if origType.originalType == substType && !origType.originalType~>.hasTypeParameter {
        return false
    }

    // Otherwise, query specifically for the original type.
    return SILType.isFormallyReturnedIndirectly(type: origType.originalType, module: module, signature: origType.genericSignature)
}
