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
@testable import SwiftMocks

class DummyFactoryTests_DefaultWitnessFactory: XCTestCase {
    func testOpaqueExistential() throws {
        let dummy = try dummyInstance(of: (ProtocolWithAMethod & ProtocolWithFiveMethods).self)
        let any = dummy as Any
        _ = String(describing: dummy) // if it doesn't blow up, it passed
        expect(dummy).to(beAKindOf((ProtocolWithAMethod & ProtocolWithFiveMethods).self))
        expect(any).to(beAKindOf((ProtocolWithAMethod & ProtocolWithFiveMethods).self))
    }

    func testOpaqueExistentialUnderlyingObject() throws {
        let dummy = try dummyInstance(of: (ProtocolWithAMethod & ProtocolWithFiveMethods).self)
        expect(dummy).to(beAKindOf(ExistentialDummy.self))
    }

    func testOpaqueExistentialDummyDoesNotRetainDummyObject() throws {
        weak var weakExistentialDummy: AnyObject?
        func f() {
            let dummy = try! dummyInstance(of: (ProtocolWithAMethod & ProtocolWithFiveMethods).self)
            weakExistentialDummy = dummy as AnyObject
            expect(weakExistentialDummy).toNot(beNil())
            _ = String(describing: dummy)
        }
        f()
        expect(weakExistentialDummy).to(beNil())
    }

    func testClassExistential() throws {
        let dummy = try dummyInstance(of: (EmptyProtocolWithClassConstraint & AnotherEmptyProtocol).self)
        _ = String(describing: dummy) // if it doesn't blow up, it passed
        expect(dummy).to(beAKindOf((EmptyProtocolWithClassConstraint & AnotherEmptyProtocol).self))
    }

    func testClassExistentialUnderlyingObject() throws {
        let dummy = try dummyInstance(of: (EmptyProtocolWithClassConstraint & ProtocolWithAMethod).self)
        expect(dummy).to(beAKindOf(ExistentialDummy.self))
        _ = String(describing: dummy)
    }

    func testStructsWithExistentials() throws {
        struct S {
            let a: EmptyProtocol & AnotherEmptyProtocol
            let b: EmptyProtocolWithClassConstraint & ProtocolWithFiveMethods
        }
        let dummy = try dummyInstance(of: S.self)
        expect(dummy.a).to(beAKindOf((EmptyProtocol & AnotherEmptyProtocol).self))
        expect(dummy.b).to(beAKindOf((ProtocolWithFiveMethods & EmptyProtocolWithClassConstraint).self))
        _ = String(describing: dummy)
    }

    // MARK: - Default implementations. Test that they don't throw

    func testMethod() throws {
        let dummy = try dummyInstance(of: RealisticallyLookingProtocol.self)
        let any = dummy as Any
        expect((any as! RealisticallyLookingProtocol).method(param: 2.0)) == [:]
    }

    func testVar() throws {
        let dummy = try dummyInstance(of: RealisticallyLookingProtocol.self)
        expect(dummy.someVar) == ""
    }

    func test01SettingVar() throws {
        var dummy = try dummyInstance(of: RealisticallyLookingProtocol.self)
        dummy.someVar = "12345"
    }

    func test02ModifyVar() throws {
        var dummy = try dummyInstance(of: ProtocolWithModify.self)
        dummy.modifiableStructProp.prop.append("foo bar") // if it doesn't throw, it passed
    }

    func test03StaticMethod() throws {
        let dummy = try dummyInstance(of: RealisticallyLookingProtocol.self)
        expect(type(of: dummy).staticMethod(1234)) == []
    }

    func testModifyTupleVar() throws {
        var dummy = try dummyInstance(of: ProtocolWithModify.self)
        dummy.modifiableTupleProp.0 = "foo bar" // if it doesn't throw, it passed
    }

    func testSubscript() throws {
        var dummy = try dummyInstance(of: ProtocolWithSubscript.self)
        expect(dummy[0].prop) == ""
        dummy[0].prop.append("foo bar") // if it doesn't throw, it passed
        expect(dummy[10, "foo"].prop) == ""
        dummy[1, "foo"].prop.append("foo bar") // if it doesn't throw, it passed
    }
}

struct ProtocolWithModifyFake: ProtocolWithModify {
    var modifiableTupleProp: (String, [Int]) = { fatalError() }()
    var modifiableStructProp: ModifiableStruct = { fatalError() }()
}
struct ProtocolWithSubscriptFake: ProtocolWithSubscript {
    subscript(index: Int) -> ModifiableStruct {
        get { fatalError() }
        set { fatalError() }
    }

    subscript(index1: Int, index2: String) -> ModifiableStruct {
        get { fatalError() }
        set { fatalError() }
    }
}
