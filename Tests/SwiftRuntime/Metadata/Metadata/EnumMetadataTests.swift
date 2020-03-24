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

private enum ComplexEnum {
    case bar(Int)
    case foo
    case baz(String, String)
}

class EnumMetadataTests: XCTestCase {
    func testTypeOfMetadata() {
        let metadata = Metadata.of(ComplexEnum.self)
        expect(metadata).to(beAKindOf(EnumMetadata.self))
        let _ = String(describing: metadata)
    }

    func testDescription() {
        let metadata = Metadata.of(ComplexEnum.self) as! EnumMetadata
        expect(metadata.description).to(beAKindOf(EnumDescriptor.self))
        let _ = String(describing: metadata)
    }

    func testFields() {
        let metadata = Metadata.of(ComplexEnum.self) as! EnumMetadata

        expect(metadata.description.numberOfCases) == 3
        expect(metadata.description.numberOfEmptyCases) == 1
        expect(metadata.description.numberOfPayloadCases) == 2

        let field0 = metadata.description.fields[0]
        expect(field0.name) == "bar"
        expect(field0.resolveType(contextDescriptor: metadata.description, genericArguments: metadata.genericArgumentsPointer) == Int.self) == true

        let field1 = metadata.description.fields[1]
        expect(field1.name) == "baz"
        expect(field1.resolveType(contextDescriptor: metadata.description, genericArguments: metadata.genericArgumentsPointer)) == (String, String).self

        let field2 = metadata.description.fields[2]
        expect(field2.name) == "foo"
        expect(field2.resolveType(contextDescriptor: metadata.description, genericArguments: metadata.genericArgumentsPointer)).to(beNil())
        let _ = String(describing: metadata)
    }
}
