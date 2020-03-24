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

class ProtocolDescriptorTests: XCTestCase {
    func testProtocolName() {
        let proto = descriptor(EmptyChildProtocol.self)
        expect(proto.name)  == "EmptyChildProtocol"
    }

    func testHasClassConstraint() {
        let proto = descriptor(EmptyProtocolWithClassConstraint.self)
        expect(proto.hasClassConstraint) == true
    }

    func testHasClassConstraint_2() {
        let proto = descriptor(RealisticallyLookingProtocolWithABaseClass.self)
        expect(proto.hasClassConstraint) == true
    }

    func testHasClassConstraint_3() {
        let proto = descriptor(EmptyProtocol.self)
        expect(proto.hasClassConstraint) == false
    }

    func testIsSpecialProtocol() {
        let proto = descriptor(Error.self)
        expect(proto.specialProtocol) == SpecialProtocol.none // XXX: why?
    }

    func testProtocolRequirementsSignature() {
        let requirements = descriptor(RealisticallyLookingProtocolWithABaseClass.self).requirementSignature
        expect(requirements).to(haveCount(2))

        if case .baseClass(_) = requirements[0].kind {}
        else { fail("Expected .baseClass kind") }
        expect(requirements[0].hasKeyArgument) == false
        expect(requirements[0].hasExtraArgument) == false

        if case .protocol = requirements[1].kind {}
        else { fail("Expected .protocol kind") }
        expect(requirements[1].hasKeyArgument) == true
        expect(requirements[1].hasExtraArgument) == false
    }

    func testProtocolRequirements() {
        let requirements = descriptor(RealisticallyLookingProtocolWithABaseClass.self).requirements

        expect(requirements).to(haveCount(4))
        expect(requirements[0].kind) == .baseProtocol
        expect(requirements[1].kind) == .getter
        expect(requirements[2].kind) == .method
        expect(requirements[2].isInstance) == true
        expect(requirements[3].kind) == .method
        expect(requirements[3].isInstance) == false
    }

    private func descriptor(_ type: Any.Type) -> ProtocolDescriptor {
        let metadata = Metadata.of(type) as! ExistentialTypeMetadata
        let proto = metadata.protocols[0]
        return proto
    }
}
