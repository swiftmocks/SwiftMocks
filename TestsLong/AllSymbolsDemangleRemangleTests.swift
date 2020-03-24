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

class SdkSymbolsTests: XCTestCase {
    func testAllSymbolsWeCanFind() {
        var successes = 0
        var demanglingErrors = 0
        var remanglingErrorItems = [String]()

        let images = MachImage.all
        let allSymbols = images.flatMap { $0.definedSymbols(in: MachSection.textSection, MachSection.dataSection, MachSection.textConstSection) }.compactMap { $0.name.hasPrefix("_$") ? String($0.name.dropFirst()) : nil }
        for symbol in allSymbols {
            let expectedDemangled = Runtime.demangle(symbol)
            if expectedDemangled == nil || expectedDemangled == symbol {
                continue
            }

            do {
                let node: Node = try Mangle.demangleSymbol(mangledName: symbol)
                let demangled = node.description
                expect(demangled) == expectedDemangled

                let remangled = Mangle.mangleNode(node: node)
                // expect(remangled) == symbol

                if demangled == expectedDemangled {
                    successes += 1
                } else {
                    demanglingErrors += 1
                }
                // there is a bug in the remangler, see `todo_test_$s10Foundation4DataV15replaceSubrange_4withySnySiG_xtSlRzs5UInt8V7ElementRtzlFySpySo28_ConditionalAllocationBufferaGXEfU_s15EmptyCollectionVyAHG_Tgq5TA_dot_414`, so we don't count those errors.
                if remangled != symbol {
                    remanglingErrorItems.append(symbol)
                }
            } catch {
                demanglingErrors += 1
                fail(String(describing: error) + ": \(symbol)")
            }
        }
        print("successes: \(successes)")
        print("errors: \(demanglingErrors)")
        expect(demanglingErrors) == 0

        /// at the time of writing, there are 21 errors with remanglings of .PartialApplyForwarder and `xyz.resume.0` coroutines
        expect(remanglingErrorItems).to(haveCount(21))
    }
}
