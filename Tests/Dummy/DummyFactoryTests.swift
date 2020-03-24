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

class DummyFactoryTests: XCTestCase {
    override func tearDown() {
        gcDummies()
    }

    func testStruct() throws {
        struct S {
            let a: String
            let b: [Float]
            let c: Set<Int>
            let d: [UInt: Double]
        }

        let dummy = try dummyInstance(of: S.self)
        expect(dummy).to(beAKindOf(S.self))
        expect(dummy.a).to(beAKindOf(String.self))
        expect(dummy.b).to(beAKindOf([Float].self))
        expect(dummy.c).to(beAKindOf(Set<Int>.self))
        expect(dummy.d).to(beAKindOf([UInt: Double].self))
    }

    func testStructWithOpaqueTypes() throws {
        struct S {
            let a: Int16
        }
        let dummy = try! dummyInstance(of: S.self)
        expect(dummy).to(beAKindOf(S.self))
        _ = String(describing: dummy)
    }

    func testOptionalInt() throws {
        let dummy = try dummyInstance(of: Int?.self)
        expect(dummy).to(beNil())
    }

    func testOptionalPointer() throws {
        let dummy = try dummyInstance(of: UnsafeRawPointer?.self)
        expect(dummy).to(beNil())
    }

    func testStructWithOptionalFields() throws {
        struct S {
            let a: String?
            let b: [Float]?
            let c: Set<Int?>?
            let d: [UInt: Double?]?
            let e: Int?
        }

        let dummy = try dummyInstance(of: S.self)
        expect(dummy).to(beAKindOf(S.self))
        expect(dummy.a).to(beNil())
        expect(dummy.b).to(beNil())
        expect(dummy.c).to(beNil())
        expect(dummy.d).to(beNil())
        expect(dummy.e).to(beNil())
    }

    func testStructWithWeakReference() throws {
        struct S {
            weak var a: EmptyClass?
        }
        let dummy = try dummyInstance(of: S.self)
        expect(dummy).to(beAKindOf(S.self))
        expect(dummy.a).to(beNil())
    }

    func testGenericStruct() throws {
        struct S<T> {
            let a: T
        }
        class C {}
        let dummy = try dummyInstance(of: S<C>.self)
        expect(dummy).to(beAKindOf(S<C>.self))
        expect(dummy.a).to(beAKindOf(C.self))
    }

    func testClass() throws {
        class C {
            let a = 0xF1
            weak var dateFormatter: DateFormatter?
            let c = 0xF3
        }
        let dummy = try dummyInstance(of: C.self)
        expect(dummy).to(beAKindOf(C.self))
    }

    func testClassDummyDoesNotRetainDummyObject() throws {
        class C {
            weak var dateFormatter: DateFormatter?
        }
        weak var theDummy: C?
        do {
            let dummy = try dummyInstance(of: C.self)
            theDummy = dummy
        }
        expect(theDummy).toNot(beNil())
        gcDummies()
        expect(theDummy).to(beNil())
    }

    func testTuple() throws {
        let dummy = try dummyInstance(of: (Int, String).self)
        expect(dummy).to(beAKindOf((Int, String).self))
        expect(dummy.1).to(beAKindOf(String.self))
        _ = String(describing: dummy)
    }

    func testFunction() throws {
        let dummy = try dummyInstance(of: SimplestFunctionType.self)
        expect(dummy).to(beAKindOf(SimplestFunctionType.self))
        _ = String(describing: dummy)
    }

    func testCFunction() throws {
        let dummy = try dummyInstance(of: SimplestCFunctionType.self)
        expect(dummy).to(beAKindOf(SimplestCFunctionType.self))
        _ = String(describing: dummy)
    }

    func testMetatype() throws {
        let dummy = try dummyInstance(of: GenericParentClass<Int>.Type.self)
        expect(dummy).to(beAKindOf(GenericParentClass<Int>.Type.self))
        _ = String(describing: dummy)
    }

    func testExistentialMetatype() throws {
        let dummy = try dummyInstance(of: EmptyProtocol.Type.self)
        expect(dummy).to(beAKindOf(EmptyProtocol.Protocol.self))
        _ = String(describing: dummy)
    }

    func testObjcWrapperClass() throws {
        let dummy = try dummyInstance(of: DateFormatter.self)
        expect(dummy).to(beAKindOf(DateFormatter.self))
        _ = String(describing: dummy)
    }

    // MARK: - SDK types

    func testAnyHashable() throws {
        let dummy = try dummyInstance(of: AnyHashable.self)
        expect(dummy).to(beAKindOf(AnyHashable.self))
    }

    func testContiguousArray() throws {
        let dummy: ContiguousArray<String> = try dummyInstance()
        expect(dummy).to(beAKindOf(ContiguousArray<String>.self))
    }

    func testError() throws {
        let dummy: Error = try dummyInstance()
        expect(dummy).to(beAKindOf(Error.self))
    }

    func testLocalizedError() throws {
        let dummy: LocalizedError = try dummyInstance()
        expect(dummy).to(beAKindOf(LocalizedError.self))
    }

    func testCustomNSError() throws {
        let dummy: CustomNSError = try dummyInstance()
        expect(dummy).to(beAKindOf(CustomNSError.self))
    }

    func testKeyPath() throws {
        let dummy: WritableKeyPath<Int, String> = try dummyInstance()
        expect(dummy).to(beAKindOf(WritableKeyPath<Int, String>.self))
    }
}

func dummyInstance<T>(of type: T.Type = T.self) throws -> T {
    try theCore.dummyFactory.dummyInstance(of: type)
}

func gcDummies() {
    theCore.dummyFactory.gcDummies()
}

private typealias SimplestFunctionType = () -> Void
private typealias SimplestCFunctionType = @convention(c) () -> Void

class ProtocolWithFiveMethodsFake: ProtocolWithFiveMethods {
    func method_0() {}
    func method_1() {}
    func method_2() {}
    func method_3() {}
    func method_4() {}
}

class AnotherEmptyProtocolFake: AnotherEmptyProtocol {}

class EmptyProtocolWithClassConstraintFake: EmptyProtocolWithClassConstraint {}
