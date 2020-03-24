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

extension BuiltinIntegerType: CustomStringConvertible {
    var description: String {
        if let kind = OpaqueMetadata.Builtin.kind(of: opaqueMetadata) {
            return "Builtin.\(kind)"
        } else {
            return "Builtin.UnknownKind"
        }
    }
}

extension NominalType: CustomStringConvertible {
    var description: String {
        metadata.silDescription
    }
}

extension NominalType: CustomDebugStringConvertible {
    var debugDescription: String {
        "\(Self.self): \(metadata.silDescription)"
    }
}

extension BoundGenericType: CustomStringConvertible {
    var description: String {
        typeContextDescriptor.fqn + (typeContextDescriptor.isGeneric ? "<" + genericParams.map { "\($0)" }.joined(separator: ", ") + ">" : "") // XXX: add protocol conformances (witness tables)
    }
}

extension BoundGenericType: CustomDebugStringConvertible {
    var debugDescription: String {
        "\(Self.self)"
            .appending("typeContextDescriptor", typeContextDescriptor)
            .appending("genericParams", genericParams, condensed: true) // XXX: add protocol conformances (witness tables)
    }
}

extension TupleType: CustomStringConvertible {
    var description: String {
        "(" + elements.map { "\($0)" }.joined(separator: ", ") + ")"
    }
}

extension ProtocolCompositionType: CustomStringConvertible {
    var description: String {
        metadata.silDescription
    }
}

extension ProtocolCompositionType: CustomDebugStringConvertible {
    var debugDescription: String {
        "\(Self.self) \(self.metadata)"
    }
}

extension AnyMetatypeType: CustomStringConvertible {
    var description: String {
        let instanceTypeDescription: String
        if let protocomp = instanceType as? ProtocolCompositionType {
            instanceTypeDescription = "(\(protocomp))"
        } else {
            instanceTypeDescription = "\(instanceType)"
        }
        if let repr = representation {
            return "\(repr) \(instanceTypeDescription).Type"
        }
        return "\(instanceTypeDescription).Type"
    }
}

extension AnyMetatypeType: CustomDebugStringConvertible {
    var debugDescription: String {
        "\(Self.self) \(instanceType) \(representation?.description ?? "")"
    }
}

extension AnyFunctionType.Param: CustomStringConvertible {
    var description: String {
        let ownership: String?
        switch self.ownership {
        case .default:
            ownership = nil
        case .inOut:
            ownership = "inout"
        case .shared:
            ownership = "__shared"
        case .owned:
            ownership = "__owned"
        }
        var flags = [String]()
        if self.flags.isVariadic {
            flags.append("variadic")
        }
        if self.flags.isAutoclosure {
            flags.append("autoclosure")
        }
        if let ownership = ownership {
            flags.insert(ownership, at: 0)
        }
        var ret = (identifier != nil ? "\(identifier!): " : "") + "\(type)"
        if !flags.isEmpty {
            ret += " (" + flags.joined(separator: ", ") + ")"
        }
        return ret
    }
}

extension FunctionType: CustomStringConvertible {
    var description: String {
        var ret = ""
        if silRepresentation != .thick {
            ret += "@convention(\(representation)) "
        }
        ret += "(" + params.map { $0.description }.joined(separator: ", ") + ")"

        let resultDescription = "\(resultType)"
        if extInfo.throws {
            ret += " throws"
        }
        ret += " -> " + resultDescription
        return ret
    }
}

extension FunctionType: CustomDebugStringConvertible {
    var debugDescription: String {
        "FunctionType"
            .appending("params", params.map { "\($0)" }, condensed: true)
            .appending("result", resultType)
    }
}

extension GenericFunctionType: CustomStringConvertible {
    var description: String {
        debugDescription // XXX
    }
}

extension GenericFunctionType: CustomDebugStringConvertible {
    var debugDescription: String {
        "GenericFunctionType"
            .appending("params", params.map { "\($0)" }, condensed: true)
            .appending("result", resultType)
            .appending("genericSignature", genericSignature!)
    }
}

extension GenericTypeParamType: CustomStringConvertible {
    var description: String {
        "τ_\(depth)_\(index)"
    }
}

extension Requirement.Kind: CustomStringConvertible {
    var description: String {
        switch self {
        case .conformance:
            return "conforms_to"
        case .layout:
            return "layout"
        case .superclass:
            return "superclass"
        case .sameType:
            return "same_type"
        }
    }
}

extension Requirement: CustomStringConvertible {
    var description: String {
        precondition(kind == .conformance) // that's the only thing we support
        return "\(kind.description): \(first) \(second!)"
    }
}

extension GenericSignature: CustomStringConvertible {
    var description: String {
        var ret = "<" + genericParams.map { "\($0)" }.joined(separator: ", ")
        if !requirements.isEmpty {
            ret += " where "
            ret += requirements.map { req -> String in
                precondition(req.kind == .conformance)
                return "\(req.first) : \(req.second!)"
            }
            .joined(separator: ", ")
        }
        ret += ">"
        return ret
    }
}

extension DynamicSelfType: CustomStringConvertible {
    var description: String {
        "Self"
    }
}

extension Metadata {
    // The default description of Any.Type gives just the name of the type, without parents. We want parents too, but no module.
    // For now this only works with non-generic parents; for generic parents we need to add the generic args as we walk up the parent chain
    var silDescription: String {
        if let existentialTypeMetadata = self as? ExistentialTypeMetadata {
            if existentialTypeMetadata.protocols.isEmpty {
                return existentialTypeMetadata.isClassBounded ? "AnyObject" : "Any"
            }
            return existentialTypeMetadata.protocols.map { $0.name }.joined(separator: " & ")
        }
        guard let typeContextDescriptor = typeContextDescriptor else {
            return "<no type descriptor>"
        }
        let parentChain = typeContextDescriptor.parentChain
        let fullName = parentChain.isEmpty ? typeContextDescriptor.name : parentChain.map { $0.name }.joined(separator: ".") + "." + typeContextDescriptor.name
        let ret = fullName + (typeContextDescriptor.isGeneric ? "<" + genericParameters.map { "\($0)" }.joined(separator: ", ") + ">" : "")
        return ret
    }
}

private extension TypeContextDescriptor {
    var fqn: String {
        return parentChain.isEmpty ? name : parentChain.map { $0.name }.joined(separator: ".") + "." + name
    }
}

private let anyObjectMetadata: Metadata = {
    Metadata.of(AnyObject.self)
}()

private let anyMetadata: Metadata = {
    Metadata.of(Any.self)
}()

private extension TypeContextDescriptor {
    /// Returns a chain of _only_ `TypeContextDescriptor`s
    var parentChain: [TypeContextDescriptor] {
        var result = [TypeContextDescriptor]()
        var parent = self
        while let newParent = parent.parent as? TypeContextDescriptor {
            parent = newParent
            result.append(parent)
        }
        return result
    }
}
