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

import XCTest
import Nimble
@testable import SwiftMocks

class PunyCodeTests: XCTestCase {
    func testToArrayMappingNonSymbolChars_NonSymbolChars_True() {
        let input = "a+!"
        let converted = input.toArrayMappingNonSymbolChars(mapNonSymbolChars: true)
        let expected = [UInt32](arrayLiteral: 97, 0xD800 + 43, 0xD800 + 33)
        expect(converted) == expected
        print(converted)
    }

    func testToArrayMappingNonSymbolChars_NonSymbolChars_False() {
        let input = "a+!"
        let converted = input.toArrayMappingNonSymbolChars(mapNonSymbolChars: false)
        let expected = [UInt32](arrayLiteral: 97, 43, 33)
        expect(converted) == expected
        print(converted)
    }

    func testEncode() {
        let input = "Привіт! 这样啊！那吃鱼吧。鱼可是你伯母的拿手菜 😄 الى اللقاء"
        let expected = "rAaCbrFamDjrDlmbaaABawabaGetHAGgrAsegzarHEdnlagzGDrCmBgosdBGzeomosxosCeqEGdgfvdIdfcxEicaHBCADcsaadnGECJJabDIEe"
        let encoded = encodePunyCodeUTF8(input, mapNonSymbolChars: true)
        expect(encoded) == expected
        let decoded = decodeSwiftPunycode(encoded ?? "")
        expect(decoded) == input
    }
}
