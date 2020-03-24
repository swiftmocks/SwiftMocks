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

class DummyFactoryTests_TODO: XCTestCase {
    func todo_testBridgedObjcInstance() {
        struct S<T> {
            let a: T
        }
        let dummy = try! dummyInstance(of: S<DateFormatter>.self)
        expect(dummy).to(beAKindOf(S<DateFormatter>.self))
        expect(dummy.a).toNot(beNil())
    }
}
