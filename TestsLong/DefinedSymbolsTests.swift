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
@testable import SwiftMocks

class DefinedSymbolsTests: XCTestCase {
    func testDefinedSymbols() { // FIXME: either complete or remove
        let symbols = MachImage.all.flatMap { $0.definedSymbols(in: MachSection.dataSection) }
        let maybeSwiftSymbols = symbols.filter({ $0.name.hasPrefix("_$")})

        var totalTests = 0
        var undlsymable = 0
        for symbol in maybeSwiftSymbols {
            if let dlsymResult = simpleDlsym(String(symbol.name.dropFirst())) {
                expect(dlsymResult) == symbol.pointer
                totalTests += 1
            } else {
                undlsymable += 1
                let name = String(symbol.name.dropFirst())
//                if name.hasSuffix("MI") || // type metadata instantiation cache
//                    name.hasSuffix("Wp") || // protocol witness table pattern
//                    name.hasSuffix("WL") || // lazy protocol witness table cache variable
//                    name.hasSuffix("ML") // lazy cache variable for type metadata
//                {
//                    continue
//                }
                let p = symbol.pointer
                let dladdred = simpleDladdr(p)
                expect(dladdred) == name
            }
        }

        expect(maybeSwiftSymbols).toNot(beEmpty())
        expect(totalTests) != 0
        print("dlsymable: \(totalTests), undlsymable: \(undlsymable), total: \(totalTests + undlsymable)")
    }
}
