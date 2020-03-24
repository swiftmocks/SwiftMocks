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

class OpaqueTypeDescriptorTests: XCTestCase {

    func _testFoo() {
        let red5 = launchFighter()
        let metadata = Metadata.of(type(of: red5))
        print(metadata)
        let mt = Metadata.of(type(of: launchFighter.self))
        print(mt)
        print()
    }
}
