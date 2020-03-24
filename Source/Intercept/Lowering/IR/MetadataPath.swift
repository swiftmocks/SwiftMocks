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

enum OperationCost: Int, Comparable {
    case free = 0
    case arithmetic = 1
    case load = 3
    case call = 10

    static func < (lhs: OperationCost, rhs: OperationCost) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// A path from one source metadata --- either Swift type metadata or a Swift protocol conformance --- to another.
struct MetadataPath {
    var path = [Component]()

    /// Return an abstract measurement of the cost of this path.
    var cost: OperationCost {
        var cost = OperationCost.free.rawValue
        for component in path {
            cost += component.cost.rawValue
        }
        return OperationCost(rawValue: cost)!
    }

    /// Add a step to this path which will cause a dynamic assertion if it's followed.
    mutating func addImpossibleComponent() {
        path.append(Component(kind: .impossible))
    }

    /// Add a step to this path which gets the type metadata stored at requirement index n in a generic type metadata.
    mutating func addNominalTypeArgumentComponent(index: Int) {
        path.append(Component(kind: .nominalTypeArgument, index: index))
    }

    /// Add a step to this path which gets the protocol witness table stored at requirement index n in a generic type metadata.
    mutating func addNominalTypeArgumentConformanceComponent(index: Int) {
        path.append(Component(kind: .nominalTypeArgumentConformance, index: index))
    }

    /// Add a step to this path which gets the inherited protocol at a particular witness index.
    mutating func addInheritedProtocolComponent(index: WitnessIndex) {
        assert(!index.isPrefix)
        path.append(Component(kind: .outOfLineBaseProtocol, index: index.value))
    }

    /// Add a step to this path which gets the associated conformance at a particular witness index.
    mutating func addAssociatedConformanceComponent(index: WitnessIndex) {
        assert(!index.isPrefix)
        path.append(Component(kind: .associatedConformance, index: index.value))
    }

    mutating func addConditionalConformanceComponent(index: Int) {
        path.append(Component(kind: .conditionalConformance, index: index))
    }
}

extension MetadataPath {
    struct Component {
        enum Kind: UInt8 {
            // Some components carry indices.
            // P means the primary index.

            /// Associated conformance of a protocol.  P is the WitnessIndex.
            case associatedConformance

            /// Base protocol of a protocol.  P is the WitnessIndex.
            case outOfLineBaseProtocol

            /// Witness table at requirement index P of a generic nominal type.
            case nominalTypeArgumentConformance

            /// Type metadata at requirement index P of a generic nominal type.
            case nominalTypeArgument

            /// Conditional conformance at index P (i.e. the P'th element) of a conformance.
            case conditionalConformance
            // lastWithPrimaryIndex = ConditionalConformance,

            // Everything past this point has no index.

            /// An impossible path.
            case impossible

            static let lastWithPrimaryIndex: Kind = .conditionalConformance
        }

        private static let kindMask = 0xF
        private static let indexShift = 4

        private static func hasPrimaryIndex(kind: Kind) -> Bool {
            kind.rawValue <= Kind.lastWithPrimaryIndex.rawValue
        }

        let kind: Kind
        let index: Int

        init(kind: Kind) {
            precondition(!Self.hasPrimaryIndex(kind: kind))
            self.kind = kind
            self.index = 0
        }

        init(kind: Kind, index: Int) {
            precondition(Self.hasPrimaryIndex(kind: kind))
            self.kind = kind
            self.index = index
        }

        /// Return an abstract measurement of the cost of this component.
        var cost: OperationCost {
            switch kind {
            case .outOfLineBaseProtocol,
                 .nominalTypeArgumentConformance,
                 .nominalTypeArgument,
                 .conditionalConformance:
                return .load

            case .associatedConformance:
                return .call

            case .impossible:
                LoweringError.unreachable("cannot compute cost of an impossible path")
            }
        }
    }
}
