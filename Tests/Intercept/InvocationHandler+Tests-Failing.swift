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
@testable import IR
@testable import SwiftMocks

class InvocationHandler_Globals_Tests_Failing: XCTestCase {
    /// These currently fail as far as exact SIL signature is concerned. Runtime doesn't distinguish between indirect no-payload enums and "direct" no-payload enums, and so can't we. This means that for those enums, where we should be seeing `@guaranteed` on the parameters of their types, we see the default (direct unowned). This does not matter in practice since both get lowered to IR in exactly the same way.
    func wontfix_testIndirectNoPayloadEnums() {
        verifySignature("___753")
        verifySignature("___756")
        verifySignature("___757")
    }
}
