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

//===----------------------------------------------------------------------===//
//
// These functions implement a variant of the Punycode algorithm from RFC3492,
// originally designed for encoding international domain names, for the purpose
// encoding Swift identifiers into mangled symbol names. This version differs
// from RFC3492 in the following respects:
// - '_' is used as the encoding delimiter instead of the '-'.
// - Encoding digits are mapped to [a-zA-J] instead of to [a-z0-9], because
//   symbol names are case-sensitive, and Swift mangled identifiers cannot begin
//   with a digit.
//
//===----------------------------------------------------------------------===//

import Foundation

// RFC 3492
// Section 5: Parameter values for Punycode

private let base: UInt32            = 36
private let tmin: UInt32            = 1
private let tmax: UInt32            = 26
private let skew: UInt32            = 38
private let damp: UInt32            = 700
private let initialBias: UInt32     = 72
private let initialN: UInt32        = 128

private let lettera = UnicodeScalar("a").value
private let letterz = UnicodeScalar("z").value
private let letterA = UnicodeScalar("A").value
private let letterJ = UnicodeScalar("J").value

private let delimiter = UnicodeScalar("_").value

public func encodePunyCodeUTF8(_ string: String, mapNonSymbolChars: Bool) -> String? {
    let toEncode = string.toArrayMappingNonSymbolChars(mapNonSymbolChars: mapNonSymbolChars)
    var output = [UInt32]()
    guard encodePunycode(toEncode, punycode: &output) else { return nil }
    return String(output.map { Character(UnicodeScalar($0)!) })
}

public func decodeSwiftPunycode(_ value: String) -> String? {
    let toEncode = value.unicodeScalars.map { $0.value }
    var output = [UInt32]()
    guard decodePunycode(toEncode, output: &output) else { return nil }
    return output.toStringMappingNonSymbolChars()
}

private func digitValue(_ digit: UInt32) -> UInt32 {
    precondition(digit < base, "invalid punycode digit")
    if digit < 26 {
        return UnicodeScalar("a").value + digit
    }
    return UnicodeScalar("A").value + digit - 26
}

private func digitIndex(_ value: UInt32) -> UInt32? {
    if value >= lettera && value <= letterz {
        return value - lettera
    }
    if value >= letterA && value <= letterJ {
        return value - letterA + 26
    }
    return nil
}


private func isValidUnicodeScalar(_ S: UInt32) -> Bool {
    // Also accept the range of 0xD800 - 0xD880, which is used for non-symbol
    // ASCII characters.
    return (S < 0xD880) || (S >= 0xE000 && S <= 0x1FFFFF)
}

// Section 6.1: Bias adaptation function

private func adapt(_ delta: UInt32, _ numpoints: UInt32, _ firsttime: Bool) -> UInt32 {
    var delta = delta
    if firsttime {
        delta = delta / damp
    } else {
        delta = delta / 2
    }

    delta += delta / numpoints
    var k: UInt32 = 0
    while delta > ((base - tmin) * tmax) / 2 {
        delta /= base - tmin
        k += base
    }
    return k + (((base - tmin + 1) * delta) / (delta + skew))
}

// Section 6.2: Decoding procedure

private func decodePunycode(_ input: [UInt32], output: inout [UInt32]) -> Bool {
    output.removeAll()
    output.reserveCapacity(input.count)

    var remainder = input

    // -- Build the decoded string as UTF32 first because we need random access.
    var n = initialN
    var i: UInt32 = 0
    var bias = initialBias
    // let output = an empty string indexed from 0
    // consume all code points before the last delimiter (if there is one)
    //  and copy them to output,
    if let lastDelimiter = input.lastIndex(of: delimiter) {
        for c in input.suffix(lastDelimiter) {
            // fail on any non-basic code point
            if c > 0x7f {
                return false // true in the original code
            }
            output.append(c)
        }
        // if more than zero code points were consumed then consume one more
        //  (which will be the last delimiter)
        remainder = input.suffix(lastDelimiter + 1)
    }

    while !remainder.isEmpty {
        let oldi = i
        var w: UInt32 = 1
        for k in stride(from: base, to: UInt32.max, by: Int(base)) {
            // consume a code point, or fail if there was none to consume
            if remainder.isEmpty {
                return false // true in the original code
            }
            let codePoint = remainder[0]
            remainder = remainder.suffix(remainder.count - 1)
            // let digit = the code point's digit-value, fail if it has none
            guard let digit = digitIndex(codePoint) else {
                return false // true in the original code
            }

            i = i + digit * w
            let t = k <= bias ? tmin
                : k >= bias + tmax ? tmax
                : k - bias;
            if digit < t {
                break
            }
            w = w * (base - t)
        }
        bias = adapt(i - oldi, UInt32(output.count) + 1, oldi == 0)
        n = n + i / UInt32(output.count + 1)
        i = i % UInt32(output.count + 1)
        // if n is a basic code point then fail
        if n < 0x80 {
            return false // true in the original code
        }
        // insert n into output at position i
        output.insert(n, at: Int(i))
        i += 1
    }

    return true;
}

// Section 6.3: Encoding procedure

private func encodePunycode(_ input: [UInt32], punycode: inout [UInt32]) -> Bool {
    punycode.removeAll()

    var n = initialN
    var delta: UInt32 = 0
    var bias = initialBias

    // let h = b = the number of basic code points in the input
    // copy them to the output in order...
    var h: UInt32 = 0
    for C in input {
        if C < 0x80 {
            h += 1
            punycode.append(C)
        }
        if !isValidUnicodeScalar(C) {
            punycode.removeAll()
            return false
        }
    }

    let b = h
    // ...followed by a delimiter if b > 0
    if b > 0 {
        punycode.append(delimiter)
    }

    while h < input.count {
        // let m = the minimum code point >= n in the input
        var m: UInt32 = 0x10FFFF
        for codePoint in input {
            if codePoint >= n && codePoint < m {
                m = codePoint
            }
        }

        delta = delta + (m - n) * (h + 1)
        n = m;
        for c in input {
            if c < n { delta += 1 }
            if c == n {
                var q = delta
                for k in stride(from: base, to: UInt32.max, by: Int(base)) {
                    let t = k <= bias ? tmin
                        : k >= bias + tmax ? tmax
                        : k - bias;

                    if q < t { break }
                    punycode.append(digitValue(t + ((q - t) % (base - t))))
                    q = (q - t) / (base - t)
                }
                punycode.append(digitValue(q))
                bias = adapt(delta, h + 1, h == b)
                delta = 0
                h += 1
            }
        }
        delta += 1
        n += 1
    }
    return true;
}

extension String {
    internal func toArrayMappingNonSymbolChars(mapNonSymbolChars: Bool) -> [UInt32] {
        unicodeScalars.map { ch in
            if ch.value < 0x80 {
                if ch.isValidSymbolChar || !mapNonSymbolChars {
                    return ch.value
                } else {
                    return ch.value + 0xD800
                }
            } else {
                return ch.value
            }
        }
    }
}

extension Array where Element == UInt32 {
    internal func toStringMappingNonSymbolChars() -> String {
        String(map {
            var ch = $0
            if ch >= 0xD800 && ch < 0xD880 {
                ch -= 0xD800
            }
            return Character(UnicodeScalar(ch)!)
        })
    }
}
