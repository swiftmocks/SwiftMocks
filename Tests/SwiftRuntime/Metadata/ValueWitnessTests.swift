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

private protocol Foo: class {}

class ValueWitnessTests: XCTestCase {
    func testClass() {
        class C {}

        let vw = Metadata.of(C.self).valueWitnesses
        verify(vw, size: 8, stride: 8, isPOD: false, isBitwiseTakable: true)
    }

    func testEmptyStruct() {
        struct S {}

        let vw = Metadata.of(S.self).valueWitnesses
        verify(vw, size: 0, stride: 1, isPOD: true, isBitwiseTakable: true)
    }

    func testPODStruct() {
        struct S { var a = 1; var b: Double }

        let vw = Metadata.of(S.self).valueWitnesses
        verify(vw, size: 16, stride: 16, isPOD: true, isBitwiseTakable: true)
    }

    func testStructWithString_NotPODButBitwiseTakable() {
        struct S {
            var a = ""
        }

        let vw = Metadata.of(S.self).valueWitnesses
        verify(vw, size: MemoryLayout<String>.size, stride: MemoryLayout<String>.stride, isPOD: false, isBitwiseTakable: true)
    }

    func testWeakStruct_NotPODNotBitwiseTakable() {
        struct S {
            weak var a: Foo?
        }

        let vw = Metadata.of(S.self).valueWitnesses
        verify(vw, size: 16 /* Optional<> */, stride: 16, isPOD: false, isBitwiseTakable: false)
    }

    func testEmptyEnum() {
        enum E {}

        let vw = Metadata.of(E.self).valueWitnesses
        verify(vw, size: 0, stride: 1, isPOD: true, isBitwiseTakable: true, hasEnumWitnesses: false)
    }

    func testSingleCaseEnum() {
        enum E { case a }

        let vw = Metadata.of(E.self).valueWitnesses
        verify(vw, size: 0, stride: 1, isPOD: true, isBitwiseTakable: true, hasEnumWitnesses: true)
    }

    func testSimpleEnum() {
        enum E { case a; case b }

        let vw = Metadata.of(E.self).valueWitnesses
        verify(vw, size: 1, stride: 1, isPOD: true, isBitwiseTakable: true, hasEnumWitnesses: true)
    }

    func testEnumWithBaseType() {
        enum E: UInt { case a; case b }

        let vw = Metadata.of(E.self).valueWitnesses
        verify(vw, size: 1, stride: 1, isPOD: true, isBitwiseTakable: true, hasEnumWitnesses: true)
    }

    func testEnumWithPayload() {
        enum E { case a(String); case b(Int16) }

        let vw = Metadata.of(E.self).valueWitnesses
        verify(vw, size: 17, stride: 24, isPOD: false, isBitwiseTakable: true, hasEnumWitnesses: true)
    }

    func testEnumWithIndirectCase() {
        enum E { case a; indirect case b(E) }

        let vw = Metadata.of(E.self).valueWitnesses
        verify(vw, size: 8, stride: 8, isPOD: false, isBitwiseTakable: true, hasEnumWitnesses: true)
    }

    func testOptional() {
        class C { var a = 1; var b = ""; var c = 2.0 }
        struct S { var a = 1; var b = ""; var c = 2.0 }

        verify(Metadata.of(Optional<C>.self).valueWitnesses, size: 8, stride: 8, isPOD: false, isBitwiseTakable: true, hasEnumWitnesses: true)
        verify(Metadata.of(Optional<S>.self).valueWitnesses, size: 32, stride: 32, isPOD: false, isBitwiseTakable: true, hasEnumWitnesses: true)
    }

    func testTuple() {
        typealias T = (Int, String)

        verify(Metadata.of(T.self).valueWitnesses, size: 24, stride: 24, isPOD: false, isBitwiseTakable: true)
    }

    func testProtocol() {
        let vw = Metadata.of(EmptyProtocol.self).valueWitnesses
        verify(vw, size: 40, stride: 40, isPOD: false, isBitwiseTakable: true)
    }

    func testNumberOfExtraInhabitants() {
        class C {}
        struct S0 {}
        struct S1 { let a: UInt }
        struct S2 { let a: String; let c: Int8; let b: UInt }
        enum E0 {}
        enum E1 { case a }
        enum E2: UInt { case a; case b }
        enum E3 { case a(String) }
        enum E4 { case a(String); case b(Int16); case c(Int8) }

        expect(Metadata.of(C.self).valueWitnesses.numberOfExtraInhabitants) == 0x7fffffff
        expect(Metadata.of(S0.self).valueWitnesses.numberOfExtraInhabitants) == 0
        expect(Metadata.of(S1.self).valueWitnesses.numberOfExtraInhabitants) == 0
        expect(Metadata.of(S2.self).valueWitnesses.numberOfExtraInhabitants) == 0x7fffffff
        expect(Metadata.of(E0.self).valueWitnesses.numberOfExtraInhabitants) == 0
        expect(Metadata.of(E1.self).valueWitnesses.numberOfExtraInhabitants) == 0
        expect(Metadata.of(E2.self).valueWitnesses.numberOfExtraInhabitants) == 254
        expect(Metadata.of(E3.self).valueWitnesses.numberOfExtraInhabitants) == 0x7fffffff
        expect(Metadata.of(E4.self).valueWitnesses.numberOfExtraInhabitants) == 253
    }

    func verify(_ vw: ValueWitnessTable, size: ValueWitnessSize, stride: ValueWitnessStride, isPOD: Bool, isBitwiseTakable: Bool, hasEnumWitnesses: Bool = false, file: FileString = #file, line: UInt = #line) {
        expect(vw.size, file: file, line: line) == size
        expect(vw.stride, file: file, line: line) == stride
        expect(vw.isPOD, file: file, line: line) == isPOD
        expect(vw.isBitwiseTakable, file: file, line: line) == isBitwiseTakable
        expect(vw.hasEnumWitnesses, file: file, line: line) == hasEnumWitnesses
    }
}
