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
import SwiftMocks
@testable import RuntimeTestFixtures

open class MethodDescriptorTests_Parent {
    init() {}
    var a = "2"
    func foo() {}
    class func bar() {}
    // dynamic func baz() {}
}

class MethodDescriptorTests_Child: MethodDescriptorTests_Parent {
    override var a: String {
        get { return "" }
        set(newValue) {}
    }

    override class func bar() {}

    override func foo() {}
}

class MethodDescriptorTests: XCTestCase {
    func testVTable() {
        let metadata = Metadata.of(MethodDescriptorTests_Parent.self) as! ClassMetadata
        let methods = metadata.description.vtableMethods

        expect(methods).to(haveCount(6))
        expect(methods[0].kind) == .`init`
        expect(methods[1].kind) == .getter
        expect(methods[2].kind) == .setter
        expect(methods[3].kind) == .modifyCoroutine
        expect(methods[4].kind) == .method
        expect(methods[4].isInstance) == true
        expect(methods[5].kind) == .method
        expect(methods[5].isInstance) == false
        for m in methods {
            expect(simpleDladdr(m.impl)).toNot(beNil())
        }
    }

    func testOverrideTable() {
        let metadata = Metadata.of(MethodDescriptorTests_Child.self) as! ClassMetadata
        let methods = metadata.description.overrideMethods

        expect(methods).to(haveCount(6))
        expect(methods[0].method?.kind) == .getter
        expect(methods[1].method?.kind) == .setter
        expect(methods[2].method?.kind) == .modifyCoroutine
        expect(methods[3].method?.kind) == .method
        expect(methods[3].method?.isInstance) == false // the override table follows the order of overriding methods, not original
        expect(methods[4].method?.kind) == .method
        expect(methods[4].method?.isInstance) == true
        expect(methods[5].method?.kind) == .`init`
        for m in methods {
            expect(simpleDladdr(m.method?.impl)).toNot(beNil())
        }
    }
}
