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

extension IRSignature: CustomStringConvertible {
    var description: String {
        let paramsAndAttributes: String = type
            .params
            .enumerated()
            .map { (index, type) -> String in
                (["\(type)"] + Array(attributes.parameterAttributes[index] ?? Set()).map { "\($0)" }).joined(separator: " ")
        }
        .joined(separator: ", ")
        return (attributes.functionAttributes + [type.result.description]).joined(separator: " ") +
            attributes.resultAttributes.joined(separator: " ") +
            " (" + paramsAndAttributes + ")"
    }
}

extension NativeConventionSchema: CustomStringConvertible {
    var description: String {
        "\(asArray)"
    }
}
