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

private func function1() {}

typealias ccFunction = @convention(c) () -> ()

private func functionThatThrows() throws {}

private func functionWithParameterFlags(_ a: inout EmptyClass, _ b: @autoclosure () -> String, etc: Int...) throws {}

private func functionThatReturnsValue() -> EmptyClass { nil! }

private class ClassWithMethods {
    func method(a: Int, b: inout EmptyClass) {}
}

class FunctionMetadataTests: XCTestCase {
    func testMetadata() {
        let metadata = Metadata.of(type(of: function1)) as! FunctionTypeMetadata
        expect(metadata.flags.numberOfParameters) == 0
        expect(metadata.flags.convention) == .swift
        expect(metadata.flags.throws) == false
        expect(metadata.flags.isEscaping) == true
        expect(metadata.flags.hasParameterFlags) == false
        expect(metadata.parameters).to(haveCount(0))
        let _ = String(describing: metadata)
    }

    func testConventionC() {
        let metadata = Metadata.of(ccFunction.self) as! FunctionTypeMetadata
        expect(metadata.flags.convention) == .cFunctionPointer
        let _ = String(describing: metadata)
    }

    func testThrows() {
        let metadata = Metadata.of(type(of: functionThatThrows)) as! FunctionTypeMetadata
        expect(metadata.flags.`throws`) == true
        let _ = String(describing: metadata)
    }

    func testParameterFlags() {
        let metadata = Metadata.of(type(of: functionWithParameterFlags)) as! FunctionTypeMetadata
        let flags = metadata.parameterFlags
        expect(flags[0].ownership) == .inOut
        expect(flags[1].isAutoclosure) == true
        expect(flags[2].isVariadic) == true
        let _ = String(describing: metadata)
    }

    func testResult() {
        let metadata = Metadata.of(type(of: functionThatReturnsValue)) as! FunctionTypeMetadata
        expect(metadata.resultType).to(beAKindOf(ClassMetadata.self))
        expect(metadata.resultType.typeContextDescriptor?.name) == "EmptyClass"
        let _ = String(describing: metadata)
    }

    func testMethod() {
        let metadata = Metadata.of(type(of: ClassWithMethods.method)) as! FunctionTypeMetadata
        // methods are curried functions
        expect(metadata.parameters).to(haveCount(1))
        expect(metadata.parameters[0].asAnyType) == ClassWithMethods.self
        let uncurried = metadata.resultType as! FunctionTypeMetadata
        expect(uncurried.flags.numberOfParameters) == 2
        expect(uncurried.flags.isEscaping) == true
        expect(uncurried.flags.convention) == .swift
        expect(uncurried.flags.hasParameterFlags) == true
        expect(uncurried.parameters[0].asAnyType) == Int.self
        expect(uncurried.parameters[1].asAnyType) == EmptyClass.self
    }
}
