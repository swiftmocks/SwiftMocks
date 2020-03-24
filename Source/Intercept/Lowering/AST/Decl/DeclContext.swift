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

/// A `DeclContext` is an AST object which acts as a semantic container for declarations.
enum DeclContext {
    case topLevel
    case genericTypeContext(GenericTypeDecl)
    case `extension`(NominalTypeDecl)

    /// If this `DeclContext` is a protocol, or an extension on a protocol, return the `ProtocolDecl`, otherwise return nil.
    var selfProtocolDecl: ProtocolDecl? {
        selfTypeDecl as? ProtocolDecl
    }

    /// If this `DeclContext` is a GenericType declaration or an extension thereof, return the `GenericTypeDecl`.
    var selfTypeDecl: GenericTypeDecl? {
        switch self {
        case .topLevel:
            return nil
        case let .genericTypeContext(typeDecl):
            return typeDecl
        case let .extension(typeDecl):
            return typeDecl
        }
    }

    /// Retrieve the interface type of 'self' for the given context.
    var selfInterfaceType: AType? {
        precondition(isTypeContext)
        // For a protocol or extension thereof, the type is 'Self'.
        if let protoDecl = selfProtocolDecl {
            return protocolSelfType
        }

        return declaredInterfaceType
    }

    var declaredInterfaceType: AType? {
        selfTypeDecl?.declaredInterfaceType
    }

    var protocolSelfType: GenericTypeParamType? {
        precondition(selfTypeDecl is ProtocolDecl)
        return GenericTypeParamType.tau00 // when generics are supported, this will need an actual implementation
    }

    var isGenericContext: Bool {
        LoweringError.notImplemented(#function)
    }

    /// `true` if this is a type context, e.g., a struct, a class, an enum, a protocol, or an extension.
    var isTypeContext: Bool {
        switch self {
        case .topLevel:
            return false
        case .genericTypeContext:
            return true
        case .extension:
            return true
        }
    }
}
