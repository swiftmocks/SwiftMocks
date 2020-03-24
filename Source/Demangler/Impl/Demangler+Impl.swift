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

let maxRepeatCount = 2048
let maxNumWords = 26

let manglingPrefixes = [
    "_T0", /*Swift 4*/
    "$S", "_$S", /*Swift 4.x*/
    "$s", "_$s" /*Swift 5+*/
]

func -(lhs: UnicodeScalar, rhs: UnicodeScalar) -> Int { Int(lhs.value) - Int(rhs.value) }

func +(lhs: Int, rhs: UnicodeScalar) -> Int { lhs + Int(rhs.value) }

private enum DemangleGenericRequirementTypeKind { case Generic, Assoc, CompoundAssoc, Substitution }

private enum DemangleGenericRequirementConstraintKind { case `Protocol`, BaseClass, SameType, Layout }

private enum DemangleFunctionEntityArgs { case None, TypeAndMaybePrivateName, TypeAndIndex, Index }

extension Node {
    init(kind: Kind, child: Node) {
        self.init(kind: kind, children: [child], payload: .None)
    }

    init(typeWithChildKind: Kind, childChildren: [Node]) {
        self.init(kind: .Type, children: [Node(kind: typeWithChildKind, children: childChildren)], payload: .None)
    }

    init(typeWithChildKind: Kind, childChild: Node) {
        self.init(typeWithChildKind: typeWithChildKind, childChildren: [childChild])
    }

    init(swiftStdlibTypeKind: Kind, name: String) {
        self.init(kind: .Type, children: [Node(kind: swiftStdlibTypeKind, children: [
            Node(kind: .Module, payload: .Text(STDLIB_NAME)),
            Node(kind: .Identifier, payload: .Text(name))
        ])], payload: .None)
    }

    internal init(swiftBuiltinType: Kind, name: String) {
        self.init(kind: .Type, children: [Node(kind: swiftBuiltinType, payload: .Text(name))])
    }

    init(kind: Kind, payload: PayloadKind) {
        self.kind = kind
        self.payload = payload
        self.children = []
    }

    var hasText: Bool { if case .Text = payload { return true } else { return false } }
    var text: String { if case let .Text(text) = payload { return text } else { fatalError("Expected text to not be nil") } }

    var hasIndex: Bool { if case .Index = payload { return true } else { return false } }
    var index: IndexType { if case let .Index(index) = payload { return index } else { fatalError("Expected index to not be nil") } }

    mutating func reverseChildren(startingAt: Int) {
        children = children.prefix(startingAt) + children.suffix(from: startingAt).reversed()
    }

    func changingChild(_ newChild: Node?, atIndex: Int) -> Node {
        guard children.indices.contains(atIndex) else { return self }

        var modifiedChildren = children
        if let nc = newChild {
            modifiedChildren[atIndex] = nc
        } else {
            modifiedChildren.remove(at: atIndex)
        }
        return Node(kind: kind, children: modifiedChildren, payload: payload)
    }

    func changingKind(_ newKind: Kind, additionalChildren: [Node] = []) -> Node {
        if case .Text(let text) = payload {
            return Node(kind: newKind, children: children + additionalChildren, payload: .Text(text))
        } else if case .Index(let i) = payload {
            return Node(kind: newKind, children: children + additionalChildren, payload: .Index(i))
        } else {
            return Node(kind: newKind, children: children + additionalChildren, payload: .None)
        }
    }

    func child(ofKind kind: Kind) -> Node? {
        children.first(where: { $0.kind == kind })
    }
}

extension Demangler {
    func require<T>(_ optional: Optional<T>) throws -> T {
        if let v = optional {
            return v
        } else {
            try throwFailure()
        }
    }

    func require(_ value: Bool) throws {
        if !value {
            try throwFailure()
        }
    }

    var failure: Error {
        return scanner.unexpectedError()
    }

    func throwFailure() throws -> Never {
        throw failure
    }

    func throwFailure(_ message: String) throws -> Never {
        throw DemanglerError.someError(message)
    }
}

extension Demangler {
    mutating func nextChar() throws -> UnicodeScalar {
        try scanner.readScalar()
    }

    mutating func nextIf(_ unicodeScalar: UnicodeScalar) -> Bool {
        scanner.conditional(scalar: unicodeScalar)
    }

    mutating func nextIf(_ string: String) -> Bool {
        scanner.conditional(string: string)
    }

    mutating func peekChar() throws -> UnicodeScalar {
        try scanner.requirePeek()
    }

    mutating func pushBack() throws {
        try scanner.backtrack()
    }
}

private enum DemanglerError: Error { case someError(String) }

extension Array {
    func at(_ index: Int) -> Element? {
        return self.indices.contains(index) ? self[index] : nil
    }
    func slice(_ from: Int, _ to: Int) -> ArraySlice<Element> {
        if from > to || from > self.endIndex || to < self.startIndex {
            return ArraySlice()
        } else {
            return self[(from > self.startIndex ? from : self.startIndex)..<(to < self.endIndex ? to : self.endIndex)]
        }
    }
}

extension Demangler {
    mutating func parseAndPushNodes() throws {
        while !scanner.isAtEnd {
            nodeStack.append(try demangleOperator())
        }
    }

    mutating func demangleTypeMangling() throws -> Node {
        let type = try require(pop(kind: .Type))
        if let labelList = try popFunctionParamLabels(type: type) {
            return Node(kind: .TypeMangling, children: [labelList, type])
        }
        return Node(kind: .TypeMangling, children: [type])
    }

    mutating func demangleSymbolicReference(rawKind: UInt8) throws -> Node {
        // The symbolic reference is a 4-byte machine integer encoded in the following four bytes.
        let value = try scanner.readPointer()

        // Map the encoded kind to a specific kind and directness.
        let kind: SymbolicReferenceKind
        let direct: Directness
        switch (rawKind) {
        case 1:
            kind = .Context
            direct = .Direct
        case 2:
            kind = .Context
            direct = .Indirect
        case 9:
            kind = .AccessorFunctionReference
            direct = .Direct
        default:
            try throwFailure()
        }

        // Use the resolver, if any, to produce the demangling tree the symbolic reference represents.
        // With no resolver, or a resolver that failed, refuse to demangle further.
        guard let resolved = try symbolicReferenceResolver?(kind, direct, value) else {
            try throwFailure()
        }

        // Types register as substitutions even when symbolically referenced.
        if (kind == .Context && resolved.kind != .OpaqueTypeDescriptorSymbolicReference) {
            addSubstitution(resolved)
        }
        return resolved
    }

    mutating func demangleOperator() throws -> Node {
        // A 0xFF byte is used as alignment padding for symbolic references
        // when the platform toolchain has alignment restrictions for the
        // relocations that form the reference value. It can be skipped.
        while try peekChar() == "\u{FF}" {
            let _ = try nextChar()
        }
        let c = try nextChar()
        switch c {
        case "\u{0}"..."\u{C}": return try demangleSymbolicReference(rawKind: UInt8(c.value))
        case "A": return try demangleMultiSubstitutions()
        case "B": return try demangleBuiltinType()
        case "C": return try demangleAnyGenericType(kind: .Class)
        case "D": return try demangleTypeMangling()
        case "E": return try demangleExtensionContext()
        case "F": return try demanglePlainFunction()
        case "G": return try demangleBoundGenericType()
        case "H":
            let c2 = try nextChar()
            switch c2 {
            case "A": return try demangleDependentProtocolConformanceAssociated()
            case "C": return try demangleConcreteProtocolConformance()
            case "D": return try demangleDependentProtocolConformanceRoot()
            case "I": return try demangleDependentProtocolConformanceInherited()
            case "P":
                return try Node(kind: .ProtocolConformanceRefInTypeModule, child: popProtocol())
            case "p":
                return try Node(kind: .ProtocolConformanceRefInProtocolModule, child: popProtocol())
            default:
                try pushBack()
                try pushBack()
                return try demangleIdentifier()
            }

        case "I": return try demangleImplFunctionType()
        case "K": return Node(kind: .ThrowsAnnotation)
        case "L": return try demangleLocalIdentifier()
        case "M": return try demangleMetatype()
        case "N": return Node(kind: .TypeMetadata, child:
            try require(pop(kind: .Type)))
        case "O": return try demangleAnyGenericType(kind: .Enum)
        case "P": return try demangleAnyGenericType(kind: .Protocol)
        case "Q": return try demangleArchetype()
        case "R": return try demangleGenericRequirement()
        case "S": return try demangleStandardSubstitution()
        case "T": return try demangleThunkOrSpecialization()
        case "V": return try demangleAnyGenericType(kind: .Structure)
        case "W": return try demangleWitness()
        case "X": return try demangleSpecialType()
        case "Z": return Node(kind: .Static, child: try require(pop(where: { $0.isEntity })))
        case "a": return try demangleAnyGenericType(kind: .TypeAlias)
        case "c": return try popFunctionType(kind: .FunctionType)
        case "d": return Node(kind: .VariadicMarker)
        case "f": return try demangleFunctionEntity()
        case "g": return try demangleRetroactiveConformance()
        case "h": return Node(typeWithChildKind: .Shared, childChild: try require(popTypeAndGetChild()))
        case "i": return try demangleSubscript()
        case "l": return try demangleGenericSignature(hasParamCounts: false)
        case "m": return Node(typeWithChildKind: .Metatype, childChild: try require(pop(kind: .Type)))
        case "n":
            return Node(typeWithChildKind: .Owned, childChild: try popTypeAndGetChild())
        case "o": return try demangleOperatorIdentifier()
        case "p": return try demangleProtocolListType()
        case "q": return Node(kind: .Type, child: try demangleGenericParamIndex())
        case "r": return try demangleGenericSignature(hasParamCounts: true)
        case "s": return Node(kind: .Module, payload: .Text(STDLIB_NAME))
        case "t": return try popTuple()
        case "u": return try demangleGenericType()
        case "v": return try demangleVariable()
        case "w": return try demangleValueWitness()
        case "x": return Node(kind: .Type, child: try getDependentGenericParamType(depth: 0, index: 0))
        case "y": return Node(kind: .EmptyList)
        case "z": return Node(typeWithChildKind: .InOut, childChild: try popTypeAndGetChild())
        case "_": return Node(kind: .FirstElementMarker)
        case ".":
            // IRGen still uses ".<n>" to disambiguate partial apply thunks and
            // outlined copy functions. We treat such a suffix as "unmangled suffix".
            try pushBack()
            return Node(kind: .Suffix, payload: .Text(scanner.remainder()))
        default:
            try pushBack()
            return try demangleIdentifier()
        }
    }

    mutating func demangleNatural() throws -> Int {
        if try !peekChar().isDigit {
            return -1000
        }
        var num = 0
        while true {
            let c = try peekChar()
            if !c.isDigit {
                return num
            }
            let newNum = (10 * num) + (c - "0")
            if newNum < num {
                return -1000
            }
            num = newNum
            _ = try nextChar()
        }
    }

    mutating func demangleIndex() throws -> Int {
        if nextIf("_") {
            return 0
        }
        let num = try require(demangleNatural())
        if num >= 0 && nextIf("_") {
            return Int(num + 1)
        }
        try throwFailure()
    }

    mutating func demangleIndexAsNode() throws -> Node { Node(kind: .Number, payload: .Index(UInt64(try demangleIndex()))) }

    mutating func demangleMultiSubstitutions() throws -> Node {
        var repeatCount = -1
        while true {
            let c = try nextChar()
            if (c == "\u{0}") {
                // End of text.
                try throwFailure()
            }
            if c.isLower {
                // It"s a substitution with an index < 26.
                let nd = try pushMultiSubstitutions(repeatCount: repeatCount, index: Int(c.value - UnicodeScalar("a").value))
                nodeStack.append(nd)
                repeatCount = -1
                // A lowercase letter indicates that there are more substitutions to
                // follow.
                continue
            } else if c.isUpper {
                // The last substitution.
                return try pushMultiSubstitutions(repeatCount: repeatCount, index: Int(c.value - UnicodeScalar("A").value))
            } else if (c == "_") {
                // The previously demangled number is actually not a repeat count but
                // the large (> 26) index of a substitution. Because it"s an index we
                // have to add 27 and not 26.
                let idx = repeatCount + 27
                if idx >= substitutions.count {
                    try throwFailure()
                }
                return substitutions[idx]
            }
            try pushBack()
            // Not a letter? Then it can only be a natural number which might be the
            // repeat count or a large (> 26) substitution index.
            repeatCount = Int(try require(demangleNatural()))
            try require(repeatCount >= 0)
        }
    }

    mutating func pushMultiSubstitutions(repeatCount: Int, index: Int) throws -> Node {
        try require(index < substitutions.count)
        try require(repeatCount <= maxRepeatCount)
        let node = try require(substitutions.at(index))
        if repeatCount > 1 {
            for _ in 0..<repeatCount - 1 {
                nodeStack.append(node)
            }
        }
        return node
    }

    mutating func demangleStandardSubstitution() throws -> Node {
        switch try nextChar() {
        case "o": return Node(kind: .Module, payload: .Text(MANGLING_MODULE_OBJC))
        case "C": return Node(kind: .Module, payload: .Text(MANGLING_MODULE_CLANG_IMPORTER))
        case "g":
            let optionalTy = Node(typeWithChildKind: .BoundGenericEnum, childChildren: [Node(swiftStdlibTypeKind: .Enum, name: "Optional"), Node(kind: .TypeList, child: try require(pop(kind: .Type)))])
            addSubstitution(optionalTy)
            return optionalTy
        default:
            try pushBack()
            let repeatCount = try demangleNatural()
            try require(repeatCount <= maxRepeatCount)
            let node = try createStandardSubstitution(Subst: try nextChar())
            if repeatCount > 1 {
                for _ in 0..<(repeatCount-1) {
                    nodeStack.append(node)
                }
            }
            return node
        }
    }

    private func createStandardSubstitution(Subst: UnicodeScalar) throws -> Node {
        // see generators
        if Subst == "A".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("AutoreleasingUnsafeMutablePointer"))])) }
        if Subst == "a".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("Array"))])) }
        if Subst == "b".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("Bool"))])) }
        if Subst == "c".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("UnicodeScalar"))])) }
        if Subst == "D".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("Dictionary"))])) }
        if Subst == "d".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("Double"))])) }
        if Subst == "f".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("Float"))])) }
        if Subst == "h".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("Set"))])) }
        if Subst == "I".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("DefaultIndices"))])) }
        if Subst == "i".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("Int"))])) }
        if Subst == "J".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("Character"))])) }
        if Subst == "N".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("ClosedRange"))])) }
        if Subst == "n".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("Range"))])) }
        if Subst == "O".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("ObjectIdentifier"))])) }
        if Subst == "P".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("UnsafePointer"))])) }
        if Subst == "p".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("UnsafeMutablePointer"))])) }
        if Subst == "R".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("UnsafeBufferPointer"))])) }
        if Subst == "r".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("UnsafeMutableBufferPointer"))])) }
        if Subst == "S".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("String"))])) }
        if Subst == "s".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("Substring"))])) }
        if Subst == "u".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("UInt"))])) }
        if Subst == "V".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("UnsafeRawPointer"))])) }
        if Subst == "v".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("UnsafeMutableRawPointer"))])) }
        if Subst == "W".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("UnsafeRawBufferPointer"))])) }
        if Subst == "w".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("UnsafeMutableRawBufferPointer"))])) }
        if Subst == "q".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Enum, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("Optional"))])) }
        if Subst == "B".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("BinaryFloatingPoint"))])) }
        if Subst == "E".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("Encodable"))])) }
        if Subst == "e".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("Decodable"))])) }
        if Subst == "F".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("FloatingPoint"))])) }
        if Subst == "G".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("RandomNumberGenerator"))])) }
        if Subst == "H".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("Hashable"))])) }
        if Subst == "j".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("Numeric"))])) }
        if Subst == "K".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("BidirectionalCollection"))])) }
        if Subst == "k".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("RandomAccessCollection"))])) }
        if Subst == "L".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("Comparable"))])) }
        if Subst == "l".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("Collection"))])) }
        if Subst == "M".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("MutableCollection"))])) }
        if Subst == "m".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("RangeReplaceableCollection"))])) }
        if Subst == "Q".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("Equatable"))])) }
        if Subst == "T".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("Sequence"))])) }
        if Subst == "t".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("IteratorProtocol"))])) }
        if Subst == "U".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("UnsignedInteger"))])) }
        if Subst == "X".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("RangeExpression"))])) }
        if Subst == "x".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("Strideable"))])) }
        if Subst == "Y".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("RawRepresentable"))])) }
        if Subst == "y".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("StringProtocol"))])) }
        if Subst == "Z".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("SignedInteger"))])) }
        if Subst == "z".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(STDLIB_NAME)), Node(kind: .Identifier, payload: .Text("BinaryInteger"))])) }
        try throwFailure()
    }

    mutating func demangleIdentifier() throws -> Node {
        var hasWordSubsts = false
        var isPunycoded = false
        let c = try peekChar()
        try require(c.isDigit)
        if (c == "0") {
            _ = try nextChar()
            if try peekChar() == "0" {
                _ = try nextChar()
                isPunycoded = true
            } else {
                hasWordSubsts = true
            }
        }

        var identifier = ""
        repeat {
            while try hasWordSubsts && peekChar().isLetter == true {
                let c = try nextChar()
                var wordIdx = 0
                if (c.isLower) {
                    wordIdx = Int(c.value - UnicodeScalar("a").value)
                } else {
                    try require(c.isUpper)
                    wordIdx = Int(c.value - UnicodeScalar("A").value)
                    hasWordSubsts = false
                }
                try require(wordIdx < words.count)
                try require(wordIdx < maxNumWords)
                let slice = try require(words.at(wordIdx))
                identifier.append(slice)
            }
            if nextIf("0") {
                break
            }
            let numChars = try require(demangleNatural())
            try require(numChars > 0)
            if isPunycoded {
                _ = nextIf("_")
            }
            let slice = try scanner.readScalars(count: Int(numChars))
            if (isPunycoded) {
                guard let decoded = decodeSwiftPunycode(slice) else {
                    fatalError("Failed to decode punycode: \(slice)")
                }
                identifier.append(decoded)
            } else {
                identifier.append(slice)
                var wordStartPos = -1
                let end = slice.count
                for idx in 0...end {
                    let currentIndex = slice.index(slice.startIndex, offsetBy: idx)
                    let c = idx < end ? slice.unicodeScalars[currentIndex] : "\u{0}"
                    if wordStartPos >= 0 && c.isWordEnd(prevCh: slice.unicodeScalars[slice.index(before: currentIndex)]) {
                        if idx - wordStartPos >= 2 && words.count < maxNumWords {
                            let start = slice.index(slice.startIndex, offsetBy: wordStartPos)
                            let end = slice.index(start, offsetBy: idx - wordStartPos)
                            let word = String(slice[start..<end])
                            words.append(word)
                        }
                        wordStartPos = -1
                    }
                    if wordStartPos < 0 && c.isWordStart {
                        wordStartPos = idx
                    }
                }
            }
        } while hasWordSubsts

        try require(!identifier.isEmpty)
        let ident = Node(kind: .Identifier, payload: .Text(identifier))
        addSubstitution(ident)
        return ident
    }

    mutating func demangleOperatorIdentifier() throws -> Node {
        let ident = try require(pop(kind: .Identifier))
        let opCharTable = Array("& @/= >    <*!|+?%-~   ^ .".unicodeScalars)

        var opStr = ""
        for c in (try require(ident.text)).unicodeScalars {
            if !c.isASCII {
                // Pass through Unicode characters.
                opStr.unicodeScalars.append(c)
                continue
            }
            try require(c.isLower)
            let o = opCharTable[c - "a"]
            opStr.unicodeScalars.append(o)
        }
        switch try nextChar() {
        case "i": return Node(kind: .InfixOperator, payload: .Text(opStr))
        case "p": return Node(kind: .PrefixOperator, payload: .Text(opStr))
        case "P": return Node(kind: .PostfixOperator, payload: .Text(opStr))
        default: try throwFailure()
        }
    }

    mutating func demangleLocalIdentifier() throws -> Node {
        if (nextIf("L")) {
            let discriminator = try require(pop(kind: .Identifier))
            let name = try require(pop(where: { $0.isDeclName }))
            return Node(kind: .PrivateDeclName, children: [ discriminator, name])
        }
        if (nextIf("l")) {
            let discriminator = try require(pop(kind: .Identifier))
            return Node(kind: .PrivateDeclName, child: discriminator)
        }
        if try ((peekChar() >= "a" && peekChar() <= "j") ||
            (peekChar() >= "A" && peekChar() <= "J")) {
            let relatedEntityKind = try nextChar()
            let kindNd = Node(kind: .Identifier, payload: .Text(String(relatedEntityKind)))
            let name = try require(pop())
            let result = Node(kind: .RelatedEntityDeclName, children: [kindNd, name])
            return result
        }
        let discriminator = try require(demangleIndexAsNode())
        let name = try require(pop(where: { $0.isDeclName }))
        return Node(kind: .LocalDeclName, children: [discriminator, name])
    }

    mutating func demangleBuiltinType() throws -> Node {
        let maxTypeSize = 4096 // a very conservative upper bound
        switch try nextChar() {
        case "b": return Node(swiftBuiltinType: .BuiltinTypeName, name: "Builtin.BridgeObject")
        case "B": return Node(swiftBuiltinType: .BuiltinTypeName, name: "Builtin.UnsafeValueBuffer")
        case "f":
            let size = try demangleIndex() - 1
            try require(size > 0 && size < maxTypeSize)
            let name = "Builtin.FPIEEE\(size)"
            return Node(swiftBuiltinType: .BuiltinTypeName, name: name)
        case "i":
            let size = try demangleIndex() - 1
            try require(size > 0 && size < maxTypeSize)
            let name = "Builtin.Int\(size)"
            return Node(swiftBuiltinType: .BuiltinTypeName, name: name)
        case "I":
            return Node(swiftBuiltinType: .BuiltinTypeName, name: "Builtin.IntLiteral")
        case "v":
            let elts = try demangleIndex() - 1
            try require(elts > 0 && elts < maxTypeSize)
            let eltType = try popTypeAndGetChild()
            let text = try require(eltType.text)
            try require(eltType.kind == .BuiltinTypeName && text.starts(with: "Builtin.") == true)
            let name = "Builtin.Vec\(elts)x\(text["Builtin.".endIndex...])"
            return Node(swiftBuiltinType: .BuiltinTypeName, name: name)
        case "O":
            return Node(swiftBuiltinType: .BuiltinTypeName, name: "Builtin.UnknownObject")
        case "o":
            return Node(swiftBuiltinType: .BuiltinTypeName, name: "Builtin.NativeObject")
        case "p":
            return Node(swiftBuiltinType: .BuiltinTypeName, name: "Builtin.RawPointer")
        case "t":
            return Node(swiftBuiltinType: .BuiltinTypeName, name: "Builtin.SILToken")
        case "w":
            return Node(swiftBuiltinType: .BuiltinTypeName, name: "Builtin.Word")
        default: try throwFailure()
        }
    }

    mutating func demangleAnyGenericType(kind: Node.Kind) throws -> Node {
        let name = try require(pop(where: { $0.isDeclName }))
        let ctx = try popContext()
        let type = Node(typeWithChildKind: kind, childChildren: [ctx, name])
        addSubstitution(type)
        return type
    }

    mutating func demangleExtensionContext() throws -> Node {
        let GenSig = pop(kind: .DependentGenericSignature)
        let Module = try require(popModule())
        let Type = try require(popTypeAndGetAnyGeneric())
        if let g = GenSig {
            return Node(kind: .Extension, children: [Module, Type, g])
        }
        return Node(kind: .Extension, children: [Module, Type])
    }

    mutating func demanglePlainFunction() throws -> Node {
        let GenSig = pop(kind: .DependentGenericSignature)
        var Type = try popFunctionType(kind: .FunctionType)
        let LabelList = try popFunctionParamLabels(type: Type)

        if let g = GenSig {
            Type = Node(typeWithChildKind: .DependentGenericType, childChildren: [g, Type])
        }

        let Name = try require(pop(where: { $0.isDeclName }))
        let Ctx = try popContext()

        if let ll = LabelList {
            return Node(kind: .Function, children: [Ctx, Name, ll, Type])
        }

        return Node(kind: .Function, children: [Ctx, Name, Type])
    }

    mutating func demangleRetroactiveProtocolConformanceRef() throws -> Node {
        let module = try require(popModule())
        let proto = try popProtocol()
        return Node(kind: .ProtocolConformanceRefInOtherModule, children: [proto, module])
    }

    mutating func demangleConcreteProtocolConformance() throws -> Node {
        let conditionalConformanceList = try popAnyProtocolConformanceList()

        let conformanceRef = try (
            pop(kind: .ProtocolConformanceRefInTypeModule) ?? pop(kind: .ProtocolConformanceRefInProtocolModule) ?? demangleRetroactiveProtocolConformanceRef())

        let type = try require(pop(kind: .Type))
        return Node(kind: .ConcreteProtocolConformance, children: [type, conformanceRef, conditionalConformanceList])
    }

    mutating func demangleDependentProtocolConformanceRoot() throws -> Node {
        let index = try demangleDependentConformanceIndex()
        let `protocol` = try popProtocol()
        let dependentType = try require(pop(kind: .Type))
        return Node(kind: .DependentProtocolConformanceRoot, children: [dependentType, `protocol`, index])
    }

    mutating func demangleDependentProtocolConformanceInherited() throws -> Node {
        let index = try demangleDependentConformanceIndex()
        let `protocol` = try popProtocol()
        let nested = try popDependentProtocolConformance()
        return Node(kind: .DependentProtocolConformanceInherited, children: [nested, `protocol`, index])
    }

    mutating func demangleDependentProtocolConformanceAssociated() throws -> Node {
        let index = try demangleDependentConformanceIndex()
        let associatedConformance = try popDependentAssociatedConformance()
        let nested = try popDependentProtocolConformance()
        return Node(kind: .DependentProtocolConformanceAssociated, children: [nested, associatedConformance, index])
    }

    mutating func demangleDependentConformanceIndex() throws -> Node {
        let index = try demangleIndex()
        // index < 0 indicates a demangling error.
        // index == 0 is ill-formed by the (originally buggy) use of this production.
        try require(index > 0)

        // index == 1 indicates an unknown index.
        if index == 1 {
            return Node(kind: .UnknownIndex)
        }

        // Remove the index adjustment.
        return Node(kind: .Index, payload: .Index(UInt64(index) - 2))
    }

    mutating func demangleRetroactiveConformance() throws -> Node {
        let index = try demangleIndexAsNode()
        let conformance = try popAnyProtocolConformance()
        return Node(kind: .RetroactiveConformance, children: [index, conformance])
    }

    mutating func demangleBoundGenerics() throws -> (typeList: [Node], retroactiveConformances: Node?) {
        var TypeListList = [Node]()
        var retroactiveConformances: Node?
        while let conformance = pop(kind: .RetroactiveConformance) {
            if retroactiveConformances == nil {
                retroactiveConformances = Node(kind: .TypeList)
            }
            retroactiveConformances?.children.append(conformance)
        }
        retroactiveConformances?.children.reverse()

        while true {
            var tlist = [Node]()
            while let Ty = pop(kind: .Type) {
                tlist.append(Ty)
            }
            tlist.reverse()
            TypeListList.append(Node(kind: .TypeList, children: tlist))

            if pop(kind: .EmptyList) != nil {
                break
            }
            _ = try require(pop(kind: .FirstElementMarker))
        }
        return (TypeListList, retroactiveConformances)
    }

    mutating func demangleBoundGenericType() throws -> Node {
        let (typeList, retroactiveConformances) = try demangleBoundGenerics()

        let nominal = try require(popTypeAndGetAnyGeneric())
        var boundNode = try require(demangleBoundGenericArgs(nominal: nominal, typeLists: typeList, typeListIdx: 0))
        if let retroactiveConformances = retroactiveConformances {
            boundNode.children.append(retroactiveConformances)
        }
        let type = Node(kind: .Type, child: boundNode)
        addSubstitution(type)
        return type
    }

    mutating func demangleBoundGenericArgs(nominal: Node, typeLists: [Node], typeListIdx: Int) throws -> Node {
        var nominal = nominal
        var typeListIdx = typeListIdx

        // TO_apple_DO: This would be a lot easier if we represented bound generic args
        // flatly in the demangling tree, since that"s how they"re mangled and also
        // how the runtime generally wants to consume them.

        try require(typeListIdx < typeLists.count)

        // Associate a context symbolic reference with all remaining generic
        // arguments.
        if nominal.kind == .TypeSymbolicReference || nominal.kind == .ProtocolSymbolicReference {
            let remainingTypeList = typeLists.suffix(from: typeListIdx).reversed().flatMap { $0.children }
            return Node(kind: .BoundGenericOtherNominalType, children: [Node(kind: .Type, child: nominal), Node(kind: .TypeList, children: remainingTypeList)])
        }

        // Generic arguments for the outermost type come first.
        try require(nominal.children.count > 0)

        let context = nominal.children[0]

        let consumesGenericArgs = nodeConsumesGenericArgs(node: nominal)

        let args = typeLists[typeListIdx]

        if consumesGenericArgs {
            typeListIdx += 1
        }

        if typeListIdx < typeLists.count {
            var boundParent: Node
            if (context.kind == .Extension) {
                boundParent = try demangleBoundGenericArgs(nominal: context.children[1], typeLists: typeLists, typeListIdx: typeListIdx)
                boundParent = Node(kind: .Extension, children: [context.children[0], boundParent])
                if (context.children.count == 3) {
                    // Add the generic signature of the extension context.
                    boundParent.children.append(context.children[2])
                }
            } else {
                boundParent = try demangleBoundGenericArgs(nominal: context, typeLists: typeLists, typeListIdx: typeListIdx)
            }
            // Rebuild this type with the new parent type, which may have
            // had its generic arguments applied.
            var newNominal = Node(kind: nominal.kind, child: boundParent)

            // Append remaining children of the origin nominal.
            newNominal.children += nominal.children.dropFirst()
            nominal = newNominal
        }

        if !consumesGenericArgs {
            return nominal
        }

        // If there were no arguments at this level there is nothing left
        // to do.
        if args.children.isEmpty {
            return nominal
        }

        let kind: Node.Kind
        switch nominal.kind {
        case .Class:
            kind = .BoundGenericClass
        case .Structure:
            kind = .BoundGenericStructure
        case .Enum:
            kind = .BoundGenericEnum
        case .Protocol:
            kind = .BoundGenericProtocol
        case .OtherNominalType:
            kind = .BoundGenericOtherNominalType
        case .TypeAlias:
            kind = .BoundGenericTypeAlias
        case .Function,
             .Constructor:
            // Well, not really a nominal type.
            return Node(kind: .BoundGenericFunction, children: [nominal, args])
        default:
            try throwFailure()
        }
        return Node(kind: kind, children: [Node(kind: .Type, child: nominal), args])
    }

    mutating func demangleImplParamConvention() throws -> Node? {
        let attr: String
        switch try nextChar() {
        case "i": attr = "@in"
        case "c": attr = "@in_constant"
        case "l": attr = "@inout"
        case "b": attr = "@inout_aliasable"
        case "n": attr = "@in_guaranteed"
        case "x": attr = "@owned"
        case "g": attr = "@guaranteed"
        case "e": attr = "@deallocating"
        case "y": attr = "@unowned"
        default:
            try pushBack()
            return nil
        }
        return Node(kind: .ImplParameter, child: Node(kind: .ImplConvention, payload: .Text(attr)))
    }

    mutating func demangleImplResultConvention(convKind: Node.Kind) throws -> Node? {
        let attr: String
        switch try nextChar() {
        case "r": attr = "@out"
        case "o": attr = "@owned"
        case "d": attr = "@unowned"
        case "u": attr = "@unowned_inner_pointer"
        case "a": attr = "@autoreleased"
        default:
            try pushBack()
            return nil
        }
        return Node(kind: convKind, child: Node(kind: .ImplConvention, payload: .Text(attr)))
    }

    mutating func demangleImplFunctionType() throws -> Node {
        var type = Node(kind: .ImplFunctionType)

        var genSig = pop(kind: .DependentGenericSignature)
        if let g = genSig, nextIf("P") {
            genSig = g.changingKind(.DependentPseudogenericSignature)
        }

        if nextIf("e") {
            type.children.append(Node(kind: .ImplEscaping))
        }

        let cAttr: String
        switch try nextChar() {
        case "y": cAttr = "@callee_unowned"
        case "g": cAttr = "@callee_guaranteed"
        case "x": cAttr = "@callee_owned"
        case "t": cAttr = "@convention(thin)"
        default: try throwFailure()
        }
        type.children.append(Node(kind: .ImplConvention, payload: .Text(cAttr)))

        let fAttr: String?
        switch try nextChar() {
        case "B": fAttr = "@convention(block)"
        case "C": fAttr = "@convention(c)"
        case "M": fAttr = "@convention(method)"
        case "O": fAttr = "@convention(objc_method)"
        case "K": fAttr = "@convention(closure)"
        case "W": fAttr = "@convention(witness_method)"
        default:
            try pushBack()
            fAttr = nil
        }

        if let fAttr = fAttr {
            type.children.append(Node(kind: .ImplFunctionAttribute, payload: .Text(fAttr)))
        }

        if let genSig = genSig {
            type.children.append(genSig)
        }

        var numTypesToAdd = 0
        while let param = try demangleImplParamConvention() {
            type.children.append(param)
            numTypesToAdd += 1
        }
        while let result = try demangleImplResultConvention(convKind: .ImplResult) {
            type.children.append(result)
            numTypesToAdd += 1
        }
        if nextIf("z") {
            let errorResult = try require(demangleImplResultConvention(convKind: .ImplErrorResult))
            type.children.append(errorResult)
            numTypesToAdd += 1
        }
        try require(nextIf("_"))

        for i in 0..<numTypesToAdd {
            try require(type.children.indices.contains(type.children.count - i - 1))
            type.children[type.children.count - i - 1].children.append(try require(pop(kind: .Type)))
        }
        return Node(typeWithChildKind: .ImplFunctionType, childChildren: type.children)
    }

    mutating func demangleMetatype() throws -> Node {
        func createWithPoppedType(_ kind: Node.Kind) throws -> Node { Node(kind: kind, child: try require(pop(kind: .Type))) }

        switch try nextChar() {
        case "c": return Node(kind: .ProtocolConformanceDescriptor, child: try require(popProtocolConformance()))
        case "f": return try createWithPoppedType(.FullTypeMetadata)
        case "P": return try createWithPoppedType(.GenericTypeMetadataPattern)
        case "a": return try createWithPoppedType(.TypeMetadataAccessFunction)
        case "g": return Node(kind: .OpaqueTypeDescriptorAccessor, child: try require(pop()))
        case "h": return Node(kind: .OpaqueTypeDescriptorAccessorImpl, child: try require(pop()))
        case "j": return Node(kind: .OpaqueTypeDescriptorAccessorKey, child: try require(pop()))
        case "k": return Node(kind: .OpaqueTypeDescriptorAccessorVar, child: try require(pop()))
        case "I": return try createWithPoppedType(.TypeMetadataInstantiationCache)
        case "i": return try createWithPoppedType(.TypeMetadataInstantiationFunction)
        case "r": return try createWithPoppedType(.TypeMetadataCompletionFunction)
        case "l": return try createWithPoppedType(.TypeMetadataSingletonInitializationCache)
        case "L": return try createWithPoppedType(.TypeMetadataLazyCache)
        case "m": return try createWithPoppedType(.Metaclass)
        case "n": return try createWithPoppedType(.NominalTypeDescriptor)
        case "o": return try createWithPoppedType(.ClassMetadataBaseOffset)
        case "p": return Node(kind: .ProtocolDescriptor, child: try require(popProtocol()))
        case "Q": return Node(kind: .OpaqueTypeDescriptor, child: try require(pop()))
        case "S": return Node(kind: .ProtocolSelfConformanceDescriptor, child: try require(popProtocol()))
        case "u": return try createWithPoppedType(.MethodLookupFunction)
        case "U": return try createWithPoppedType(.ObjCMetadataUpdateFunction)
        case "s": return try createWithPoppedType(.ObjCResilientClassStub)
        case "t": return try createWithPoppedType(.FullObjCResilientClassStub)
        case "B": return Node(kind: .ReflectionMetadataBuiltinDescriptor, child: try require(pop(kind: .Type)))
        case "F": return Node(kind: .ReflectionMetadataFieldDescriptor, child: try require(pop(kind: .Type)))
        case "A": return Node(kind: .ReflectionMetadataAssocTypeDescriptor, child: try require(popProtocolConformance()))
        case "C":
            let Ty = try require(pop(kind: .Type))
            try require(Ty.children.first?.kind.isAnyGeneric == true)
            return Node(kind: .ReflectionMetadataSuperclassDescriptor, child: try require(Ty.children.first))
        case "V": return Node(kind: .PropertyDescriptor, child: try require(pop(where: { $0.isEntity })))
        case "X": return try demanglePrivateContextDescriptor()
        default: try throwFailure()
        }
    }

    mutating func demanglePrivateContextDescriptor() throws -> Node {
        switch try nextChar() {
        case "E": return Node(kind: .ExtensionDescriptor, child: try require(popContext()))
        case "M": return Node(kind: .ModuleDescriptor, child: try require(popModule()))
        case "Y": return Node(kind: .AnonymousDescriptor, children: [try require(pop()), try require(popContext())])
        case "X": return Node(kind: .AnonymousDescriptor, child: try require(popContext()))
        case "A": return Node(kind: .AssociatedTypeGenericParamRef, children: [try require(pop(kind: .Type)), try require(popAssocTypePath())])
        default: try throwFailure()
        }
    }

    mutating func demangleArchetype() throws -> Node{
        switch try nextChar() {
        case "a":
            let ident = try require(pop(kind: .Identifier))
            let archeTy = try popTypeAndGetChild()
            let assocTy = Node(typeWithChildKind: .AssociatedTypeRef, childChildren: [archeTy, ident])
            addSubstitution(assocTy)
            return assocTy
        case "O":
            let definingContext = try require(popContext())
            return Node(kind: .OpaqueReturnTypeOf, child: definingContext)
        case "o":
            let index = try demangleIndex()
            let (boundGenericArgs, retroactiveConformances) = try demangleBoundGenerics()
            let name = try require(pop())
            var opaque = Node(kind: .OpaqueType, children: [name, Node(kind: .Index, payload: .Index(UInt64(index)))])
            let boundGenerics = Node(kind: .TypeList, children: boundGenericArgs.reversed())
            opaque.children.append(boundGenerics)
            if let retroactiveConformances = retroactiveConformances {
                opaque.children.append(retroactiveConformances)
            }

            let opaqueTy = Node(kind: .Type, child: opaque)
            addSubstitution(opaqueTy)
            return opaqueTy
        case "r":
            return Node(kind: .Type, child: Node(kind: .OpaqueReturnType))
        case "y":
            let T = try demangleAssociatedTypeSimple(genericParamIdx: try demangleGenericParamIndex())
            addSubstitution(T)
            return T
        case "z":
            let T = try demangleAssociatedTypeSimple(genericParamIdx: getDependentGenericParamType(depth: 0, index: 0))
            addSubstitution(T)
            return T
        case "Y":
            let T = try demangleAssociatedTypeCompound(genericParamIdx:  demangleGenericParamIndex())
            addSubstitution(T)
            return T
        case "Z":
            let T = try demangleAssociatedTypeCompound(genericParamIdx: getDependentGenericParamType(depth: 0, index: 0))
            addSubstitution(T)
            return T
        default: try throwFailure()
        }
    }

    mutating func demangleAssociatedTypeSimple(genericParamIdx: Node) throws -> Node {
        let gpi = Node(kind: .Type, child: genericParamIdx)
        let assocTypeName = try popAssocTypeName()
        return Node(kind: .Type, child: Node(kind: .DependentMemberType, children: [gpi, assocTypeName]))
    }

    mutating func demangleAssociatedTypeCompound(genericParamIdx: Node) throws -> Node {
        var assocTyNames = [Node]()
        var firstElem = false
        repeat {
            firstElem = pop(kind: .FirstElementMarker) != nil
            let AssocTyName = try popAssocTypeName()
            assocTyNames.append(AssocTyName)
        } while !firstElem

        var base = genericParamIdx

        while let assocTy = assocTyNames.popLast() {
            base = Node(kind: .DependentMemberType, children: [Node(kind: .Type, child: base), assocTy])
        }
        return Node(kind: .Type, child: base)
    }


    private mutating func getDependentGenericParamType(depth: Int, index: Int) throws -> Node {
        try require(depth >= 0 && index >= 0)
        return Node(kind: .DependentGenericParamType, children: [Node(kind: .Index, payload: .Index(UInt64(depth))), Node(kind: .Index, payload: .Index(UInt64(index)))])
    }

    mutating func demangleGenericParamIndex() throws -> Node {
        if nextIf("d") {
            let depth = try demangleIndex() + 1
            let index = try demangleIndex()
            return try getDependentGenericParamType(depth: depth, index: index)
        }
        if nextIf("z") {
            return try getDependentGenericParamType(depth: 0, index: 0)
        }
        return try getDependentGenericParamType(depth: 0, index: demangleIndex() + 1)
    }

    mutating func demangleThunkOrSpecialization() throws -> Node {
        let c = try nextChar()
        switch c {
        case "c": return Node(kind: .CurryThunk, child: try require(pop(where: { $0.isEntity })))
        case "j": return Node(kind: .DispatchThunk, child: try require(pop(where: { $0.isEntity })))
        case "q": return Node(kind: .MethodDescriptor, child: try require(pop(where: { $0.isEntity })))
        case "o": return Node(kind: .ObjCAttribute)
        case "O": return Node(kind: .NonObjCAttribute)
        case "D": return Node(kind: .DynamicAttribute)
        case "d": return Node(kind: .DirectMethodReferenceAttribute)
        case "a": return Node(kind: .PartialApplyObjCForwarder)
        case "A": return Node(kind: .PartialApplyForwarder)
        case "m": return Node(kind: .MergedFunction)
        case "X": return Node(kind: .DynamicallyReplaceableFunctionVar)
        case "x": return Node(kind: .DynamicallyReplaceableFunctionKey)
        case "I": return Node(kind: .DynamicallyReplaceableFunctionImpl)
        case "C":
            let type = try require(pop(kind: .Type))
            return Node(kind: .CoroutineContinuationPrototype, child: type)
        case "V":
            let Base = try require(pop(where: { $0.isEntity }))
            let Derived = try require(pop(where: { $0.isEntity }))
            return Node(kind: .VTableThunk, children: [Derived, Base])
        case "W":
            let Entity = try require(pop(where: { $0.isEntity }))
            let Conf = try popProtocolConformance()
            return Node(kind: .ProtocolWitness, children: [Conf, Entity])
        case "S": return Node(kind: .ProtocolSelfConformanceWitness, child: try require(pop(where: { $0.isEntity })))
        case "R": fallthrough
        case "r": fallthrough
        case "y":
            let kind: Node.Kind
            if c == "R" { kind = .ReabstractionThunkHelper }
            else if c == "y" { kind = .ReabstractionThunkHelperWithSelf }
            else { kind = .ReabstractionThunk }
            var thunk = Node(kind: kind)
            if let GenSig = pop(kind: .DependentGenericSignature) {
                thunk.children.append(GenSig)
            }
            if kind == .ReabstractionThunkHelperWithSelf {
                thunk.children.append(try require(pop(kind: .Type)))
            }
            thunk.children.append(try require(pop(kind: .Type)))
            thunk.children.append(try require(pop(kind: .Type)))
            return thunk
        case "g": return try demangleGenericSpecialization(specKind: .GenericSpecialization)
        case "G": return try demangleGenericSpecialization(specKind: .GenericSpecializationNotReAbstracted)
        case "i": return try demangleGenericSpecialization(specKind: .InlinedGenericFunction)
        case"p":
            var spec = try demangleSpecAttributes(specKind: .GenericPartialSpecialization)
            let param = Node(kind: .GenericSpecializationParam, child: try require(pop(kind: .Type)))
            spec.children.append(param)
            return spec
        case"P":
            var spec = try demangleSpecAttributes(specKind: .GenericPartialSpecializationNotReAbstracted)
            let param = Node(kind: .GenericSpecializationParam, child: try require(pop(kind: .Type)))
            spec.children.append(param)
            return spec

        case"f": return try demangleFunctionSpecialization()
        case "K": fallthrough
        case "k":
            let nodeKind: Node.Kind = c == "K" ? .KeyPathGetterThunkHelper : .KeyPathSetterThunkHelper

            let isSerialized = nextIf("q")

            var types = [Node]()
            var node: Node? = try require(pop(kind: .Type))
            while let n = node, n.kind == .Type {
                types.append(n)
                node = pop()
            }

            var result: Node
            if let n = node {
                if n.kind == .DependentGenericSignature {
                    let decl = try require(pop())
                    result = Node(kind: nodeKind, children: [decl, /*sig*/ n])
                } else {
                    result = Node(kind: nodeKind, child: /*decl*/ n)
                }
            } else {
                try throwFailure()
            }

            for t in types.reversed() {
                result.children.append(t)
            }

            if isSerialized {
                result.children.append(Node(kind: .IsSerialized))
            }

            return result

        case "l":
            let assocTypeName = try popAssocTypeName()
            return Node(kind: .AssociatedTypeDescriptor, child: assocTypeName)

        case "L": return Node(kind: .ProtocolRequirementsBaseDescriptor, child: try require(popProtocol()))

        case "M": return Node(kind: .DefaultAssociatedTypeMetadataAccessor, child: try require(popAssocTypeName()))

        case "n":
            let requirementTy = try popProtocol()
            let conformingType = try popAssocTypePath()
            let protoTy = try require(pop(kind: .Type))
            return Node(kind: .AssociatedConformanceDescriptor, children: [protoTy, conformingType, requirementTy])

        case "N":
            let requirementTy = try popProtocol()
            let assocTypePath = try popAssocTypePath()
            let protoTy = try require(pop(kind: .Type))
            return Node(kind: .DefaultAssociatedConformanceAccessor, children: [protoTy, assocTypePath, requirementTy])

        case "b":
            let requirementTy = try popProtocol()
            let protoTy = try require(pop(kind: .Type))
            return Node(kind: .BaseConformanceDescriptor, children: [protoTy, requirementTy])

        case "H": fallthrough
        case "h":
            let nodeKind: Node.Kind = c == "H" ? .KeyPathEqualsThunkHelper : .KeyPathHashThunkHelper

            let isSerialized = nextIf("q")

            var genericSig: Node?
            var types = [Node]()

            let node = pop()
            if let n = node {
                if (n.kind == .DependentGenericSignature) {
                    genericSig = n
                } else if n.kind == .Type {
                    types.append(n)
                } else {
                    try throwFailure()
                }
            } else {
                try throwFailure()
            }

            while let n = pop() {
                try require(n.kind != .Type)
                types.append(n)
            }

            var result = Node(kind: nodeKind)
            for t in types.reversed() {
                result.children.append(t)
            }
            if let genericSig = genericSig {
                result.children.append(genericSig)
            }

            if isSerialized {
                result.children.append(Node(kind: .IsSerialized))
            }
            return result
        case "v":
            return Node(kind: .OutlinedVariable, payload: .Index(UInt64(try require(demangleIndex()))))
        case "e":
            return Node(kind: .OutlinedBridgedMethod, payload: .Text(try demangleBridgedMethodParams()))
        default:
            try throwFailure()
        }
    }

    mutating func demangleBridgedMethodParams() throws -> String {
        if nextIf("_") {
            return ""
        }

        var str = ""

        let kind = try nextChar()
        switch (kind) {
        case "p", "a", "m":
            str.unicodeScalars.append(kind)
        default:
            try throwFailure()
        }

        while !nextIf("_") {
            let c = try nextChar()
            try require(c == "n" || c == "b")
            str.unicodeScalars.append(c)
        }
        return str
    }

    mutating func demangleGenericSpecialization(specKind: Node.Kind) throws -> Node {
        var spec = try demangleSpecAttributes(specKind: specKind)
        let tyList = try popTypeList()
        for ty in tyList.children {
            spec.children.append(Node(kind: .GenericSpecializationParam, child: ty))
        }
        return spec
    }

    mutating func demangleFunctionSpecialization() throws -> Node {
        var spec = try demangleSpecAttributes(specKind: .FunctionSignatureSpecialization)
        while !nextIf("_") {
            spec.children.append(try demangleFuncSpecParam(Kind: .FunctionSignatureSpecializationParam))
        }
        if !nextIf("n") {
            spec.children.append(try demangleFuncSpecParam(Kind: .FunctionSignatureSpecializationReturn))
        }

        // Add the required parameters in reverse order.
        for index in spec.children.indices.reversed() {
            if spec.children[index].kind != .FunctionSignatureSpecializationParam {
                continue
            }

            if spec.children[index].children.count == 0 {
                continue
            }
            let kindNd = spec.children[index].children[0]
            try require(kindNd.kind == .FunctionSignatureSpecializationParamKind)
            let kindNdIdx = try require(kindNd.index)
            let paramKind = FunctionSigSpecializationParamKind(rawValue: kindNdIdx)
            switch paramKind {
            case .ConstantPropFunction: fallthrough
            case .ConstantPropGlobal: fallthrough
            case .ConstantPropString: fallthrough
            case .ClosureProp:
                let FixedChildren = spec.children[index].children.count
                while let Ty = pop(kind: .Type) {
                    try require(paramKind == .ClosureProp)
                    spec.children[index].children.append(Ty)
                }
                let Name = try require(pop(kind: .Identifier))
                var Text = try require(Name.text)
                if paramKind == .ConstantPropString && !Text.isEmpty && Text.unicodeScalars.first == "_" {
                    // A "_" escapes a leading digit or "_" of a string constant.
                    Text = String(Text.dropFirst())
                }
                spec.children[index].children.append(Node(kind:.FunctionSignatureSpecializationParamPayload, payload: .Text(Text)))
                spec.children[index].reverseChildren(startingAt: FixedChildren)
            default:
                break
            }
        }
        return spec
    }

    mutating func demangleFuncSpecParam(Kind: Node.Kind) throws -> Node {
        try require(Kind == .FunctionSignatureSpecializationParam || Kind == .FunctionSignatureSpecializationReturn)
        var param = Node(kind: Kind)
        switch try nextChar() {
        case "n": break
        case "c":
            // Consumes an identifier and multiple type parameters.
            // The parameters will be added later.
            param.children.append(Node(kind: .FunctionSignatureSpecializationParamKind, payload: .Index(UInt64(FunctionSigSpecializationParamKind.ClosureProp.rawValue))))
        case "p":
            switch try nextChar() {
            case "f":
                // Consumes an identifier parameter, which will be added later.
                param.children.append(Node(kind: .FunctionSignatureSpecializationParamKind, payload: .Index(UInt64(FunctionSigSpecializationParamKind.ConstantPropFunction.rawValue))))
            case "g":
                // Consumes an identifier parameter, which will be added later.
                param.children.append(Node(kind: .FunctionSignatureSpecializationParamKind, payload:  .Index(UInt64(FunctionSigSpecializationParamKind.ConstantPropGlobal.rawValue))))
            case "i":
                return try addFuncSpecParamNumber(param: param, kind: FunctionSigSpecializationParamKind.ConstantPropInteger)
            case "d":
                return try addFuncSpecParamNumber(param: param, kind: FunctionSigSpecializationParamKind.ConstantPropFloat)
            case "s":
                // Consumes an identifier parameter (the string constant),
                // which will be added later.
                let encoding: String
                switch try nextChar() {
                case "b": encoding = "u8"
                case "w": encoding = "u16"
                case "c": encoding = "objc"
                default: try throwFailure()
                }
                param.children.append(Node(kind: .FunctionSignatureSpecializationParamKind, payload:  .Index(UInt64(FunctionSigSpecializationParamKind.ConstantPropString.rawValue))))
                param.children.append(Node(kind: .FunctionSignatureSpecializationParamPayload, payload: .Text(encoding)))
            default:
                try throwFailure()
            }

        case "e":
            var value = FunctionSigSpecializationParamKind.ExistentialToGeneric.rawValue
            if nextIf("D") {
                value |= FunctionSigSpecializationParamKind.Dead.rawValue
            }
            if nextIf("G") {
                value |= FunctionSigSpecializationParamKind.OwnedToGuaranteed.rawValue
            }
            if nextIf("O") {
                value |= FunctionSigSpecializationParamKind.GuaranteedToOwned.rawValue
            }
            if nextIf("X") {
                value |= FunctionSigSpecializationParamKind.SROA.rawValue
            }
            param.children.append(Node(kind: .FunctionSignatureSpecializationParamKind, payload: .Index(UInt64(value))))

        case "d":
            var value = FunctionSigSpecializationParamKind.Dead.rawValue
            if nextIf("G") {
                value |= FunctionSigSpecializationParamKind.OwnedToGuaranteed.rawValue
            }
            if nextIf("O") {
                value |= FunctionSigSpecializationParamKind.GuaranteedToOwned.rawValue
            }
            if nextIf("X") {
                value |= FunctionSigSpecializationParamKind.SROA.rawValue
            }
            param.children.append(Node(kind: .FunctionSignatureSpecializationParamKind, payload: .Index(UInt64(value))))

        case "g":
            var value = FunctionSigSpecializationParamKind.OwnedToGuaranteed.rawValue
            if nextIf("X") {
                value |= FunctionSigSpecializationParamKind.SROA.rawValue
            }
            param.children.append(Node(kind: .FunctionSignatureSpecializationParamKind, payload: .Index(UInt64(value))))

        case "o":
            var value = FunctionSigSpecializationParamKind.GuaranteedToOwned.rawValue
            if nextIf("X") {
                value |= FunctionSigSpecializationParamKind.SROA.rawValue
            }
            param.children.append(Node(kind: .FunctionSignatureSpecializationParamKind, payload: .Index(UInt64(value))))

        case "x": param.children.append(Node(kind: .FunctionSignatureSpecializationParamKind, payload: .Index(UInt64(FunctionSigSpecializationParamKind.SROA.rawValue))))
        case "i": param.children.append(Node(kind: .FunctionSignatureSpecializationParamKind, payload: .Index(UInt64(FunctionSigSpecializationParamKind.BoxToValue.rawValue))))
        case "s": param.children.append(Node(kind: .FunctionSignatureSpecializationParamKind, payload: .Index(UInt64(FunctionSigSpecializationParamKind.BoxToStack.rawValue))))
        default:
            try throwFailure()
        }
        return param
    }

    mutating func addFuncSpecParamNumber(param: Node, kind: FunctionSigSpecializationParamKind) throws -> Node {
        var Param = param
        Param.children.append(Node(kind: .FunctionSignatureSpecializationParamKind, payload: .Index(UInt64(kind.rawValue))))
        var str = ""
        while try peekChar().isDigit {
            str += try String(nextChar())
        }
        try require(!str.isEmpty)
        Param.children.append(Node(kind: .FunctionSignatureSpecializationParamPayload, payload: .Text(str)))
        return Param
    }

    mutating func demangleSpecAttributes(specKind: Node.Kind) throws -> Node {
        let isSerialized = nextIf("q")

        let PassID = try nextChar() - "0"
        try require(PassID >= 0 && PassID <= 9)

        var SpecNd = Node(kind: specKind)
        if (isSerialized) {
            SpecNd.children.append(Node(kind: .IsSerialized))
        }

        SpecNd.children.append(Node(kind: .SpecializationPassID, payload: .Index(UInt64(PassID))))
        return SpecNd
    }

    mutating func demangleWitness() throws -> Node {
        switch try nextChar() {
        case "C":
            return Node(kind: .EnumCase, child: try require(pop(where: { $0.isEntity })))
        case "V":
            return Node(kind: .ValueWitnessTable, child: try require(pop(kind: .Type)))
        case "v":
            let directness: UInt64
            switch try nextChar() {
            case "d": directness = Directness.Direct.rawValue
            case "i": directness = Directness.Indirect.rawValue
            default: try throwFailure()
            }
            return Node(kind: .FieldOffset, children: [Node(kind: .Directness, payload: .Index(directness)), try require(pop(where: { $0.isEntity }))])
        case "S":
            return Node(kind: .ProtocolSelfConformanceWitnessTable, child: try popProtocol())
        case "P":
            return Node(kind: .ProtocolWitnessTable, child: try popProtocolConformance())
        case "p":
            return Node(kind: .ProtocolWitnessTablePattern, child: try popProtocolConformance())
        case "G":
            return Node(kind: .GenericProtocolWitnessTable, child: try popProtocolConformance())
        case "I":
            return Node(kind: .GenericProtocolWitnessTableInstantiationFunction, child: try popProtocolConformance())

        case "r":
            return Node(kind: .ResilientProtocolWitnessTable, child: try popProtocolConformance())

        case "l":
            let Conf = try popProtocolConformance()
            let Type = try require(pop(kind: .Type))
            return Node(kind: .LazyProtocolWitnessTableAccessor, children: [Type, Conf])
        case "L":
            let Conf = try popProtocolConformance()
            let Type = try require(pop(kind: .Type))
            return Node(kind: .LazyProtocolWitnessTableCacheVariable, children: [Type, Conf])
        case "a":
            return Node(kind: .ProtocolWitnessTableAccessor, child: try popProtocolConformance())
        case "t":
            let Name = try require(pop(where: { $0.isDeclName }))
            let Conf = try popProtocolConformance()
            return Node(kind: .AssociatedTypeMetadataAccessor, children: [Conf, Name])
        case "T":
            let ProtoTy = try require(pop(kind: .Type))
            let ConformingType = try popAssocTypePath()
            let Conf = try popProtocolConformance()
            return Node(kind: .AssociatedTypeWitnessTableAccessor, children: [Conf, ConformingType, ProtoTy])
        case "b":
            let ProtoTy = try require(pop(kind: .Type))
            let Conf = try popProtocolConformance()
            return Node(kind: .BaseWitnessTableAccessor, children: [Conf, ProtoTy])
        case "O":
            let sig = pop(kind: .DependentGenericSignature)
            let type = try require(pop(kind: .Type))
            let children: [Node] = sig.map { [type, $0] } ?? [type]
            switch try nextChar() {
            case "y": return Node(kind: .OutlinedCopy, children: children)
            case "e": return Node(kind: .OutlinedConsume, children: children)
            case "r": return Node(kind: .OutlinedRetain, children: children)
            case "s": return Node(kind: .OutlinedRelease, children: children)
            case "b": return Node(kind: .OutlinedInitializeWithTake, children: children)
            case "c": return Node(kind: .OutlinedInitializeWithCopy, children: children)
            case "d": return Node(kind: .OutlinedAssignWithTake, children: children)
            case "f": return Node(kind: .OutlinedAssignWithCopy, children: children)
            case "h": return Node(kind: .OutlinedDestroy, children: children)
            default:
                try throwFailure()
            }
        default:
            try throwFailure()
        }
    }

    mutating func demangleSpecialType() throws -> Node {
        let specialChar = try nextChar()
        switch specialChar {
        case "E":
            return try popFunctionType(kind: .NoEscapeFunctionType)
        case "A":
            return try popFunctionType(kind: .EscapingAutoClosureType)
        case "f":
            return try popFunctionType(kind: .ThinFunctionType)
        case "K":
            return try popFunctionType(kind: .AutoClosureType)
        case "U":
            return try popFunctionType(kind: .UncurriedFunctionType)
        case "B":
            return try popFunctionType(kind: .ObjCBlock)
        case "C":
            return try popFunctionType(kind: .CFunctionPointer)
        case "o":
            return Node(typeWithChildKind: .Unowned, childChild: try require(pop(kind: .Type)))
        case "u":
            return Node(typeWithChildKind: .Unmanaged, childChild: try require(pop(kind: .Type)))
        case "w":
            return Node(typeWithChildKind: .Weak, childChild: try require(pop(kind: .Type)))
        case "b":
            return Node(typeWithChildKind: .SILBoxType, childChild: try require(pop(kind: .Type)))
        case "D":
            return Node(typeWithChildKind: .DynamicSelf, childChild: try require(pop(kind: .Type)))
        case "M":
            let mtr = try demangleMetatypeRepresentation()
            let type = try require(pop(kind: .Type))
            return Node(typeWithChildKind: .Metatype, childChildren: [mtr, type])
        case "m":
            let mtr = try demangleMetatypeRepresentation()
            let type = try require(pop(kind: .Type))
            return Node(typeWithChildKind: .ExistentialMetatype, childChildren: [mtr, type])
        case "p":
            return Node(typeWithChildKind: .ExistentialMetatype, childChild: try require(pop(kind: .Type)))
        case "c":
            let superclass = try require(pop(kind: .Type))
            let protocols = try demangleProtocolList()
            return Node(typeWithChildKind: .ProtocolListWithClass, childChildren: [protocols, superclass])
        case "l":
            let protocols = try demangleProtocolList()
            return Node(typeWithChildKind: .ProtocolListWithAnyObject, childChild: protocols)
        case "X", "x":
            // SIL box types.
            var signatureGenericArgs: (Node, Node)? = nil
            if (specialChar == "X") {
                signatureGenericArgs = (try require(pop(kind: .DependentGenericSignature)), try popTypeList())
            }

            let fieldTypes = try popTypeList()
            // Build layout.
            var layout = Node(kind: .SILBoxLayout)
            for fieldType in fieldTypes.children {
                try require(fieldType.kind == .Type)
                // "inout" typelist mangling is used to represent mutable fields.
                if fieldType.children.first?.kind == .InOut {
                    layout.children.append(Node(kind: .SILBoxMutableField, child: Node(kind: .Type, child: try require(fieldType.children.first?.children.first))))
                } else {
                    layout.children.append(Node(kind: .SILBoxImmutableField, child: fieldType))
                }
            }
            var boxTy = Node(kind: .SILBoxTypeWithLayout, child: layout)
            if let (signature, genericArgs) = signatureGenericArgs {
                boxTy.children.append(signature)
                boxTy.children.append(genericArgs)
            }
            return Node(kind: .Type, child: boxTy)
        case "Y":
            return try demangleAnyGenericType(kind: .OtherNominalType)
        case "Z":
            let types = try popTypeList()
            let name = try require(pop(kind: .Identifier))
            let parent = try popContext()
            return Node(kind: .AnonymousContext, children: [name, parent, types])
        case "e":
            return Node(kind: .Type, child: Node(kind: .ErrorType))
        case "S":
            // Sugared type for debugger.
            switch try nextChar() {
            case "q":
                return Node(kind: .Type, child: Node(kind: .SugaredOptional, child: try require(pop(kind: .Type))))
            case "a":
                return Node(kind: .Type, child: Node(kind: .SugaredArray, child: try require(pop(kind: .Type))))
            case "D":
                let value = try require(pop(kind: .Type))
                let key = try require(pop(kind: .Type))
                return Node(typeWithChildKind: .SugaredDictionary, childChildren: [key, value])
            case "p":
                return Node(kind: .Type, child: Node(kind: .SugaredParen, child: try require(pop(kind: .Type))))
            default:
                try throwFailure()
            }
        default:
            try throwFailure()
        }
    }

    mutating func demangleMetatypeRepresentation() throws -> Node {
        switch try nextChar() {
        case "t":
            return Node(kind: .MetatypeRepresentation, payload: .Text("@thin"))
        case "T":
            return Node(kind: .MetatypeRepresentation, payload: .Text("@thick"))
        case "o":
            return Node(kind: .MetatypeRepresentation, payload: .Text("@objc_metatype"))
        default:
            try throwFailure()
        }
    }

    mutating func demangleAccessor(childNode: Node) throws -> Node {
        let kind: Node.Kind
        switch try nextChar() {
        case "m": kind = .MaterializeForSet
        case "s": kind = .Setter
        case "g": kind = .Getter
        case "G": kind = .GlobalGetter
        case "w": kind = .WillSet
        case "W": kind = .DidSet
        case "r": kind = .ReadAccessor
        case "M": kind = .ModifyAccessor
        case "a":
            switch try nextChar() {
            case "O": kind = .OwningMutableAddressor
            case "o": kind = .NativeOwningMutableAddressor
            case "P": kind = .NativePinningMutableAddressor
            case "u": kind = .UnsafeMutableAddressor
            default: try throwFailure()
            }
            break
        case "l":
            switch try nextChar() {
            case "O": kind = .OwningAddressor
            case "o": kind = .NativeOwningAddressor
            case "p": kind = .NativePinningAddressor
            case "u": kind = .UnsafeAddressor
            default: try throwFailure()
            }
            break
        case "p": // Pseudo-accessor referring to the variable/subscript itself
            return childNode
        default: try throwFailure()
        }
        return Node(kind: kind, child: childNode)
    }

    mutating func demangleFunctionEntity() throws -> Node {
        var args: DemangleFunctionEntityArgs
        var kind: Node.Kind = .EmptyList
        switch try nextChar() {
        case "D": args = .None; kind = .Deallocator
        case "d": args = .None; kind = .Destructor
        case "E": args = .None; kind = .IVarDestroyer
        case "e": args = .None; kind = .IVarInitializer
        case "i": args = .None; kind = .Initializer
        case "C": args = .TypeAndMaybePrivateName; kind = .Allocator
        case "c": args = .TypeAndMaybePrivateName; kind = .Constructor
        case "U": args = .TypeAndIndex; kind = .ExplicitClosure
        case "u": args = .TypeAndIndex; kind = .ImplicitClosure
        case "A": args = .Index; kind = .DefaultArgumentInitializer
        case "p": return try demangleEntity(kind: .GenericTypeParamDecl)
        default: try throwFailure()
        }

        var children = [Node]()
        switch (args) {
        case .None:
            break
        case .TypeAndMaybePrivateName:
            let privateName = pop(kind: .PrivateDeclName)
            let paramType = try require(pop(kind: .Type))
            let labelList = try popFunctionParamLabels(type: paramType)
            if let ll = labelList {
                children.append(ll)
                children.append(paramType)
            } else {
                children.append(paramType)
            }
            if let pn = privateName {
                children.append(pn)
            }
        case .TypeAndIndex:
            let index = try demangleIndexAsNode()
            let type = try require(pop(kind: .Type))
            children += [index, type]
        case .Index:
            children.append(try demangleIndexAsNode())
        }
        children.insert(try popContext(), at: 0)
        let entity = Node(kind: kind, children: children)
        return entity
    }

    mutating func demangleEntity(kind: Node.Kind) throws -> Node {
        let type = try require(pop(kind: .Type))
        let labelList = try popFunctionParamLabels(type: type)
        let name = try require(pop(where: { $0.isDeclName }))
        let context = try popContext()
        if let ll = labelList {
            return Node(kind: kind, children: [context, name, ll, type])
        }
        return Node(kind: kind, children: [context, name, type])
    }

    mutating func demangleVariable() throws -> Node {
        let variable = try demangleEntity(kind: .Variable)
        return try demangleAccessor(childNode: variable)
    }

    mutating func demangleSubscript() throws -> Node {
        let privateName = pop(kind: .PrivateDeclName)
        let type = try require(pop(kind: .Type))
        let labelList = try require(popFunctionParamLabels(type: type))
        let context = try popContext()

        var subscrpt = Node(kind: .Subscript, children: [context, labelList, type])
        if let pn = privateName {
            subscrpt.children.append(pn)
        }

        return try demangleAccessor(childNode: subscrpt)
    }

    mutating func demangleProtocolList() throws -> Node {
        var typeList = Node(kind: .TypeList)
        if pop(kind: .EmptyList) == nil {
            var firstElem = false
            repeat {
                firstElem = pop(kind: .FirstElementMarker) != nil
                let Proto = try popProtocol()
                typeList.children.append(Proto)
            } while !firstElem

            typeList.reverseChildren(startingAt: 0)
        }
        return Node(kind: .ProtocolList, child: typeList)
    }

    mutating func demangleProtocolListType() throws -> Node {
        let protoList = try demangleProtocolList()
        return Node(kind: .Type, child: protoList)
    }

    mutating func demangleGenericSignature(hasParamCounts: Bool) throws -> Node {
        var sig = Node(kind: .DependentGenericSignature)
        if hasParamCounts {
            while !nextIf("l") {
                var count = 0
                if !nextIf("z") {
                    count = try demangleIndex() + 1
                }
                if count < 0 {
                    try throwFailure()
                }
                sig.children.append(Node(kind: .DependentGenericParamCount, payload: .Index(UInt64(count))))
            }
        } else {
            sig.children.append(Node(kind: .DependentGenericParamCount, payload: .Index(1)))
        }
        let NumCounts = sig.children.count
        while let Req = pop(where: { $0.isRequirement }) {
            sig.children.append(Req)
        }
        sig.reverseChildren(startingAt: NumCounts)
        return sig
    }

    mutating func demangleGenericRequirement() throws -> Node {
        let typeKind: DemangleGenericRequirementTypeKind
        let constraintKind: DemangleGenericRequirementConstraintKind
        switch try nextChar() {
        case "c": constraintKind = .BaseClass; typeKind = .Assoc
        case "C": constraintKind = .BaseClass; typeKind = .CompoundAssoc
        case "b": constraintKind = .BaseClass; typeKind = .Generic
        case "B": constraintKind = .BaseClass; typeKind = .Substitution
        case "t": constraintKind = .SameType; typeKind = .Assoc
        case "T": constraintKind = .SameType; typeKind = .CompoundAssoc
        case "s": constraintKind = .SameType; typeKind = .Generic
        case "S": constraintKind = .SameType; typeKind = .Substitution
        case "m": constraintKind = .Layout; typeKind = .Assoc
        case "M": constraintKind = .Layout; typeKind = .CompoundAssoc
        case "l": constraintKind = .Layout; typeKind = .Generic
        case "L": constraintKind = .Layout; typeKind = .Substitution
        case "p": constraintKind = .Protocol; typeKind = .Assoc
        case "P": constraintKind = .Protocol; typeKind = .CompoundAssoc
        case "Q": constraintKind = .Protocol; typeKind = .Substitution
        default:  constraintKind = .Protocol; typeKind = .Generic; try pushBack()
        }

        let constrTy: Node
        switch typeKind {
        case .Generic:
            constrTy = Node(kind: .Type, child: try demangleGenericParamIndex())
        case .Assoc:
            constrTy = try demangleAssociatedTypeSimple(genericParamIdx: demangleGenericParamIndex())
            addSubstitution(constrTy)
        case .CompoundAssoc:
            constrTy = try demangleAssociatedTypeCompound(genericParamIdx: demangleGenericParamIndex())
            addSubstitution(constrTy)
        case .Substitution:
            constrTy = try require(pop(kind: .Type))
        }

        switch constraintKind {
        case .Protocol:
            return Node(kind: .DependentGenericConformanceRequirement, children: [constrTy, try popProtocol()])
        case .BaseClass:
            return Node(kind: .DependentGenericConformanceRequirement, children: [constrTy, try require(pop(kind: .Type))])
        case .SameType:
            return Node(kind: .DependentGenericSameTypeRequirement, children: [constrTy, try require(pop(kind: .Type))])
        case .Layout:
            let c = try nextChar()
            var size: Node?
            var alignment: Node?
            let name: String
            if (c == "U") {
                name = "U"
            } else if (c == "R") {
                name = "R"
            } else if (c == "N") {
                name = "N"
            } else if (c == "C") {
                name = "C"
            } else if (c == "D") {
                name = "D"
            } else if (c == "T") {
                name = "T"
            } else if (c == "E") {
                size = try demangleIndexAsNode()
                alignment = try demangleIndexAsNode()
                name = "E"
            } else if (c == "e") {
                size = try demangleIndexAsNode()
                name = "e"
            } else if (c == "M") {
                size = try demangleIndexAsNode()
                alignment = try demangleIndexAsNode()
                name = "M"
            } else if (c == "m") {
                size = try demangleIndexAsNode()
                name = "m"
            } else {
                // Unknown layout constraint.
                try throwFailure()
            }

            let NameNode = Node(kind: .Identifier, payload: .Text(name))
            var LayoutRequirement = Node(kind: .DependentGenericLayoutRequirement, children: [constrTy, NameNode])
            if let sz = size {
                LayoutRequirement.children.append(sz)
            }
            if let al = alignment {
                LayoutRequirement.children.append(al)
            }
            return LayoutRequirement
        }
    }

    mutating func demangleGenericType() throws -> Node {
        let GenSig = try require(pop(kind: .DependentGenericSignature))
        let Ty = try require(pop(kind: .Type))
        return Node(typeWithChildKind: .DependentGenericType, childChildren: [GenSig, Ty])
    }

    private func decodeValueWitnessKind(code: String) throws -> UInt64 {
        if (code == "al") { return ValueWitnessKind.allocateBuffer.rawValue }
        if (code == "ca") { return ValueWitnessKind.assignWithCopy.rawValue }
        if (code == "ta") { return ValueWitnessKind.assignWithTake.rawValue }
        if (code == "de") { return ValueWitnessKind.deallocateBuffer.rawValue }
        if (code == "xx") { return ValueWitnessKind.destroy.rawValue }
        if (code == "XX") { return ValueWitnessKind.destroyBuffer.rawValue }
        if (code == "Xx") { return ValueWitnessKind.destroyArray.rawValue }
        if (code == "CP") { return ValueWitnessKind.initializeBufferWithCopyOfBuffer.rawValue }
        if (code == "Cp") { return ValueWitnessKind.initializeBufferWithCopy.rawValue }
        if (code == "cp") { return ValueWitnessKind.initializeWithCopy.rawValue }
        if (code == "Tk") { return ValueWitnessKind.initializeBufferWithTake.rawValue }
        if (code == "tk") { return ValueWitnessKind.initializeWithTake.rawValue }
        if (code == "pr") { return ValueWitnessKind.projectBuffer.rawValue }
        if (code == "TK") { return ValueWitnessKind.initializeBufferWithTakeOfBuffer.rawValue }
        if (code == "Cc") { return ValueWitnessKind.initializeArrayWithCopy.rawValue }
        if (code == "Tt") { return ValueWitnessKind.initializeArrayWithTakeFrontToBack.rawValue }
        if (code == "tT") { return ValueWitnessKind.initializeArrayWithTakeBackToFront.rawValue }
        if (code == "xs") { return ValueWitnessKind.storeExtraInhabitant.rawValue }
        if (code == "xg") { return ValueWitnessKind.getExtraInhabitantIndex.rawValue }
        if (code == "ug") { return ValueWitnessKind.getEnumTag.rawValue }
        if (code == "up") { return ValueWitnessKind.destructiveProjectEnumData.rawValue }
        if (code == "ui") { return ValueWitnessKind.destructiveInjectEnumTag.rawValue }
        if (code == "et") { return ValueWitnessKind.getEnumTagSinglePayload.rawValue }
        if (code == "st") { return ValueWitnessKind.storeEnumTagSinglePayload.rawValue }
        try throwFailure()
    }

    mutating func demangleValueWitness() throws -> Node {
        let code = "\(try nextChar())\(try nextChar())"
        let kind = try decodeValueWitnessKind(code: code)
        var vw = Node(kind: .ValueWitness)
        vw.children.append(Node(kind: .Index, payload: .Index(UInt64(kind))))
        vw.children.append(try require(pop(kind: .Type)))
        return vw
    }

    mutating func demangleObjCTypeName() throws -> Node {
        var ty = Node(kind: .Type)
        let global = Node(kind: .Global, child: Node(kind: .TypeMangling, child: ty))
        var nominal: Node
        var isProto = false
        if nextIf("C") {
            nominal = Node(kind: .Class)
            ty.children.append(nominal)
        } else if nextIf("P") {
            isProto = true
            nominal = Node(kind: .Protocol)
            let x = Node(kind: .ProtocolList, child: Node(kind: .TypeList, child: Node(kind: .Type, child: nominal)))
            ty.children.append(x)
        } else {
            try throwFailure()
        }

        if nextIf("s") {
            nominal.children.append(Node(kind: .Module, payload: .Text("Swift")))
        } else {
            let Module = try demangleIdentifier().changingKind(.Module)
            nominal.children.append(Module)
        }

        let Ident = try demangleIdentifier()
        nominal.children.append(Ident)

        if isProto && !nextIf("_") {
            try throwFailure()
        }

        try require(scanner.isAtEnd)

        return global
    }
}
