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

/// A ProtocolConformanceRef is a handle to a protocol conformance which may be either concrete or abstract.
///
/// A concrete conformance is derived from a specific protocol conformance declaration.
///
/// An abstract conformance is derived from context: the conforming type is either existential or opaque (i.e. an archetype), and while the type-checker promises that the conformance exists, it is not known statically which concrete conformance it refers to.
struct ProtocolConformanceRef: Hashable {
    let proto: ProtocolDecl
    let conformance: ProtocolConformance?
    let isObjC: Bool = false

    var isConcrete: Bool {
        conformance != nil
    }

    init(proto: ProtocolType, conformance: ProtocolConformance? = nil) {
        self.proto = ProtocolDecl(proto: proto)
        self.conformance = conformance
    }

    static func == (lhs: ProtocolConformanceRef, rhs: ProtocolConformanceRef) -> Bool {
        lhs.isObjC == rhs.isObjC && lhs.proto.proto == rhs.proto.proto && lhs.conformance == rhs.conformance
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(isObjC)
        hasher.combine(proto.proto)
        hasher.combine(conformance)
    }
}

/// Describes the kind of protocol conformance structure used to encode
/// conformance.
enum ProtocolConformanceKind {
  /// "Normal" conformance of a (possibly generic) nominal type, which contains complete mappings.
  case normal
  /// Self-conformance of a protocol to itself.
  case `self`
  /// Conformance for a specialization of a generic type, which projects the underlying generic conformance.
  case specialized
  /// Conformance of a generic class type projected through one of its superclass's conformances.
  case inherited
}

struct ProtocolConformance: Hashable {
    let kind: ProtocolConformanceKind
    let conformingType: AType
}
