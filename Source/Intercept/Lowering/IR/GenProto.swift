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

/// Given a generic signature, add the argument types required in order to call it.
func expandPolymorphicSignature(_ igm: IRGenModule, _ polyFn: SILFunctionType) -> [LLVMType] {
    ExpandPolymorphicSignature(igm: igm, fnType: polyFn).expand()
}

func enumerateGenericSignatureRequirements(signature: GenericSignature?, callback: GenericRequirement.Callback) {
    guard let signature = signature else {
        return
    }
    signature.forEachParam { (ty, isCanonical) in
        if isCanonical {
            callback(GenericRequirement(typeParameter: ty, proto: nil))
        }
    }
    for reqt in signature.requirements {
        switch reqt.kind {
        // Ignore these; they don't introduce extra requirements.
        case .superclass,
             .sameType,
             .layout:
            continue

        case .conformance:
            let type = reqt.first
            let proto = ProtocolDecl(proto: (reqt.second as! ProtocolType))
            callback(GenericRequirement(typeParameter: type, proto: proto)) // XXX: objc proto would not do the callback
            continue
        }
    }
}

struct MetadataSource {
    enum Kind {
        /// Metadata is derived from a source class pointer.
        case classPointer
        /// Metadata is derived from a type metadata pointer.
        case metadata
        /// Metadata is derived from the origin type parameter.
        case genericLValueMetadata
        /// Metadata is obtained directly from the from a Self metadata parameter passed via the WitnessMethod convention.
        case selfMetadata
        /// Metadata is derived from the Self witness table parameter passed via the WitnessMethod convention.
        case selfWitnessTable
    }

    static let invalidSourceIndex = -1

    static func requiresSourceIndex(kind: Kind) -> Bool {
        kind == .classPointer ||
            kind == .metadata ||
            kind == .genericLValueMetadata
    }

    /// The kind of source this is.
    let kind: Kind
    /// The parameter index, for ClassPointer and Metadata sources.
    let index: Int

    let type: AType

    init(kind: Kind, index: Int, type: AType) {
        precondition(index != Self.invalidSourceIndex || !Self.requiresSourceIndex(kind: kind))
        self.kind = kind
        self.index = index
        self.type = type
    }
}

private class ExpandPolymorphicSignature: PolymorphicConvention {
    override init(igm: IRGenModule, fnType: SILFunctionType) {
        super.init(igm: igm, fnType: fnType)
    }

    func expand() -> [LLVMType] {
        var ret = [LLVMType]()
        for source in sources {
            addEarlySource(source: source, out: &ret)
        }

        enumerateUnfulfilledRequirements { req in
            ret.append(req.proto != nil ? igm.witnessTablePtrTy : igm.typeMetadataPtrTy)
        }
        return ret
    }

    private func addEarlySource(source: MetadataSource, out: inout [LLVMType]) {
        switch source.kind {
        case .classPointer:
        return // already accounted for
        case .metadata:
        return // already accounted for
        case .genericLValueMetadata:
            out.append(igm.typeMetadataPtrTy)
        case .selfMetadata:
        return // handled as a special case in expand()
        case .selfWitnessTable:
            return // handled as a special case in expand()
        }
    }
}

/// A class for computing how to pass arguments to a polymorphic function.  The subclasses of this are the places which need to be updated if the convention changes.
private class PolymorphicConvention {
    let igm: IRGenModule
    let fnType: SILFunctionType
    let generics: GenericSignature?

    private(set) var sources = [MetadataSource]()
    private(set) var fulfillments = FulfillmentMap()

    init(igm: IRGenModule, fnType: SILFunctionType) {
        self.igm = igm
        self.fnType = fnType
        self.generics = fnType.genericSig

        let rep = fnType.representation

        if fnType.isPseudoGeneric {
            LoweringError.notImplemented("Obj-C")
        }

        if rep == .witnessMethod {
            // Protocol witnesses always derive all polymorphic parameter information
            // from the Self and Self witness table arguments. We also *cannot* consider
            // other arguments; doing so would potentially make the signature
            // incompatible with other witnesses for the same method.
            considerWitnessSelf(fnType)
        } /* else if rep == .objc { ... } */ else {
            // We don't need to pass anything extra as long as all of the
            // archetypes (and their requirements) are producible from
            // arguments.
            var selfIndex: Int = -1
            let params = fnType.parameters
            // Consider 'self' first.
            if fnType.hasSelfParam {
                selfIndex = params.count - 1
                considerParameter(params[selfIndex], index: selfIndex, isSelfParameter: true)
            }

            // Now consider the rest of the parameters.
            for index in params.indices {
                if (index != selfIndex) {
                    considerParameter(params[index], index: index, isSelfParameter: false)
                }
            }
        }
    }

    func enumerateUnfulfilledRequirements(callback: GenericRequirement.Callback) {
        enumerateRequirements { requirement in
            if let proto = requirement.proto {
                if fulfillments.getWitnessTable(type: requirement.typeParameter, proto: proto) == nil {
                    callback(requirement)
                }
            } else {
                if fulfillments.getTypeMetadata(type: requirement.typeParameter) == nil {
                    callback(requirement)
                }
            }
        }
    }

    func enumerateRequirements(callback: GenericRequirement.Callback) {
        enumerateGenericSignatureRequirements(signature: generics, callback: callback)
    }

    private func considerNewTypeSource(kind: MetadataSource.Kind, paramIndex: Int, type: AType, isExact: Bool) {
        if !FulfillmentMap.isInterestingTypeForFulfillments(type: type) {
            return
        }

        // Prospectively add a source.
        sources.append(MetadataSource(kind: kind, index: paramIndex, type: type))

        // Consider the source.
        if !considerType(type: type, isExact: isExact, sourceIndex: sources.count - 1, path: MetadataPath()) {
            // If it wasn't used in any fulfillments, remove it.
            sources.removeLast()
        }
    }

    @discardableResult
    private func considerType(type: AType, isExact: Bool, sourceIndex: Int, path: MetadataPath) -> Bool {
        let callbacks = FulfillmentMapCallback(this: self)
        return fulfillments.searchTypeMetadata(igm: igm, type: type, isExact: isExact, metadataState: MetadataState.metadataStateComplete, source: sourceIndex, path: path, keys: callbacks)
    }

    private func considerWitnessSelf(_ fnType: SILFunctionType) {
        let selfTy = fnType.selfInstanceType.type
        let conformance = fnType.witnessMethodConformance! // we shouldn't be here if witness method conformance is nil

        // First, bind type metadata for Self.
        sources.append(MetadataSource(kind: .selfMetadata, index: MetadataSource.invalidSourceIndex, type: selfTy))

        if selfTy is GenericTypeParamType {
            // The Self type is abstract, so we can fulfill its metadata from the Self metadata parameter.
            addSelfMetadataFulfillment(selfTy)
        }

        considerType(type: selfTy, isExact: false, sourceIndex: sources.count - 1, path: MetadataPath())

        // The witness table for the Self : P conformance can be fulfilled from the Self witness table parameter.
        sources.append(MetadataSource(kind: .selfWitnessTable, index: MetadataSource.invalidSourceIndex, type: selfTy))
        addSelfWitnessTableFulfillment(selfTy, conformance: conformance)
    }

    private func considerParameter(_ param: SILParameterInfo, index paramIndex: Int, isSelfParameter: Bool) {
        let type = param.type.type
        switch param.convention {
        // Indirect parameters do give us a value we can use, but right now we don't bother, for no good reason. But if this is 'self', consider passing an extra metatype.
        case .indirectIn,
             .indirectInConstant,
             .indirectInGuaranteed,
             .indirectInout,
             .indirectInoutAliasable:
            if !isSelfParameter {
                return
            }

            if param.type.isNominalOrBoundGenericNominal {
                considerNewTypeSource(kind: .genericLValueMetadata, paramIndex: paramIndex, type: type, isExact: true)
            }

        case .directOwned,
             .directUnowned,
             .directGuaranteed:
            // Classes are sources of metadata.
            if type.isClassOrBoundGenericClass {
                considerNewTypeSource(kind: .classPointer, paramIndex: paramIndex, type: type, isExact: false)
                return
            }

            if type is GenericTypeParamType {
                if let superclassTy = generics?.getSuperclassBound(type) {
                    considerNewTypeSource(kind: .classPointer, paramIndex: paramIndex, type: superclassTy, isExact: false)
                }
            }

            // Thick metatypes are sources of metadata.
            if let metatypeTy = type as? MetatypeType {
                if metatypeTy.representation != .thick {
                    return
                }

                // Thick metatypes for Objective-C parameterized classes are not sources of metadata.
                let objTy = metatypeTy.instanceType
                if /* let classDecl = */ objTy.isClassOrBoundGenericClass {
                    // if (classDecl->usesObjCGenericsModel()) return;
                    considerNewTypeSource(kind: .metadata, paramIndex: paramIndex, type: objTy, isExact: false)
                }
            }
        }
    }

    private func addSelfMetadataFulfillment(_ arg: AType) {
        let source = sources.count - 1
        fulfillments.addFulfillment(key: FulfillmentMap.FulfillmentKey(type: arg, proto: nil), source: source, path: MetadataPath(), metadataState: .metadataStateComplete)
    }

    private func addSelfWitnessTableFulfillment(_ arg: AType, conformance: ProtocolConformanceRef) {
        let proto = conformance.proto
        let source = sources.count - 1
        fulfillments.addFulfillment(key: FulfillmentMap.FulfillmentKey(type: arg, proto: proto), source: source, path: MetadataPath(), metadataState: .metadataStateComplete)


        if let conformance = conformance.conformance {
            let callbacks = FulfillmentMapCallback(this: self)
            fulfillments.searchConformance(igm: igm, conformance: conformance, sourceIndex: source, path: MetadataPath(), interestingKeys: callbacks)
        }
    }

    private func getFulfillmentForTypeMetadata(_ ty: AType) -> Fulfillment? {
        fulfillments.getTypeMetadata(type: ty)
    }

    private func getConformsTo(_ t: AType) -> [ProtocolDecl] {
        generics!.getConformsTo(type: t)
    }

    private func getSuperclassBound(_ t: AType) -> AType? {
        if let superclassTy = generics?.getSuperclassBound(t) {
            return superclassTy
        }
        return nil
    }


    private struct FulfillmentMapCallback: FulfillmentMap.InterestingKeysCallback {
        let this: PolymorphicConvention

        func isInterestingType(type: AType) -> Bool {
            type.hasTypeParameter
        }

        func hasInterestingType(type: AType) -> Bool {
            type.hasTypeParameter
        }

        func hasLimitedInterestingConformances(type: AType) -> Bool {
            true
        }

        func getInterestingConformances(type: AType) -> [ProtocolDecl] {
            this.getConformsTo(type)
        }

        func getSuperclassBound(type: AType) -> AType? {
            this.getSuperclassBound(type)
        }
    }
}
