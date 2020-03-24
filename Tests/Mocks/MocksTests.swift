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
import SwiftMocks
@testable import MocksFixtures

class MocksTests: XCTestCase {
    override func tearDown() {
        resetAllMocks()
    }

    func testGlobalVoidFunction() {
        stub { voidFunction() }.toReturn()
        expect(voidFunction()) == ()
    }
    
    func testGlobalSimpleFunction() {
        stub { simpleFunction(any()) }.toReturn(32)
        expect(simpleFunction(1.0)) == 32
    }

    func testInstanceOfClass() {
        let sut = SomeClass()
        stub { sut.method(string: any()) }.toReturn(123)
        expect(sut.method(string: "foo bar baz")) == 123
    }

    func testInstanceOfEquatableStruct() {
        let sut = SomeStruct()
        stub { sut.method(any(), any()) }.toReturn("blah blah")
        // ...the stub is in effect for equal instances...
        expect(sut.method(12, "foo bar")) == "blah blah"
        expect(SomeStruct().method(12, "foo bar")) == "blah blah"
        // ...while not equal instances use the stubbed value of `everyInstanceOf`
        expect(SomeStruct(varWithDidSet: ["boo"]).method(12, "foo bar")) == ""
    }

    func testClassMethodOfClass() {
        stub { SomeClass.classMethod(any(), any()) }.toReturn(56789)
        expect(SomeClass.classMethod(11.5, "foo bar baz")) == 56789
    }

    func testStaticMethodOfStruct() {
        stub { SomeStruct.staticMethod(any(), any()) }.toReturn(["foo": 101])
        expect(SomeStruct.staticMethod(11, "baz")) == ["foo": 101]
    }

    func testEveryInstanceOfStruct() {
        // TODO notation idea: stub { everyInstance(of: SomeStruct.self).method(...) }.toReturn(...)
        stub(everyInstanceOf: SomeStruct.self) { everyInstance in everyInstance.method(any(), any()) }.toReturn("foo bar baz")
        let sut1 = SomeStruct()
        let sut2 = SomeStruct()
        expect(sut1.method(23.0, "foo bar")) == "foo bar baz"
        expect(sut2.method(23.0, "bar baz")) == "foo bar baz"
    }

    func testEveryInstanceOfClass() {
        stub(everyInstanceOf: SomeClass.self) { $0.method(string: any()) }.toReturn(98765)
        let sut1 = SomeClass()
        let sut2 = SomeClass()
        expect(sut1.method(string: "foo baz")) == 98765
        expect(sut2.method(string: "baz quuz")) == 98765
    }

    func testEveryInstanceOfClassThenSpecificInstance() {
        let sut = SomeClass()
        // when stubbing every instance...
        stub(everyInstanceOf: SomeClass.self) { $0.method(string: any()) }.toReturn(123)
        // ..._and_ a specific one...
        stub { sut.method(string: any()) }.toReturn(456)
        // ...the specific one is in effect for that instance...
        expect(sut.method(string: "baz quuz")) == 456
        // ...while all other instances use the stubbed value of `everyInstanceOf`
        expect(SomeClass().method(string: "baz quuz")) == 123
    }

    func testEveryInstanceOfEquatableStructThenSpecificInstance() {
        // when stubbing every instance...
        stub(everyInstanceOf: SomeStruct.self) { $0.method(any(), any()) }.toReturn("123")
        // ..._and_ a specific one...
        let sut = SomeStruct()
        stub { sut.method(any(), any()) }.toReturn("456")
        // ...the specific one is in effect for equal instances...
        expect(SomeStruct().method(20.5, "foo bar")) == "456"
        // ...while not equal instances use the stubbed value of `everyInstanceOf`
        expect(SomeStruct(varWithDidSet: ["boo"]).method(20.5, "foo bar")) == "123"
    }

    func testStubSpecificInstanceOfClassThenSameInstance() {
        let sut = SomeClass()
        stub { sut.method(string: any()) }.toReturn(123)
        // when stubbing an instance method twice...
        stub { sut.method(string: any()) }.toReturn(456)
        // the second stub should be in effect...
        expect(sut.method(string: "baz quuz")) == 456
        // ...while all other instances just call the original implementation
        expect(SomeClass().method(string: "baz quuz")) == 0
    }

    func testStubSpecificInstanceOfEquatableStructThenEqualInstance() {
        let sut1 = SomeStruct()
        stub { sut1.method(any(), any()) }.toReturn("123")
        // when stubbing an equal instance again...
        let sut2 = SomeStruct()
        stub { sut2.method(any(), any()) }.toReturn("456")
        // the second stub should be in effect...
        let equalInstance = SomeStruct()
        expect(equalInstance.method(11.5, "foo")) == "456"
        // ...while other, not equal, instances just call the original implementation
        let notEqualInstance = SomeStruct(varWithDidSet: ["dsaf", "adsf"])
        expect(notEqualInstance.method(11.5, "foo")) == ""
    }

    func testStubEveryInstanceThenAgainEveryInstance() {
        stub(everyInstanceOf: SomeClass.self) { $0.method(string: any()) }.toReturn(123)
        // when stubbing a method for every instance twice...
        stub(everyInstanceOf: SomeClass.self) { $0.method(string: any()) }.toReturn(456)
        let sut = SomeClass()
        // ...the last stub should be in effect
        expect(sut.method(string: "baz quuz")) == 456
    }

    func testStubGlobalThenAgainGlobal() {
        stub { simpleFunction(any()) } .toReturn(10)
        // when stubbing the same function twice...
        stub { simpleFunction(any()) } .toReturn(20)
        // ...the second stub should be in effect
        expect(simpleFunction(0)) == 20
    }

    func testEveryInstanceOfClassOnAChild() {
        stub(everyInstanceOf: SomeClass.self) { $0.method(string: any()) }.toReturn(1234)
        let sut = SomeChildClass()
        expect(sut.method(string: "foo bar")) == 1234
    }

    func testClassMethodOfClassOnAChild() {
        stub { SomeClass.classMethod(any(), any()) }.toReturn(456)
        expect(SomeChildClass.classMethod(11.5, "foo")) == 456
    }

    func fixme_testEveryInstanceOfClassOnAParent() { // this is a corner case, and can only be fixed once .proceed is working
        // if we stub a method for all instances of a child class, _and_ this method is defined in the parent class, _and_ that method is then called on an instance of a parent class, we don't want to capture it
        stub(everyInstanceOf: SomeChildClass.self) { $0.method(string: any()) }.toReturn(1234)
        let sut = SomeClass()
        expect(sut.method(string: "foo bar")) == 0
    }

    func testGlobalThrow() {
        stub { try voidThrowingFunction() }.toThrow(E.someError)
        do {
            try voidThrowingFunction()
            fail("should have thrown")
        } catch {
            expect(error as? E) == .someError
        }
    }

    func testInstanceMethodOfClassThrowing() {
        let sut = SomeClass()
        stub { try sut.throwingMethod(string: any()) }.toThrow(E.someError)
        expect(try? sut.throwingMethod(string: "foo bar baz")).to(beNil()) // because of try?, nil here means that the method did throw
        // ... but other instances shall use the default impl
        expect(try SomeClass().throwingMethod(string: "baz")) == 0
    }

    func testInstanceMethodOfEquatableStructThrowing() {
        let sut = SomeStruct()
        stub { try sut.throwingMethod(any(), any()) }.toThrow(E.someError)
        expect(try sut.throwingMethod(2.5, "foo bar baz")).to(throwError())
        // ... and equal instances also use the stub
        expect(try SomeStruct().throwingMethod(-10, "zuuq")).to(throwError())
        // ... but other, not equal, instances shall use the default impl
        expect(try SomeStruct(varWithDidSet: ["foo", "bar"]).throwingMethod(2.5, "quuz")) == ""
    }

    func testClassMethodThrowing() {
        stub { try SomeClass.throwingClassMethod(any(), any()) }.toThrow(E.someError)
        expect(try? SomeClass.throwingClassMethod(2.0, "foo")).to(beNil()) // because of try?, nil here means that the method did throw
    }

    func testStaticMethodOfStructThrowing() {
        stub { try SomeStruct.throwingStaticMethod(any(), any()) }.toThrow(E.someError)
        expect(try? SomeStruct.throwingStaticMethod(2.0, "bar")).to(beNil()) // because of try?, nil here means that the method did throw
    }

    func testGlobalVar() {
        stub { someGlobalVar }.toReturn(1224)
        expect(someGlobalVar) == 1224
    }

    func testComputedVarOfClass() {
        let sut = SomeClass()
        stub { sut.computedVar }.toReturn("foo")
        expect(sut.computedVar) == "foo"
        // ... but other instances shall use the default impl
        expect(SomeClass().computedVar) == ""
    }

    func testComputedVarOfClassWithDidSet() {
        let sut = SomeClass()
        stub { sut.varWithDidSet }.toReturn(["bar"])
        expect(sut.varWithDidSet) == ["bar"]
        // ... but other instances shall use the default impl
        expect(SomeClass().varWithDidSet) == []
    }

    func testComputedVarOfEquatableStruct() {
        let sut = SomeStruct()
        stub { sut.computedVar }.toReturn("foo")
        expect(sut.computedVar) == "foo"
        // ... but other instances shall use the default impl
        expect(SomeStruct(varWithDidSet: ["quuz"]).computedVar) == ""
    }

    func fixme_testVarOfEquatableStruct() { // requires .proceed to work. the endless loop is caused by the filter comparing the instance, which triggers var accessed, which is replaced, and so forth
        let sut = SomeStruct()
        stub { sut.varWithDidSet }.toReturn(["bar"])
        expect(sut.varWithDidSet) == ["bar"]
    }

    func testInOutParams() {
        let cannedString = "foo"
        let cannedClass = SomeClass()
        let cannedStruct = SomeStruct()
        stub { functionWithInOutParameters(&InOut.any, &InOut.any, &InOut.any) }.toReturn((cannedString, cannedClass, cannedStruct))
        var param1 = ""
        var param2 = SomeClass()
        var param3 = SomeStruct()
        let result: (String, SomeClass, SomeStruct) = functionWithInOutParameters(&param1, &param2, &param3)
        expect(result.0) == cannedString
        expect(result.1) === cannedClass
        expect(result.2) == cannedStruct
    }

    func testProtocolMethodDefaultImplementation() {
        class C: ProtocolWithDefaultImplementation {}
        class AnotherC: ProtocolWithDefaultImplementation {}
        let sut = C()
        print(Unmanaged.passUnretained(sut).toOpaque())
        // when stubbing a default implementation with a non-protocol instance as self...
        stub { sut.method(any()) }.toReturn(1234)
        // ... that instance returns the stubbed value
        // expect(sut.method(987)) == 1234
        // ... and other instances of the same type invoke default implementation
        expect(C().method(987)) == 0
        // ... and instances of other types conforming to the same protocol also use the default implementation
        expect(AnotherC().method(987)) == 0
    }

    func todo_testClassMethodOfClassOverriddenByChildIsStillStubbed() {} // I think we want it. Or not.
    func todo_testMethodOfClassOverriddenByChildIsStillStubbed() {} // I think we want it. Or not.

    func testNonRequirementProtocolExtensionMethod() {
        class C: ProtocolWithDefaultImplementation {}
        class AnotherC: ProtocolWithDefaultImplementation {}
        let sut = C()
        print(Unmanaged.passUnretained(sut).toOpaque())
        // when stubbing a default implementation with a non-protocol instance as self...
        stub { sut.nonRequirementMethod(any()) }.toReturn(1234)
        // ... that instance returns the stubbed value
        expect(sut.nonRequirementMethod("foo bar")) == 1234
        // ... and other instances of the same type invoke default implementation
        expect(C().nonRequirementMethod("foo bar")) == 0
        // ... and instances of other types conforming to the same protocol also use the default implementation
        expect(AnotherC().nonRequirementMethod("foo bar")) == 0
    }

    // MARK: - Unsupported

    func testNonEquatableStruct() {
        expect(stub { NonEquatableStructWithAMethod().method() }.toReturn(123)).to(raiseException { ex in
            expect(ex.name.rawValue).to(contain("annot stub a method"))
        })
    }

    private enum E: LocalizedError, Equatable {
        case someError
    }
}
