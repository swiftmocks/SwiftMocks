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

final class TupleType: AType, ATypeEquatable, CanComputeMetadata {
    let metadata: Metadata?
    let elements: [AType]

    lazy var computedMetadata: Metadata = {
        Runtime.getTupleTypeMetadata(elements: elements.map { TypeFactory.convert($0) })
    }()

    lazy var parameterTypeFlags: [ParameterTypeFlags] = {
        // for now, just return defaults. As the TODO in the compiler sources next to ParameterTypeFlags notes, these shouldn't be in tuples anyway. But supporting autoclosure and variadic params is on our TODO
        Array(repeating: ParameterTypeFlags(), count: elements.count)
    }()

    private init(elements: [AType], metadata: TupleTypeMetadata? = nil) {
        self.elements = elements
        self.metadata = metadata
        super.init(kind: .tuple)
    }

    func isEqual(to other: AType) -> Bool {
        guard let other = other as? TupleType else {
            return false
        }
        return other.elements == elements
    }

    /// To be used only by `TypeFactory`
    static func _get(metadata: TupleTypeMetadata) -> TupleType {
        let elements = metadata.elements.map { TypeFactory.from(metadata: $0.metadata) }
        return TupleType(elements: elements, metadata: metadata)
    }

    static func _get(elements: [AType]) -> TupleType {
        TupleType(elements: elements)
    }
}
