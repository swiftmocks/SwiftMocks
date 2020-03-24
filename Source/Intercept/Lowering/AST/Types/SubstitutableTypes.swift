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

class SubstitutableType: AType {}

class GenericTypeParamType: SubstitutableType, ATypeEquatable {
    private let depthAndIndex: Int

    var depth: Int {
        depthAndIndex >> 16
    }

    var index: Int {
        Int(Int16(truncatingIfNeeded: depthAndIndex) & Int16(bitPattern: 0xFFFF))
    }

    // tau00 is the only generic type param we are using (for protocols)
    private init(depth: Int, index: Int) {
        depthAndIndex = depth << 16 | index
        super.init(kind: .genericTypeParam)
    }

    func isEqual(to other: AType) -> Bool {
        guard let other = other as? GenericTypeParamType else {
            return false
        }
        return other.depthAndIndex == depthAndIndex
    }

    static var tau00: GenericTypeParamType = .init(depth: 0, index: 0)
}

class ArchetypeType: SubstitutableType {
    var requiresClass: Bool { false }
    var superclass: AType? { nil }
    var root: ArchetypeType { self }
}
class PrimaryArchetypeType: ArchetypeType {}
class OpaqueTypeArchetypeType: ArchetypeType {}
class OpenedArchetypeType: ArchetypeType {}
class NestedArchetypeType: ArchetypeType {}

class DependentMemberType: AType, ATypeEquatable {
    let base: AType

    init(base: AType) {
        self.base = base
        super.init(kind: .dependentMember)
    }

    func isEqual(to other: AType) -> Bool {
        guard let other = other as? DependentMemberType else {
            return false
        }
        return other.base == base
    }
}

