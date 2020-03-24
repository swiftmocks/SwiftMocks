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

private class Empty {}

class TypeContextDescriptorTests: XCTestCase {
    func testNumImmediateMembers_Empty() {
        class C {}

        let metadata = classMetadata(type: C.self)
        let description = metadata.description
        // only init here, dealloc is trivial and must have been optimised out
        expect(description.numImmediateMembers) == 1
        expect(description.vtableSize) == 1
        let _ = String(describing: metadata)
    }

    func testNumImmediateMembers_Var() {
        class C { var a = 42 }

        let metadata = classMetadata(type: C.self)
        // getter + setter + modify + allocating_init
        expect(metadata.description.vtableSize) == 4
        expect(metadata.vtable).to(haveCount(4))
        expect(metadata.description.numImmediateMembers) == 5
        let _ = String(describing: metadata)
    }

    func testFieldOffsets() {
        class OneVar { var a = 42 }
        class TwoVars { var a = 1; var b = 2; }
        class FourVars { var a: UInt8 = 1; var b: UInt8 = 2; var c: UInt16 = 3; var d: UInt64 = 4 }

        expect(classMetadata(type: OneVar.self).fieldOffsets).to(haveCount(1))
        expect(classMetadata(type: TwoVars.self).fieldOffsets).to(haveCount(2))
        expect(classMetadata(type: FourVars.self).fieldOffsets).to(haveCount(4))
        expect(classMetadata(type: FourVars.self).fieldOffsets) == [0, 1, 2, 8 /* XXX why not 4? */].map { 16 + $0 }
    }

    func testName() {
        let metadata = Metadata.of(Empty.self) as! ClassMetadata
        expect(metadata.description.name) == "Empty"
        let _ = String(describing: metadata)
    }

    func testFieldsEmpty() {
        class ClassWithoutAnyVars {}

        let metadata = Metadata.of(ClassWithoutAnyVars.self) as! ClassMetadata
        expect(metadata.description.fieldDescriptor?.numberOfFields) == 0
        expect(metadata.description.fields).to(beEmpty())
        let _ = String(describing: metadata)
    }

    func testFields_Class() {
        class Parent<T> { var foo: T? }
        class Child<T, V>: Parent<T> { var bar: V?; let baz = "" }

        let metadata: Metadata = Metadata.of(Child<Int, Float>.self)
        let fields = metadata.typeContextDescriptor!.fields
        expect(fields).to(haveCount(2))
        verify(fields[0], contextDescriptor: metadata.typeContextDescriptor, genericArguments: metadata.genericArgumentsPointer, name: "bar", type: Float?.self, isVar: true)
        verify(fields[1], contextDescriptor: metadata.typeContextDescriptor, genericArguments: metadata.genericArgumentsPointer, name: "baz", type: String.self, isVar: false)
        let _ = String(describing: metadata)
    }

    func testFields_Struct() {
        struct S { let a = 1; var b = 2.0 }

        let metadata: Metadata = Metadata.of(S.self)
        let fields = metadata.typeContextDescriptor!.fields
        expect(fields).to(haveCount(2))
        verify(fields[0], contextDescriptor: metadata.typeContextDescriptor, genericArguments: metadata.genericArgumentsPointer, name: "a", type: Int.self, isVar: false)
        verify(fields[1], contextDescriptor: metadata.typeContextDescriptor, genericArguments: metadata.genericArgumentsPointer, name: "b", type: Double.self, isVar: true)
        let _ = String(describing: metadata)
    }

    func testFields_Enum() {
        enum E { case foo; case bar; indirect case baz(E) }

        let metadata: Metadata = Metadata.of(E.self)
        let fields = metadata.typeContextDescriptor!.fields
        expect(fields).to(haveCount(3))
        verify(fields[0], contextDescriptor: metadata.typeContextDescriptor, genericArguments: metadata.genericArgumentsPointer, name: "baz", type: E.self, isVar: false, isIndirectEnumCase: true)
        verify(fields[1], contextDescriptor: metadata.typeContextDescriptor, genericArguments: metadata.genericArgumentsPointer, name: "foo", type: nil, isVar: false, isIndirectEnumCase: false)
        verify(fields[2], contextDescriptor: metadata.typeContextDescriptor, genericArguments: metadata.genericArgumentsPointer, name: "bar", type: nil, isVar: false, isIndirectEnumCase: false)
        let _ = String(describing: metadata)
    }

    private func verify(_ field: FieldRecord, contextDescriptor: ContextDescriptor?, genericArguments: BufferPointer<RawPointer>?, name: String, type: Any.Type?, isVar: Bool, isIndirectEnumCase: Bool = false, file: FileString = #file, line: UInt = #line) {
        if let type = type {
            expect(field.resolveType(contextDescriptor: contextDescriptor, genericArguments: genericArguments)) == type
        } else {
            expect(field.resolveType(contextDescriptor: contextDescriptor, genericArguments: genericArguments)).to(beNil())
        }
        expect(field.name) == name
        expect(field.isVar) == isVar
        expect(field.isIndirectEnumCase) == isIndirectEnumCase
    }
}

func classMetadata<T>(type: T.Type) -> ClassMetadata {
    Metadata.of(type) as! ClassMetadata
}
