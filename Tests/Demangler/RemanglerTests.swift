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

class RemanglerTests: XCTestCase {
    func testAssortedManglings() {
        for m in assortedManglings.map({ $0.normalised }) {
            let demangled = try! Mangle.demangleSymbol(mangledName: m)
            let mangled = Mangle.mangleNode(node: demangled)
            if m != mangled {
                print(m, mangled)
                print(demangled)
            }
            expect(mangled) == m
        }
    }

    func `test_s7TestMod5OuterV3Fooayx_SiGD`() {
        let input = "$s7TestMod5OuterV3Fooayx_SiGD"
        let demangled = try! Mangle.demangleSymbol(mangledName: input)
        let remangled = Mangle.mangleNode(node: demangled)
        expect(remangled) == input
    }

    func `test_s3red4testyAA3ResOyxSayq_GAEs5ErrorAAq_sAFHD1__HCg_GADyxq_GsAFR_r0_lF`() {
        let input = "$s3red4testyAA3ResOyxSayq_GAEs5ErrorAAq_sAFHD1__HCg_GADyxq_GsAFR_r0_lF"
        let demangled = try! Mangle.demangleSymbol(mangledName: input)
        let remangled = Mangle.mangleNode(node: demangled)
        expect(remangled) == input
    }

    func `test_s3red4testyAA7OurTypeOy4them05TheirD0Vy5AssocQzGAjE0F8ProtocolAAxAA0c7DerivedH0HD1_AA0c4BaseH0HI1_AieKHA2__HCg_GxmAaLRzlF`() {
        let input = "$s3red4testyAA7OurTypeOy4them05TheirD0Vy5AssocQzGAjE0F8ProtocolAAxAA0c7DerivedH0HD1_AA0c4BaseH0HI1_AieKHA2__HCg_GxmAaLRzlF"
        let demangled = try! Mangle.demangleSymbol(mangledName: input)
        let remangled = Mangle.mangleNode(node: demangled)
        expect(remangled) == input
    }

    func `test_ss23LazyPrefixWhileSequenceVsSlRzrlEy7ElementQzABsSlRzrlE5IndexVyx_Gcig`() {
        let input = "$ss23LazyPrefixWhileSequenceVsSlRzrlEy7ElementQzABsSlRzrlE5IndexVyx_Gcig"
        let demangled = try! Mangle.demangleSymbol(mangledName: input)
        let remangled = Mangle.mangleNode(node: demangled)
        expect(remangled) == input
    }
}

extension String {
    var normalised: String {
        var result = self
        if result.hasPrefix("_") {
            result = String(result.suffix(result.count - 1))
        }
        if result.hasPrefix("$S") {
            result = "$s" + result.suffix(result.count - 2)
        }
        return result
    }
}
