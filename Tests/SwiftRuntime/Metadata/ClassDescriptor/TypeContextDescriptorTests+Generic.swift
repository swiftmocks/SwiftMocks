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

private class C<T, U: Equatable & Comparable> {}
private struct S<T, U: Equatable & Comparable> {}
private enum E<T, U: Equatable & Comparable> {}

private let genericTypes: [Any.Type] = [C<EmptyClass, String>.self, S<EmptyClass, String>.self, E<EmptyClass, String>.self]
private let genericTypeMetadatas = genericTypes.map { Metadata.of($0) }
private let typeGenericTypeDescriptors = genericTypes.map { Metadata.of($0).typeContextDescriptor! }

class TypeContextDescriptorTests_Generic: XCTestCase {
    func testTypeGenericContextDescriptors() {
        for description in typeGenericTypeDescriptors {
            expect(description.isGeneric) == true

            expect(description.numberOfGenericParameters) == 2
            expect(description.numberOfGenericRequirements) == 1

            let genericParams = description.genericParams
            expect(genericParams).to(haveCount(2))
            verify(genericParams[0], hasKeyArgument: true, hasExtraArgument: false)
            verify(genericParams[1], hasKeyArgument: true, hasExtraArgument: false)

            let genericRequirements = description.genericRequirements
            expect(genericRequirements).to(haveCount(1))
        }
    }

    private func verify(_ param: GenericParamDescriptor, hasKeyArgument: Bool, hasExtraArgument: Bool, kind: GenericParamKind = .type /* there are no others */, file: FileString = #file, line: UInt = #line) {
        expect(param.hasKeyArgument) == hasKeyArgument
        expect(param.hasExtraArgument) == hasExtraArgument
        expect(param.kind) == kind
    }
}
