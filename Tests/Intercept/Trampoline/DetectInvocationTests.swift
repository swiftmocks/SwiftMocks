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

class DetectInvocationTests: XCTestCase {
    let image = MachImage.allExcludingKnownSystemPaths.first { $0.filename.hasSuffix("MocksFixtures") }!

    func testVoidFunc() {
        let name = myDetectInvocation(execute: voidFunction(), returning: ())
        expect(name).to(contain("voidFunction"))
    }

    func testSimpleArgReturnInt() {
        let name = myDetectInvocation(execute: simpleFunction(21.35), returning: 0)
        expect(name).to(contain("simpleFunction"))
    }

    func testInstanceNoArgsNoReturn() {
        let sut = SomeClass()
        let name = myDetectInvocation(execute: sut.method(string: "foo bar baz"), returning: 0)
        expect(name).to(contain("method"))
    }

    private func myDetectInvocation<R>(execute: @autoclosure () -> R, returning result: R) -> String? {
        guard case .success(let result) = theCore.interceptor.detect(execute: execute, returning: result) else {
            fatalError()
        }
        switch result.index {
        case .regular(let index):
            return theCore.interceptor.name(at: index)
        default:
            fatalError()
        }
    }
}
