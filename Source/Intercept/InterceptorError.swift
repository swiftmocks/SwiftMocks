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
import MachO

/// Errors that can be thrown by the various bits of interceptor where the context allows throwing
enum InterceptorError: LocalizedError, CustomStringConvertible {
    case couldNotDemangle(String, Swift.Error)
    case unsupportedFunctionType(String)
    case couldNotGetType(String)
    case unrecognisedProtocolConformance
    case unrecognisedWitnessTableEntry
    case loweringError(LoweringError)

    var errorDescription: String? {
        switch self {
        case let .couldNotDemangle(name, error):
            return "Could not demangle \(name): \(error)"
        case let .unsupportedFunctionType(name):
            if let demangled = Runtime.demangle(name) {
                return "Unsupported function type: \(name) (\(demangled))"
            }
            return "Unsupported function type: \(name)"
        case let .couldNotGetType(name):
            return "Could not materialise type \(name)"
        case .unrecognisedProtocolConformance:
            return "Unrecognized protocol conformance"
        case .unrecognisedWitnessTableEntry:
            return "Unrecognized witness table entry"
        case .loweringError(let error):
            return error.errorDescription
        }
    }

    var description: String {
        "\(Self.self): \(errorDescription ?? String(reflecting: self))"
    }
}
