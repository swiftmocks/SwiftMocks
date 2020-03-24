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

enum SILFunctionLanguage: Int8 {
    case swift
    case c
}

/// The representation form of a SIL function.
enum SILFunctionTypeRepresentation: Int8, Hashable {
    /// A freestanding thick function.
    case thick
    /// A freestanding thin function that needs no context.
    case thin
    /// A Swift instance method.
    case method
    /// A Swift protocol witness.
    case witnessMethod
    /// A closure invocation function that has not been bound to a context.
    case closure

    /// Map a SIL function representation to the base language calling convention it uses.
    var silFunctionLanguage: SILFunctionLanguage {
        switch self {
        case .thick, .thin, .method, .witnessMethod, .closure:
            return .swift
        }
    }
}

typealias YieldConvention = ParameterConvention

/// SILFunctionType - The lowered type of a function value, suitable for use by SIL.
class SILFunctionType: AType, ATypeEquatable {
    // when adding new stored properties, remember to update isEqual
    let extInfo: ExtInfo
    let calleeConvention: ParameterConvention
    let coroutineKind: SILCoroutineKind

    /// Function parameters, not including any formally indirect results.
    let parameters: [SILParameterInfo]
    let yields: [SILYieldInfo]
    /// Return the array of all result information. This may contain inter-mingled direct and indirect results.
    let anyResults: [SILResultInfo]
    /// Blessed Swift-native error result
    let errorResult: SILResultInfo?

    private var formalResultCache: CanType? = nil
    private var allResultCache: CanType? = nil

    let genericSig: GenericSignature?
    let witnessMethodConformance: ProtocolConformanceRef?

    lazy var numberOfAnyIndirectFormalResults: Int = {
        anyResults.filter { $0.isFormalIndirect }.count
    }()

    /// Get the representation of the function type.
    var representation: SILFunctionTypeRepresentation {
        extInfo.representation
    }

    /// Is this function pseudo-generic?  A pseudo-generic function is not permitted to dynamically depend on its type arguments.
    var isPseudoGeneric: Bool {
        extInfo.isPseudogeneric
    }

    var isNoEscape: Bool {
        extInfo.isNoEscape
    }

    var isCoroutine: Bool {
        coroutineKind != .none
    }

    var language: SILFunctionLanguage {
        get { representation.silFunctionLanguage }
    }

    var hasSelfParam: Bool {
        switch representation {
        case .thick,
             .thin,
             .closure:
            return false
        case .method,
             .witnessMethod:
            return true
        }
    }

    /// True if the function representation carries context.
    var hasContext: Bool {
        switch representation {
        case .thick:
            return true
        case .thin,
             .method,
             .witnessMethod,
             .closure:
            return false
        }
    }

    var hasResultCache: Bool {
        numberOfAnyResults > 1 && !isCoroutine
    }

    /// Return the array of all result information. This may contain inter-mingled direct and indirect results.
    var results: [SILResultInfo] {
        anyResults
    }

    var numberOfResults: Int {
        isCoroutine ? 0 : numberOfAnyResults
    }

    /// Given that this function type has exactly one result, return it.
    /// This is a common situation when working with a function with a known signature.  It is *not* safe to assume that C functions satisfy this, because void functions have zero results.
    var singleResult: SILResultInfo {
        precondition(numberOfResults == 1)
        return results[0]
    }

    /// Given that this function type has exactly one formally direct result, return it. Some formal calling conventions only apply when a single direct result is present.
    var singleDirectFormalResult: SILResultInfo {
        precondition(numberOfDirectFormalResults == 1)
        for result in results {
            if !result.isFormalIndirect {
                return result
            }
        }
        LoweringError.unreachable("expected to find a single formal result, but found none")
    }

    // Get the number of results that require a formal indirect calling convention regardless of whether SIL requires address types. Even if the substituted SIL types match, a formal direct argument may not be passed to a formal indirect parameter and vice-versa. Hence, the formally indirect property, not the SIL indirect property, should be consulted to determine whether function reabstraction is necessary.
    var numberOfIndirectFormalResults: Int {
        numberOfAnyIndirectFormalResults
    }

    /// Does this function have any formally indirect results?
    var hasIndirectFormalResults: Bool {
        numberOfIndirectFormalResults > 0
    }

    var numberOfDirectFormalResults: Int {
        isCoroutine ? 0 : numberOfAnyResults - numberOfAnyIndirectFormalResults
    }

    /// A range of SILResultInfo for all formally indirect results.
    var indirectFormalResults: [SILResultInfo] {
        anyResults.filter { $0.isFormalIndirect }
    }

    /// A range of SILResultInfo for all formally direct results.
    var directFormalResults: [SILResultInfo] {
        anyResults.filter { $0.isFormalDirect }
    }

    /// Get a single non-address SILType that represents all formal direct results. The actual SIL result type of an apply instruction that calls this function depends on the current SIL stage and is known by SILFunctionConventions. It may be a wider tuple that includes formally indirect results.
    var directFormalResultsType: SILType {
        let type: CanType
        if numberOfDirectFormalResults == 0 {
            type = CanType.TheEmptyTupleType
        } else if numberOfDirectFormalResults == 1 {
            type = singleDirectFormalResult.type
        } else {
            if let cache = formalResultCache {
                type = cache
            } else {
                var elts = [AType]()
                for result in results {
                    if !result.isFormalIndirect {
                        elts.append(result.type.type)
                    }
                }
                type = CanType(type: TypeFactory.createTupleType(elements: elts))
                formalResultCache = type
            }
        }
        return SILType.getPrimitiveObjectType(type)
    }

    /// Get a single non-address SILType for all SIL results regardless of whether they are formally indirect. The actual SIL result type of an apply instruction that calls this function depends on the current SIL stage and is known by SILFunctionConventions. It may be a narrower tuple that omits formally indirect results.
    var allResultsType: SILType {
        let type: CanType
        if numberOfResults == 0 {
            type = CanType.TheEmptyTupleType;
        } else if numberOfResults == 1 {
            type = results[0].type
        } else {
            if let cache = allResultCache {
                type = cache
            } else {
                var elts = [AType]()
                for result in results {
                    if !result.isFormalIndirect {
                        elts.append(result.type.type)
                    }
                }
                type = CanType(type: TypeFactory.createTupleType(elements: elts))
                allResultCache = type
            }
        }
        return SILType.getPrimitiveObjectType(type)
    }

    /// Returns the 'self' parameter, assuming that this is the type of a method.
    var selfParameter: SILParameterInfo {
        parameters.last!
    }

    var isPolymorphic: Bool {
        genericSig != nil
    }

    /// Returns the 'self' parameter, assuming that this is the type of a method.
    var selfInstanceType: CanType {
        var type = selfParameter.type
        if let metatype = type.type as? AnyMetatypeType  {
            type = metatype.instanceType.canonicalType
        }
        return type
    }

    /// Thick swift noescape function types are trivial.
    var isTrivialNoEscape: Bool {
        isNoEscape && representation == .thick
    }

    var isNoReturnFunction: Bool {
        results.contains { $0.type~>.isUninhabited }
    }

    private var numberOfAnyResults: Int {
        anyResults.count
    }

    fileprivate init(genericSig: GenericSignature?,
         extInfo: ExtInfo,
         coroutineKind: SILCoroutineKind,
         calleeConvention: ParameterConvention,
         params: [SILParameterInfo],
         yields: [SILYieldInfo],
         normalResults: [SILResultInfo],
         errorResult: SILResultInfo?,
         properties: RecursiveTypeProperties,
         witnessMethodConformance: ProtocolConformanceRef?) {
        precondition(!calleeConvention.isIndirectFormalParameter)
        self.genericSig = genericSig
        self.extInfo = extInfo
        self.coroutineKind = coroutineKind
        self.calleeConvention = calleeConvention
        self.parameters = params
        self.yields = yields
        self.anyResults = normalResults

        self.errorResult = errorResult

        self.witnessMethodConformance = witnessMethodConformance

        super.init(kind: .silFunction)
    }

    func isEqual(to other: AType) -> Bool {
        guard let other = other as? SILFunctionType else {
            return false
        }

        let ret = genericSig == other.genericSig &&
            extInfo == other.extInfo &&
            calleeConvention == other.calleeConvention &&
            coroutineKind == other.coroutineKind &&
            parameters == other.parameters &&
            yields == other.yields &&
            anyResults == other.anyResults &&
            errorResult == other.errorResult &&
            witnessMethodConformance == other.witnessMethodConformance

        return ret
    }

    /// To be used only by `TypeFactory`
    static func _get(genericSig: GenericSignature?,
                     extInfo: ExtInfo,
                     coroutineKind: SILCoroutineKind,
                     calleeConvention: ParameterConvention,
                     params: [SILParameterInfo],
                     yields: [SILYieldInfo],
                     normalResults: [SILResultInfo],
                     errorResult: SILResultInfo?,
                     properties: RecursiveTypeProperties,
                     witnessMethodConformance: ProtocolConformanceRef?) -> SILFunctionType {
        SILFunctionType(genericSig: genericSig, extInfo: extInfo, coroutineKind: coroutineKind, calleeConvention: calleeConvention, params: params, yields: yields, normalResults: normalResults, errorResult: errorResult, properties: properties, witnessMethodConformance: witnessMethodConformance)
    }
}

typealias SILYieldInfo = SILParameterInfo

extension SILFunctionType {
    struct ExtInfo: Hashable {
        let representation: SILFunctionTypeRepresentation
        let isPseudogeneric: Bool
        let isNoEscape: Bool

        init(representation: SILFunctionTypeRepresentation, isPseudogeneric: Bool = false, isNoEscape: Bool = false) {
            self.representation = representation
            self.isPseudogeneric = isPseudogeneric
            self.isNoEscape = isNoEscape
        }

        /// True if the function representation carries context.
        var hasContext: Bool {
          switch representation {
          case .thick:
            return true
          case .thin,
               .method,
               .witnessMethod,
               .closure:
            return false
          }
        }
    }
}

extension SILFunctionType {
    /// Create a new function type by replacing all parameters and results of `τ_0_0` type with the given `replacementType` and `τ_0_0.Type` with `replacementType.Type`, and removing the generic signature. It is an extremely shallow version of `substGenericArgs()` (like, several orders of magnitude shallower).
    func replacingTau00(with replacementType: AType, generic: Bool) -> SILFunctionType {
        let exemplarWitnessSelfType = GenericTypeParamType.tau00
        let metatype = TypeFactory.createMetatype(instanceType: exemplarWitnessSelfType, representation: .thick)
        let params = self.parameters.map { param -> SILParameterInfo in
            if param.type.type == exemplarWitnessSelfType {
                return SILParameterInfo(type: replacementType, convention: param.convention)
            } else if param.type.type == metatype {
                return SILParameterInfo(type: TypeFactory.createMetatype(instanceType: replacementType, representation: .thick), convention: param.convention)
            } else {
                return param
            }
        }
        let results = self.results.map { result -> SILResultInfo in
            if result.type.type == exemplarWitnessSelfType {
                return SILResultInfo(type: replacementType, convention: result.convention)
            } else if result.type.type == metatype {
                return SILResultInfo(type: TypeFactory.createMetatype(instanceType: replacementType, representation: .thick), convention: result.convention)
            } else {
                return result
            }
        }
        let ret = TypeFactory.getSILFunctionType(genericSig: generic ? genericSig : nil, extInfo: extInfo, coroutineKind: coroutineKind, calleeConvention: calleeConvention, params: params, yields: yields, normalResults: results, errorResult: errorResult, witnessMethodConformance: witnessMethodConformance)
        return ret
    }
}

/// SILCoroutineKind - What kind of coroutine is this SILFunction?
enum SILCoroutineKind {
    /// This function is not a coroutine.  It may have arbitrary normal results and may not have yield results.
    case none

    /// This function is a yield-once coroutine (used by e.g. accessors). It must not have normal results and may have arbitrary yield results.
    case yieldOnce

    /// This function is a yield-many coroutine (used by e.g. generators). It must not have normal results and may have arbitrary yield results.
    case yieldMany
}
