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

class ExtensionContextDescriptorTests: XCTestCase {
    func testExtendedContextType() {
        let metadata: Metadata = Metadata.of(GenericParentClass<Int>.Child.self)
        let cd = metadata.typeContextDescriptor?.parent as! ExtensionContextDescriptor
        expect(cd.resolveExtendedContextType(genericArguments: nil)) == GenericParentClass<Int>.self
        let _ = String(describing: cd)
    }

    func testIndirectablePointer() {
        // this uses indirectable pointer
        let cd = Metadata.of(GenericParentClass<Int>.Child.self).typeContextDescriptor?.parent
        expect(cd).toNot(beNil())
        let _ = String(describing: cd)
    }
}

extension XCTestCase: EmptyProtocol {
    class FooBar {}
}

extension GenericParentClass where T == Int {
    class Child {
        var t: T?
    }
}
