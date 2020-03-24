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

/// The representation form of a function.
enum FunctionTypeRepresentation: Int8 {
    /// The default native function representation. A "thick" function that carries a context pointer to reference captured state.
    case swift
    /// A thick function that is represented as an Objective-C block.
    // case _block
    /// A "thin" function that needs no context.
    case thin
    /// A C function pointer, which is thin and also uses the C calling convention.
    // case cfunctionPointer
}

/// A function type has zero or more input parameters and a single result. The result type may be a tuple. For example: `(int) -> int` or `(a : int, b : int) -> (int, int)`.
/// There are two kinds of function types:  monomorphic (`FunctionType`) and polymorphic (`GenericFunctionType`). Both type families additionally can be 'thin', indicating that a function value has no capture context and can be represented at the binary level as a single function pointer.
class AnyFunctionType: AType, ATypeEquatable {
    // when adding new stored properties, remember to update isEqual
    let params: [Param]
    let resultType: AType
    let extInfo: ExtInfo
    let genericSignature: GenericSignature?

    var representation: FunctionTypeRepresentation {
        extInfo.representation
    }

    var silRepresentation: SILFunctionTypeRepresentation {
        extInfo.silRepresentation
    }

    fileprivate init(kind: TypeKind, params: [Param], output: AType, extInfo: ExtInfo, genericSignature: GenericSignature? = nil) {
        self.params = params
        self.resultType = output
        self.extInfo = extInfo
        self.genericSignature = genericSignature
        super.init(kind: kind)
    }

    func isEqual(to other: AType) -> Bool {
        guard let other = other as? AnyFunctionType else {
            return false
        }
        return params == other.params &&
            resultType == other.resultType &&
            extInfo == other.extInfo &&
            genericSignature == other.genericSignature
    }

    /// To be used only by `TypeFactory`
    static func _get(params: [Param], result: AType, extInfo: ExtInfo, genericSignature: GenericSignature?) -> AnyFunctionType {
        if let genericSignature = genericSignature {
            return GenericFunctionType(params: params, output: result, extInfo: extInfo, genericSignature: genericSignature)
        }

        return FunctionType(params: params, output: result, extInfo: extInfo)
    }

    /// To be used only by `TypeFactory`
    static func _get(metadata: FunctionTypeMetadata) -> AnyFunctionType {
        FunctionType(metadata: metadata)
    }

    /// Return a new instance with the given representation. To be used only by `TypeFactory`
    func _settingRepresentation(_ representation: SILFunctionTypeRepresentation) -> AnyFunctionType {
        let extInfo = self.extInfo.setting(silRepresentation: representation)
        if self is FunctionType {
            return FunctionType(params: params, output: resultType, extInfo: extInfo)
        }

        if self is GenericFunctionType {
            return GenericFunctionType(params: params, output: resultType, extInfo: extInfo, genericSignature: genericSignature!)
        }

        LoweringError.unreachable("bad function subclass")
    }
}

/// A monomorphic function type, specified with an arrow, for example: `let x : (Float, Int) -> Int`
class FunctionType: AnyFunctionType {
    fileprivate init(metadata: FunctionTypeMetadata) {
        let params: [Param]
        if metadata.flags.hasParameterFlags {
            params = zip(metadata.parameters, metadata.parameterFlags).map { Param(type: TypeFactory.from(metadata: $0.0), flags: ParameterTypeFlags(isVariadic: $0.1.isVariadic, isAutoclosure: $0.1.isAutoclosure, valueOwnership: $0.1.ownership), identifier: nil) }
        } else {
            params = metadata.parameters.map { Param(type: TypeFactory.from(metadata: $0), flags: .init()) }
        }
        super.init(kind: .function, params: params, output: TypeFactory.from(metadata: metadata.resultType), extInfo: ExtInfo(silRepresentation: metadata.flags.convention.asSILRepresentation, isNoEscape: !metadata.flags.isEscaping, throws: metadata.flags.throws))
    }

    init(params: [Param], output: AType, extInfo: ExtInfo) {
        super.init(kind: .function, params: params, output: output, extInfo: extInfo)
    }
}

/// A generic function type describes a function that is polymorphic with respect to some set of generic parameters and the requirements placed on those parameters and dependent member types thereof. The input and output types of the generic function can be expressed in terms of those generic parameters.
class GenericFunctionType: AnyFunctionType {
    fileprivate init(params: [Param], output: AType, extInfo: ExtInfo, genericSignature: GenericSignature) {
        super.init(kind: .function, params: params, output: output, extInfo: extInfo, genericSignature: genericSignature)
    }
}

private extension FunctionMetadataConvention {
    var asSILRepresentation: SILFunctionTypeRepresentation {
        switch self {
        case .swift:
            return .thick
        case .block:
            LoweringError.notImplemented("Objective-C blocks")
        case .thin:
            return .thin
        case .cFunctionPointer:
            LoweringError.notImplemented("C functions")
        }
    }
}

extension AnyFunctionType {
    struct Param: Hashable {
        let type: AType
        let identifier: String?
        let flags: ParameterTypeFlags

        init(type: AType, flags: ParameterTypeFlags = ParameterTypeFlags(), identifier: String? = nil) {
            self.type = type
            self.identifier = identifier
            self.flags = flags
        }

        var isVariadic: Bool {
            flags.isVariadic
        }

        var isAutoclosure: Bool {
            flags.isAutoclosure
        }

        var ownership: ValueOwnership {
            flags.valueOwnership
        }

        func getPlainType() -> AType {
            type
        }

        func getParameterType(forCanonical: Bool = true /* always canonical */) -> AType {
          let type = getPlainType()
          if isVariadic {
            LoweringError.notImplemented("variadic function parameters")
          }
          return type
        }
    }

    struct ExtInfo: Hashable {
        let silRepresentation: SILFunctionTypeRepresentation
        let isNoEscape: Bool
        let `throws`: Bool

        init(representation: FunctionTypeRepresentation = .swift, isNoEscape: Bool = false, `throws`: Bool = false) {
            self.silRepresentation = SILFunctionTypeRepresentation(rawValue: representation.rawValue)!
            self.isNoEscape = isNoEscape
            self.throws = `throws`
        }

        init(silRepresentation: SILFunctionTypeRepresentation, isNoEscape: Bool, `throws`: Bool) {
            self.silRepresentation = silRepresentation
            self.isNoEscape = isNoEscape
            self.throws = `throws`
        }

        var representation: FunctionTypeRepresentation {
            FunctionTypeRepresentation(rawValue: silRepresentation.rawValue) ?? .swift // if the value is too high, it means it's a SIL representation, and they all map to .swift
        }

        var hasSelfParam: Bool {
            switch silRepresentation {
            case .thick,
                 .thin,
                 .closure:
                return false
            case .method,
                 .witnessMethod:
                return true
            }
        }

        /// True if the function representation carries context.
        var hasContext: Bool {
            switch silRepresentation {
            case .thick:
                return true
            case .thin,
                 .method,
                 .witnessMethod,
                 .closure:
                return false
            }
        }

        func setting(silRepresentation: SILFunctionTypeRepresentation) -> ExtInfo {
            ExtInfo(silRepresentation: silRepresentation, isNoEscape: self.isNoEscape, throws: self.throws)
        }

        func setting(representation: FunctionTypeRepresentation) -> ExtInfo {
            ExtInfo(representation: representation, isNoEscape: self.isNoEscape, throws: self.throws)
        }

        func setting(throws: Bool) -> ExtInfo {
            ExtInfo(silRepresentation: silRepresentation, isNoEscape: self.isNoEscape, throws: `throws`)
        }
    }
}

