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

extension LLVMType: CustomStringConvertible {
    var description: String {
        switch self {
        case .void:
            return "void"
        case .i1:
            return "i1"
        case .i8:
            return "i8"
        case .i16:
            return "i16"
        case .i32:
            return "i32"
        case .i64:
            return "i64"
        case .float:
            return "float"
        case .double:
            return "double"
        case .x86_fp80:
            return "x86_fp80"
        case let .array(type, size):
            return "[ \(size) x \(type) ]"
        case let .struct(types):
            return "{ " + types.map { $0.description }.joined(separator: ", ") + " }"
        case .pointer:
            return "i8*"
        }
    }
}

extension LLVMFunctionType: CustomStringConvertible {
    var description: String {
        "\(result) (\(params.map { $0.description }.joined(separator: ", ")))"
    }
}
