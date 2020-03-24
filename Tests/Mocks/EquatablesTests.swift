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
@testable import RuntimeTestFixtures

private class ClassConformingToEquatable: Equatable {
    static func == (lhs: ClassConformingToEquatable, rhs: ClassConformingToEquatable) -> Bool {
        true
    }
}

private struct StructConformingToEquatableAndEmptyProtocol: Equatable, EmptyProtocol {}

class EquatablesConformsToEquatable: XCTestCase {
    func testNonEquatableStructInstance() {
        struct S {}
        expect(Equatables.conformsToEquatable(S())) == false
    }

    func testEquatableStructInstance() {
        struct S: Equatable {}
        expect(Equatables.conformsToEquatable(S())) == true
    }

    func testNonEquatableClass() {
        class C {}
        expect(Equatables.conformsToEquatable(C())) == false
    }

    func testEquatableClass() {
        expect(Equatables.conformsToEquatable(ClassConformingToEquatable())) == true
    }

    func testNonConformingExistentialWithConformingRuntimeType() {
        /// `Equatables.conformsToEquatable()` evaluates the runtime type, not the type as written, so even though the protocol itself does not conform to `Equatable`, the underlying runtime type is, and so the result is `true`.
        let instance: EmptyProtocol = StructConformingToEquatableAndEmptyProtocol()
        expect(Equatables.conformsToEquatable(instance)) == true
    }
}

class EquatablesAreEqualTests: XCTestCase {
    func testNotEquatableStruct() {
        struct S {}
        let sut = S()
        expect(Equatables.areEqual(lhs: sut, rhs: sut)).to(beNil())
    }

    func testDifferentStructs() {
        struct LHS {}
        struct RHS {}
        expect(Equatables.areEqual(lhs: LHS(), rhs: RHS())).to(beNil())
    }

    func testDifferentEquatableStructs() {
        struct LHS: Equatable {}
        struct RHS: Equatable {}
        expect(Equatables.areEqual(lhs: LHS(), rhs: RHS())).to(beNil())
    }

    func testEquatableStructEqual() {
        struct EquatableStruct: Equatable {
            let prop: Int
        }

        let sut = EquatableStruct(prop: 11)
        expect(Equatables.areEqual(lhs: sut, rhs: sut)) == true

        expect(Equatables.areEqual(lhs: EquatableStruct(prop: 10), rhs: EquatableStruct(prop: 10))) == true
    }

    func testEquatableStructNotEqual() {
        struct EquatableStruct: Equatable {
            let prop: Int
        }

        expect(Equatables.areEqual(lhs: EquatableStruct(prop: 10), rhs: EquatableStruct(prop: 11))) == false
    }

    func testEquatableEnumEqual() {
        enum EquatableEnum: Equatable {
            case foo
        }

        expect(Equatables.areEqual(lhs: EquatableEnum.foo, rhs: EquatableEnum.foo)) == true
    }

    func testEquatableEnumNotEqual() {
        enum EquatableEnum: Equatable {
            case foo
            case bar
        }

        expect(Equatables.areEqual(lhs: EquatableEnum.foo, rhs: EquatableEnum.bar)) == false
    }

    func testClassesNotSupported() {
        class C {}

        // we don't need to test class instances for equality, so we don't bother to support them
        expect(Equatables.areEqual(lhs: C(), rhs: C())).to(beNil())
        expect(Equatables.areEqual(lhs: ClassConformingToEquatable(), rhs: ClassConformingToEquatable())).to(beNil())

        // ... but when we do, some things to test:
        func testEquatableParentChildClasses() {}

        func testEquatableParentAndChildClasses_0() {}
        func testEquatableParentAndChildClasses_1() {} // swap lhs, rhs

        func testNonEquatableParentEquatableChildClasses_0() {}
        func testNonEquatableParentEquatableChildClasses_1() {} // swap lhs, rhs
    }
}
