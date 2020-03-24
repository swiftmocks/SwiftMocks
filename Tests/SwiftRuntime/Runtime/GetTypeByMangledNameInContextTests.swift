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
@testable import AnotherModule
@testable import SwiftMocks

class GetTypeTests: XCTestCase {
    func testBuiltinType() {
        let type = Runtime.getNonGenericTypeByMangledName(name: "ss6UInt64V13SIMD64StorageV")
        expect(type) == UInt64.SIMD64Storage.self
    }

    func testNonGenericType() {
        let type = Runtime.getNonGenericTypeByMangledName(name: "ss6UInt64V13SIMD64StorageV")
        expect(type) == UInt64.SIMD64Storage.self
    }

    func testGenericTypeWithParentFromAnotherModule() {
        class Child<T, V>: InternalEmptyClassFromAnotherModule {}

        let metadata = Metadata.of(Child<Int, Float>.self) as! ClassMetadata
        let cd = metadata.typeContextDescriptor
        print(String(cString: cd.superclassTypeMangledName!))
        let type = Runtime.getTypeByMangledNameInContext(name: cd.superclassTypeMangledName!, contextDescriptor: cd, genericArguments: metadata.genericArgumentsPointer)
        expect(type) == InternalEmptyClassFromAnotherModule.self
    }

    func testGenericType() {
        class Parent<T> {}
        class Child<T, V>: Parent<T> {}

        let metadata = Metadata.of(Child<Int, Float>.self) as! ClassMetadata
        let cd = metadata.typeContextDescriptor
        let type = Runtime.getTypeByMangledNameInContext(name: cd.superclassTypeMangledName!, contextDescriptor: cd, genericArguments: metadata.genericArgumentsPointer)
        expect(type) == Parent<Int>.self
    }
}
