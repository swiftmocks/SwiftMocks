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
@testable import IR
@testable import SwiftMocks

class SIL_CustomStringConvertible: XCTestCase {
    func testParamStringConvertible() {
        let type = TypeFactory.from(anyType: AnotherEmptyClass.self)
        expect(SILParameterInfo(type: type, convention: .directGuaranteed).description) == "@guaranteed AnotherEmptyClass"
        expect(SILParameterInfo(type: type, convention: .indirectIn).description) == "@in AnotherEmptyClass"
        expect(SILParameterInfo(type: type, convention: .directUnowned).description) == "AnotherEmptyClass"
    }

    func testResultStringConvertible() {
        let type = TypeFactory.from(anyType: AnotherEmptyClass.self)
        expect(SILResultInfo(type: type, convention: .owned).description) == "@owned AnotherEmptyClass"
        expect(SILResultInfo(type: type, convention: .unowned).description) == "AnotherEmptyClass"
    }

    func testVoidResultStringConvertible() {
        let type = TypeFactory.void
        expect(SILResultInfo(type: type, convention: .unowned).description) == "()"
    }
}
