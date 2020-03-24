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

class ExistentialMetatypeMetadataTests: XCTestCase {
    func testExistentialMetatypeMetadata() {
        let metadata = Metadata.of((EmptyProtocol & AnotherEmptyProtocol).Type.self)
        expect(metadata.kind) == .existentialMetatype
    }

    func testExistentialMetatypeMetadataInstanceType() {
        let metadata = Metadata.of((EmptyProtocol & AnotherEmptyProtocol).Type.self) as! ExistentialMetatypeMetadata
        expect(metadata.instanceType.asAnyType) == (EmptyProtocol & AnotherEmptyProtocol).self
    }

    func testExistentialMetatypeMetadataInstanceFlags() {
        let metadata = Metadata.of((EmptyProtocol & AnotherEmptyProtocol).Type.self) as! ExistentialMetatypeMetadata
        expect(metadata.flags.numberOfWitnessTables) == 2
        expect(metadata.flags.classConstraint) == .any
        expect(metadata.flags.hasSuperclassConstraint) == false
        expect(metadata.flags.specialProtocol) == SpecialProtocol.none
    }
}
