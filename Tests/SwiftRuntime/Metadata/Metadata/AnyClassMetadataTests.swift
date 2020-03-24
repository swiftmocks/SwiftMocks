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

private class ChildOfEmptyClass: EmptyClass {}
private class ChildOfChildOfEmptyClass: ChildOfEmptyClass {}

class AnyClassMetadataTests: XCTestCase {
    func testRelationshipSame() {
        let lhs = Metadata.of(EmptyClass.self) as! AnyClassMetadata
        let rhs = Metadata.of(EmptyClass.self) as! AnyClassMetadata

        expect(lhs.isRelated(to: rhs)) == .same
        expect(rhs.isRelated(to: lhs)) == .same
    }

    func testRelationshipChild_2() {
        let sut = Metadata.of(ChildOfChildOfEmptyClass.self) as! AnyClassMetadata
        let parent = Metadata.of(ChildOfEmptyClass.self) as! AnyClassMetadata
        let grandparent = Metadata.of(EmptyClass.self) as! AnyClassMetadata

        expect(sut.isRelated(to: parent)) == .child
        expect(sut.isRelated(to: grandparent)) == .child
    }

    func testRelationshipParent() {
        let sut = Metadata.of(EmptyClass.self) as! AnyClassMetadata
        let child = Metadata.of(ChildOfEmptyClass.self) as! AnyClassMetadata
        let grandchild = Metadata.of(ChildOfChildOfEmptyClass.self) as! AnyClassMetadata

        expect(sut.isRelated(to: child)) == .parent
        expect(sut.isRelated(to: grandchild)) == .parent
    }

    func testRelationshipUnrelated() {
        let lhs = Metadata.of(EmptyClass.self) as! AnyClassMetadata
        let rhs = Metadata.of(BaseClassForRealisticallyLookingProtocol.self) as! AnyClassMetadata

        expect(lhs.isRelated(to: rhs)) == .unrelated
        expect(rhs.isRelated(to: lhs)) == .unrelated
    }
}
