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
import AnotherModule
@testable import RuntimeTestFixtures

class ClassExistentialTests: XCTestCase {
    func testOneProtocol() {
        class C: EmptyProtocolWithClassConstraint {}
        let instance = C()
        var existential: EmptyProtocolWithClassConstraint = instance
        let box = ClassExistentialBox(&existential, numberOfWitnessTables: 1)

        expect(box.container.value) == Unmanaged.passUnretained(instance).toOpaque()
        expect(box.witnessTables).to(haveCount(1))
        expect(box.witnessTables[0].descriptor.protocol.name) == "EmptyProtocolWithClassConstraint"

        let _ = String(describing: box)
    }

    func testThreeProtocols() {
        class C2: EmptyProtocolWithClassConstraint, EmptyProtocolFromAnotherModule, EmptyProtocolWithClassConstraintFromAnotherModule {}
        let instance = C2()
        var existential: EmptyProtocolWithClassConstraint & EmptyProtocolFromAnotherModule & EmptyProtocolWithClassConstraintFromAnotherModule = instance
        let box = ClassExistentialBox(&existential, numberOfWitnessTables: 3)

        expect(box.container.value) == Unmanaged.passUnretained(instance).toOpaque()
        expect(box.witnessTables).to(haveCount(3))
        // XXX: The ordering doesn't match the declaration order
        let protocolNames: [String] = box.witnessTables.map { $0.descriptor.protocol.name }
        expect(protocolNames).to(contain("EmptyProtocolWithClassConstraint"))
        expect(protocolNames).to(contain("EmptyProtocolFromAnotherModule"))
        expect(protocolNames).to(contain("EmptyProtocolWithClassConstraintFromAnotherModule"))

        let _ = String(describing: box)
    }

    func testAnyObjectExistentialBox() {
        class C: EmptyProtocolWithClassConstraint {}
        let instance = C()
        let existential: EmptyProtocolWithClassConstraint = instance
        var anyObject: AnyObject = existential
        let box = AnyObjectExistentialBox(&anyObject)
        expect(box.container.value) == Unmanaged.passUnretained(instance).toOpaque()
    }

}
