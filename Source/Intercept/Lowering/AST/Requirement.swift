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

/// A single requirement placed on the type parameters (or associated types thereof).
///
/// This is just the bare-bones implementation to support rudimentary `GenericSignature`s required for protocol witnesses.
struct Requirement: Hashable {
    /// Describes the kind of a requirement that occurs within a requirements clause.
    enum Kind: Hashable {
        /// A conformance requirement T : P, where T is a type that depends on a generic parameter and P is a protocol to which T must conform.
        case conformance
        /// A superclass requirement T : C, where T is a type that depends on a generic parameter and C is a concrete class type which T must equal or be a subclass of.
        case superclass
        /// A same-type requirement T == U, where T and U are types that shall be equivalent.
        case sameType
        /// A layout bound T : L, where T is a type that depends on a generic parameter and L is some layout specification that should bound T.
        case layout
    }

    let kind: Kind
    let first: AType
    let second: AType?

    private init(kind: Kind, first: AType, second: AType?) {
        self.kind = kind
        self.first = first
        self.second = second
    }

    static func conformance(of first: AType, to second: AType) -> Requirement {
        .init(kind: .conformance, first: first, second: second)
    }
}
