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

class NodePrinterTests: XCTestCase {
    func testManglings() {
        for mangled in assortedManglings {
            let demangled = try? Mangle.demangleSymbol(mangledName: mangled).description
            expect(demangled) == Runtime.demangle(mangled)
        }
    }

    func `test_$sSo8PHChangeC6PhotosE13changeDetails3forSo014PHObjectChangeD0CyxGSgx_tSo0F0CRbzlF`() {
        let mangled = "$sSo8PHChangeC6PhotosE13changeDetails3forSo014PHObjectChangeD0CyxGSgx_tSo0F0CRbzlF"
        let demangled = try? Mangle.demangleSymbol(mangledName: mangled).description
        expect(demangled) == Runtime.demangle(mangled)
    }

    func `test_$sBf128_N`() {
        let mangled = "$sBf128_N"
        let demangled = try? Mangle.demangleSymbol(mangledName: mangled).description
        expect(demangled) == Runtime.demangle(mangled)
    }

    func `test_$sSNsSxRzSZ6StrideRpzrlE10startIndexSNsSxRzSZABRQrlE0C0Oyx_Gvg`() {
        let mangled = "$sSNsSxRzSZ6StrideRpzrlE10startIndexSNsSxRzSZABRQrlE0C0Oyx_Gvg"
        let demangled = try? Mangle.demangleSymbol(mangledName: mangled).description
        expect(demangled) == Runtime.demangle(mangled)
    }

    func `test_$sSC11CKErrorCodeLeV8CloudKitE12clientRecordSo8CKRecordCSgvg`() {
        let mangled = "_$sSC11CKErrorCodeLeV8CloudKitE12clientRecordSo8CKRecordCSgvg"
        let demangled = try? Mangle.demangleSymbol(mangledName: mangled).description
        expect(demangled) == Runtime.demangle(mangled)
    }

    func `test_$s4test3fooV4blahyAA1SV1fQryFQOy_Qo_AHF`() {
        let mangled = "$s4test3fooV4blahyAA1SV1fQryFQOy_Qo_AHF"
        let demangled = try? Mangle.demangleSymbol(mangledName: mangled).description
        expect(demangled) == Runtime.demangle(mangled)
    }
}
