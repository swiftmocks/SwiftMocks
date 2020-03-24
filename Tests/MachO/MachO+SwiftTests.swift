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
@testable import IR
@testable import SwiftMocks

class MachO_SwiftTests: XCTestCase {
    let image = MachImage.allExcludingKnownSystemPaths.first { $0.filename.hasSuffix("IR") }!

    func testReplacementVars() {
        let replacementVars = image.replacementVars
        // replacementVars.forEach { print($0.key.name) }
        expect(replacementVars).to(containElementSatisfying({ $0.key.name == "$s2IR8___S3011V7___3011yyFZTx" }))
    }

    func testTypes() {
        let types = image.types
        expect(types).to(contain(Metadata.of(___C2000.self).typeContextDescriptor!))
        _ = String(reflecting: types) // if it doesn't blow up, it passed
    }

    func testProtocols() {
        let protocols = image.protocols
        expect(protocols).toNot(beEmpty())
        _ = String(reflecting: protocols) // if it doesn't blow up, it passed
    }

    func testProtocolConformanceSection() {
        let protocolConformances = image.protocolConformances
        expect(protocolConformances).toNot(beEmpty())
        _ = String(reflecting: protocolConformances) // if it doesn't blow up, it passed
    }
}
