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

private class Qux {}

private struct SomeStruct {
    var foo: Int
    var bar: [String]
    var baz: Qux
}

class StructMetadataTests: XCTestCase {
    func testTypeOfMetadata() {
        let metadata = Metadata.of(SomeStruct.self)
        expect(metadata).to(beAKindOf(StructMetadata.self))
        let _ = String(describing: metadata)
    }

    func testDescription() {
        let metadata = Metadata.of(SomeStruct.self) as! StructMetadata
        expect(metadata.description).to(beAKindOf(StructDescriptor.self))
        let _ = String(describing: metadata)
    }

    func testFieldOffsets() {
        let fieldOffsets = (Metadata.of(SomeStruct.self) as! StructMetadata).fieldOffsets

        expect(fieldOffsets).to(haveCount(3))
        expect(fieldOffsets[0]) == 0
        expect(fieldOffsets[1]) == 8
        expect(fieldOffsets[2]) == 16
    }

    func testFields() {
        let metadata = Metadata.of(SomeStruct.self) as! StructMetadata

        expect(metadata.description.numberOfFields) == 3
        expect(metadata.description.fields.count) == 3

        let field0 = metadata.description.fields[0]
        expect(field0.name) == "foo"
        expect(field0.isVar) == true
        expect(field0.resolveType(contextDescriptor: metadata.description, genericArguments: metadata.genericArgumentsPointer)) == Int.self

        let field1 = metadata.description.fields[1]
        expect(field1.name) == "bar"
        expect(field1.isVar) == true
        expect(field1.resolveType(contextDescriptor: metadata.description, genericArguments: metadata.genericArgumentsPointer)) == [String].self

        let field2 = metadata.description.fields[2]
        expect(field2.name) == "baz"
        expect(field2.isVar) == true
        expect(field2.resolveType(contextDescriptor: metadata.description, genericArguments: metadata.genericArgumentsPointer)) == Qux.self

        let _ = String(describing: metadata)
    }
}
