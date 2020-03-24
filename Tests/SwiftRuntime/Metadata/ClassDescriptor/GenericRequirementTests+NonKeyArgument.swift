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

private enum F<T> where T: NSCopying {}

extension EmptyClass: NSCopying {
    public func copy(with zone: NSZone? = nil) -> Any { nil! }
}

class GenericRequirementTests_NonKeyArgument: XCTestCase {
    func testHasKeyArgument_Not() {
        let d = Metadata.of(F<EmptyClass>.self).typeContextDescriptor!
        expect(d.genericRequirements?.first!.hasKeyArgument) == false
        expect(d.genericRequirements?.first!.hasExtraArgument) == false
    }

    // https://medium.com/@slavapestov/the-secret-life-of-types-in-swift-ff83c3c000a5
}
