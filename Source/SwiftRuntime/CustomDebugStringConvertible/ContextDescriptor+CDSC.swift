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

extension ContextDescriptor: CustomStringConvertible {
    public var description: String {
        switch self {
        case let typeContextDescriptor as TypeContextDescriptor:
            return "\(Self.self)(name:\(typeContextDescriptor.name))"
        case let moduleContextDescriptor as ModuleContextDescriptor:
            return "ModuleContextDescriptor(name: \(moduleContextDescriptor.name))"
        case let anonymousContextDescriptor as AnonymousContextDescriptor:
            return "AnonymousContextDescriptor(name: \(anonymousContextDescriptor.hasMangledContextName ? anonymousContextDescriptor.mangledContextName : "<nil>")"
        case let protocolDescriptor as ProtocolDescriptor:
            return "ProtocolDescriptor(name: \(protocolDescriptor.name))"
        default:
            return "\(Self.self)"
        }
    }
}

extension ClassDescriptor: CustomDebugStringConvertible {
    public var debugDescription: String {
        "ClassDescriptor"
            .appending("name", name)
            .appending("kind", kind)
            .appending("isGeneric", isGeneric)
            .appending("parent", parent)
            .appending("kindSpecificFlags", String(binary: kindSpecificFlags))
            .appending("fieldDescriptor", fieldDescriptor, onlyIf: fieldDescriptor != nil && fieldDescriptor?.numberOfFields != 0)
            .appending("fields", fields, condensed: false, onlyIf: fields.count > 0)
            .appending("superclassTypeMangledName", try? Mangle.demangleType(mangledName: superclassTypeMangledName!).description, onlyIf: superclassTypeMangledName != nil)
            .appending("numImmediateMembers", numImmediateMembers)
            .appending("fieldOffsetVectorOffset", fieldOffsetVectorOffset)
            .appending("vtableOffset", vtableOffset, onlyIf: hasVTable)
            .appending("vtableSize", vtableSize, onlyIf: hasVTable)
            .appending("methods", vtableMethods, condensed: false, onlyIf: hasVTable)
            .appending("numberOfOverrideTableEntries", numberOfOverrideTableEntries, onlyIf: hasOverrideTable)
            .appending("overrideMethodDescriptors", overrideMethods, condensed: false, onlyIf: hasOverrideTable)
            .appendingTypeGenericContextDebugDescription(self)
    }
}

extension StructDescriptor: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "StructDescriptor"
            .appending("name", name)
            .appending("isGeneric", isGeneric)
            .appending("kindSpecificFlags", String(binary: kindSpecificFlags), onlyIf: kindSpecificFlags != 0)
            .appending("parent", parent)
            .appending("fieldDescriptor", fieldDescriptor, onlyIf: fieldDescriptor != nil && fieldDescriptor?.numberOfFields != 0)
            .appending("fields", fields, condensed: false, onlyIf: fields.count > 0)
            .appendingTypeGenericContextDebugDescription(self)
    }
}

extension EnumDescriptor: CustomDebugStringConvertible {
    public var debugDescription: String {
        "EnumDescriptor"
            .appending("name", name)
            .appending("numberOfEmptyCases", numberOfEmptyCases)
            .appending("numberOfPayloadCases", numberOfPayloadCases)
            .appending("payloadSizeOffset", payloadSizeOffset)
            .appending("fieldDescriptor", fieldDescriptor, onlyIf: fieldDescriptor != nil && fieldDescriptor?.numberOfFields != 0)
            .appending("fields", fields, condensed: false, onlyIf: fields.count > 0)
            .appendingTypeGenericContextDebugDescription(self)
    }
}

extension ProtocolDescriptor: CustomDebugStringConvertible {
    public var debugDescription: String {
        if numberOfRequirementsInSignature == 0 && numberOfRequirements == 0 && associatedTypeNames.isEmpty {
            return "ProtocolDescriptor(name: \(name))"
        }
        return "ProtocolDescriptor"
            .appending("name", name)
            .appending("associatedTypeNames", associatedTypeNames, onlyIf: !associatedTypeNames.isEmpty)
            .appending("requirementSignature", requirementSignature, onlyIf: requirementSignature.count > 0)
            .appending("requirements", requirements, condensed: false)
    }
}

extension ModuleContextDescriptor: CustomDebugStringConvertible {
    public var debugDescription: String {
        "ModuleContextDescriptor(name: \(name))"
    }
}

extension AnonymousContextDescriptor: CustomDebugStringConvertible {
    public var debugDescription: String {
        var result = "AnonymousContextDescriptor"
            .appending("mangledContextName", mangledContextName)
        if isGeneric {
            result = result
                .appending("numberOfGenericParameters", numberOfGenericParameters)
                .appending("numberOfGenericRequirements", numberOfGenericRequirements)
                .appending("numberOfGenericKeyArguments", numberOfGenericKeyArguments)
                .appending("numberOfGenericExtraArguments", numberOfGenericExtraArguments)
                .appending("genericParams", genericParams, condensed: false)
                .appending("genericRequirements", genericRequirements, condensed: false)
        }
        return result
    }
}

extension ExtensionContextDescriptor: CustomDebugStringConvertible {
    public var debugDescription: String {
        var result = "ExtensionContextDescriptor"
            .appending("extendedContextType", resolveExtendedContextType)
        if isGeneric {
            result = result
                .appending("numberOfGenericParameters", numberOfGenericParameters)
                .appending("numberOfGenericRequirements", numberOfGenericRequirements)
                .appending("numberOfGenericKeyArguments", numberOfGenericKeyArguments)
                .appending("numberOfGenericExtraArguments", numberOfGenericExtraArguments)
                .appending("genericParams", genericParams, condensed: false)
                .appending("genericRequirements", genericRequirements, condensed: false)
        }
        return result
    }
}

private extension String {
    func appendingTypeGenericContextDebugDescription(_ descriptor: TypeGenericContext) -> String {
        guard descriptor.isGeneric else { return self }
        return self
            .appending("numberOfGenericParameters", descriptor.numberOfGenericParameters)
            .appending("numberOfGenericRequirements", descriptor.numberOfGenericRequirements)
            .appending("numberOfGenericKeyArguments", descriptor.numberOfGenericKeyArguments)
            .appending("numberOfGenericExtraArguments", descriptor.numberOfGenericExtraArguments)
            .appending("genericParams", descriptor.genericParams, condensed: false)
            .appending("genericRequirements", descriptor.genericRequirements, condensed: false)
    }
}

// PRAGMA MARK: -

extension GenericParamDescriptor: CustomDebugStringConvertible {
    public var debugDescription: String {
        "GenericParamDescriptor"
            .appending("hasKeyArgument", hasKeyArgument)
            .appending("hasExtraArgument", hasExtraArgument)
            .appending("kind", kind)
    }
}

extension GenericRequirementDescriptor: CustomDebugStringConvertible {
    public var debugDescription: String {
        "GenericRequirementDescriptor"
            .appending("kind", kind)
            .appending("hasKeyArgument", hasKeyArgument)
            .appending("hasExtraArgument", hasExtraArgument)
            .appending("type", String(cString: mangledTypeName))
    }
}

extension MethodOverrideDescriptor: CustomDebugStringConvertible {
    public var debugDescription: String {
        "MethodOverrideDescriptor"
            .appending("class", `class`)
            .appending("method", method)
            .appending("impl", impl)
    }
}

extension MethodDescriptor: CustomDebugStringConvertible {
    public var debugDescription: String {
        "MethodDescriptor"
            .appending("kind", kind)
            .appending("isInstance", isInstance)
            .appending("isDynamic", isDynamic)
            .appending("impl", "\(impl != nil ? "\(impl!)" : "<nil>") -> \(simpleDladdr(impl) ?? "<unknown>")")
    }
}

extension ProtocolRequirement: CustomDebugStringConvertible {
    public var debugDescription: String {
        "ProtocolRequirement"
            .appending("kind", kind)
            .appending("isInstance", isInstance)
            .appending("defaultImplementation", defaultImplementation, onlyIf: defaultImplementation != nil)
    }
}
