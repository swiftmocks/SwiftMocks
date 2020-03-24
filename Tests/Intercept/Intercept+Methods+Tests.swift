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

class Intercept_Methods_Tests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    // MARK: - Class

    func testSimplestMethodOfClass() {
        verifySignature("___2000")

        let instance = ___C2000()
        let args = testableInterceptVoid {
            instance.___2000()
        }
        expect(args[0]) === instance
    }

    func testSimplestMethodOfClass_NoRetainProblems() {
        weak var weakInstance: ___C2000?

        func doIntercept() {
            let instance = ___C2000()
            weakInstance = instance
            let args = testableInterceptVoid {
                instance.___2000()
            }
            _ = "\(args[0])"
        }

        doIntercept()

        expect(weakInstance).to(beNil())
    }

    func testSimpleMethodOfClass() {
        verifySignature("___2001")

        let instance = ___C2001()
        let injectedResult = 0xabba
        let actualArg = 0xbeef
        let (args, result) = testableIntercept(returning: injectedResult) {
            instance.___2001(param: actualArg)
        }

        expect(args[0]) ~= actualArg
        expect(args[1]) === instance
        expect(result) == injectedResult
    }

    func testMethodOfClassReturningSelf() {
        verifySignature("___2002")

        let instance = ___C2002()
        let injectedResult = ___C2002()
        let actualArg = 0xbeef
        let (args, result) = testableIntercept(returning: injectedResult) {
            instance.___2002(param: actualArg)
        }

        expect(args[0]) ~= actualArg
        expect(args[1]) === instance
        expect(result) === injectedResult
    }

    func testMethodOfClassThrowing() {
        verifySignature("___2003")

        enum E: Error {
            case someError
        }
        let instance = ___C2003()
        let actualArg = 0xbeef
        do {
            try testableIntercept(throwing: E.someError) {
                try instance.___2003(param: actualArg)
            }
            fail("should have thrown")
        } catch {
            // success
            expect(error).to(beAKindOf(E.self))
        }
    }

    func testSimpleClassMethodOfClass() {
        verifySignature("___2004")

        let injectedResult = 0xabba
        let actualArg = 0xbeef
        let (args, result) = testableIntercept(returning: injectedResult) {
            ___C2004.___2004(param: actualArg)
        }

        expect(args[0]) ~= actualArg
        expect(type(of: args[1])) == type(of: ___C2004.self)
        expect(result) == injectedResult
    }

    func testExtensionMethod_Class() {
        verifySignature("___2005")

        let instance = ___C2005()
        let injectedResult: Float = 100.5
        let actualArg = 4567
        let (args, result) = testableIntercept(returning: injectedResult) {
            instance.___2005(param: actualArg)
        }
        expect(args[0]) ~= actualArg
        expect(result) == injectedResult
    }

    func testExtensionVar_Class() {
        verifySignature("___2006", kind: .getter)

        let instance = ___C2006()
        let injectedResult: [String] = ["foo bar"]
        let (_, result) = testableIntercept(returning: injectedResult) {
            instance.___2006
        }
        expect(result) == injectedResult
    }

    func testComputedVar_Class() {
        verifySignature("___102", kind: .getter)

        let sut = ___C102()
        let injectedResult = AnEmptyClass()
        let (_, result) = testableIntercept(returning: injectedResult) {
            sut.___102
        }
        expect(result) === injectedResult
    }

    func testVarGetter_Class() {
        verifySignature("___103", kind: .getter)

        let sut = ___C103()
        let injectedResult = AnEmptyClass()
        let (_, result) = testableIntercept(returning: injectedResult) {
            sut.___103
        }
        expect(result) === injectedResult
    }

    func testVarSetter_Class() { // TODO: change numbering of tests for vars in class and struct
        verifySignature("___103", kind: .setter) // signature only, since setters are not replaceable
    }

    func testStaticComputedVar_Class() {
        verifySignature("___106", kind: .getter)

        let injectedResult = "bar baz"
        let (_, result) = testableIntercept(returning: injectedResult) {
            ___C106.___106
        }
        expect(result) == injectedResult
    }

    func testStaticVarWithDidSet_Class() {
        verifySignature("___107", kind: .getter)

        let injectedResult = "bar baz"
        let (_, result) = testableIntercept(returning: injectedResult) {
            ___C107.___107
        }
        expect(result) == injectedResult
    }

    // MARK: - Struct

    func testSimplestMethodOfStruct() {
        verifySignature("___2010")

        let instance = ___S2010(property: 123)
        let args = testableInterceptVoid {
            instance.___2010()
        }
        expect(args[0]) ~= instance
    }

    func testSimpleMethodOfStruct() {
        verifySignature("___2011")

        let instance = ___S2011(property: 456)
        let injectedResult = 0xabba
        let actualArg = 0xbeef
        let (args, result) = testableIntercept(returning: injectedResult) {
            instance.___2011(param: actualArg)
        }

        expect(args[0]) ~= actualArg
        expect(args[1]) ~= instance
        expect(result) == injectedResult
    }

    func testMethodOfStructReturningSelf() {
        verifySignature("___2012")

        let instance = ___S2012(property: 123)
        let injectedResult = ___S2012(property: 456)
        let actualArg = 0xbeef
        let (args, result) = testableIntercept(returning: injectedResult) {
            instance.___2012(param: actualArg)
        }

        expect(args[0]) ~= actualArg
        expect(args[1]) ~= instance
        expect(result) == injectedResult
    }

    func testMethodOfStructThrowing() {
        verifySignature("___2013")

        enum E: Error {
            case someError
        }
        let instance = ___S2013(property: 123)
        let actualArg = 0xbeef
        do {
            try testableIntercept(throwing: E.someError) {
                try instance.___2013(param: actualArg)
            }
            fail("should have thrown")
        } catch {
            // success
            expect(error).to(beAKindOf(E.self))
        }
    }

    func testSimpleStaticMethodOfStruct() {
        verifySignature("___2014")

        let injectedResult = 0xabba
        let actualArg = 0xbeef
        let (args, result) = testableIntercept(returning: injectedResult) {
            ___S2014.___2014(param: actualArg)
        }

        expect(args[0]) ~= actualArg
        expect(type(of: args[1])) == type(of: ___S2014.self)
        expect(result) == injectedResult
    }

    func testMethodOfEmptyStruct() {
        verifySignature("___2015")

        let instance = ___S2015()
        let injectedResult = 100
        let actualArg = 21
        let (args, result) = testableIntercept(returning: injectedResult) {
            instance.___2015(actualArg)
        }

        expect(args[0]) ~= actualArg
        expect(args[1]) ~= instance
        expect(result) == injectedResult
    }

    func testExtensionMethod_Struct() {
        verifySignature("___2016")

        let instance = ___S2016()
        let injectedResult = "bar baz"
        let (_, result) = testableIntercept(returning: injectedResult) {
            instance.___2016()
        }
        expect(result) == injectedResult
    }

    func testExtensionVar_Struct() {
        verifySignature("___2017", kind: .getter)

        let instance = ___S2017()
        let injectedResult = 11
        let (_, result) = testableIntercept(returning: injectedResult) {
            instance.___2017
        }
        expect(result) == injectedResult
    }

    func testComputedVar_Struct() {
        verifySignature("___104", kind: .getter)

        let sut = ___S104()
        let injectedResult = AnEmptyClass()
        let (_, result) = testableIntercept(returning: injectedResult) {
            sut.___104
        }
        expect(result) === injectedResult
    }

    func testVarWithDidSet_Struct() {
        verifySignature("___105", kind: .getter)

        let sut = ___S105()
        let injectedResult = AnEmptyClass()
        let (_, result) = testableIntercept(returning: injectedResult) {
            sut.___105
        }
        expect(result) === injectedResult
    }

    func testStaticComputedVar_Struct() {
        verifySignature("___108", kind: .getter)

        let injectedResult = "bar baz"
        let (_, result) = testableIntercept(returning: injectedResult) {
            ___S108.___108
        }
        expect(result) == injectedResult
    }

    func testStaticVarWithDidSet_Struct() {
        verifySignature("___109", kind: .getter)

        let injectedResult = "bar baz"
        let (_, result) = testableIntercept(returning: injectedResult) {
            ___S109.___109
        }
        expect(result) == injectedResult
    }

    // MARK: - Enums

    func testSimplestMethodOfEnum() {
        verifySignature("___2020")

        let instance = ___E2020.foo(___S2020(property: 123))
        let args = testableInterceptVoid {
            instance.___2020()
        }
        expect(args[0]) ~= instance
    }

    func testSimpleMethodOfEnum() {
        verifySignature("___2021")

        let instance = ___E2021.foo(___S2021(property: 456))
        let injectedResult = 0xabba
        let actualArg = 0xbeef
        let (args, result) = testableIntercept(returning: injectedResult) {
            instance.___2021(param: actualArg)
        }

        expect(args[0]) ~= actualArg
        expect(args[1]) ~= instance
        expect(result) == injectedResult
    }

    func testMethodOfEnumReturningSelf() {
        verifySignature("___2022")

        let instance = ___E2022.foo(___S2022(property: 123))
        let injectedResult = ___E2022.foo(___S2022(property: 456))
        let actualArg = 0xbeef
        let (args, result) = testableIntercept(returning: injectedResult) {
            instance.___2022(param: actualArg)
        }

        expect(args[0]) ~= actualArg
        expect(args[1]) ~= instance
        expect(result) == injectedResult
    }

    func testMethodOfEnumThrowing() {
        verifySignature("___2023")

        enum E: Error {
            case someError
        }
        let instance = ___E2023.foo(___S2023(property: 123))
        let actualArg = 0xbeef
        do {
            try testableIntercept(throwing: E.someError) {
                try instance.___2023(param: actualArg)
            }
            fail("should have thrown")
        } catch {
            // success
            expect(error).to(beAKindOf(E.self))
        }
    }

    func testSimpleStaticMethodOfEnum() {
        verifySignature("___2024")

        let injectedResult = 0xabba
        let actualArg = 0xbeef
        let (args, result) = testableIntercept(returning: injectedResult) {
            ___E2024.___2024(param: actualArg)
        }

        expect(args[0]) ~= actualArg
        expect(type(of: args[1])) == type(of: ___E2024.self)
        expect(result) == injectedResult
    }

    func testExtensionMethod_Enum() {
        verifySignature("___2025")

        let instance = ___E2025.foo
        let injectedResult: CChar = 32
        let (_, result) = testableIntercept(returning: injectedResult) {
            instance.___2025()
        }
        expect(result) == injectedResult
    }

    func testExtensionVar_Enum() {
        verifySignature("___2026", kind: .getter)

        let instance = ___E2026.foo
        let injectedResult = RawPointer(bitPattern: 0xabbaabba)!
        let (_, result) = testableIntercept(returning: injectedResult) {
            instance.___2026
        }
        expect(result) == injectedResult
    }

    // MARK: - Subscripts

    func testSimpleSubscript() {
        verifySignature("___2100", kind: .subscriptGet)

        let instance = ___2100()
        let injectedResult: Character = "©"
        let (_, result) = testableIntercept(returning: injectedResult) {
            instance["foo"]
        }
        expect(result) ~= injectedResult
    }

    func testSubscriptGet() {
        verifySignature("___2101", kind: .subscriptGet)

        let instance = ___2101()
        let injectedResult = "hi"
        let index = 2.0
        let (_, result) = testableIntercept(returning: injectedResult) {
            instance[index]
        }
        expect(result) ~= injectedResult
    }

    func testSubscriptSet() {
        verifySignature("___2101", kind: .subscriptSet)

        let instance = ___2101()
        let injectedArg = "hi"
        let index = 2.0
        let args = testableInterceptVoid {
            instance[index] = injectedArg
        }
        expect(args).to(haveCount(3))
        expect(args[0]) ~= injectedArg
        expect(args[1]) ~= index
    }

    func testSubscriptModify() {
        verifySignature("___2101", kind: .subscriptModify)

        // not replaceable, so no tests
    }

    func testSubscriptCompoundKeyGet() {
        verifySignature("___2102", kind: .subscriptGet)

        let instance = ___2102()
        let injectedResult = "hi"
        let index0 = 2.0
        let index1 = 11
        let (_, result) = testableIntercept(returning: injectedResult) {
            instance[index0, index1]
        }
        expect(result) ~= injectedResult
    }

    func testSubscriptCompoundKeySet() {
        verifySignature("___2102", kind: .subscriptSet)

        var instance = ___2102()
        let injectedArg = "hi"
        let index0 = 2.0
        let index1 = 11
        let args = testableInterceptVoid {
            instance[index0, index1] = injectedArg
        }
        expect(args).to(haveCount(4))
        expect(args[0]) ~= injectedArg
        expect(args[1]) ~= index0
        expect(args[2]) ~= index1
        expect(args[3] as? ___2102) == instance
    }

    func testSubscriptCompoundKeyModify() {
        verifySignature("___2102", kind: .subscriptModify)

        // not replaceable, so no tests
    }

    func testSubscriptStatic() {
        verifySignature("___2103", kind: .subscriptGet)

        let (args, result) = testableIntercept(returning: "©" as UnicodeScalar) {
            ___2103["foo", 23]
        }
        expect(args).to(haveCount(3))
        expect(args[0]) ~= "foo"
        expect(args[1]) ~= 23
        expect(args[2]).to(beAKindOf(___2103.Type.self))
        expect(result) ~= "©" as UnicodeScalar
    }

    func testSubscriptReturningTuple_Get() {
        verifySignature("___2104", kind: .subscriptGet)

        let (args, result) = testableIntercept(returning: ("©" as UnicodeScalar, 15.5)) {
            ___2104["foo", 23]
        }
        expect(args).to(haveCount(3))
        expect(args[0]) ~= "foo"
        expect(args[1]) ~= 23
        expect(args[2]).to(beAKindOf(___2104.Type.self))
        expect(result).to(beAKindOf((UnicodeScalar, Double).self))
        expect(result.0) ~= "©" as UnicodeScalar
        expect(result.1) ~= 15.5
    }

    func testSubscriptReturningTuple_Set() {
        verifySignature("___2104", kind: .subscriptSet)

        let injectedResult = ("©" as UnicodeScalar, 15.5)
        let args = testableInterceptVoid {
            ___2104["foo", 23] = injectedResult
        }
        expect(args).to(haveCount(4))
        expect((args[0] as! (UnicodeScalar, Double)).0) ~= "©" as UnicodeScalar
        expect((args[0] as! (UnicodeScalar, Double)).1) ~= 15.5
        expect(args[1]) ~= "foo"
        expect(args[2]) ~= 23
        expect(args[3]).to(beAKindOf(___2104.Type.self))
    }
}
