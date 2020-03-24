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
@testable import SwiftMocks

class TupleTypeMetadataTests: XCTestCase {
    func testCreateTupleTypeMetadata() {
        expect(Metadata.of((Int, String).self)).to(beAKindOf(TupleTypeMetadata.self))
    }

    func testNumberOfElements() {
        expect((Metadata.of((Int, String).self) as! TupleTypeMetadata).numberOfElements) == 2
        expect((Metadata.of((Int, String, Double).self) as! TupleTypeMetadata).numberOfElements) == 3
    }

    func testLabelsAsString() {
        typealias Tuple = (a: Int, b: String)
        expect((Metadata.of(Tuple.self) as! TupleTypeMetadata).labelsAsString) == "a b "
    }

    func testLabelsAsString_Nil() {
        typealias Tuple = (Int, String)
        expect((Metadata.of(Tuple.self) as! TupleTypeMetadata).labelsAsString).to(beNil())
    }

    func testLabels() {
        typealias Tuple = (a: Int, b: String)
        expect((Metadata.of(Tuple.self) as! TupleTypeMetadata).labels) == ["a", "b"]
    }

    func testElements() {
        typealias Tuple = (a: Int, b: String)

        let metadata = Metadata.of(Tuple.self) as! TupleTypeMetadata
        expect(metadata.elements[0].offset) == 0
        expect(metadata.elements[0].metadata) == Metadata.of(Int.self)
        expect(metadata.elements[1].offset) == 8
        expect(metadata.elements[1].metadata) == Metadata.of(String.self)
        let _ = String(describing: metadata)
    }
}
