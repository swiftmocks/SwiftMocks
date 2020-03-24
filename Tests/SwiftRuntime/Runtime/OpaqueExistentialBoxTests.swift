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

class OpaqueExistentialBoxTests: XCTestCase {
    func testOneProtocol() {
        class C: EmptyProtocol {}
        let instance = C()
        var existential: EmptyProtocol = instance
        let box = OpaqueExistentialBox(&existential, numberOfWitnessTables: 1)

        expect(box.container.buffer.asRawPointers[0]) == Unmanaged.passUnretained(instance).toOpaque()
        expect(box.container.type) == Metadata.of(C.self)
        expect(box.witnessTables).to(haveCount(1))
        expect(box.witnessTables[0].descriptor.protocol.name) == "EmptyProtocol"

        let _ = String(describing: box)
    }

    func testTwoProtocols() {
        class C2: EmptyProtocol, AnotherEmptyProtocol {}
        let instance = C2()
        var existential: EmptyProtocol & AnotherEmptyProtocol = instance
        let box = OpaqueExistentialBox(&existential, numberOfWitnessTables: 2)

        expect(box.container.buffer.asRawPointers[0]) == Unmanaged.passUnretained(instance).toOpaque()
        expect(box.container.type) == Metadata.of(C2.self)
        expect(box.witnessTables).to(haveCount(2))
        // XXX: The ordering doesn't match the declaration order
        let protocolNames: [String] = box.witnessTables.map { $0.descriptor.protocol.name }
        expect(protocolNames).to(contain("EmptyProtocol"))
        expect(protocolNames).to(contain("AnotherEmptyProtocol"))

        let _ = String(describing: box)
    }

    func testTwoProtocolsWithInlineFittingStruct() {
        struct S: EmptyProtocol, AnotherEmptyProtocol {
            let a: Int
            let b: Int
            let c: Int
        }
        let instance = S(a: 100, b: 101, c: 102)
        var existential: EmptyProtocol & AnotherEmptyProtocol = instance
        let box = OpaqueExistentialBox(&existential, numberOfWitnessTables: 2)

        expect(box.container.projected) == box.pointer
        expect(BufferPointer(start: box.container.projected.reinterpret(Int.self), count: 3).map { $0 }) == [100, 101, 102]
        expect(box.container.buffer.asInts[0]) == 100
        expect(box.container.buffer.asInts[1]) == 101
        expect(box.container.buffer.asInts[2]) == 102
        expect(box.container.type) == Metadata.of(S.self)
        expect(box.witnessTables).to(haveCount(2))

        let _ = String(describing: box)
    }

    func testTwoProtocolsWithOutOfLineStruct() {
        struct S: EmptyProtocol, AnotherEmptyProtocol {
            let a: Int
            let b: Int
            let c: Int
            let d: Int
        }
        let instance = S(a: 100, b: 101, c: 102, d: 103)
        var existential: EmptyProtocol & AnotherEmptyProtocol = instance
        let box = OpaqueExistentialBox(&existential, numberOfWitnessTables: 2)

        expect(box.container.projected) == box.container.buffer.asRawPointers[0] + 16 /* heap object header size - this is runtime-private constant */
        expect(BufferPointer(start: box.container.projected.reinterpret(Int.self), count: 4).map { $0 }) == [100, 101, 102, 103]
        let heapObjectMetadata = Metadata.from(box.container.buffer.asRawPointers[0].reinterpret(RawPointer.self).pointee)
        expect(heapObjectMetadata).to(beAKindOf(HeapLocalVariableMetadata.self)) // see note in Metadata.create()
        expect(box.container.type) == Metadata.of(S.self)
        expect(box.witnessTables).to(haveCount(2))

        let _ = String(describing: box)
    }

    func testAnyExistentialBox() {
        struct S: EmptyProtocol {}
        let instance = S()
        let existential: EmptyProtocol = instance
        var any: Any = existential
        let box = AnyExistentialBox(&any)
        expect(box.container.type) == Metadata.of(S.self)
    }
}
