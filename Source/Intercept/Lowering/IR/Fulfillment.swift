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

/// The metadata value can be fulfilled by following the given metadata path from the given source.
struct Fulfillment {
    /// The source index.
    let sourceIndex: Int

    /// The state of the metadata at the fulfillment.
    let state: MetadataState

    /// The path from the source metadata.
    let path: MetadataPath
}

protocol FulfillmentMapInterestingKeysCallback {
    /// Is the given type something that we should add fulfillments for?
    func isInterestingType(type: AType) -> Bool

    /// Is the given type expressed in terms of types that we should add fulfillments for? It's okay to conservatively return true here.
    func hasInterestingType(type: AType) -> Bool

    /// Are we only interested in a subset of the conformances for a given type?
    func hasLimitedInterestingConformances(type: AType) -> Bool

    /// Return the limited interesting conformances for an interesting type.
    func getInterestingConformances(type: AType) -> [ProtocolDecl]

    /// Return the limited interesting conformances for an interesting type.
    func getSuperclassBound(type: AType) -> AType?
}

class FulfillmentMap {
    typealias InterestingKeysCallback = FulfillmentMapInterestingKeysCallback

    struct FulfillmentKey: Hashable {
        let type: AType
        let proto: ProtocolDecl?

        static func == (lhs: FulfillmentMap.FulfillmentKey, rhs: FulfillmentMap.FulfillmentKey) -> Bool {
            lhs.type == rhs.type && lhs.proto?.proto == rhs.proto?.proto
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(type)
        }
    }

    private(set) var fulfillments = [FulfillmentKey: Fulfillment]()

    /// Testify that there's a fulfillment at the given path.
    @discardableResult
    func addFulfillment(key: FulfillmentKey, source: Int, path: MetadataPath, metadataState: MetadataState) -> Bool {
        // Only add a fulfillment if we don't have any previous fulfillment for that value or if it 's cheaper than the existing fulfillment.
        if let existing = fulfillments[key] {
            // If the new fulfillment is worse than the existing one, ignore it.
            let existingState = existing.state
            if metadataState.rawValue > existingState.rawValue {
                return false
            }

            // Consider cost only if the fulfillments are equivalent in state.
            // this is potentially suboptimal, but it generally won't matter.
            if metadataState == existingState && path.cost >= existing.path.cost {
                return false
            }

            fulfillments[key] = Fulfillment(sourceIndex: source, state: existing.state, path: path)
            return true
        } else {
            fulfillments[key] = Fulfillment(sourceIndex: source, state: metadataState, path: path)
            return true
        }
    }

    func getWitnessTable(type: AType, proto: ProtocolDecl) -> Fulfillment? {
        fulfillments[FulfillmentKey(type: type, proto: nil)]
    }

    func getTypeMetadata(type: AType) -> Fulfillment? {
        fulfillments[FulfillmentKey(type: type, proto: nil)]
    }

    /// Given that we have a source for metadata of the given type, check to see if it fulfills anything.
    ///
    ///
    /// - Parameters:
    ///   - isExact: true if the metadata is known to be exactly the metadata for the given type, false if it might be a subtype
    func searchTypeMetadata(igm: IRGenModule, type: AType, isExact: Bool, metadataState: MetadataState, source: Int, path: MetadataPath, keys: InterestingKeysCallback) -> Bool {

        // If this is an exact source, and it's an interesting type, add this as a fulfillment.
        if isExact && keys.isInterestingType(type: type) {
            // If the type isn't a leaf type, also check it as an inexact match.
            var hadFulfillment = false
            if !isLeafTypeMetadata(type) {
                hadFulfillment = hadFulfillment || searchTypeMetadata(igm: igm, type: type, isExact: false, metadataState: metadataState, source: source, path: path, keys: keys)
            }

            // Consider its super class bound.
            if metadataState == MetadataState.metadataStateComplete {
                if let superclassTy = keys.getSuperclassBound(type: type) {
                    hadFulfillment = hadFulfillment || searchNominalTypeMetadata(IGM: igm, type: superclassTy, metadataState: metadataState, source: source, path: path, keys: keys)
                }
            }

            // Add the fulfillment.
            hadFulfillment = hadFulfillment || addFulfillment(key: FulfillmentMap.FulfillmentKey(type: type, proto: nil), source: source, path: path, metadataState: metadataState)
            return hadFulfillment
        }

        // Search the superclass fields.  We can only do this if the metadata is complete.
        if metadataState == MetadataState.metadataStateComplete && keys.isInterestingType(type: type) {
            if let superclassTy = keys.getSuperclassBound(type: type) {
                return searchNominalTypeMetadata(IGM: igm, type: superclassTy, metadataState: metadataState, source: source, path: path, keys: keys)
            }
        }

        // Inexact metadata will be a problem if we ever try to use this
        // to remember that we already have the metadata for something.
        if type is NominalType || type is BoundGenericType {
            return searchNominalTypeMetadata(IGM: igm, type: type, metadataState: metadataState, source: source, path: path, keys: keys)
        }

        // [apple] TODO: tuples
        // [apple] TODO: functions
        // [apple] TODO: metatypes

        return false
    }

    func searchNominalTypeMetadata(IGM: IRGenModule, type: AType, metadataState: MetadataState, source: Int, path: MetadataPath, keys: InterestingKeysCallback) -> Bool {

        return false // LoweringError.notImplemented(#function)
    }

    @discardableResult
    func searchConformance(igm: IRGenModule, conformance: ProtocolConformance, sourceIndex: Int, path: MetadataPath, interestingKeys: InterestingKeysCallback) -> Bool {
        return false // LoweringError.notImplemented(#function)
    }

    /// Is it even theoretically possible that we might find a fulfillment in the given type?
    static func isInterestingTypeForFulfillments(type: AType) -> Bool {
        // Some day, if we ever record fulfillments for concrete types, this optimization will probably no longer be useful.
        return type.hasTypeParameter
    }
}

/// Is metadata for the given type kind a "leaf", or does it possibly store any other type metadata that we can statically extract?
///
/// It's okay to conservatively answer "no".  It's more important for this to be quick than for it to be accurate; don't recurse.
private func isLeafTypeMetadata(_ type: AType) -> Bool {
    if type is BuiltinType {
        // All the builtin types are leaves.
        return true
    }
    switch type.kind {
    // Type parameters are statically opaque.
    case .primaryArchetype,
         .openedArchetype,
         .nestedArchetype,
         .opaqueTypeArchetype,
         .genericTypeParam,
         .dependentMember:
        return true

    // Only the empty tuple is a leaf.
    case .tuple:
        return (type as! TupleType).elements.count == 0

    // Nominal types might have generic parents.
    case .class,
         .enum,
         .protocol,
         .struct:
        LoweringError.notImplemented("NominalType decl") // !(type as! NominalType)->getDecl()->isGenericContext();

    // Bound generic types have type arguments.
    case .boundGenericClass,
         .boundGenericEnum,
         .boundGenericStruct:
        return false

    // Functions have component types.
    case .function,
         .genericFunction: // included for future-proofing
        return false
        
    // Protocol compositions have component types.
    case .protocolComposition:
        return false

    // Metatypes have instance types.
    case .metatype,
         .existentialMetatype:
        return false
    default:
        LoweringError.unreachable("these types do not have metadata")
    }
}
