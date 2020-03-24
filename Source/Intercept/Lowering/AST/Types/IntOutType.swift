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

class InOutType: AType, ATypeEquatable {
    let objectType: AType

    fileprivate init(objectType: AType) {
        self.objectType = objectType
        super.init(kind: .inOut)
    }

    func isEqual(to other: AType) -> Bool {
        guard let other = other as? InOutType else {
            return false
        }
        return other.objectType == objectType
    }

    /// To be called only by `TypeFactory`
    static func _get(objectType: AType) -> InOutType {
        InOutType(objectType: objectType)
    }
}
