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
@testable import MocksFixtures
@testable import SwiftMocks

class MachOTests: XCTestCase {
    let image = MachImage.allExcludingKnownSystemPaths.first { $0.filename.hasSuffix("MocksFixtures") }!

    func testDefinedSymbols() {
        continueAfterFailure = false
        let symbols = image.definedSymbols(in: MachSection.dataSection) + image.definedSymbols(in: MachSection.textSection) + image.definedSymbols(in: MachSection.textConstSection)
        expect(symbols).toNot(beEmpty())
        expect(symbols.map { $0.name }).to(contain("_$s13MocksFixtures12voidFunctionyyFTX"))
        let maybeSwiftSymbols: [MachSymbol] = symbols.filter({ $0.name.hasPrefix("_$")})
        expect(maybeSwiftSymbols).toNot(beEmpty())
        var totalTests = 0
        for symbol in maybeSwiftSymbols {
            let dlsymed = simpleDlsym(String(symbol.name.dropFirst()))
            if let dlsymed = dlsymed {
                // some things are not dlsymable
                expect(dlsymed) == symbol.pointer
                totalTests += 1
            }
        }
        expect(totalTests) != 0
        print("totalTests: \(totalTests)")
    }

    func testInterestingImages() {
        let interestingImages = MachImage.allExcludingKnownSystemPaths
        expect(interestingImages).toNot(beEmpty())
    }
}
