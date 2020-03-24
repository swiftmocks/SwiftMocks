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

class RuntimeTests_ConformsToProtocol: XCTestCase {
    func testSimple() {
        let emptyProto: ProtocolDescriptor = (Metadata.of(EmptyProtocol.self) as! ExistentialTypeMetadata).protocols[0]
        let anotherProto: ProtocolDescriptor = (Metadata.of(AnotherEmptyProtocol.self) as! ExistentialTypeMetadata).protocols[0]

        class Foo: EmptyProtocol {}
        let metadata: Metadata = Metadata.of(Foo.self)

        expect(Runtime.conformsToProtocol(metadata: metadata, proto: emptyProto)).toNot(beNil())
        expect(Runtime.conformsToProtocol(metadata: metadata, proto: anotherProto)).to(beNil())
    }

    func testNonExistential() {
        class CollectionProtocolDescriptorExtractionHelper<T: Encodable> {}
        let encodableProto = ProtocolDescriptorExtractor.extract(type: CollectionProtocolDescriptorExtractionHelper<Int>.self)
        let emptyProto = (Metadata.of(EmptyProtocol.self) as! ExistentialTypeMetadata).protocols[0]

        class Foo: Encodable {}
        let metadata = Metadata.of(Foo.self)

        expect(Runtime.conformsToProtocol(metadata: metadata, proto: encodableProto)).toNot(beNil())
        expect(Runtime.conformsToProtocol(metadata: metadata, proto: emptyProto)).to(beNil())
    }
}
