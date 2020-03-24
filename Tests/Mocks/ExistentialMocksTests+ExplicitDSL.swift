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
@testable import MocksFixtures

class ExistentialMocksTests_ExplicitDSL: XCTestCase {
    override func tearDown() {
        resetAllMocks()
    }

    func testOneMethod() {
        let mocked = mock(of: ProtocolWithAMethod.self)
        stub(mocked) { $0.method() }.toReturn(123)
        expect(mocked.method()) == 123
    }

    func testMethod() {
        let mocked = mock(of: RealisticallyLookingProtocol.self)
        stub(mocked) { $0.method(param: any()) }.toReturn(["Foo": [2, 3]])
        expect(mocked.method(param: 12.5)) == ["Foo": [2, 3]]
    }

    func testStaticMethod() {
        let mocked = mock(of: RealisticallyLookingProtocol.self)
        stub(mocked) { type(of: $0).staticMethod(any()) }.toReturn(["foo"])
        expect(type(of: mocked).staticMethod(1)) == ["foo"]
    }

    func testVarGetter() {
        let mocked = mock(of: RealisticallyLookingProtocol.self)
        stub(mocked) { $0.someVar }.toReturn("foo bar")
        expect(mocked.someVar) == "foo bar"
    }

    func testBaseProtocolMethod() {
        let mocked = mock(of: RealisticallyLookingProtocolWithABaseProtocol.self)
        stub(mocked) { $0.method(param: any()) }.toReturn("©")
        expect(mocked.method(param: 1.25)) == "©"
    }

    func testBaseProtocolMethodOverride() {
        let mocked = mock(of: RealisticallyLookingProtocolWithABaseProtocol.self)
        let cannedReturn = EmptyClass()
        stub(mocked) { $0.methodToOverride(any()) }.toReturn(cannedReturn)
        expect(mocked.methodToOverride(22)) === cannedReturn
    }

    func testBaseProtocolVar() {
        let mocked = mock(of: RealisticallyLookingProtocolWithABaseProtocol.self)
        stub(mocked) { $0.someVar }.toReturn("foo bar baz")
        expect(mocked.someVar) == "foo bar baz"
    }

    func testBaseProtocolVarOverride() {
        let mocked = mock(of: RealisticallyLookingProtocolWithABaseProtocol.self)
        stub(mocked) { $0.someVarToOverride }.toReturn(20.25)
        expect(mocked.someVarToOverride) == 20.25
    }

    func testBaseProtocolStaticMethod() {
        let mocked = mock(of: RealisticallyLookingProtocolWithABaseProtocol.self)
        stub(mocked) { type(of: $0).staticMethod(any()) }.toReturn(["foo bar baz"])
        expect(type(of: mocked).staticMethod(12)) == ["foo bar baz"]
    }

    func testBaseProtocolStaticMethodOverride() {
        let mocked = mock(of: RealisticallyLookingProtocolWithABaseProtocol.self)
        var arg = EmptyClass()
        stub(mocked) { type(of: $0).staticMethodToOverride(&InOut.any) }.toReturn(12345)
        expect(type(of: mocked).staticMethodToOverride(&arg)) == 12345
    }

    func testTwoBaseProtocols() {
        let mocked = mock(of: ProtocolWithTwoBaseProtocols.self)
        stub(mocked) { $0.method() }.toReturn(123)
        stub(mocked) { $0.method(param: any()) }.toReturn("®")
        stub(mocked) { $0.method(any()) }.toReturn(["foo", "bar"])
        expect(mocked.method()) == 123
        expect(mocked.method(param: 2.0)) == "®"
        expect(mocked.method("foo")) == ["foo", "bar"]
    }

    func testDefaultMethodImplementation() {
        let mocked = mock(of: ProtocolWithDefaultImplementation.self)
        stub(mocked) { $0.method(any()) }.toReturn(12.5)
        expect(mocked.method(12)) == 12.5
    }

    func fixme_testNonRequirementDefaultMethodImplementation() {
        let mocked = mock(of: ProtocolWithDefaultImplementation.self)
        stub(mocked) { $0.nonRequirementMethod(any()) }.toReturn(123)
        expect(mocked.nonRequirementMethod("foo")) == 123
    }

    func testNonRequirementComputedVar() {
        let mocked = mock(of: ProtocolWithDefaultImplementation.self)
        stub(mocked) { $0.nonRequirementVar }.toReturn(456)
        expect(mocked.nonRequirementVar) == 456
    }
}
