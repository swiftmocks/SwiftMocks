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

// dummy enums are fully functional instances that are good for passing to String(describing:).
class DummyFactoryTests_Enum: XCTestCase {
    override func tearDown() {
        gcDummies()
    }

    func testSingleCaseEnum() throws {
        enum E: Equatable { case a }
        let dummy = try dummyInstance(of: E.self)
        expect(dummy) == .a
        let _ = String(describing: dummy)
    }

    func testNoPayloadEnum() throws {
        enum E: Equatable { case foo, bar, baz }
        let dummy = try dummyInstance(of: E.self)
        expect(dummy) == .foo
        let _ = String(describing: dummy)
    }

    func testSinglePayloadEnumWithNonPayloadCases() throws {
        enum E: Equatable { case foo, bar, baz(String) }
        let dummy = try dummyInstance(of: E.self)
        expect(dummy) == .foo // creates the first non-payload case
        let _ = String(describing: dummy)
    }

    func testSinglePayloadEnumWithoutNonPayloadCases() throws {
        enum E: Equatable { case quuz(String) }
        let dummy = try dummyInstance(of: E.self)
        expect(dummy) == .quuz("")
        let _ = String(describing: dummy)
    }

    func testSinglePayloadEnum_NonTrivial() throws {
        enum E { case foo, bar, baz([Int]) }
        let dummy = try dummyInstance(of: E.self)
        expect(dummy).to(beAKindOf(E.self))
        let _ = String(describing: dummy)
    }

    func testMultiPayloadEnum_1() throws {
        enum E { case foo(String), bar(String), baz(String) }
        let dummy = try dummyInstance(of: E.self)
        expect(dummy).to(beAKindOf(E.self))
        let _ = String(describing: dummy)
    }

    func testMultiPayloadEnum_2() throws {
        enum E { case foo([String]), bar(EmptyClass?), baz(String) }
        let dummy = try dummyInstance(of: E.self)
        expect(dummy).to(beAKindOf(E.self))
        let _ = String(describing: dummy)
    }

    func testMultiPayloadEnum_WhereFirstPayloadIsShorterThanOthers() throws {
        enum E { case foo(Bool), bar([String]), baz }
        let dummy = try dummyInstance(of: E.self)
        expect(dummy).to(beAKindOf(E.self))
        let _ = String(describing: dummy)
    }

    func todo_test() throws {
        // FIXME: builtins are not working!
        enum E { case foo(Int), bar([String]), baz }
        let dummy = try dummyInstance(of: E.self)
        expect(dummy).to(beAKindOf(E.self))
        let _ = String(describing: dummy)
    }
}
