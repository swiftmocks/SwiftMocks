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

internal extension String {
    func shiftingRight(by numberOfSpaces: Int) -> String {
        let spaces: String = String(repeating: " ", count: numberOfSpaces)
        return self.split(separator: "\n").map { "\(spaces)\($0)" }.joined(separator: "\n")
    }

    func appending<T>(_ name: String, _ value: @autoclosure () -> T, onlyIf: Bool = true) -> String {
        guard onlyIf else { return self }
        let lines = String(describing: value()).split(separator: "\n")
        let result = self + "\n  - \(name): " + (lines.isEmpty ? "" : lines.first!)
        guard lines.count > 1 else {
            return result
        }
        return result + "\n" + lines.dropFirst().map { "    \($0)" }.joined(separator: "\n")
    }

    func appending<T>(_ name: String, _ value: @autoclosure () -> T?, onlyIf: Bool = true) -> String {
        guard onlyIf else { return self }
        let lines = String(describing: value() ?? "nil" as Any).split(separator: "\n")
        let result = self + "\n  - \(name): " + (lines.isEmpty ? "" : lines.first!)
        guard lines.count > 1 else {
            return result
        }
        return result + "\n" + lines.dropFirst().map { "    \($0)" }.joined(separator: "\n")
    }

    /// With autoclosures, unlike regular parameters, the type system always selects @autoclosure () -> T over @autoclosure () -> [T] for arguments of array type. Use `condensed` parameter to force the array variant.
    func appending<T>(_ name: String, _ values: @autoclosure () -> [T], condensed: Bool, onlyIf: Bool = true) -> String {
        guard onlyIf else { return self }
        let values = values()
        guard !values.isEmpty else {
            return self + "\n  - \(name): []"
        }
        let descriptions: [String] = values.map { String(describing: $0) }
        // if there is only one element, and its description is not multi-line, force condensed mode
        let condensed = condensed || (values.count == 1 && descriptions.first?.contains("\n") == false)
        if condensed {
            return self + "\n  - \(name): [" + descriptions.joined(separator: ", ") + "]"
        }

        return self + "\n  - \(name): [\n" + descriptions.map { $0.shiftingRight(by: 6)}.joined(separator: "\n") + "\n    ]"
    }

    func appending<T>(_ name: String, _ values: @autoclosure () -> [T]?, condensed: Bool, onlyIf: Bool = true) -> String {
        guard onlyIf else { return self }
        if let values = values() {
            return appending(name, values, condensed: condensed)
        } else {
            return appending(name, nil as Any?)
        }
    }
}

extension String {
    init<T: BinaryInteger>(binary: T) {
        self = String(binary, radix: 2).grouping(every: 4)
    }

    private func grouping(every n: Int) -> String {
        enumerated().reduce(into: "") { acc, current in
            if current.offset != 0 && (count - current.offset) % n == 0 {
                acc.append(" ")
            }
            acc.append(current.element)
        }
    }
}
