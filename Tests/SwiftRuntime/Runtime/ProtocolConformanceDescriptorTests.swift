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
import ResilientFixtures
import AnotherModule
import SwiftMocks
@testable import RuntimeTestFixtures

class ProtocolConformanceDescriptorTests: XCTestCase {
    func testSimple() {
        class C: ProtocolWithFiveMethods {
            func method_0() {}
            func method_1() {}
            func method_2() {}
            func method_3() {}
            func method_4() {}
        }
        let instance = C()
        var existential: ProtocolWithFiveMethods = instance
        let witnessTables = OpaqueExistentialBox(&existential, numberOfWitnessTables: 1).witnessTables

        let witnessTable = witnessTables[0]
        let conformanceDescriptor = witnessTable.descriptor
        expect(conformanceDescriptor.protocol.name) == "ProtocolWithFiveMethods"
        guard case let .typeDescriptor(typeDescriptor) = conformanceDescriptor.typeReference else {
            fail()
            return
        }
        expect(typeDescriptor) == Metadata.of(C.self).typeContextDescriptor
        expect(conformanceDescriptor.flags.isRetroactive) == false
        expect(conformanceDescriptor.flags.isSynthesizedNonUnique) == false
        expect(conformanceDescriptor.flags.numberOfConditionalRequirements) == 0
        expect(conformanceDescriptor.flags.hasResilientWitnesses) == false
        expect(conformanceDescriptor.flags.hasGenericWitnessTable) == false

        let _ = String(describing: witnessTables)
    }

    func testResilient() {
        class C: ResilientRealisticallyLookingProtocol {
            init(prop: ResilientOutsideParent) {
                self.prop = prop
            }
            var prop: ResilientOutsideParent
            func someFunc() {}
            static func someStaticFunc() {}
        }
        var existential: ResilientRealisticallyLookingProtocol = C(prop: ResilientOutsideParent())
        let witnessTable = OpaqueExistentialBox(&existential, numberOfWitnessTables: 1).witnessTables[0]
        let conformanceDescriptor = witnessTable.descriptor
        expect(conformanceDescriptor.protocol.name) == "ResilientRealisticallyLookingProtocol"
        guard case let .typeDescriptor(typeDescriptor) = conformanceDescriptor.typeReference else {
            fail()
            return
        }
        expect(typeDescriptor) == Metadata.of(C.self).typeContextDescriptor
        expect(conformanceDescriptor.flags.isRetroactive) == false
        expect(conformanceDescriptor.flags.isSynthesizedNonUnique) == false
        expect(conformanceDescriptor.flags.numberOfConditionalRequirements) == 0
        expect(conformanceDescriptor.flags.hasResilientWitnesses) == true
        expect(conformanceDescriptor.flags.hasGenericWitnessTable) == true

        expect(conformanceDescriptor.resilientWitnesses).to(haveCount(5))
        expect(conformanceDescriptor.genericWitnessTable).toNot(beNil())

        let _ = String(describing: witnessTable)
    }

    func testRetroactive() {
        var existential: EmptyProtocolFromAnotherModule = EmptyClassFromAnotherModule()
        let witnessTable = OpaqueExistentialBox(&existential, numberOfWitnessTables: 1).witnessTables[0]
        let conformanceDescriptor = witnessTable.descriptor
        expect(conformanceDescriptor.protocol.name) == "EmptyProtocolFromAnotherModule"
        guard case let .typeDescriptor(typeDescriptor) = conformanceDescriptor.typeReference else {
            fail()
            return
        }
        expect(typeDescriptor) == Metadata.of(EmptyClassFromAnotherModule.self).typeContextDescriptor
        expect(conformanceDescriptor.flags.isRetroactive) == true
        expect(conformanceDescriptor.flags.isSynthesizedNonUnique) == false
        expect(conformanceDescriptor.flags.numberOfConditionalRequirements) == 0
        expect(conformanceDescriptor.flags.hasResilientWitnesses) == false
        expect(conformanceDescriptor.flags.hasGenericWitnessTable) == false

        expect(conformanceDescriptor.retroactiveContext).to(beAKindOf(ModuleContextDescriptor.self))

        let _ = String(describing: witnessTable)
    }

    func testHasGenericWitnessTable() {
        var existential: ResilientEmptyProtocol = ResilientOutsideParent()
        let witnessTable = OpaqueExistentialBox(&existential, numberOfWitnessTables: 1).witnessTables[0]
        let conformanceDescriptor = witnessTable.descriptor
        expect(conformanceDescriptor.protocol.name) == "ResilientEmptyProtocol"
        guard case let .typeDescriptor(typeDescriptor) = conformanceDescriptor.typeReference else {
            fail()
            return
        }
        expect(typeDescriptor) == Metadata.of(ResilientOutsideParent.self).typeContextDescriptor
        expect(conformanceDescriptor.flags.isRetroactive) == true
        expect(conformanceDescriptor.flags.isSynthesizedNonUnique) == false
        expect(conformanceDescriptor.flags.numberOfConditionalRequirements) == 0
        expect(conformanceDescriptor.flags.hasResilientWitnesses) == false
        expect(conformanceDescriptor.flags.hasGenericWitnessTable) == true // see note for ConformanceFlags.hasGenericWitnessTable

        expect(conformanceDescriptor.retroactiveContext).to(beAKindOf(ModuleContextDescriptor.self))
        print(conformanceDescriptor.retroactiveContext!)

        let _ = String(describing: witnessTable)
    }

    func testConditional() {
        var existential: EmptyProtocol = GenericParentClass<Float>()
        let witnessTable = OpaqueExistentialBox(&existential, numberOfWitnessTables: 1).witnessTables[0]
        let conformanceDescriptor = witnessTable.descriptor
        expect(conformanceDescriptor.protocol.name) == "EmptyProtocol"
        guard case let .typeDescriptor(typeDescriptor) = conformanceDescriptor.typeReference else {
            fail()
            return
        }
        expect(typeDescriptor) == Metadata.of(GenericParentClass<Float>.self).typeContextDescriptor
        expect(conformanceDescriptor.flags.isRetroactive) == true
        expect(conformanceDescriptor.flags.isSynthesizedNonUnique) == false
        expect(conformanceDescriptor.flags.numberOfConditionalRequirements) == 1
        expect(conformanceDescriptor.flags.hasResilientWitnesses) == false
        expect(conformanceDescriptor.flags.hasGenericWitnessTable) == false

        expect(conformanceDescriptor.genericRequirements).to(haveCount(1))
        guard case .sameType = conformanceDescriptor.genericRequirements[0].kind else { fail(); return }

        let _ = String(describing: witnessTable)
    }
}

extension ResilientOutsideParent: ResilientEmptyProtocol {}
extension GenericParentClass: EmptyProtocol where T == Float {}
extension EmptyClassFromAnotherModule: EmptyProtocolFromAnotherModule {}
