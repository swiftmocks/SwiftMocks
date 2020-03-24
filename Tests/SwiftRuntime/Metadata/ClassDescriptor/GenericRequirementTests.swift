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

class GenericRequirementTests: XCTestCase {
    func testGenericRequirementCount() {
        class F: EmptyClass, EmptyProtocol {}
        class G<T : AnyObject, U: EmptyProtocol, W: Equatable> where U: EmptyClass {}

        let description = (Metadata.of(G<F, F, String>.self) as! ClassMetadata).description
        let requirements = description.genericRequirements!
        expect(requirements).to(haveCount(4))
    }

    func testGenericRequirementProtocol_Swift() {
        class C<T> where T: EmptyProtocol {}
        class E: EmptyProtocol {}

        let description = (Metadata.of(C<E>.self) as! ClassMetadata).description

        let req: GenericRequirementDescriptor = description.genericRequirements![0]
        if case let .protocol(descriptor) = req.kind {
            expect(descriptor).toNot(beNil())
            expect(descriptor?.name) == "EmptyProtocol"
        } else {
            fail("Expected kind to equal .protocol")
        }
        let _ = String(describing: req)
    }

    func testGenericRequirementProtocol_ObjC() {
        class C<T> where T: EmptyObjCProtocol {}
        class E: EmptyObjCProtocol {}

        let description = (Metadata.of(C<E>.self) as! ClassMetadata).description

        let req: GenericRequirementDescriptor = description.genericRequirements![0]
        if case let .protocol(descriptor) = req.kind {
            expect(descriptor).to(beNil())
        } else {
            fail("Expected kind to equal .protocol")
        }
        let _ = String(describing: req)
    }

    func testGenericRequirementSameType() {
        class G<T: Sequence, U> where T.Element == U {}

        let metadata: ClassMetadata = Metadata.of(G<[String], String>.self) as! ClassMetadata
        let requirements = metadata.description.genericRequirements!

        if case let .protocol(descriptor) = requirements[0].kind {
            expect(descriptor?.name) == "Sequence"
        } else {
            fail("Expected kind == .protocol(Sequence)")
        }
        if case let .sameType(name) = requirements[1].kind {
            let ty = Runtime.getTypeByMangledNameInContext(name: name, contextDescriptor: metadata.typeContextDescriptor, genericArguments: metadata.genericArgumentsPointer)
            expect(ty) == String.self
        } else {
            fail("Expected kind == .sameType(Element)")
        }

        let _ = String(describing: requirements)
    }

    func testGenericRequirementBaseClass() {
        class Element<V> {}
        class G<V, T : Element<V>> {}

        let metadata: ClassMetadata = Metadata.of(G<Int, Element<Int>>.self) as! ClassMetadata

        let req = metadata.description.genericRequirements![0]
        if case let .baseClass(name) = req.kind {
            let ty = Runtime.getTypeByMangledNameInContext(name: name, contextDescriptor: metadata.typeContextDescriptor, genericArguments: metadata.genericArgumentsPointer)
            expect(ty) == Element<Int>.self
        } else {
            fail("Expected kind to equal .baseClass")
        }
        let _ = String(describing: req)
    }

    func testGenericRequirementLayout() {
        class G<T : AnyObject> {}

        let req = (Metadata.of(G<EmptyClass>.self) as! ClassMetadata).description.genericRequirements![0]

        if case let .layout(layoutKind) = req.kind {
            expect(layoutKind) == .class
        } else {
            fail("Expected kind to equal .layout(.class)")
        }
        let _ = String(describing: req)
    }
}
