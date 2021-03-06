//
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

class IRFunctionTypeParser_Tests: XCTestCase {
    func testSanity() throws {
        let s = "{ %swift.type*, { %swift.type*, i64 }, { %swift.type*, double, i8** } } (%Foo* noalias nocapture sret, %T2IR8___C3001C* swiftself, %swift.type* %Self, %Bar* noalias align 8 nocapture dereferenceable(112))"
        let signature = try IRTest.parseIRFunctionType(s)
        expect(signature.type.result) == .struct([.pointer, .struct([.pointer, .i64]), .struct([.pointer, .double, .pointer])])
        expect(signature.type.params) == [.pointer, .pointer, .pointer, .pointer]
    }
}
