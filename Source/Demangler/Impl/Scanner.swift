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
//
// This source file contains code from CwlUtils, licensed under ISC license.
// Copyright © 2017 Matt Gallagher ( http://cocoawithlove.com ). All rights reserved.

import Foundation

struct ScalarScanner<C: Collection> where C.Iterator.Element == UnicodeScalar, C.Index: BinaryInteger {
    /// The underlying storage
    let scalars: C

    /// Current scanning index
    var index: C.Index

    /// Number of scalars consumed up to `index` (since String.UnicodeScalarView.Index is not a RandomAccessIndex, this makes determining the position *much* easier)
    var consumed: Int

    /// Construct from a String.UnicodeScalarView and a context value
    init(scalars: C) {
        self.scalars = scalars
        self.index = self.scalars.startIndex
        self.consumed = 0
    }

    /// Attempt to advance the `index` by count, returning `false` and `index` unchanged if `index` would advance past the end, otherwise returns `true` and `index` is advanced.
    mutating func backtrack(count: Int = 1) throws {
        if count <= consumed {
            if count == 1 {
                index = scalars.index(index, offsetBy: -1)
                consumed -= 1
            } else {
                let limit = consumed - count
                while consumed != limit {
                    index = scalars.index(index, offsetBy: -1)
                    consumed -= 1
                }
            }
        } else {
            throw ScalarScannerError.endedPrematurely(count: -count, at: consumed)
        }
    }

    /// Returns all content after the current `index`. `index` is advanced to the end.
    mutating func remainder() -> String {
        var string: String = ""
        while index != scalars.endIndex {
            string.unicodeScalars.append(scalars[index])
            index = scalars.index(after: index)
            consumed += 1
        }
        return string
    }

    /// If the next scalars after the current `index` match `value`, advance over them and return `true`, otherwise, leave `index` unchanged and return `false`.
    /// WARNING: `string` is used purely for its `unicodeScalars` property and matching is purely based on direct scalar comparison (no decomposition or normalization is performed).
    mutating func conditional(string: String) -> Bool {
        var i = index
        var c = 0
        for s in string.unicodeScalars {
            if i == scalars.endIndex || s != scalars[i] {
                return false
            }
            i = self.scalars.index(after: i)
            c += 1
        }
        index = i
        consumed += c
        return true
    }

    /// If the next scalar after the current `index` match `value`, advance over it and return `true`, otherwise, leave `index` unchanged and return `false`.
    mutating func conditional(scalar: UnicodeScalar) -> Bool {
        if index == scalars.endIndex || scalar != scalars[index] {
            return false
        }
        index = self.scalars.index(after: index)
        consumed += 1
        return true
    }

    /// If the `index` is at the end, throw, otherwise, return the next scalar at the current `index` without advancing `index`.
    func requirePeek() throws -> UnicodeScalar {
        if index == scalars.endIndex {
            throw ScalarScannerError.endedPrematurely(count: 1, at: consumed)
        }
        return scalars[index]
    }

    /// If the `index` is at the end, throw, otherwise, return the next scalar at the current `index`, advancing `index` by one.
    mutating func readScalar() throws -> UnicodeScalar {
        if index == scalars.endIndex {
            throw ScalarScannerError.endedPrematurely(count: 1, at: consumed)
        }
        let result = scalars[index]
        index = self.scalars.index(after: index)
        consumed += 1
        return result
    }

    /// Consume and return `count` scalars. `index` will be advanced by count. Throws if end of `scalars` occurs before consuming `count` scalars.
    mutating func readScalars(count: Int) throws -> String {
        var result = String()
        result.reserveCapacity(count)
        var i = index
        for _ in 0..<count {
            if i == scalars.endIndex {
                throw ScalarScannerError.endedPrematurely(count: count, at: consumed)
            }
            result.unicodeScalars.append(scalars[i])
            i = self.scalars.index(after: i)
        }
        index = i
        consumed += count
        return result
    }

    mutating func readPointer() throws -> ConstRawPointer {
        let index = self.index
        if index.advanced(by: 4) > scalars.endIndex {
            throw ScalarScannerError.endedPrematurely(count: 4, at: consumed)
        }
        let base = (scalars as! StringRef).pointer + Int(index) - 1
        let offset = ((scalars as! StringRef).pointer + Int(index)).raw.reinterpret(Int32.self, aligned: false).pointee
        self.index = index.advanced(by: 4)
        consumed += 4
        return (base + Int(offset)).raw
    }

    /// Returns a throwable error capturing the current scanner progress point.
    func unexpectedError() -> ScalarScannerError {
        return ScalarScannerError.unexpected(at: consumed)
    }

    var isAtEnd: Bool {
        return index == scalars.endIndex
    }
}

/// A type for representing the different possible failure conditions when using ScalarScanner
public enum ScalarScannerError: Error {
    /// The scalar at the specified index doesn't match the expected grammar
    case unexpected(at: Int)

    /// Expected numerals at offset `at`
    case expectedInt(at: Int)

    /// Attempted to read `count` scalars from position `at` but hit the end of the sequence
    case endedPrematurely(count: Int, at: Int)
}
