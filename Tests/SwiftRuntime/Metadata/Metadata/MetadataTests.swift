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

import UIKit
import XCTest
import Nimble
import SwiftMocks
@testable import RuntimeTestFixtures

class MetadataTests: XCTestCase {
    func testIsClassObject() {
        class C {}
        struct S {}

        expect(Metadata.of(C.self).isClassObject) == true
        expect(Metadata.of(S.self).isClassObject) == false
        expect(Metadata.of(UIView.self).isClassObject) == false
    }

    func testIsAnyExistentialType() {
        struct S: EmptyProtocol { var a = 1; }

        func verifyExistential<T>(_ p: T) {
            let metadata: Metadata = Metadata.of(type(of: p))
            expect(metadata.kind) == .existential
            expect(metadata.isAnyExistentialType) == true
            let _ = String(describing: metadata)
        }

        let existential: EmptyProtocol = S()
        verifyExistential(existential)
    }

    func testIsAnyKindOfClass() {
        class C {}
        enum E {}

        expect(Metadata.of(C.self).isAnyKindOfClass) == true
        expect(Metadata.of(UIView.self).isAnyKindOfClass) == true
        expect(Metadata.of(E.self).isAnyKindOfClass) == false
    }

    func testOptional() {
        let metadata = Metadata.of(String?.self)
        expect(metadata).to(beAKindOf(OptionalMetadata.self))
        let _ = String(describing: metadata)
    }

    func testBasicValueWitnessValues() {
        class C {}

        let valueWitnesses = Metadata.of(C.self).valueWitnesses
        expect(valueWitnesses.size) == 8
        expect(valueWitnesses.stride) == 8
        expect(valueWitnesses.isValueInline) == true
        expect(valueWitnesses.alignmentMask) == 8 - 1
        expect(valueWitnesses.hasEnumWitnesses) == false
        expect(valueWitnesses.isBitwiseTakable) == true
        expect(valueWitnesses.isPOD) == false
    }
}
