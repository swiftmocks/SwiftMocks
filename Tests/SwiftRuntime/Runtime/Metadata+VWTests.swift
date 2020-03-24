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

class Metadata_VWTests: XCTestCase {
    var storage: RawPointer!

    override func setUp() {
        storage = RawPointer.allocateWithZeroFill(size: 4096, alignment: 16)
    }

    override func tearDown() {
        storage.deallocate()
        storage = nil
    }

    func testInt() {
        let value = 4
        Metadata.of(type(of: value)).initialize(storage, withCopyOf: value)
        let rt = Metadata.of(type(of: value)).copy(from: storage)
        expect(rt) ~= value
    }

    func testString() {
        let value = "\(self)"
        Metadata.of(type(of: value)).initialize(storage, withCopyOf: value)
        let rt = Metadata.of(type(of: value)).copy(from: storage)
        expect(rt) ~= value
    }

    func testSmallStruct() {
        struct S: Equatable {
            let a: UInt8
            let b: UInt16
        }
        let value = S(a: 123, b: 456)
        Metadata.of(type(of: value)).initialize(storage, withCopyOf: value)
        let rt = Metadata.of(type(of: value)).copy(from: storage)
        expect(rt) ~= value
    }

    func testStructBiggerThanInlineStorageOfAny() {
        struct S: Equatable {
            let a: Int
            let b: Int
            let c: Int
            let d: Int
        }
        let value = S(a: 12, b: 13, c: 14, d: 15)
        Metadata.of(type(of: value)).initialize(storage, withCopyOf: value)
        let rt = Metadata.of(type(of: value)).copy(from: storage)
        expect(rt) ~= value
    }

    func testStructWithReferences() {
        struct S {
            var obj: AnyObject
            weak var weakObj: AnyObject?
        }
        var instance0: AnyObject? = EmptyClass()
        var instance1: AnyObject? = RealisticallyLoookingClass()
        let value = S(obj: instance0!, weakObj: instance1!)
        Metadata.of(type(of: value)).initialize(storage, withCopyOf: value)
        let rt = Metadata.of(type(of: value)).copy(from: storage)
        expect((rt as! S).obj) === instance0
        expect((rt as! S).weakObj) === instance1

        instance0 = nil
        instance1 = nil

        expect(value.obj).toNot(beNil())
        expect((rt as! S).obj).toNot(beNil())

        expect(value.weakObj).to(beNil())
        expect((rt as! S).weakObj).to(beNil())
    }

    func testClass() {
        class C {
            var a: String
            init(_ a: String) {
                self.a = a
            }
        }
        let value = C("\(self)")
        Metadata.of(type(of: value)).initialize(storage, withCopyOf: value)
        let rt = Metadata.of(type(of: value)).copy(from: storage)
        expect((rt as! C).a) == value.a
        expect(rt) === value
    }

    func testSimpleError() {
        enum E: Error, Equatable {
            case a
            case b
        }
        let value = E.a
        Metadata.of(type(of: value)).initialize(storage, withCopyOf: value)
        let rt = Metadata.of(type(of: value)).copy(from: storage)
        expect(rt) ~= value
    }

    func testSimpleErrorPassedAsAny() {
        enum E: Error, Equatable {
            case a
            case b
        }
        let value: Any = E.a
        Metadata.of(type(of: value)).initialize(storage, withCopyOf: value)
        let rt = Metadata.of(type(of: value)).copy(from: storage)
        expect(rt).to(beAKindOf(E.self))
    }
}
