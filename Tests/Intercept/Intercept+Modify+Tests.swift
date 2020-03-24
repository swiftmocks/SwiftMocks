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

// except for synthesised wintesses, test signature only, since setters are not replaceable
class Intercept_Modify_Tests: XCTestCase {
    func wontfix_testGlobal() { // globals, even with didSet {}, by default do not have _modify coroutine
        verifySignature("___150", kind: .modify)
    }

    func testGlobalWithCustomModifyCoroutine() {
        verifySignature("___151", kind: .modify)
    }

    func testVar_Class() {
        verifySignature("___155", kind: .modify)
    }

    func testStaticVar_Class() {
        verifySignature("___156", kind: .modify)
    }

    func testVar_Struct() {
        verifySignature("___160", kind: .modify)
    }

    func testStaticVar_Struct() {
        verifySignature("___160", kind: .modify)
    }
}
