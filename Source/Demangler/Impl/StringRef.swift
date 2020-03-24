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

/// A non-mutable string-like struct that allows keeping zeroes as part of the string. Useful primarily for mangled names.
public struct StringRef {
    public let pointer: ConstPointer<CChar>
    public let length: Int

    public init(pointer: ConstPointer<CChar>, length: Int) {
        self.pointer = pointer
        self.length = length
    }
}

extension StringRef: BidirectionalCollection {
    public typealias Index = Int
    public typealias Element = UnicodeScalar

    public func index(after i: Int) -> Int {
        i + 1
    }

    public func index(before i: Int) -> Int {
        i - 1
    }

    public subscript(position: Int) -> UnicodeScalar {
        _read {
            // yield here is not adding anything useful, but it's kindof cool
            yield UnicodeScalar(pointer.reinterpret(UInt8.self).advanced(by: position).pointee)
        }
    }

    public var startIndex: Int {
        0
    }

    public var endIndex: Int {
        length
    }
}
