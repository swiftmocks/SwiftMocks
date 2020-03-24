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

@objc private class ObjCChild: NSObject {}
private class Empty {}
private class EmptyChild: Empty {}
private class ParentWithProperties { var a = "" }
private class ChildWithProperties: ParentWithProperties { var b = 1; var c = 2.0 }

class ClassMetadataTests: XCTestCase {
    func testSuperclass() {
        let metadata = Metadata.of(EmptyChild.self) as! ClassMetadata
        expect(metadata.superclass) == Metadata.of(Empty.self)
        let _ = String(describing: metadata)
    }

    func testFlags() {
        let metadata = Metadata.of(Empty.self) as! ClassMetadata
        expect(metadata.flags) == [.usesSwiftRefcounting]
        let _ = String(describing: metadata)
    }

    func testFlagsObjCChild() {
        let metadata = Metadata.of(ObjCChild.self) as! ClassMetadata
        expect(metadata.flags) == []
        let _ = String(describing: metadata)
    }

    func testFieldOffsets() {
        let fieldOffsets = (Metadata.of(ChildWithProperties.self) as! ClassMetadata).fieldOffsets

        // XXX: investigate field layout in this case: too big first offset
        expect(fieldOffsets).to(haveCount(2))
        expect(fieldOffsets[0]) == 32
        expect(fieldOffsets[1]) == 40
    }

    func testDescription() {
        let metadata = Metadata.of(Empty.self) as! ClassMetadata
        expect(type(of: metadata.description)) == ClassDescriptor.self
        let _ = String(describing: metadata)
    }

    func testSanity() {
        class EmptyClass {}
        class SomewhatRealisticParent {
            func frobnicate() {}
        }
        class SomewhatRealisticClass {
            weak var foo: EmptyClass?
            var bar: EmptyClass = EmptyClass()
            var int = 1 {
                didSet {}
            }
            var string: String {
                get { return "" }
                set(newValue) { }
            }
            func frobnicate() {}
            func qux() -> Int { return 1 }
        }

        let metadata = Metadata.of(SomewhatRealisticClass.self) as! ClassMetadata
        let _ = String(describing: metadata) // if this doesn't crash, it passed :)
    }
}
