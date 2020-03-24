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

class ExistentialMetadataTests: XCTestCase {
    func testFlags_SingleProtocol() {
        verify(EmptyProtocol.self,
               numberOfProtocols: 1,
               numberOfWitnessTables: 1,
               protocolClassConstraint: .any,
               hasSuperclassConstraint: false,
               isErrorProtocol: false,
               representation: .opaque)
    }

    func testFlags_SingleChildProtocol() {
        verify(EmptyChildProtocol.self,
               numberOfProtocols: 1,
               numberOfWitnessTables: 1,
               protocolClassConstraint: .any,
               hasSuperclassConstraint: false,
               isErrorProtocol: false,
               representation: .opaque)
    }

    func testFlags_TwoProtocols() {
        verify((EmptyProtocol & AnotherEmptyProtocol).self,
               numberOfProtocols: 2,
               numberOfWitnessTables: 2,
               protocolClassConstraint: .any,
               hasSuperclassConstraint: false,
               isErrorProtocol: false,
               representation: .opaque)
    }

    func testFlags_ClassConstraint() {
        verify(EmptyProtocolWithClassConstraint.self,
               numberOfProtocols: 1,
               numberOfWitnessTables: 1,
               protocolClassConstraint: .class,
               hasSuperclassConstraint: false,
               isErrorProtocol: false,
               representation: .class)
    }

    func xxxtestFlags_HasSuperclassConstraint() {
        verify(RealisticallyLookingProtocolWithABaseClass.self,
               numberOfProtocols: 1,
               numberOfWitnessTables: 1,
               protocolClassConstraint: .class,
               hasSuperclassConstraint: true,
               isErrorProtocol: false,
               representation: .class)
    }

    func testFlags_ErrorProtocol() {
        verify(Error.self,
               numberOfProtocols: 1,
               numberOfWitnessTables: 1,
               protocolClassConstraint: .any,
               hasSuperclassConstraint: false,
               isErrorProtocol: true,
               representation: .error)
        verify(EmptyErrorProtocol.self,
               numberOfProtocols: 1,
               numberOfWitnessTables: 1,
               protocolClassConstraint: .any,
               hasSuperclassConstraint: false,
               isErrorProtocol: /* XXX: why? */ false,
               representation: .opaque)
    }

    func testProtocolNames() {
        let metadata = Metadata.of((EmptyProtocol & AnotherEmptyProtocol).self) as! ExistentialTypeMetadata
        let protocols = metadata.protocols
        expect(protocols).to(haveCount(2))
        // XXX: why in reverse order?
        expect(protocols[1].name) == "EmptyProtocol"
        expect(protocols[0].name) == "AnotherEmptyProtocol"
        let _ = String(describing: metadata)
    }

    func verify<T>(_ p: T.Type,
                   numberOfProtocols: Int,
                   numberOfWitnessTables: UInt,
                   protocolClassConstraint: ProtocolClassConstraint,
                   hasSuperclassConstraint: Bool,
                   isErrorProtocol: Bool,
                   representation: ExistentialTypeRepresentation,
                   file: FileString = #file,
                   line: UInt = #line) {
        let metadata = Metadata.of(p) as! ExistentialTypeMetadata
        expect(metadata.numberOfProtocols, file: file, line: line) == numberOfProtocols
        expect(metadata.flags.numberOfWitnessTables, file: file, line: line) == numberOfWitnessTables
        expect(metadata.flags.classConstraint, file: file, line: line) == protocolClassConstraint
        expect(metadata.flags.hasSuperclassConstraint, file: file, line: line) == hasSuperclassConstraint
        expect(metadata.flags.specialProtocol, file: file, line: line) == (isErrorProtocol ? SpecialProtocol.error : SpecialProtocol.none)
        expect(metadata.representation, file: file, line: line) == representation
        let _ = String(describing: metadata)
    }
}
