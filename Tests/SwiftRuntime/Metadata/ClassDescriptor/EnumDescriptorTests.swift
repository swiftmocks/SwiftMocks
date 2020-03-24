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

class EnumDescriptorTests: XCTestCase {
    func testEmptyEnum() {
        enum E {}
        let d = enumDescriptor(E.self)
        expect(d.numberOfCases) == 0
        expect(d.numberOfEmptyCases) == 0
        expect(d.numberOfPayloadCases) == 0
    }

    func testSimpleEnum() {
        enum E { case north, south }
        let d = enumDescriptor(E.self)
        expect(d.numberOfCases) == 2
        expect(d.numberOfEmptyCases) == 2
        expect(d.numberOfPayloadCases) == 0
    }

    func testSinglePayloadEnum() {
        enum E { case north, south, east(String) }
        let d = enumDescriptor(E.self)
        expect(d.numberOfCases) == 3
        expect(d.numberOfEmptyCases) == 2
        expect(d.numberOfPayloadCases) == 1
    }

    func testMultiPayloadEnum() {
        enum E { case north, south, east(String), west(Int) }
        let d = enumDescriptor(E.self)
        expect(d.numberOfCases) == 4
        expect(d.numberOfEmptyCases) == 2
        expect(d.numberOfPayloadCases) == 2
    }

    func _testFoo() {
        enum E { case north, south, east(RawPointer), west(Int, Double) }
        let m = Metadata.of(E.self) as! EnumMetadata
        let d = enumDescriptor(E.self)

        let type = d.fields[0].resolveType(contextDescriptor: d, genericArguments: m.genericArgumentsPointer)!
        // Metadata.create(type: type).valueWitnesses.numberOfExtraInhabitants
        print(type)
        print(m.valueWitnesses.size)
        print(m.valueWitnesses.numberOfExtraInhabitants)
    }

    private func enumDescriptor(_ type: Any.Type) -> EnumDescriptor {
        Metadata.of(type).typeContextDescriptor as! EnumDescriptor
    }
}
