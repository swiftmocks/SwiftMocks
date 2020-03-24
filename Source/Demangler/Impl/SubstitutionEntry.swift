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

func == (lhs: SubstitutionEntry, rhs: SubstitutionEntry) -> Bool {
    if lhs.storedHash != rhs.storedHash {
      return false
    }
    if lhs.treatAsIdentifier != rhs.treatAsIdentifier {
      return false
    }
    if lhs.treatAsIdentifier {
        return SubstitutionEntry.identifierEquals(lhs: lhs.node, rhs: rhs.node)
    }
    return SubstitutionEntry.deepEquals(lhs: lhs.node, rhs: rhs.node)
}

struct SubstitutionEntry: Equatable {
    typealias HashType = UInt

    let node: Node
    let storedHash: HashType
    let treatAsIdentifier: Bool

    init(node: Node, treatAsIdentifier: Bool) {
        self.node = node
        self.treatAsIdentifier = treatAsIdentifier
        let hasher = Hasher(node: node, treatAsIdentifier: treatAsIdentifier)
        self.storedHash = hasher.hash
    }

    fileprivate static func identifierEquals(lhs: Node, rhs: Node) -> Bool {
        let length = lhs.text.count
        if rhs.text.count != length {
            return false
        }
        // The fast path.
        if lhs.kind == rhs.kind {
            return lhs.text == rhs.text
        }
        // The slow path.
        for i in 0..<length {
            if getCharOfNodeText(lhs, idx: i) != getCharOfNodeText(rhs, idx: i) {
                return false
            }
        }
        return true
    }

    fileprivate static func deepEquals(lhs: Node, rhs: Node) -> Bool {
        if lhs.kind != rhs.kind {
            return false
        }
        if lhs.hasIndex {
            if !rhs.hasIndex {
                return false
            }
            if lhs.index != rhs.index {
                return false
            }
        } else if lhs.hasText {
            if !rhs.hasText {
                return false
            }
            if lhs.text != rhs.text {
                return false
            }
        } else if rhs.hasIndex || rhs.hasText {
            return false
        }

        for i in 0..<lhs.children.count {
            if !deepEquals(lhs: lhs.children[i], rhs: rhs.children[i]) {
                return false
            }
        }
        return true
    }

    struct Hasher {
        let treatAsIdentifier: Bool
        var hash: HashType = 0

        init(node: Node, treatAsIdentifier: Bool) {
            self.treatAsIdentifier = treatAsIdentifier
            deepHash(node: node)
        }

        private mutating func combineHash(_ newValue: HashType) {
            hash = 33 &* hash &+ newValue
        }

        private mutating func deepHash(node: Node) {
            if treatAsIdentifier {
                combineHash(HashType(Node.Kind.Identifier.rawValue))
                precondition(node.hasText)
                switch node.kind {
                case .InfixOperator: fallthrough
                case .PrefixOperator: fallthrough
                case .PostfixOperator:
                    for c in node.text.unicodeScalars {
                        combineHash(HashType(c.translatingToOperatorChar.value))
                    }
                    return
                default: break
                }
            } else {
                combineHash(HashType(node.kind.rawValue))
            }
            if node.hasIndex {
                combineHash(HashType(node.index))
            } else if node.hasText {
                for c in node.text.unicodeScalars {
                    combineHash(HashType(c.value))
                }
            }
            for child in node.children {
                deepHash(node: child)
            }
        }
    }
}

private func getCharOfNodeText(_ node: Node, idx: Int) -> UnicodeScalar {
    let text = node.text.unicodeScalars
    let ch = text[text.index(text.startIndex, offsetBy: idx)]
    switch node.kind {
    case .InfixOperator: fallthrough
    case .PrefixOperator: fallthrough
    case .PostfixOperator:
        return ch.translatingToOperatorChar
    default:
        return ch
    }
}
