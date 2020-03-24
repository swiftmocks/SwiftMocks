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

class Intercept_Witnesses_Tests: XCTestCase {
    override func setUp() {
        continueAfterFailure = true
    }

    func testSimple() {
        verifySignature("___3000", isWitness: true)

        let p: ___P3000 = ___C3000()
        let args = testableInterceptVoid {
            p.___3000()
        }
        expect(args[0]).to(beAKindOf(___P3000.self))
    }

    func testClassConstrained() {
        verifySignature("___3001", isWitness: true)
    }

    func testClassConstrainedViaSuper() {
        verifySignature("___3002", isWitness: true)
    }

    func testClassConstrainedViaSuperClass() {
        verifySignature("___3003", isWitness: true)
    }

    func testStaticMethod_Class() {
        verifySignature("___3010", isWitness: true)
    }

    func testStaticMethod_Struct() {
        verifySignature("___3011", isWitness: true)
    }

    func testStaticMethodEnum() {
        verifySignature("___3012", isWitness: true)
    }

    func testGetter() {
        verifySignature("___3013", isWitness: true, kind: .getter)
    }

    func testStaticGetter() {
        verifySignature("___3014", isWitness: true, kind: .getter)
    }

    func testBaseProtocolMethod() {
        verifySignature("___3015", isWitness: true)
    }

    func testBaseProtocolVar() {
        verifySignature("___3016", isWitness: true, kind: .getter)
    }

    func testBaseProtocolStaticVar() {
        verifySignature("___3017", isWitness: true, kind: .getter)
    }

    func testVarModify() {
        verifySignature("___3019", isWitness: true, kind: .modify)
    }

    // MARK: - Default implementations

    func testProtocolMethodDefaultImplementation() {
        verifySignature("___3100", isWitness: true)
    }

    func testNonRequirementExtensionMethod() {
        verifySignature("___3101", isWitness: false) // non-requirement extension methods are not witnesses
    }

    func todo_testNonRequirementExtensionMethod_Fulfillment() { // tests fulfillment of metadata for the second parameter. atm not supported anyway, because it contains a generic parameter in the function signature
        verifySignature("___3102", isWitness: false) // non-requirement extension methods are not witnesses
    }
}
