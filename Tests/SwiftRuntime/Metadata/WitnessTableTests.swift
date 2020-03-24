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

class WitnessTableTests: XCTestCase {
    func testRealWitnessTable() {
        class C: ProtocolWithFiveMethods {
            func method_0() {}
            func method_1() {}
            func method_2() {}
            func method_3() {}
            func method_4() {}
        }
        var existential: ProtocolWithFiveMethods = C()
        let witnessTable = OpaqueExistentialBox(&existential, numberOfWitnessTables: 1).witnessTables[0]
        for i in 0..<5 {
            expect(simpleDladdr(witnessTable.witnesses[i])?.hasSuffix("FTW")) == true
        }
    }

    func `testWitnessWithDefaultImplementation_StillPointsToWitnessFunc`() {
        class C: ProtocolWithDefaultImplementation {}
        var existential: ProtocolWithDefaultImplementation = C()
        let witnessTable = OpaqueExistentialBox(&existential, numberOfWitnessTables: 1).witnessTables[0]
        expect(simpleDladdr(witnessTable.witnesses[0])?.hasSuffix("FTW")) == true
    }
}

internal func simpleDladdr(_ pointer: RawPointer?) -> String? {
    var dlinfo = Dl_info()
    dladdr(pointer, &dlinfo)
    guard let cString = dlinfo.dli_sname else { return nil }
    return String(cString: cString)
}
