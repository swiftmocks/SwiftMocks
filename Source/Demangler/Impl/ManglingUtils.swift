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

extension UnicodeScalar {
    /// Tests if the scalar is within a range
    func isInRange(_ range: ClosedRange<UnicodeScalar>) -> Bool {
        return range.contains(self)
    }

    /// Tests if the scalar is a plain ASCII digit
    var isDigit: Bool {
        return ("0"..."9").contains(self)
    }

    /// Tests if the scalar is a plain ASCII English alphabet lowercase letter
    var isLower: Bool {
        return ("a"..."z").contains(self)
    }

    /// Tests if the scalar is a plain ASCII English alphabet uppercase letter
    var isUpper: Bool {
        return ("A"..."Z").contains(self)
    }

    /// Tests if the scalar is a plain ASCII English alphabet letter
    var isLetter: Bool {
        return isLower || isUpper
    }

    /// Returns true if `ch` is a character which defines the begin of a substitution word.
    var isWordStart: Bool {
        return !isDigit && self != "_" && value != 0
    }

    /// Returns true if the receiver is a character (following `prevCh`) which defines the end of a substitution word.
    func isWordEnd(prevCh: UnicodeScalar) -> Bool {
        if self == "_" || value == 0 {
            return true
        }

        if !prevCh.isUpper && isUpper {
            return true
        }

        return false
    }

    /// Returns true if the receiver is a valid character which may appear in a symbol mangling.
    var isValidSymbolChar: Bool {
        return isLetter || isDigit || self == "_" || self == "$"
    }

    /// Translate the given operator character into its mangled form. Current operator characters:   @/=-+*%<>!&|^~ and the special operator '..'
    var translatingToOperatorChar: UnicodeScalar {
        switch self {
        case "&": return "a" // "and"
        case "@": return "c" // "commercial at sign"
        case "/": return "d" // "divide"
        case "=": return "e" // "equal"
        case ">": return "g" // "greater"
        case "<": return "l" // "less"
        case "*": return "m" // "multiply"
        case "!": return "n" // "negate"
        case "|": return "o" // "or"
        case "+": return "p" // "plus"
        case "?": return "q" // "question"
        case "%": return "r" // "remainder"
        case "-": return "s" // "subtract"
        case "~": return "t" // "tilde"
        case "^": return "x" // "xor"
        case ".": return "z" // "zperiod" (the z is silent)
        default: return self
        }
    }
}

extension String {
    /// Returns true if `str` contains any character which may not appear in a mangled symbol string and therefore must be punycode encoded.
    var needsPunycodeEncoding: Bool { unicodeScalars.contains { !$0.isValidSymbolChar } }

    /// Returns true if `str` contains any non-ASCII character.
    var isNonAscii: Bool { unicodeScalars.contains { $0.value >= 0x80 } }

    /// Returns a string where all operator characters in the receiver are translated to their mangled form.
    var translatingOperators: String { unicodeScalars.map { $0.translatingToOperatorChar }.reduce(into: "", { $0 += "\($1)" }) }
}

/// Describes a Word in a mangled identifier.
struct SubstitutionWord {

    /// The position of the first word character in the mangled string.
    var start: size_t

    /// The length of the word.
    let length: size_t
}

/// Helper struct which represents a word substitution.
struct WordReplacement {
    /// The position in the identifier where the word is substituted.
    let stringPos: size_t

    /// The index into the mangler's Words array (-1 if invalid).
    let WordIdx: Int
}

func getStandardTypeSubst(typeName: String) -> UnicodeScalar? {
    if (typeName == "AutoreleasingUnsafeMutablePointer") { return "A" }
    if (typeName == "Array") { return "a" }
    if (typeName == "Bool") { return "b" }
    if (typeName == "UnicodeScalar") { return "c" }
    if (typeName == "Dictionary") { return "D" }
    if (typeName == "Double") { return "d" }
    if (typeName == "Float") { return "f" }
    if (typeName == "Set") { return "h" }
    if (typeName == "DefaultIndices") { return "I" }
    if (typeName == "Int") { return "i" }
    if (typeName == "Character") { return "J" }
    if (typeName == "ClosedRange") { return "N" }
    if (typeName == "Range") { return "n" }
    if (typeName == "ObjectIdentifier") { return "O" }
    if (typeName == "UnsafePointer") { return "P" }
    if (typeName == "UnsafeMutablePointer") { return "p" }
    if (typeName == "UnsafeBufferPointer") { return "R" }
    if (typeName == "UnsafeMutableBufferPointer") { return "r" }
    if (typeName == "String") { return "S" }
    if (typeName == "Substring") { return "s" }
    if (typeName == "UInt") { return "u" }
    if (typeName == "UnsafeRawPointer") { return "V" }
    if (typeName == "UnsafeMutableRawPointer") { return "v" }
    if (typeName == "UnsafeRawBufferPointer") { return "W" }
    if (typeName == "UnsafeMutableRawBufferPointer") { return "w" }
    if (typeName == "Optional") { return "q" }
    if (typeName == "BinaryFloatingPoint") { return "B" }
    if (typeName == "Encodable") { return "E" }
    if (typeName == "Decodable") { return "e" }
    if (typeName == "FloatingPoint") { return "F" }
    if (typeName == "RandomNumberGenerator") { return "G" }
    if (typeName == "Hashable") { return "H" }
    if (typeName == "Numeric") { return "j" }
    if (typeName == "BidirectionalCollection") { return "K" }
    if (typeName == "RandomAccessCollection") { return "k" }
    if (typeName == "Comparable") { return "L" }
    if (typeName == "Collection") { return "l" }
    if (typeName == "MutableCollection") { return "M" }
    if (typeName == "RangeReplaceableCollection") { return "m" }
    if (typeName == "Equatable") { return "Q" }
    if (typeName == "Sequence") { return "T" }
    if (typeName == "IteratorProtocol") { return "t" }
    if (typeName == "UnsignedInteger") { return "U" }
    if (typeName == "RangeExpression") { return "X" }
    if (typeName == "Strideable") { return "x" }
    if (typeName == "RawRepresentable") { return "Y" }
    if (typeName == "StringProtocol") { return "y" }
    if (typeName == "SignedInteger") { return "Z" }
    if (typeName == "BinaryInteger") { return "z" }
    return nil
}

/// Mangles an identifier.
/// - parameter identifier: an identifier to mangle
/// - parameter buffer: a string where the mangled identifier is written to
/// - parameter words: an array of `SubstitutionWord` which holds the current list of found words which can be used for substitutions.
/// - parameter usePunycode: a flag indicating if punycode encoding should be done
/// - parameter maxNumWords: a maximum number of words that can be substituted
func mangle(identifier: String,
            buffer: inout String,
            words: inout [SubstitutionWord],
            usePunycode: Bool = true,
            maxNumWords: Int = 26
) {
    var substWordsInIdent = [WordReplacement]()
    var wordsInBuffer = words.count
    precondition(substWordsInIdent.isEmpty)
    if usePunycode && identifier.needsPunycodeEncoding {
        // If the identifier contains non-ASCII character, we mangle
        // with an initial '00' and Punycode the identifier string.
        guard let punycodeBuf = encodePunyCodeUTF8(identifier, mapNonSymbolChars: true) else {
            precondition(false)
            return
        }
        let pcIdent = punycodeBuf
        buffer << "00"
        buffer << pcIdent.count
        if pcIdent.unicodeScalars.first!.isDigit || pcIdent.unicodeScalars.first! == "_" {
            buffer << "_"
        }
        buffer << pcIdent
        return
    }

    let ident = identifier.unicodeScalars
    // Search for word substitutions and for new words.
    var wordStartPos = ident.endIndex
    for _Pos in 0...ident.count {
        let Pos = ident.index(ident.startIndex, offsetBy: _Pos)
        let ch: UnicodeScalar = Pos != ident.endIndex ? ident[Pos] : "\u{0}"
        if wordStartPos != ident.endIndex && ch.isWordEnd(prevCh: ident[ident.index(before: Pos)]) {
            // This position is the end of a word, i.e. the next character after a
            // word.
            precondition(Pos > wordStartPos)
            let wordLen = ident.distance(from: wordStartPos, to: Pos)
            let Word = ident[wordStartPos..<Pos]

            // Helper function to lookup the Word in a string.
            func lookupWord(str: String.UnicodeScalarView, fromWordIdx: size_t, toWordIdx: size_t) -> Int {
                for Idx in fromWordIdx..<toWordIdx {
                    let w: SubstitutionWord = words[Idx]
                    let existingWord =  str[str.index(str.startIndex, offsetBy: w.start)..<str.index(str.startIndex, offsetBy: w.start + w.length)]
                    if String(Word) == String(existingWord) {
                        return Idx
                    }
                }
                return -1
            }

            // Is the word already present in the so far mangled string?
            var WordIdx = lookupWord(str: buffer.unicodeScalars, fromWordIdx: 0, toWordIdx: wordsInBuffer)
            // Otherwise, is the word already present in this identifier?
            if WordIdx < 0 {
                WordIdx = lookupWord(str: ident, fromWordIdx: wordsInBuffer, toWordIdx: words.count)
            }

            let _wordStartPos  = ident.distance(from: ident.startIndex, to: wordStartPos)
            if WordIdx >= 0 {
                // We found a word substitution!
                precondition(WordIdx < 26)
                substWordsInIdent.append(WordReplacement(stringPos: _wordStartPos, WordIdx: WordIdx))
            } else if wordLen >= 2 && words.count < maxNumWords {
                // It's a new word: remember it.
                // Note: at this time the word's start position is relative to the
                // begin of the identifier. We must update it afterwards so that it is
                // relative to the begin of the whole mangled Buffer.
                words.append(SubstitutionWord(start: _wordStartPos, length: wordLen))
            }
            wordStartPos = ident.endIndex
        }
        if wordStartPos == ident.endIndex && ch.isWordStart {
            // This position is the begin of a word.
            wordStartPos = Pos
        }
    }
    // If we have word substitutions mangle an initial '0'.
    if !substWordsInIdent.isEmpty {
        buffer << "0"
    }

    var position = 0
    // Add a dummy-word at the end of the list.
    substWordsInIdent.append(WordReplacement(stringPos: ident.count, WordIdx: -1))

    // Mangle a sequence of word substitutions and sub-strings.
    let end: Int = substWordsInIdent.count
    for idx in 0..<end {
        let replacement: WordReplacement = substWordsInIdent[idx]
        if position < replacement.stringPos {
            // Mangle the sub-string up to the next word substitution (or to the end
            // of the identifier - that's why we added the dummy-word).
            // The first thing: we add the encoded sub-string length.
            buffer << (replacement.stringPos - position)
            precondition(!ident[ident.index(ident.startIndex, offsetBy: position)].isDigit, "first char of sub-string may not be a digit")
            repeat {
                // Update the start position of new added words, so that they refer to
                // the begin of the whole mangled Buffer.
                if wordsInBuffer < words.count && words[wordsInBuffer].start == position {
                    words[wordsInBuffer].start = buffer.count
                    wordsInBuffer += 1
                }
                // Add a literal character of the sub-string.
                buffer << ident[ident.index(ident.startIndex, offsetBy: position)]
                position += 1
            } while position < replacement.stringPos
        }
        // Is it a "real" word substitution (and not the dummy-word)?
        if replacement.WordIdx >= 0 {
            precondition(replacement.WordIdx <= wordsInBuffer)
            position += words[replacement.WordIdx].length
            if idx < end - 2 {
                buffer << UnicodeScalar(replacement.WordIdx + "a")!
            } else {
                // The last word substitution is a capital letter.
                buffer << UnicodeScalar(replacement.WordIdx + "A")!
                if position == ident.count {
                    buffer << "0"
                }
            }
        }
    }
    substWordsInIdent.removeAll()
}

/// Utility class for mangling merged substitutions. Used in the Mangler and Remangler.
class SubstitutionMerging {
    /// The position of the last substitution mangling, e.g. 3 for 'AabC' and 'Aab4C'
    var lastSubstPosition: size_t = 0

    /// The size of the last substitution mangling, e.g. 1 for 'AabC' or 2 for 'Aab4C'
    var lastSubstSize: size_t = 0

    /// The repeat count of the last substitution, e.g. 1 for 'AabC' or 4 for 'Aab4C'
    var lastNumSubsts: size_t = 0

    /// True if the last substitution is an 'S' substitution, false if the last substitution is an 'A' substitution.
    var lastSubstIsStandardSubst = false

    // The only reason to limit the number of repeated substitutions is that we don't want that the demangler blows up on a bogus substitution, e.g. ...A832456823746582B...
    static let maxRepeatCount = 2048

    func clear() {
        lastNumSubsts = 0
    }

    /// Tries to merge the substitution `subst` with a previously mangled substitution. Returns true on success. In case of `false`, the caller must mangle the substitution separately in the form `S<Subst>` or `A<Subst>`.
    func tryMergeSubst(subst: UnicodeScalar, isStandardSubst: Bool, buffer: inout String) -> Bool {
        precondition(subst.isUpper || (isStandardSubst && subst.isLower))
        if lastNumSubsts > 0 && lastNumSubsts < SubstitutionMerging.maxRepeatCount && buffer.unicodeScalars.count == lastSubstPosition + lastSubstSize && lastSubstIsStandardSubst == isStandardSubst {

            // The last mangled thing is a substitution.
            precondition(lastSubstPosition > 0 && lastSubstPosition < buffer.count)
            precondition(lastSubstSize > 0)
            let lastSubst: UnicodeScalar = buffer.unicodeScalars.last! // XXX
            precondition(lastSubst.isUpper || (isStandardSubst && lastSubst.isLower))
            if lastSubst != subst && !isStandardSubst {
                // We can merge with a different 'A' substitution,
                // e.g. 'AB' -> 'AbC'.
                lastSubstPosition = buffer.count
                lastNumSubsts = 1
                buffer = String(buffer.prefix(buffer.count - 1))
                precondition(lastSubst.isUpper)
                buffer << UnicodeScalar(lastSubst - "A" + "a")!
                buffer << subst
                lastSubstSize = 1
                return true
            }
            if lastSubst == subst {
                // We can merge with the same 'A' or 'S' substitution,
                // e.g. 'AB' -> 'A2B', or 'S3i' -> 'S4i'
                lastNumSubsts += 1
                buffer = String(buffer.prefix(lastSubstPosition)) // aka resetBuffer()
                buffer << lastNumSubsts
                buffer << subst
                lastSubstSize = buffer.count - lastSubstPosition
                return true
            }
        }
        // We can't merge with the previous substitution, but let's remember this
        // substitution which will be mangled by the caller.
        lastSubstPosition = buffer.count + 1
        lastSubstSize = 1
        lastNumSubsts = 1
        lastSubstIsStandardSubst = isStandardSubst
        return false
    }
}

/// The name of the standard library, which is a reserved module name.
let STDLIB_NAME = "Swift"
/// The name of the Onone support library, which is a reserved module name.
let SWIFT_ONONE_SUPPORT = "SwiftOnoneSupport"
/// The name of the SwiftShims module, which contains private stdlib decls.
let SWIFT_SHIMS_NAME = "SwiftShims"
/// The name of the Builtin module, which contains Builtin functions.
let BUILTIN_NAME = "Builtin"
/// The prefix of module names used by LLDB to capture Swift expressions
let LLDB_EXPRESSIONS_MODULE_NAME_PREFIX = "__lldb_expr_"

/// The name of the fake module used to hold imported Objective-C things.
let MANGLING_MODULE_OBJC = "__C"
/// The name of the fake module used to hold synthesized ClangImporter things.
let MANGLING_MODULE_CLANG_IMPORTER = "__C_Synthesized"

/// The name of the Builtin type prefix
let BUILTIN_TYPE_NAME_PREFIX = "Builtin."
/// The name of the Builtin type for Int
let BUILTIN_TYPE_NAME_INT = "Builtin.Int"
/// The name of the Builtin type for Int8
let BUILTIN_TYPE_NAME_INT8 = "Builtin.Int8"
/// The name of the Builtin type for Int16
let BUILTIN_TYPE_NAME_INT16 = "Builtin.Int16"
/// The name of the Builtin type for Int32
let BUILTIN_TYPE_NAME_INT32 = "Builtin.Int32"
/// The name of the Builtin type for Int64
let BUILTIN_TYPE_NAME_INT64 = "Builtin.Int64"
/// The name of the Builtin type for Int128
let BUILTIN_TYPE_NAME_INT128 = "Builtin.Int128"
/// The name of the Builtin type for Int256
let BUILTIN_TYPE_NAME_INT256 = "Builtin.Int256"
/// The name of the Builtin type for Int512
let BUILTIN_TYPE_NAME_INT512 = "Builtin.Int512"
/// The name of the Builtin type for IntLiteral
let BUILTIN_TYPE_NAME_INTLITERAL = "Builtin.IntLiteral"
/// The name of the Builtin type for Float
let BUILTIN_TYPE_NAME_FLOAT = "Builtin.FPIEEE"
/// The name of the Builtin type for NativeObject
let BUILTIN_TYPE_NAME_NATIVEOBJECT = "Builtin.NativeObject"
/// The name of the Builtin type for BridgeObject
let BUILTIN_TYPE_NAME_BRIDGEOBJECT = "Builtin.BridgeObject"
/// The name of the Builtin type for RawPointer
let BUILTIN_TYPE_NAME_RAWPOINTER = "Builtin.RawPointer"
/// The name of the Builtin type for UnsafeValueBuffer
let BUILTIN_TYPE_NAME_UNSAFEVALUEBUFFER = "Builtin.UnsafeValueBuffer"
/// The name of the Builtin type for UnknownObject
let BUILTIN_TYPE_NAME_UNKNOWNOBJECT = "Builtin.UnknownObject"
/// The name of the Builtin type for Vector
let BUILTIN_TYPE_NAME_VEC = "Builtin.Vec"
/// The name of the Builtin type for SILToken
let BUILTIN_TYPE_NAME_SILTOKEN = "Builtin.SILToken"
/// The name of the Builtin type for Word
let BUILTIN_TYPE_NAME_WORD = "Builtin.Word"
let SEMANTICS_PROGRAMTERMINATION_POINT = "programtermination_point"

let MANGLING_PREFIX = "$s"

func nodeConsumesGenericArgs(node: Node) -> Bool {
    switch node.kind {
    case .Variable: fallthrough
    case .Subscript: fallthrough
    case .ImplicitClosure: fallthrough
    case .ExplicitClosure: fallthrough
    case .DefaultArgumentInitializer: fallthrough
    case .Initializer:
        return false
    default:
        return true
    }
}

/// A simple default implementation that assigns letters to type parameters in alphabetic order.
func genericParameterName(depth: UInt64, index: UInt64) -> String {
    var name = ""
    var charIndex = index
    repeat {
        let letter = UnicodeScalar(UnicodeScalar("A").value + UInt32(charIndex % 26))! // yes, it's still going to be a valid unicode scalar
        name.unicodeScalars.append(letter)
        charIndex /= 26
    } while charIndex != 0
    if depth != 0 {
        name += "\(depth)"
    }
    return name

}

func manglingPrefixLength(mangledName: String) -> Int {
    for prefix in manglingPrefixes {
        if mangledName.starts(with: prefix) {
            return prefix.count
        }
    }
    return 0
}

