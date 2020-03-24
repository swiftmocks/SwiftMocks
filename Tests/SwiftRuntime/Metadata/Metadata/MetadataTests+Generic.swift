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
@testable import SwiftMocks

private class Empty {}

private class C<T, U: Equatable & Comparable> {}
private struct S<T, U: Equatable & Comparable> {}
private enum E<T, U: Equatable & Comparable> {}

private let genericTypes: [Any.Type] = [C<Empty, String>.self, S<Empty, String>.self, E<Empty, String>.self]
private let genericTypeMetadatas = genericTypes.map { Metadata.of($0) }

class MetadataTests_Generic: XCTestCase {
    func testGenericArguments() {
        for metadata in genericTypeMetadatas {
            let genericArguments = metadata.genericParameters
            expect(genericArguments).to(haveCount(2))

            expect(genericArguments[0]).to(beAKindOf(ClassMetadata.self))
            expect(genericArguments[0].typeContextDescriptor!.name) == "Empty"
            expect(genericArguments[1]).to(beAKindOf(StructMetadata.self))
            expect(genericArguments[1].typeContextDescriptor!.name) == "String"
        }
    }

}
