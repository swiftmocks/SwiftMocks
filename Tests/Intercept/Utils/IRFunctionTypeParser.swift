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

import Foundation
@testable import SwiftMocks

enum IRTest {
    /// Parses a nameless function type, for example `define hidden swiftcc i8 (i8)` (note missing name)
    static func parseIRFunctionType(_ string: String) throws -> IRSignature {
        var scanner = Scanner(string)
        var tokens = [Token]()
        while let token = consumeToken(from: &scanner) {
            tokens.append(token)
        }
        // tokens.forEach { print($0) }

        guard let firstLeftParen = tokens.firstIndex(where: { $0 == .lparen }) else {
            throw Error.noParen
        }
        guard tokens.last == .rparen else {
            throw Error.noParen
        }

        // ok, we got params (everything between the first left paren and the last symbol which should be a right paren) and the head (function attrs and return type)
        let headTokens = tokens[0..<firstLeftParen]
        let paramTokens = tokens[(firstLeftParen+1)..<(tokens.count-1)]

        var tokenScanner = TokenScanner(tokens: Array(paramTokens))
        let params = try parseParameters(scanner: &tokenScanner)
        if !tokenScanner.isEOF {
            print("Error: parser did not fully consume the parameter tokens.\n\(tokenScanner)")
            throw Error.cannotParse
        }

        tokenScanner = TokenScanner(tokens: Array(headTokens))
        let retTy = try parseReturnTypeAndAttrs(scanner: &tokenScanner)
        // print(retTy)
        if !tokenScanner.isEOF {
            print("Error: parser did not fully consume the head tokens.\n\(tokenScanner)")
            throw Error.cannotParse
        }

        let fnType = try LLVMFunctionType(result: retTy.type.toLLVMType(), params: params.map { try $0.type.toLLVMType() }, isVarArgs: false)
        let parameterAttrs = params.enumerated().reduce(into: [Int: Set<String>]()) { (result, el) in
            let (index, (_, attrs)) = el
            result[index] = Set(attrs)
        }
        let attrs = LLVMAttributeList(functionAttributes: Set(retTy.functionAttrs), resultAttributes: Set(retTy.attrs), parameterAttributes: parameterAttrs)
        let ret = IRSignature(type: fnType, attributes: attrs)
        return ret
    }

    // MARK: - Implementation

    private enum FullLLVMType: Hashable {
        case void
        case float
        case double
        case x86_fp80
        case i(Int)
        indirect case array(FullLLVMType, Int)
        indirect case `struct`([FullLLVMType])
        indirect case packedStruct([FullLLVMType]?, String?)
        indirect case pointer(FullLLVMType)
        case named(String)

        func toLLVMType() throws -> LLVMType {
            switch self {
            case .void:
                return .void
            case let .i(bits):
                switch bits {
                case 1:
                    return .i1
                case 8:
                    return .i8
                case 16:
                    return .i16
                case 32:
                    return .i32
                case 64:
                    return .i64
                default:
                    throw Error.unsupportedIntWidth
                }
            case .float:
                return .float
            case .double:
                return .double
            case .x86_fp80:
                return .x86_fp80
            case let .array(type, size):
                return try .array(type.toLLVMType(), size)
            case let .struct(types):
                return try .struct(types.map { try $0.toLLVMType() })
            case .packedStruct:
                throw Error.packedStructsNotSupported
            case .pointer:
                return .pointer
            case .named:
                throw Error.namedTypesNotSupported
            }
        }
    }
    private typealias Param = (type: FullLLVMType, attrs: [String])
    private typealias ReturnAndFunctionAttrs = (type: FullLLVMType, attrs: [String], functionAttrs: [String])

    private enum Token: Hashable, CustomStringConvertible {
        case lparen // (
        case rparen // )
        case lbrace // {
        case rbrace // }
        case langle // <
        case rangle // >
        case lsquare // [
        case rsquare // ]
        case comma // ,
        case star // *
        case void
        case i(Int)
        case float
        case double
        case x86_fp80
        case identifier(String)
        case attribute(String)
        case number(Int)

        var description: String {
            switch self {
            case .lparen:
                return "("
            case .rparen:
                return ")"
            case .lbrace:
                return "{"
            case .rbrace:
                return "}"
            case .langle:
                return "<"
            case .rangle:
                return ">"
            case .lsquare:
                return "["
            case .rsquare:
                return "]"
            case .comma:
                return ","
            case .star:
                return "*"
            case .void:
                return "void"
            case let .i(width):
                return "i\(width)"
            case .float:
                return "float"
            case .double:
                return "double"
            case .x86_fp80:
                return "x86_fp80"
            case let .identifier(identifier):
                return "%\(identifier)"
            case let .attribute(attribute):
                return "'\(attribute)'"
            case let .number(number):
                return "'\(number)'"
            }
        }
    }

    private enum Error: Swift.Error {
        case noParen
        case cannotParse
        case namedTypesNotSupported
        case packedStructsNotSupported
        case unsupportedIntWidth
    }

    private static func parseReturnTypeAndAttrs(scanner: inout TokenScanner) throws -> ReturnAndFunctionAttrs {
        var functionAttrs = [String]()
        while let attr = try maybeAttribute(scanner: &scanner) {
            functionAttrs.append(attr)
        }
        let ty = try type(scanner: &scanner)
        var typeAttrs = [String]()
        while let attr = try maybeAttribute(scanner: &scanner) {
            typeAttrs.append(attr)
        }
        return (type: ty, attrs: typeAttrs, functionAttrs: functionAttrs)
    }

    private static func parseParameters(scanner: inout TokenScanner) throws -> [Param] {
        guard let p = try? parameter(scanner: &scanner) else {
            return []
        }
        var ret = [Param]()
        ret.append(p)
        while true {
            guard scanner.peek() == .comma else {
                return ret
            }
            _ = try scanner.consume() // comma
            try ret.append(parameter(scanner: &scanner))
        }
    }

    private static func parameter(scanner: inout TokenScanner) throws -> Param {
        let ty = try type(scanner: &scanner)
        var attrs = [String]()
        while let attr = try maybeAttribute(scanner: &scanner) {
            attrs.append(attr)
        }
        _ = try maybeIdentifier(scanner: &scanner) // local name
        return (type: ty, attrs: attrs)
    }

    // https://github.com/llvm/llvm-project/blob/master/llvm/lib/AsmParser/LLParser.cpp#L2321
    private static func type(scanner: inout TokenScanner) throws -> FullLLVMType {
        var ret: FullLLVMType?
        switch scanner.peek() {
        case .void:
            _ = try scanner.consume()
            ret = .void
        case let .i(width):
            _ = try scanner.consume()
            ret = .i(width)
        case .float:
            _ = try scanner.consume()
            ret = .float
        case .double:
            _ = try scanner.consume()
            ret = .double
        case .x86_fp80:
            _ = try scanner.consume()
            ret = .x86_fp80
        case .lbrace:
            let body = try anonStructType(scanner: &scanner)
            ret = .struct(body)
        case .lsquare: // we never have arrays except as part of a pointed-to structs (and as such they don't matter because our pointers are typeless) so I'm just going to pretend they dont' exist
            while case let token = try scanner.consume(), token != .rsquare {}
            ret = .void
        case .langle: // either vector or a packed structure
            _ = try scanner.consume()
            if scanner.peek() == .lbrace {
                let body = try anonStructType(scanner: &scanner)
                if !scanner.consumeIf(.rangle) { // must have a closing '>' at the end of packed struct
                    throw Error.cannotParse
                }
                ret = .packedStruct(body, nil)
            } else {
                notImplemented("Vectors")
            }
        case .identifier: // assume it's always followed by a pointer
            _ = try scanner.consume()
            ret = .named("foo")
        default:
            throw Error.cannotParse
        }

        while true {
            if scanner.consumeIf(.star) {
                ret = .pointer(ret!)
                continue
            }
            if let result = ret {
                return result
            }
            throw Error.cannotParse
        }
    }

    // Reference: https://github.com/llvm/llvm-project/blob/master/llvm/lib/AsmParser/LLParser.cpp#L2749
    private static func anonStructType(scanner: inout TokenScanner) throws -> [FullLLVMType] {
        let lbrace = try scanner.consume()
        precondition(lbrace == .lbrace)
        if scanner.peek() == .rbrace {
            _ = try scanner.consume()
            
        }
        var fields = [FullLLVMType]()
        let firstTy = try type(scanner: &scanner)
        fields.append(firstTy)
        while scanner.consumeIf(.comma) {
            let ty = try type(scanner: &scanner)
            fields.append(ty)
        }
        if try scanner.consume() != .rbrace {
            throw Error.cannotParse
        }
        return fields
    }

    private static func maybeAttribute(scanner: inout TokenScanner) throws -> String? {
        if case let .attribute(text) = scanner.peek() {
            _ = try scanner.consume()
            return text
        }
        return nil
    }

    private static func maybeIdentifier(scanner: inout TokenScanner) throws -> String? {
        if case let .identifier(ident) = scanner.peek() {
            _ = try scanner.consume()
            return ident
        }
        return nil
    }

    private static func consumeToken(from scanner: inout Scanner) -> Token? {
        func consumeTypename() -> String {
            var result = ""
            while let ch = scanner.peek(), !"(){}<>,* ".contains(ch) {
                result.append(scanner.consume())
            }
            return result
        }

        func consumeTypeNameOrAttribute() -> String {
            var result = ""
            var hasOpenedBracket = false
            // consume everything that is not a separator, including an optional argument in parens, so `foo` or `foo.bar` or `"foo bar"` or `foo(100)`
            while let ch = scanner.peek(), !"{}[]<>,* ".contains(ch) {
                if ch == ")" && !hasOpenedBracket {
                    break
                }
                if ch == "(" {
                    hasOpenedBracket = true
                }
                result.append(scanner.consume())
                if ch == ")" && hasOpenedBracket {
                    break
                }
            }
            return result
        }

        while true {
            while let ch = scanner.peek(), ch == " " {
                _ = scanner.consume()
            }
            if scanner.isEOF {
                return nil
            }
            let ch = scanner.consume()
            switch ch {
            case "(":
                return .lparen
            case ")":
                return .rparen
            case "{":
                return .lbrace
            case "}":
                return .rbrace
            case "<":
                return .langle
            case ">":
                return .rangle
            case "[":
                return .lsquare
            case "]":
                return .rsquare
            case ",":
                return .comma
            case "*":
                return .star
            case "%":
                return .identifier(consumeTypename())
            case "0"..."9":
                // just skip bare numbers. there are a couple of attributes, like `align 8`, that use them, but we don't care about those
                continue
            default:
                break
            }
            // backtrack and read what could be an attribute or a type name
            scanner.backtrack()
            let typeOrAttribute = consumeTypeNameOrAttribute()
            switch typeOrAttribute {
            case "void":
                return .void
            case "i1":
                return .i(1)
            case "i8":
                return .i(8)
            case "i16":
                return .i(16)
            case "i32":
                return .i(32)
            case "i64":
                return .i(64)
            case "float":
                return .float
            case "double":
                return .double
            case "x86_fp80":
                return .x86_fp80
            default:
                return .attribute(typeOrAttribute)
            }
        }
    }

    private struct TokenScanner: CustomStringConvertible {
        private(set) var next: Int
        private(set) var tokens: [Token]

        var isEOF: Bool {
            next >= tokens.count
        }

        init(tokens: [Token]) {
            self.tokens = tokens
            next = 0
        }

        mutating func consume() throws -> Token {
            if isEOF {
                throw Error.cannotParse
            }
            defer {
                next += 1
            }
            return tokens[next]
        }

        func peek() -> Token? {
            if isEOF {
                return nil
            }
            return tokens[next]
        }

        mutating func consumeIf(_ token: Token) -> Bool {
            guard peek() == token else {
                return false
            }
            _ = try? consume()
            return true
        }

        var description: String {
            var ret = ""
            if next > 0 {
                ret += "Consumed: " + tokens[..<next].map { $0.description }.joined(separator: " ") + "\n"
            }
            ret += "Left: " + tokens[next...].map { $0.description }.joined(separator: " ")
            return ret
        }
    }

    fileprivate struct Scanner {
        private(set) var index: String.Index
        let string: String

        var isEOF: Bool {
            index == string.endIndex
        }

        init(_ string: String) {
            self.string = string
            self.index = string.startIndex
        }

        func peek() -> Character? {
            if index == string.endIndex {
                return nil
            }
            return string[index]
        }

        mutating func consume() -> Character {
            defer {
                index = string.index(after: index)
            }
            return string[index]
        }

        mutating func backtrack() {
            if index > string.startIndex {
                index = string.index(before: index)
            }
        }
    }
}
