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

class MocksTests_ExplicitDSL: XCTestCase {
    override func tearDown() {
        resetAllMocks()
    }

    func testInstanceOfClass_ExplicitNotation() {
        let sut = SomeClass()
        stub(sut) { $0.method(string: any()) }.toReturn(123)
        expect(sut.method(string: "foo bar baz")) == 123
    }

    func testInstanceOfEquatableStruct_ExplicitNotation() {
        let sut = SomeStruct()
        // when stubbing an instance of equatable struct ...
        stub(sut) { $0.method(any(), any()) }.toReturn("blah blah")
        // ...the stub is in effect for equal instances...
        expect(sut.method(12, "foo bar")) == "blah blah"
        expect(SomeStruct().method(12, "foo bar")) == "blah blah"
        // ...while not equal instances use the stubbed value of `everyInstanceOf`
        expect(SomeStruct(varWithDidSet: ["boo"]).method(12, "foo bar")) == ""
    }

    func testClassMethodOfClass_ExplicitNotation() {
        stub(SomeClass.self) { $0.classMethod(any(), any()) }.toReturn(56789)
        expect(SomeClass.classMethod(11.5, "foo bar baz")) == 56789
    }

    func testStaticMethodOfStruct_ExplicitNotation() {
        stub(SomeStruct.self) { $0.staticMethod(any(), any()) }.toReturn(["foo": 101])
        expect(SomeStruct.staticMethod(11, "baz")) == ["foo": 101]
    }

    func testEveryInstanceOfClassThenSpecificInstance_ExplicitNotation() {
        let sut = SomeClass()
        // when stubbing every instance...
        stub(everyInstanceOf: SomeClass.self) { $0.method(string: any()) }.toReturn(123)
        // ..._and_ a specific one...
        stub(sut) { $0.method(string: any()) }.toReturn(456)
        // ...the specific one is in effect for that instance...
        expect(sut.method(string: "baz quuz")) == 456
        // ...while all other instances use the stubbed value of `everyInstanceOf`
        expect(SomeClass().method(string: "baz quuz")) == 123
    }

    func testEveryInstanceOfEquatableStructThenSpecificInstance_ExplicitNotation() {
        // when stubbing every instance...
        stub(everyInstanceOf: SomeStruct.self) { $0.method(any(), any()) }.toReturn("123")
        // ..._and_ a specific one...
        let sut = SomeStruct()
        stub(sut) { $0.method(any(), any()) }.toReturn("456")
        // ...the specific one is in effect for equal instances...
        expect(SomeStruct().method(20.5, "foo bar")) == "456"
        // ...while not equal instances use the stubbed value of `everyInstanceOf`
        expect(SomeStruct(varWithDidSet: ["boo"]).method(20.5, "foo bar")) == "123"
    }

    func testStubSpecificInstanceOfClassThenSameInstance_ExplicitNotation() {
        let sut = SomeClass()
        stub(sut) { $0.method(string: any()) }.toReturn(123)
        // when stubbing an instance method twice...
        stub(sut) { $0.method(string: any()) }.toReturn(456)
        // the second stub should be in effect...
        expect(sut.method(string: "baz quuz")) == 456
        // ...while all other instances just call the original implementation
        expect(SomeClass().method(string: "baz quuz")) == 0
    }

    func testStubSpecificInstanceOfEquatableStructThenEqualInstance_ExplicitNotation() {
        let sut1 = SomeStruct()
        stub(sut1) { $0.method(any(), any()) }.toReturn("123")
        // when stubbing an equal instance again...
        let sut2 = SomeStruct()
        stub(sut2) { $0.method(any(), any()) }.toReturn("456")
        // the second stub should be in effect...
        let equalInstance = SomeStruct()
        expect(equalInstance.method(11.5, "foo")) == "456"
        // ...while other, not equal, instances just call the original implementation
        let notEqualInstance = SomeStruct(varWithDidSet: ["dsaf", "adsf"])
        expect(notEqualInstance.method(11.5, "foo")) == ""
    }

    func testClassMethodOnAChild() {
        // when a method on a parent class is stubbed...
        stub(SomeClass.self) { $0.classMethod(any(), any()) }.toReturn(10)
        // ...calling it on a child instance (provided that it's not overridden) will return the stubbed value
        expect(SomeChildClass.classMethod(2.5, "foo")) == 10
    }

    func testInstanceMethodOfClassThrowing_ExplicitNotation() {
        let sut = SomeClass()
        stub(sut) { try $0.throwingMethod(string: any()) }.toThrow(E.someError)
        expect(try? sut.throwingMethod(string: "foo bar baz")).to(beNil()) // because of try?, nil here means that the method did throw
        // ... but other instances shall use the default impl
        expect(try SomeClass().throwingMethod(string: "baz")) == 0
    }

    func testInstanceMethodOfEquatableStructThrowing_ExplicitNotation() {
        let sut = SomeStruct()
        stub(sut) { try $0.throwingMethod(any(), any()) }.toThrow(E.someError)
        expect(try sut.throwingMethod(2.5, "foo bar baz")).to(throwError())
        // ... and equal instances also use the stub
        expect(try SomeStruct().throwingMethod(-10, "zuuq")).to(throwError())
        // ... but other, not equal, instances shall use the default impl
        expect(try SomeStruct(varWithDidSet: ["foo", "bar"]).throwingMethod(2.5, "quuz")) == ""
    }

    func testClassMethodThrowing_ExplicitNotation() {
        stub(SomeClass.self) { try $0.throwingClassMethod(any(), any()) }.toThrow(E.someError)
        expect(try? SomeClass.throwingClassMethod(2.0, "foo")).to(beNil()) // because of try?, nil here means that the method did throw
    }

    func testStaticMethodOfStructThrowing_ExplicitNotattion() {
        stub(SomeStruct.self) { try $0.throwingStaticMethod(any(), any()) }.toThrow(E.someError)
        expect(try? SomeStruct.throwingStaticMethod(2.0, "bar")).to(beNil()) // because of try?, nil here means that the method did throw
    }

    func testComputedVarOfClass_ExplicitNotation() {
        let sut = SomeClass()
        stub(sut) { $0.computedVar }.toReturn("foo")
        expect(sut.computedVar) == "foo"
        // ... but other instances shall use the default impl
        expect(SomeClass().computedVar) == ""
    }

    func testComputedVarOfClassWithDidSet_ExplicitNotation() {
        let sut = SomeClass()
        stub(sut) { $0.varWithDidSet }.toReturn(["bar"])
        expect(sut.varWithDidSet) == ["bar"]
        // ... but other instances shall use the default impl
        expect(SomeClass().varWithDidSet) == []
    }

    func testComputedVarOfEquatableStruct_ExplicitNotation() {
        let sut = SomeStruct()
        stub(sut) { $0.computedVar }.toReturn("foo")
        expect(sut.computedVar) == "foo"
        // ... but other instances shall use the default impl
        expect(SomeStruct(varWithDidSet: ["boo"]).computedVar) == ""
    }

    func fixme_testVarOfEquatableStruct_ExplicitNotation() { // requires .proceed to work. the endless loop is caused by the filter comparing the instance, which triggers var accessed, which is replaced, and so forth
        let sut = SomeStruct()
        stub(sut) { $0.varWithDidSet }.toReturn(["bar"])
        expect(sut.varWithDidSet) == ["bar"]
    }

    private enum E: LocalizedError, Equatable {
        case someError
    }
}
