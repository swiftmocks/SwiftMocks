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
@testable import MocksFixtures
@testable import IR
@testable import SwiftMocks

class Intercept_Globals_Tests: XCTestCase {
    let deadBeef = RawPointer(bitPattern: 0xdeadbeef)!
    let abba = RawPointer(bitPattern: 0xabbaabba)!
    let dude = RawPointer(bitPattern: 0xd00dd00d)!
    let intDude = RawPointer(bitPattern: 0xd00dd00d)!.reinterpret(Int.self)

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    // MARK: - General tests

    func testSimplestFunction() {
        verifySignature("___1")

        let argsAndResult = testableIntercept(returning: ()) {
            ___1()
        }
        expect(argsAndResult.arguments).to(beEmpty())
        expect(argsAndResult.result).to(beAKindOf(Void.self))
    }

    func testNoArgReturnInt() {
        verifySignature("___2")

        let (args, result) = testableIntercept(returning: 0xcafebabe) {
            ___2()
        }
        expect(args).to(beEmpty())
        expect(result) == 0xcafebabe
    }

    func testIntArgIntReturn() {
        verifySignature("___3")
        let (args, result) = testableIntercept(returning: 20) {
            ___3(10)
        }
        expect(args[0] as? Int) == 10
        expect(result) == 20
    }

    func testIntRawPointerArgsIntReturn() {
        verifySignature("___4")
        let (args, result) = testableIntercept(returning: 0xabba) {
            ___4(42, deadBeef)
        }
        expect(args[0]) ~= 42
        expect(args[1]) ~= deadBeef
        expect(result) == 0xabba
    }

    func testBuiltinsArgsNoFloats() {
        verifySignature("___5")
        let args = testableInterceptVoid {
            ___5(reg: 101, reg: 201, reg: 301, reg: 401, reg: deadBeef, reg: abba, stack: 0xF, stack: 0xE, stack: 0xD, stack: 0xC, stack: intDude)
        }
        expect(args[0]) ~= Int8(101)
        expect(args[1]) ~= Int16(201)
        expect(args[2]) ~= Int32(301)
        expect(args[3]) ~= Int64(401)
        expect(args[4]) ~= deadBeef
        expect(args[5]) ~= UnsafeRawPointer(abba)
        expect(args[6]) ~= Int8(0xF)
        expect(args[7]) ~= Int16(0xE)
        expect(args[8]) ~= Int32(0xD)
        expect(args[9]) ~= Int64(0xC)
        expect(args[10]) ~= intDude
    }

    func testBuiltinsArgs() {
        verifySignature("___6")
        let args = testableInterceptVoid {
            ___6(xmm: 10.5, xmm: 11.5, xmm: 12.25, xmm: 13.25, xmm: 14.5, reg: 15, xmm: 16.5, xmm: 17.5, xmm: 18.5, stack: 19.5, stack: 20.5, reg: 21)
        }
        expect(args[0]) ~= Float(10.5)
        expect(args[1]) ~= Float(11.5)
        expect(args[2]) ~= Double(12.25)
        expect(args[3]) ~= Double(13.25)
        expect(args[4]) ~= Float(14.5)
        expect(args[5]) ~= Int8(15)
        expect(args[6]) ~= Double(16.5)
        expect(args[7]) ~= Float(17.5)
        expect(args[8]) ~= Double(18.5)
        expect(args[9]) ~= Float(19.5)
        expect(args[10]) ~= Double(20.5)
        expect(args[11]) ~= Int16(21)
    }

    func wontfix_testSimpleStruct_InitialiserGetsIntercepted() {
        verifySignature("___7")

        let (args, result) = testableIntercept(returning: ___S7(a: 0xacceeded)) {
            ___7(___S7(a: 0xdeadbeef))
        }
        expect(args[0]) ~= ___S7(a: 0xacceeded)
        expect(result) == ___S7(a: 0xdeadbeef)
    }

    func testSimpleStruct() {
        verifySignature("___7")

        let injectedResult: ___S7 = ___S7(a: 0xacceeded)
        let actualArg: ___S7 = ___S7(a: 0xdeadbeef)
        let (args, result) = testableIntercept(returning: injectedResult) {
            ___7(actualArg)
        }
        expect(args[0]) ~= actualArg
        expect(result) == injectedResult
    }

    func testBigStruct() {
        verifySignature("___8")

        let injectedResult = ___S8(a: 10, b: "20", c: [1: [0.5]], d: nil, e: nil, f: (30, 40, "50"), g: Set(), h: 50)
        let actualArg = ___S8(a: 20, b: "30", c: [20.0: []], d: 40, e: "50", f: (60, 70, "80"), g: [nil], h: 60)
        let (args, result) = testableIntercept(returning: injectedResult) {
            ___8(actualArg)
        }
        expect(args[0]) ~= actualArg
        expect(result) == injectedResult
    }

    func testClass() {
        verifySignature("___9")

        let injectedResult = ___C9(foo: 10.25)
        let actualArg = ___C9(foo: 20.75)
        let (args, result) = testableIntercept(returning: injectedResult) {
            ___9(actualArg)
        }
        expect(args[0]) === actualArg
        expect(result) === injectedResult
    }

    func testClass_NoRetainProblems() {
        verifySignature("___9")

        weak var weakInjectedResult: ___C9?
        weak var weakActualArg: ___C9?

        func test() {
            let injectedResult = ___C9(foo: 10.25)
            let actualArg = ___C9(foo: 20.75)

            weakInjectedResult = injectedResult
            weakActualArg = actualArg

            let (_, _) = testableIntercept(returning: injectedResult) {
                ___9(actualArg)
            }

            _ = String(describing: injectedResult)
            _ = String(describing: actualArg)
        }

        test()

        expect(weakInjectedResult).to(beNil())
        expect(weakActualArg).to(beNil())
    }

    func testEnum() {
        verifySignature("___10")

        let injectedResult = ___E10.a
        let actualArg = ___E10.b
        let (args, result) = testableIntercept(returning: injectedResult) {
            ___10(actualArg)
        }
        expect(args[0]) ~= actualArg
        expect(result) == injectedResult
    }

    func testTupleAsSingleParameterAndReturn() {
        verifySignature("___12")

        let injectedResult: (Double, Float) = (20.25, 30.15)
        let actualArg: (Int16, Double) = (10, 15.75)
        let (args, result) = testableIntercept(returning: injectedResult) {
            ___12(actualArg)
        }
        expect((args[0] as! (Int16, Double)).0) == actualArg.0
        expect((args[0] as! (Int16, Double)).1) == actualArg.1
        expect(result.0) == injectedResult.0
        expect(result.1) == injectedResult.1
    }

    func testEmptyTupleAsParam() {
        verifySignature("___13")
        let args = testableInterceptVoid {
            ___13((()))
        }
        expect(args[0]).to(beAKindOf((Void).self))
    }

    func testMultipleAndNestedTupleParameters() {
        verifySignature("___14")
        typealias Param1Type = (UnicodeScalar, Void, (Void), (Void, Void), (Double, Int16, Void, (Float, Float)))
        typealias Param2Type = (CChar, Int)
        let actualArg1: Param1Type = ("a", (), (()), ((), ()), (20.0, 11, (), (11.5, 12.5)))
        let actualArg2: Param2Type = (110, 12345)
        let injectedResult: (Float, Double, Void) = (11.5, 1234.5, ())
        let (args, result) = testableIntercept(returning: injectedResult) {
            ___14(actualArg1, actualArg2)
        }
        let actualParam1 = args[0] as! Param1Type
        expect(actualParam1.0) == actualArg1.0
        expect(actualParam1.1) == actualArg1.1
        expect(actualParam1.2) == actualArg1.2
        expect(actualParam1.3.0) == actualArg1.3.0
        expect(actualParam1.3.1) == actualArg1.3.1
        expect(actualParam1.4.0) == actualArg1.4.0
        expect(actualParam1.4.1) == actualArg1.4.1
        expect(actualParam1.4.2) == actualArg1.4.2
        expect(actualParam1.4.3.0) == actualArg1.4.3.0
        expect(actualParam1.4.3.1) == actualArg1.4.3.1

        expect(result.0) == injectedResult.0
        expect(result.1) == injectedResult.1
        expect(result.2) == injectedResult.2
    }

    func testTupleReturn() {
        verifySignature("___15")
        let injectedResult: (a: Int, b: (Double, Float)) = (51, (52.75, 12))
        let (_, result) = testableIntercept(returning: injectedResult) {
            ___15()
        }
        expect(result.a) == injectedResult.a
        expect(result.b.0) == injectedResult.b.0
        expect(result.b.1) == injectedResult.b.1
    }

    func testRecursiveClass() {
        verifySignature("___16")

        let injectedResult = ___C16()
        let actualArg = ___C16()
        let (args, result) = testableIntercept(returning: injectedResult) {
            ___16(actualArg)
        }
        expect(args[0]) === actualArg
        expect(result) === injectedResult
    }

    func testRecursiveStruct() {
        verifySignature("___17")

        let injectedResult = ___S17(c: .a(nil))
        let actualArg = ___S17(c: .a(___S17(c: .a(nil))))
        let (args, result) = testableIntercept(returning: injectedResult) {
            ___17(actualArg)
        }
        expect(args[0]) ~= actualArg
        expect(result) == injectedResult
    }

    func fixme_testEscapingFuncAsParamAndReturn() { // this doesn't seem to work at all, because of shit and sticks with metadata
        verifySignature("___18")

        typealias Fn = ((Double) throws -> ((Int, Float), String))
        let injectedResult: Fn = { _ in ((10, 20.5), "foo") }
        let actualArg: Fn = { _ in ((20, 30.25), "bar") }
        let (args, result) = testableIntercept(returning: injectedResult) {
            ___18(actualArg)
        }

        // cannot compare directly, because they are covered in thick layer of reabstraction thunks and partial forwarders.
        // so comparing by their return values

        let actualArgResult = try! (args[0] as! Fn)(0)
        expect(actualArgResult.0.0) == 20
        expect(actualArgResult.0.1) == 30.25
        expect(actualArgResult.1) == "bar"

        let injectedResultResult = try! result(0)
        expect(injectedResultResult.0.0) == 10
        expect(injectedResultResult.0.1) == 20.25
        expect(injectedResultResult.1) == "foo"
    }

    func testNonEscapingFunc() { // TODO
        verifySignature("___19")
    }

    func testAutoclosure() { // TODO
        verifySignature("___20")
    }

    func testAny() {
        verifySignature("___21")

        let (args, result) = testableIntercept(returning: "foo") {
            ___21(7)
        }
        expect(args[0]) ~= 7
        expect(result) ~= "foo"
    }

    func testAnyObject() {
        verifySignature("___22")

        let injectedResult = EmptyClass()
        let actualArg = RealisticallyLoookingClass()
        let (args, result) = testableIntercept(returning: injectedResult) {
            ___22(actualArg)
        }
        expect(args[0]) === actualArg
        expect(result) === injectedResult
    }

    func testProtocol() {
        verifySignature("___23")

        class C1: ___P23 {}
        class C2: ___P23 {}
        let injectedResult = C1()
        let actualArg = C2()
        let (args, result) = testableIntercept(returning: injectedResult) {
            ___23(actualArg)
        }
        expect(args[0]) === actualArg
        expect(result) === injectedResult
    }

    func testProtocolComposition() {
        verifySignature("___24")

        class C1: ___P24_1 & ___P24_2 {}
        class C2: ___P24_1 & ___P24_2 {}
        let injectedResult = C1()
        let actualArg = C2()
        let (args, result) = testableIntercept(returning: injectedResult) {
            ___24(actualArg)
        }
        expect(args[0]) === actualArg
        expect(result) === injectedResult
    }

    func testAnyObjectProtocol() {
        verifySignature("___25")

        class C1: ___P25 {}
        class C2: ___P25 {}
        let injectedResult = C1()
        let actualArg = C2()
        let (args, result) = testableIntercept(returning: injectedResult) {
            ___25(actualArg)
        }
        expect(args[0]) === actualArg
        expect(result) === injectedResult
}

    func testInheritedAnyObjectProtocol() {
        verifySignature("___26")

        class C1: ___P26 {}
        class C2: ___P26 {}
        let injectedResult = C1()
        let actualArg = C2()
        let (args, result) = testableIntercept(returning: injectedResult) {
            ___26(actualArg)
        }
        expect(args[0]) === actualArg
        expect(result) === injectedResult
    }

    func testMetatypes() {
        // verifySignature("___27") // FIXME

        class C27FirstChild: ___C27 {}
        class C27SecondChild: ___C27 {}

        typealias Ty = (___C27.Type, ___S27.Type, ___E27.Type, ___P27.Protocol, (___P27_Another & ___P27).Protocol)
        let injectedResult: Ty = (C27FirstChild.self, ___S27.self, ___E27.self, ___P27.self, (___P27 & ___P27_Another).self)
        let (args, result) = testableIntercept(returning: injectedResult) { () -> (___C27.Type, ___S27.Type, ___E27.Type, ___P27.Protocol, (___P27_Another & ___P27).Protocol) in
            ___27(class: C27SecondChild.self, struct: ___S27.self, enum: ___E27.self, protocol: ___P27.self, protocolComp: (___P27 & ___P27_Another).self)
        }
        expect(result.0) == C27FirstChild.self
        expect(result.1) == ___S27.self
        expect(result.2) == ___E27.self
        expect(result.3) == ___P27.self
        expect(result.4) == (___P27 & ___P27_Another).self

        expect(args[0] as! ___C27.Type).to(beAKindOf(C27SecondChild.Type.self))
        // expect(args[1] as! ___S27.Type).to(beAKindOf(___S27.Type.self))
        // expect(args[2] as! ___E27.Type).to(beAKindOf(___E27.Type.self))
        // expect(args[3] as! ___P27.Protocol).to(beAKindOf(___P27.Protocol.self))
        // expect(args[4] as! (___P27 & ___P27_Another).Type).to(beAKindOf((___P27 & ___P27_Another).Protocol.self))
    }

    func testMetatypesOfGenericTypes() {
        verifySignature("___28")
    }

    func testDefaultArguments() {
        verifySignature("___29")

        func testNoDefaultsProvided() {
            let (args, _) = testableIntercept(returning: ()) {
                ___29(b: 2)
            }
            expect(args[0]) ~= 10
            expect(args[1]) ~= Float(2.0)
            expect(args[2]) ~= 11.0
        }

        func testSomeDefaultsProvided() {
            let (args, _) = testableIntercept(returning: ()) {
                ___29(a: 123, b: 2)
            }
            expect(args[0]) ~= 123
            expect(args[1]) ~= Float(2.0)
            expect(args[2]) ~= 11.0
        }

        testNoDefaultsProvided()
        testSomeDefaultsProvided()
    }

    func testThrows() {
        verifySignature("___30")

        enum E: Error, LocalizedError, Equatable {
            case someError
        }

        do {
            try testableIntercept(throwing: E.someError) {
                try ___30()
            }
            fail("expected to throw")
        } catch {
            // success
            expect(error).to(beAKindOf(E.self))
        }
    }

    func testReturnsErrorExistential() {
        verifySignature("___31")

        enum E: Error, Equatable {
            case a //(Int)
            case b
        }
        let injectedResult = E.a //(0xbeef)
        let actualArg = E.b
        let (args, result) = testableIntercept(returning: injectedResult) {
            ___31(actualArg)
        }
        expect(args[0]) ~= E.b
        expect(result) ~= E.a //(0xbeef)
    }

    func testThrowsWithParameter() {
        verifySignature("___32")

        enum E: Error, LocalizedError, Equatable {
            case someError
        }

        do {
            try testableIntercept(throwing: E.someError) {
                try ___32(42)
            }
            fail("expected to throw")
        } catch {
            // success
            expect(error).to(beAKindOf(E.self))
        }
    }


    func testMetatypesInsideAggregates() {
        verifySignature("___42")

        // let injectedResult = ___S32_Outer(class: ___C32.self, struct: ___S32.self, enum: ___E32.self, proto: ___P32.Protocol, protocolComp: (___P32 & ___P32_Another).Protocol)
    }

    func testExistentialEnumPayload() {
        verifySignature("___43")

        class C43: ___P43 {}
        class C43Another: ___P43_Another {}

        let injectedResult = ___E43.a(C43())
        let actualArg = ___E43.b(C43Another())
        let (args, result) = testableIntercept(returning: injectedResult) {
            ___43(actualArg)
        }
        if case .a = result {
            // succeed
        } else {
            fail()
        }
        if case .b = args[0] as! ___E43 {
            // succeed
        } else {
            fail()
        }
    }

    func testExistentialStructFields() {
        verifySignature("___44")

        struct ImplP44: ___P44, Equatable { let a: String }
        class ImplP44Another_1: ___P44_Another {}
        class ImplP44Another_2: ___P44_Another {}

        let injectedResult: ___S44 = ___S44(a: ImplP44(a: "result"), b: ImplP44Another_1())
        let actualArg: ___S44 = ___S44(a: ImplP44(a: "arg"), b: ImplP44Another_2())

        let (args, result) = testableIntercept(returning: injectedResult) {
            ___44(actualArg)
        }

        expect((args[0] as! ___S44).a).to(beAKindOf(ImplP44.self))
        expect(((args[0] as! ___S44).a as! ImplP44).a) == "arg"
        expect((args[0] as! ___S44).b).to(beAKindOf(ImplP44Another_2.self))

        expect((result?.a as! ImplP44).a) == "result"
        expect(result?.b).to(beAKindOf(ImplP44Another_1.self))
    }

    func testCasting() {
        struct S: ___P45, Equatable {
            let a: Int
        }

        let injectedResult = S(a: 1)
        let actualArg = S(a: 2)

        let (args, result) = testableIntercept(returning: injectedResult) {
            ___45(actualArg)
        }
        expect(result as? S) == injectedResult
        expect(args[0]) ~= actualArg
    }

    // MARK: - Vars

    func testGlobablComputedVar() {
        verifySignature("___100", kind: .getter)

        let injectedResult = "foo bar"
        let (_, result) = testableIntercept(returning: injectedResult) {
            ___100
        }
        expect(result) == injectedResult
    }

    func testGlobalVarGetter() {
        verifySignature("___101", kind: .getter)

        let injectedResult = "foo bar"
        let (_, result) = testableIntercept(returning: injectedResult) {
            ___101
        }
        expect(result) == injectedResult
    }

    func testGlobalVarSetter() {
        verifySignature("___101", kind: .setter) // signature only, because not replaceable
    }

    func todo_testGlobalVarModify() { // global vars do not have a modify accessor [?]
        verifySignature("___101", kind: .modify) // signature only, because not replaceable
    }

    // MARK: - Optionals

    func testScalarOptional() {
        verifySignature("___200")

        let injectedResult: Double? = nil
        let actualArg: Double = 2.5
        let (args, result) = testableIntercept(returning: injectedResult) {
            ___200(actualArg)
        }
        expect(args[0]) ~= actualArg
        expect(result).to(beNil())
    }

    func testOptionalStruct() {
        verifySignature("___201")

        let injectedResult: ___S201? = nil
        let actualArg: ___S201 = .init(a: nil, b: 2.25)
        let (args, result) = testableIntercept(returning: injectedResult) {
            ___201(actualArg)
        }
        expect(args[0]) ~= actualArg
        expect(result).to(beNil())
    }

    func testOptionalSmallTuple() {
        verifySignature("___202")

        typealias Ty = (Int, Double?)
        let injectedResult: Ty? = nil
        let actualArg: Ty? = (20, 11.5)
        let (args, result) = testableIntercept(returning: injectedResult) {
            ___202(actualArg)
        }
        expect((args[0] as! Ty).0) == actualArg?.0
        expect((args[0] as! Ty).1) == actualArg?.1
        expect(result).to(beNil())
    }

    // MARK: - Tuples

    func testEmptyTupleConsistingOfTwoEmptyTuples() {
        verifySignature("___250")

        typealias Ty = (Double, (Void, Void))
        let args = testableInterceptVoid {
            ___250(a: (1, ((), ())), b: 2)
        }
        expect((args[0] as! Ty).0) == 1
        expect(args[1]) ~= 2
    }

    func testNestedTupleWithVoids() {
        verifySignature("___251")

        typealias Ty = (Double, (Int16, (Int8, (Int32, Void), (Int64))))
        let actualArg: Ty = (10.5, (11, (12, (13, ()), (14))))
        let args = testableInterceptVoid {
            ___251(a: actualArg)
        }
        expect((args[0] as! Ty).0) == 10.5
        expect((args[0] as! Ty).1.1.2) == 14
    }

    // MARK: - Address-only parameters and returns

    func testAddressOnlyStruct_Weak() {
        verifySignature("___300")

        weak var weakC300Result: ___C300?
        weak var weakC300Arg: ___C300?

        func dotest() {
            let c300Result = ___C300()
            let c300Arg = ___C300()

            weakC300Result = c300Result
            weakC300Arg = c300Arg

            let injectedResult = ___S300(c: c300Result)
            let actualArg = ___S300(c: c300Arg)
            let (args, result) = testableIntercept(returning: injectedResult) {
                ___300(actualArg)
            }
            expect((args[0] as! ___S300).c) === c300Arg
            expect(result.c) === c300Result
        }

        dotest()

        expect(weakC300Arg).to(beNil())
        expect(weakC300Result).to(beNil())
    }

    func testAddressOnlyStruct_Unmanaged() {
        verifySignature("___301")

        weak var weakC301Result: ___C301?
        weak var weakC301Arg: ___C301?

        func dotest() {
            let c301Result = ___C301()
            let c301Arg = ___C301()

            weakC301Result = c301Result
            weakC301Arg = c301Arg

            let injectedResult = ___S301(c: c301Result)
            let actualArg = ___S301(c: c301Arg)
            let (args, result) = testableIntercept(returning: injectedResult) {
                ___301(actualArg)
            }
            expect((args[0] as! ___S301).c) === c301Arg
            expect(result.c) === c301Result
        }

        dotest()

        expect(weakC301Arg).to(beNil())
        expect(weakC301Result).to(beNil())
    }

    func testAddressOnlyStruct_UnownedLoadable() {
        verifySignature("___302")

        weak var weakC302Result: ___C302?
        weak var weakC302Arg: ___C302?

        func dotest() {
            let c302Result = ___C302()
            let c302Arg = ___C302()

            weakC302Result = c302Result
            weakC302Arg = c302Arg

            let injectedResult = ___S302(c: c302Result)
            let actualArg = ___S302(c: c302Arg)
            let (args, result) = testableIntercept(returning: injectedResult) {
                ___302(actualArg)
            }
            expect((args[0] as! ___S302).c) === c302Arg
            expect(result.c) === c302Result
        }

        dotest()

        expect(weakC302Arg).to(beNil())
        expect(weakC302Result).to(beNil())
    }

    func todo_testAddressOnlyStruct_UnownedAddressOnly1() {
        // I am not sure it's actually testing what it should. unowned references are limited to classes, but class objects are always loadable.
        verifySignature("___303")
    }

    func testString() {
        // TODO: it lowers to @guaranteed / @owned - why?
        verifySignature("___310")

        let injectedResult = "result"
        let actualArg = "arg"
        let (args, result) = testableIntercept(returning: injectedResult) {
            ___310(actualArg)
        }
        expect(args[0]) ~= "arg"
        expect(result) == "result"
    }

    // MARK: - Functions as parameters, properties and returns

    func testPlainFunction() {
        verifySignature("___400")
    }

    func testEscapingFunction() {
        verifySignature("___401")
    }

    func todo_testCFunction() {
        // C functions not supported currently
        verifySignature("___402")
    }

    func testOptionalFunction() {
        verifySignature("___403")
    }

    func todo_testOptionalCFunction() {
        // C functions not supported currently
        verifySignature("___404")
    }

    func testStructWithFunctionProperties() {
        verifySignature("___420")
    }

    func testSinglePayloadEnumWithAFunction() {
        verifySignature("___431")
    }

    func testSinglePayloadEnumWithAnOptionalFunction() {
        verifySignature("___432")
    }

    func testMultiPayloadEnumWithFunctions() {
        verifySignature("___433")
    }

    func testEnumWithFunctionsReturningFunctions() {
        verifySignature("___434")
    }

    func testEnumWithFunctionsReturningThatEnum() {
        verifySignature("___435")
    }

    // MARK: - Inout params

    func testInoutParamSimple() {
        verifySignature("___500")

        let injectedResult = 20
        var actualArg = 10
        let (args, result) = testableIntercept(returning: injectedResult) {
            ___500(&actualArg)
        }
        expect(args[0]) ~= actualArg
        expect(result) == injectedResult
    }

    func testInoutParamBigStruct() {
        verifySignature("___501")

        var intArg = 15
        var stringArg = "foo"
        var genericArg = [String: AnyObject]()
        var objectArg = ___C501()
        var structArg = ___S501()
        let args = testableInterceptVoid {
            ___501(&intArg, &stringArg, &genericArg, &objectArg, &structArg)
        }
        expect(args[0]) ~= 15
        expect(args[1]) ~= "foo"
        expect(args[2]).to(beAKindOf([String: AnyObject].self))
        expect(args[3]).to(beAKindOf(___C501.self))
        expect(args[4]).to(beAKindOf(___S501.self))
    }

    // MARK: - Enums

    func testEnums() {
        verifySignature("___750")
        verifySignature("___751")
        verifySignature("___752")
        verifySignature("___754")
        verifySignature("___755")
        verifySignature("___758")
        verifySignature("___759")
        verifySignature("___760")
        verifySignature("___761")
        verifySignature("___762")
        verifySignature("___763")
        verifySignature("___764")
        verifySignature("___765")
        verifySignature("___766")
        verifySignature("___767")
        verifySignature("___768")
        verifySignature("___769")
        verifySignature("___770")
        verifySignature("___771")
        verifySignature("___772")
        verifySignature("___773")
        verifySignature("___774")
        verifySignature("___775")
        verifySignature("___776")
    }

    // MARK: - Returns

    func testSimpleTupleReturn() {
        verifySignature("___850")
        let ret: (Int8, (Int8, Int8)) = (10, (20, 30))
        let (_, result) = testableIntercept(returning: ret) {
            ___850()
        }
        expect(result.0) == 10
        expect(result.1.0) == 20
        expect(result.1.1) == 30
    }

    func testTupleReturnWithEmpty() {
        verifySignature("___851")
        let ret: (Int8, Void, (Int8, Int8)) = (10, (), (20, 30))
        let (_, result) = testableIntercept(returning: ret) {
            ___851()
        }
        expect(result.0) == 10
        expect(result.2.0) == 20
        expect(result.2.1) == 30
    }

    func testTupleReturn4Registers() {
        verifySignature("___852")
        let ret: (Int, (Int16), (Int, Int)) = (10, (20), (30, 40))
        let (_, result) = testableIntercept(returning: ret) {
            ___852()
        }
        expect(result.0) == 10
        expect(result.1) == 20
        expect(result.2.0) == 30
        expect(result.2.1) == 40
    }

    func testTupleReturnNotFittingIntoRegisters() {
        verifySignature("___853")
        let ret: (Int, (Int16), (Int, Int), Int8) = (10, (20), (30, 40), 50)
        let (_, result) = testableIntercept(returning: ret) {
            ___853()
        }
        expect(result.0) == 10
        expect(result.1) == 20
        expect(result.2.0) == 30
        expect(result.2.1) == 40
        expect(result.3) == 50
    }

    func testTupleReturn4RegistersWithFloat() {
        verifySignature("___854")
        let ret: (Int, (Float), (Int, Int)) = (10, (20), (30, 40))
        let (_, result) = testableIntercept(returning: ret) {
            ___854()
        }
        expect(result.0) == 10
        expect(result.1) == 20
        expect(result.2.0) == 30
        expect(result.2.1) == 40
    }

    func testTupleReturn4RegistersAllFloats() {
        verifySignature("___855")
        let ret: (Double, (Float), (Float, Double)) = (10, (20), (30, 40))
        let (_, result) = testableIntercept(returning: ret) {
            ___855()
        }
        expect(result.0) == 10
        expect(result.1) == 20
        expect(result.2.0) == 30
        expect(result.2.1) == 40
    }

    func testTupleReturnNotFittingIntoRegistersWithDoubles() {
        verifySignature("___856")
        let ret: (Int, (Float), (Double, Int), Int8) = (10, (20), (30, 40), 50)
        let (_, result) = testableIntercept(returning: ret) {
            ___856()
        }
        expect(result.0) == 10
        expect(result.1) == 20
        expect(result.2.0) == 30
        expect(result.2.1) == 40
        expect(result.3) == 50
    }

    func testReturnAddressOnlyStruct() {
        let (_, _, irSignature) = verifySignature("___857")!
         // uses sret for indirect: one indirect result, direct result void
        expect(irSignature.usesSret) == true

        let empty = AnEmptyClass()
        let ret = AnAddressOnlyStruct(weakVar: empty)
        let (_, result) = testableIntercept(returning: ret) {
            ___857()
        }
        expect(result.weakVar).to(beAKindOf(AnEmptyClass.self))
        _fixLifetime(empty)
    }

    func testReturnATupleOfAddressOnlyStruct_1() {
        let (_, _, irSignature) = verifySignature("___858")!
         // does not use sret: > 1 indirect results, direct result void
        expect(irSignature.usesSret) == false

        let empty = AnEmptyClass()
        let aaos0 = AnAddressOnlyStruct(weakVar: empty)
        let aaos1 = AnAddressOnlyStruct(weakVar: empty)
        let (_, result) = testableIntercept(returning: (aaos0, aaos1)) {
            ___858()
        }
        expect(result.0.weakVar).to(beAKindOf(AnEmptyClass.self))
        expect(result.1.weakVar).to(beAKindOf(AnEmptyClass.self))
        _fixLifetime(empty)
    }

    func testReturnATupleOfAddressOnlyStruct_2() { // same as the previous one, but with more params
        let (_, _, irSignature) = verifySignature("___859")!
        // does not use sret: > 1 indirect results, direct result void
        expect(irSignature.usesSret) == false

        let empty = AnEmptyClass()
        let aaos0 = AnAddressOnlyStruct(weakVar: empty)
        let aaos1 = AnAddressOnlyStruct(weakVar: empty)
        let aaos2 = AnAddressOnlyStruct(weakVar: empty)
        let aaos3 = AnAddressOnlyStruct(weakVar: empty)
        let aaos4 = AnAddressOnlyStruct(weakVar: empty)
        let (_, result) = testableIntercept(returning: (aaos0, aaos1, aaos2, aaos3, aaos4)) {
            ___859()
        }
        expect(result.0.weakVar).to(beAKindOf(AnEmptyClass.self))
        expect(result.1.weakVar).to(beAKindOf(AnEmptyClass.self))
        expect(result.2.weakVar).to(beAKindOf(AnEmptyClass.self))
        expect(result.3.weakVar).to(beAKindOf(AnEmptyClass.self))
        expect(result.4.weakVar).to(beAKindOf(AnEmptyClass.self))
        _fixLifetime(empty)
    }

    func testReturnSmallTupleOfMixedLoadableAndAddressOnlyValues() {
        let (_, _, irSignature) = verifySignature("___860")!
        // does not use sret: > 1 indirect results, direct result is abi-direct
        expect(irSignature.usesSret) == false

        let empty = AnEmptyClass()
        let aaos0 = AnAddressOnlyStruct(weakVar: empty)
        let aaos1 = AnAddressOnlyStruct(weakVar: empty)
        let (_, result) = testableIntercept(returning: (aaos0, (10, aaos1), 20)) {
            ___860()
        }
        expect(result.0.weakVar).to(beAKindOf(AnEmptyClass.self))
        expect(result.1.0) == 10
        expect(result.1.1.weakVar).to(beAKindOf(AnEmptyClass.self))
        expect(result.2) == 20
        _fixLifetime(empty)
    }

    func testReturnLargeTupleOfMixedLoadableAndAddressOnlyValues_Sret() {
        let (_, _, irSignature) = verifySignature("___861")!
        // uses sret for direct: one indirect result, direct result is abi-indirect
        expect(irSignature.usesSret) == true

        let empty = AnEmptyClass()
        let aaos0 = AnAddressOnlyStruct(weakVar: empty)
        let (_, result) = testableIntercept(returning: (aaos0, 10, 20, 30, 40, 50)) {
            ___861()
        }
        expect(result.0.weakVar).to(beAKindOf(AnEmptyClass.self))
        expect(result.1) == 10
        expect(result.2) == 20
        expect(result.3) == 30
        expect(result.4) == 40
        expect(result.5) == 50
        _fixLifetime(empty)
    }

    func testReturnLargeTupleOfMixedLoadableAndAddressOnlyValues_NoSret() {
        let (_, _, irSignature) = verifySignature("___862")!
        // does not use sret even though direct result wants it: > 1 indirect result, direct result is abi-indirect
        expect(irSignature.usesSret) == false

        let empty = AnEmptyClass()
        let aaos0 = AnAddressOnlyStruct(weakVar: empty)
        let aaos1 = AnAddressOnlyStruct(weakVar: empty)
        let (_, result) = testableIntercept(returning: (aaos0, (10, aaos1), (20, 30, 40, 50))) {
            ___862()
        }
        expect(result.0.weakVar).to(beAKindOf(AnEmptyClass.self))
        expect(result.1.0) == 10
        expect(result.1.1.weakVar).to(beAKindOf(AnEmptyClass.self))
        expect(result.2.0) == 20
        expect(result.2.1) == 30
        expect(result.2.2) == 40
        expect(result.2.3) == 50
        _fixLifetime(empty)
    }

    // MARK: - Misc

    func testArrayAndDictionary() {
        verifySignature("___1000")
    }

    func testFixedSizeGenericStruct() {
        verifySignature("___1001")
    }

    func testOriginallyNonFixedSizeGenericStruct() {
        verifySignature("___1002")
    }
}
