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
//
// This source file contains code developed by Swift open source project,
// licensed under Apache License v2.0 with Runtime Library Exception. For
// licensing information, see https://swift.org/LICENSE.txt

import Foundation

class Remangler {
    var buffer = String()
    var words = [SubstitutionWord]()
    var substitutions = [SubstitutionEntry]()
    var substMerging = SubstitutionMerging()
    let resolver: Mangle.SymbolicResolver

    init(resolver: @escaping Mangle.SymbolicResolver) {
        self.resolver = resolver
        buffer.reserveCapacity(512)
    }

    func mangle(_ node: Node) {
        mangleImpl(node)
    }
}
