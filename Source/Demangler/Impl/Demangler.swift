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

struct Demangler {
    var scanner: ScalarScanner<StringRef>
    var nodeStack: [Node] = []
    var substitutions: [Node] = []
    var words: [String] = []
    var symbolicReferences: [Int32] = []
    var isOldFunctionTypeMangling: Bool = false
    var symbolicReferenceResolver: ((SymbolicReferenceKind, Directness, ConstRawPointer) throws -> Node)? = nil

    init(mangledName: String) {
        notImplemented()
        // scanner = ScalarScanner(scalars: mangledName.unicodeScalars)
    }

    init(mangledName: ConstPointer<CChar>, length: Int) {
        scanner = ScalarScanner(scalars: StringRef(pointer: mangledName, length: length))
    }

    mutating func demangleSymbol() throws -> Node {
        // Old-style class and protocol are not supported...
        if nextIf("_Tt") {
            try throwFailure("Old-style class and protocol names are not supported")
        }
        // ... and neither are old-style functions
        if nextIf("_T") {
            try throwFailure("Old function type mangling is not supported")
        }

        guard let _ = manglingPrefixes.first(where: { nextIf($0) }) else {
            try throwFailure("Unknown mangling prefix")
        }

        try parseAndPushNodes()

        var topLevel = Node(kind: .Global)
        var parentIndex: Int? = nil
        while let funcAttr = pop(where: { $0.isFunctionAttr }) {
            if let parentIndex = parentIndex {
                topLevel.children[parentIndex].children.append(funcAttr)
            } else {
                topLevel.children.append(funcAttr)
            }
            if funcAttr.kind == .PartialApplyForwarder || funcAttr.kind == .PartialApplyObjCForwarder {
                parentIndex = topLevel.children.count - 1
            }
        }

        if let parentIndex = parentIndex {
            for node in nodeStack {
                switch node.kind {
                case .Type: topLevel.children[parentIndex].children.append(node.children[0])
                default: topLevel.children[parentIndex].children.append(node)
                }
            }
        } else {
            for node in nodeStack {
                switch node.kind {
                case .Type: topLevel.children.append(node.children[0])
                default: topLevel.children.append(node)
                }
            }
        }

        try require(topLevel.children.count > 0)

        return topLevel
    }

    /// Demangle the given symbol and return the parse tree.
    ///
    /// \param MangledName The mangled type string, which does _not_ start with
    /// the mangling prefix $S.
    mutating func demangleType() throws -> Node {
        try parseAndPushNodes()
        if let result = pop() {
            return result
        }
        
        return Node(kind: .Suffix, payload: .Text(String(String.UnicodeScalarView(scanner.scalars))))
    }

    mutating func addSubstitution(_ node: Node) {
        substitutions.append(node)
    }
}
