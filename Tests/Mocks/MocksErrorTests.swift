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
import NimbleObjC
@testable import MocksFixtures
@testable import SwiftMocks

/// We use Obj-C exceptions to gracefully abort the current test, which incidentally makes it possible to test those graceful aborts
class MocksErrorTests: XCTestCase {
    override func setUp() {
        // for some of these tests, it's important to make sure the Core is alive and is intercepting, even before its methods are called (i.e. before "stub {...}")
        _ = theCore
    }

    override func tearDown() {
        resetAllMocks()
    }

    func testUndetectedFunctionInvocation() {
        func foo() {}

        expect(stub { foo() }).to(raiseException { ex in
            expect(ex.name.rawValue).to(contain("ould not detect function invocation"))
        })
    }

    func testSimplyCallingFunctionWithUnsupportedReturnTypeDoesNotThrowObjcException() {
        expect(functionWithUnsupportedReturnType()).toNot(raiseException())
    }

    func testStubbingFunctionWithUnsupportedReturnType() {
        expect(stub { functionWithUnsupportedReturnType() }).to(raiseException { ex in
            expect(ex.reason).to(contain("ot implemented"))
            expect(ex.reason).to(contain("IEEE80"))
        })
    }

    func testUnsupportedFunction() {
        expect(stub { EmptyStruct() }).to(raiseException { ex in
            expect(ex.reason).to(contain("nsupported function type"))
        })
    }

    func testNoExistingConformances() {
        expect(mock(of: ProtocolWithoutConformances.self)).to(raiseException { ex in
            expect(ex.reason).to(contain("o existing conformances for \(ProtocolWithoutConformances.self) found"))
        })
    }

    func testNoDecodableConformances() {
        class SecretClass: ProtocolWithoutDecodableConformances {
            var bar: Int = 0
        }
        expect(mock(of: ProtocolWithoutDecodableConformances.self)).to(raiseException { ex in
            expect(ex.reason).to(contain("o decodable conformances for \(ProtocolWithoutDecodableConformances.self) found"))
        })
    }

    func testUnsupportedProtocolWithAssociatedTypes() {
        expect(mock(of: UnsupportedProtocolWithBaseClass.self)).to(raiseException { ex in
            expect(ex.reason).to(contain("ocking of \(UnsupportedProtocolWithBaseClass.self) is not supported"))
        })
    }
}

private protocol ProtocolWithoutConformances {
    var foo: Int { get }
}

private protocol ProtocolWithoutDecodableConformances {
    var bar: Int { get }
}

private class BaseClassForUnsupportedProtocolWithBaseClass {}
private protocol UnsupportedProtocolWithBaseClass: BaseClassForUnsupportedProtocolWithBaseClass {}
