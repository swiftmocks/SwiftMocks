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

class RegisterProtocolConformanceTests: XCTestCase {
    func testRegisterProtocolConformance() throws {
        let (proto, typeContextDescriptor, instance, anyClass) = createProtocolAndTypeDescriptor()

        expect(instance).toNot(beAKindOf(ProtocolWithAMethod.self))

        let (sut, wt) = try ProtocolConformanceDescriptor.registerConformance(of: typeContextDescriptor, conformingTo: proto, numberOfWitnesses: 1)

        expect(sut.protocol.name) == "ProtocolWithAMethod"
        guard case let .typeDescriptor(sutTypeDescriptor) = sut.typeReference else { fail(); return }
        expect(sutTypeDescriptor.pointer) == typeContextDescriptor.pointer

        expect(type(of: instance)) == anyClass
        expect(instance).to(beAKindOf(ProtocolWithAMethod.self))
        // print(instance is ProtocolWithAMethod)
        // cannot call methods because the witness table at this point is fake
        // expect((instance as! ProtocolWithAMethod).method()) == 0

        expect(wt.descriptor) == sut
    }

    private func createProtocolAndTypeDescriptor() -> (protocol: ProtocolDescriptor, typeContextDescriptor: TypeContextDescriptor, instance: AnyObject, anyClass: Any.Type) {
        class C {}
        let metadata = Metadata.of(ProtocolWithAMethod.self) as! ExistentialTypeMetadata
        let typeContextDescriptor = Metadata.of(C.self).typeContextDescriptor!
        return (metadata.protocols[0], typeContextDescriptor, C(), C.self)
    }
}
