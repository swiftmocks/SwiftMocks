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

extension OpaqueMetadata: CustomDebugStringConvertible {
    public var debugDescription: String {
        if let kind = OpaqueMetadata.Builtin.kind(of: self) {
            return "Builtin.\(kind) (OpaqueMetadata)"
        } else {
            return "OpaqueMetadata(\(pointer))"
        }
    }
}

extension ClassMetadata: CustomDebugStringConvertible {
    public var debugDescription: String {
        guard !isPureObjC else {
            return "ClassMetadata(\(pointer))"
                .appending("isPureObjC", isPureObjC)
                .appending("superclass", superclass, onlyIf: superclass != nil)
        }
        return "ClassMetadata(\(pointer))"
            .appending("kind", kind)
            .appending("superclass", superclass)
            .appending("flags", String(binary: flags.rawValue))
            .appending("instanceAddressPoint", instanceAddressPoint)
            .appending("instanceSize", instanceSize)
            .appending("classSize", classSize)
            .appending("classAddressPoint", classAddressPoint)
            .appending("ivarDestroyer", ivarDestroyer, onlyIf: ivarDestroyer != nil)
            .appending("fieldOffsets", fieldOffsets, condensed: true, onlyIf: fieldOffsets.count > 0)
            .appending("description", description)
            .appending("vtable", zip(vtable!, vtable!.map { simpleDladdr($0) ?? "<unknown>" }).map { "\($0) -> \($1)" }, condensed: false, onlyIf: description.hasVTable)
            .appending("destroy", "\(destroy) -> \(simpleDladdr(destroy) ?? "n/a")")
    }
}

extension StructMetadata: CustomDebugStringConvertible {
    public var debugDescription: String {
        "StructMetadata(\(pointer))"
            .appending("fieldOffsets", fieldOffsets, condensed: true, onlyIf: fieldOffsets.count > 0)
            .appending("description", description)
    }
}

extension EnumMetadata: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "EnumMetadata(\(pointer))"
            .appending("hasPayloadSize", hasPayloadSize)
            .appending("payloadSize", payloadSize, onlyIf: hasPayloadSize)
            .appending("description", description)
    }
}

extension TupleTypeMetadata.Element: CustomDebugStringConvertible {
    public var debugDescription: String {
        "Element(\(pointer))"
            .appending("type", metadata.asAnyType!)
            .appending("offset", offset)
    }
}

extension TupleTypeMetadata: CustomDebugStringConvertible {
    public var debugDescription: String {
        if numberOfElements == 0 { return "()" }
        return "TupleTypeMetadata(\(pointer))"
            .appending("elements", elements, condensed: false)
            .appending("labels", labels)
    }
}

extension ExistentialTypeMetadata: CustomDebugStringConvertible {
    public var debugDescription: String {
        "ExistentialTypeMetadata(\(pointer))"
            .appending("numberOfProtocols", numberOfProtocols)
            .appending("numberOfWitnessTables", flags.numberOfWitnessTables)
            .appending("protocolClassConstraint", flags.classConstraint)
            .appending("hasSuperclassConstraint", flags.hasSuperclassConstraint)
            .appending("isSpecialProtocol", flags.specialProtocol)
            .appending("representation", representation)
            .appending("protocols", protocols, condensed: false)
            .appending("superclassConstraint", superclassConstraint)
    }
}

extension FunctionTypeFlags: CustomDebugStringConvertible {
    public var debugDescription: String {
        "FunctionTypeFlags"
            .appending("numberOfParameters", numberOfParameters)
            .appending("convention", convention)
            .appending("throws", `throws`)
            .appending("isEscaping", isEscaping)
            .appending("hasParameterFlags", hasParameterFlags)
    }
}

extension ParameterFlags: CustomDebugStringConvertible {
    public var debugDescription: String {
        "ParameterFlags(\(pointer))"
            .appending("ownership", ownership)
            .appending("isVariadic", isVariadic)
            .appending("isAutoclosure", isAutoclosure)
    }
}

extension FunctionTypeMetadata: CustomDebugStringConvertible {
    public var debugDescription: String {
        "FunctionTypeMetadata(\(pointer))"
            .appending("flags", flags)
            .appending("parameterFlags", parameterFlags, onlyIf: flags.hasParameterFlags)
            .appending("parameters", parameters, condensed: false, onlyIf: parameters.count > 0)
            .appending("result", resultType)
    }
}

extension MetatypeMetadata: CustomDebugStringConvertible {
    public var debugDescription: String {
        "MetatypeMetadata(\(pointer))"
            .appending("instanceType", instanceType)
    }
}

extension ExistentialTypeFlags: CustomDebugStringConvertible {
    public var debugDescription: String { "numberOfWitnessTables=\(numberOfWitnessTables), protocolClassConstraint=\(classConstraint), hasSuperclassConstraint=\(hasSuperclassConstraint), isSpecialProtocol=\(specialProtocol)" }
}

extension ExistentialMetatypeMetadata: CustomDebugStringConvertible {
    public var debugDescription: String {
        "ExistentialMetatypeMetadata(\(pointer))"
            .appending("instanceType", instanceType)
            .appending("flags", flags)
    }
}

extension HeapLocalVariableMetadata: CustomDebugStringConvertible {
    public var debugDescription: String {
        "HeapLocalVariableMetadata(\(pointer))"
            .appending("offsetToFirstCapture", offsetToFirstCapture)
            .appending("captureDescription", captureDescription)
    }
}

extension ValueWitnessTable: CustomDebugStringConvertible {
    public var debugDescription: String {
        "ValueWitnessTable"
            .appending("size", size)
            .appending("stride", stride)
            .appending("numberOfExtraInhabitants", numberOfExtraInhabitants)
            .appending("isInlineStorage", isValueInline)
            .appending("isPOD", isPOD)
            .appending("isBitwiseTakable", isBitwiseTakable)
            .appending("hasEnumWitnesses", hasEnumWitnesses)
            .appending("isIncomplete", isIncomplete)
            .appending("initializeBufferWithCopyOfBuffer", unsafeBitCast(pointee.initializeBufferWithCopyOfBuffer, to: RawPointer.self).withDladdrInfo)
            .appending("destroy", unsafeBitCast(pointee.destroy, to: RawPointer.self).withDladdrInfo)
            .appending("initializeWithCopy", unsafeBitCast(pointee.initializeWithCopy, to: RawPointer.self).withDladdrInfo)
            .appending("assignWithCopy", unsafeBitCast(pointee.assignWithCopy, to: RawPointer.self).withDladdrInfo)
            .appending("initializeWithTake", unsafeBitCast(pointee.initializeWithTake, to: RawPointer.self).withDladdrInfo)
            .appending("assignWithTake", unsafeBitCast(pointee.assignWithTake, to: RawPointer.self).withDladdrInfo)
            .appending("getEnumTagSinglePayload", unsafeBitCast(pointee.getEnumTagSinglePayload, to: RawPointer.self).withDladdrInfo)
            .appending("storeEnumTagSinglePayload", unsafeBitCast(pointee.storeEnumTagSinglePayload, to: RawPointer.self).withDladdrInfo)
            .appending("getEnumTag", unsafeBitCast(evwtPointee.getEnumTag, to: RawPointer.self).withDladdrInfo, onlyIf: hasEnumWitnesses)
            .appending("destructiveProjectEnumData", unsafeBitCast(evwtPointee.destructiveProjectEnumData, to: RawPointer.self).withDladdrInfo, onlyIf: hasEnumWitnesses)
            .appending("destructiveInjectEnumTag", unsafeBitCast(evwtPointee.destructiveInjectEnumTagPtr, to: RawPointer.self).withDladdrInfo, onlyIf: hasEnumWitnesses)
    }
}

extension WitnessTable: CustomDebugStringConvertible {
    public var debugDescription: String {
        "WitnessTable(\(pointer))"
            .appending("descriptor", descriptor)
    }
}

extension ConformanceFlags: CustomDebugStringConvertible {
    public var debugDescription: String {
        "ConformanceFlags"
            .appending("typeReferenceKind", typeReferenceKind)
            .appending("isRetroactive", isRetroactive)
            .appending("isSynthesizedNonUnique", isSynthesizedNonUnique)
            .appending("numberOfConditionalRequirements", numberOfConditionalRequirements)
            .appending("hasResilientWitnesses", hasResilientWitnesses)
            .appending("hasGenericWitnessTable", hasGenericWitnessTable)
    }
}

extension TypeReference: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case let .typeDescriptor(contextDescriptor): return " ".appending("typeDescriptor", contextDescriptor)
        case let .objCClassName(name): return "objCClassName(\"\(name)\")"
        case let .objCClass(metadata): return " ".appending("objCClass", metadata)
        }
    }
}

extension GenericWitnessTable: CustomDebugStringConvertible {
    public var debugDescription: String {
        "GenericWitnessTable(\(pointer))"
            .appending("witnessTableSizeInWords", witnessTableSizeInWords)
            .appending("witnessTablePrivateSizeInWords", witnessTablePrivateSizeInWords)
            .appending("requiresInstantiation", requiresInstantiation)
            .appending("privateData", privateData, onlyIf: privateData != nil)
    }
}

extension ResilientWitness: CustomDebugStringConvertible {
    public var debugDescription: String {
        "ResilientWitness"
            .appending("requirement", requirement)
            .appending("witness", witness)
    }
}

extension ProtocolConformanceDescriptor: CustomDebugStringConvertible {
    public var debugDescription: String {
        "ProtocolConformanceDescriptor(\(pointer))"
            .appending("protocol", self.protocol)
            .appending("typeReference", typeReference)
            .appending("flags", flags)
            .appending("witnessTablePattern", witnessTablePattern!.pointer, onlyIf: witnessTablePattern != nil)
            .appending("retroactiveContext", retroactiveContext, onlyIf: retroactiveContext != nil)
            .appending("genericRequirements", genericRequirements, condensed: false, onlyIf: genericRequirements.count > 0)
            .appending("resilientWitnesses", resilientWitnesses, condensed: false, onlyIf: resilientWitnesses.count > 0)
            .appending("genericWitnessTable", genericWitnessTable, onlyIf: genericWitnessTable != nil)
    }
}

extension ValueBuffer: CustomDebugStringConvertible {
    public var debugDescription: String {
        "ValueBuffer(value: [\(asRawPointers.map { $0.debugDescription } .joined(separator: ", "))])"
    }
}

private extension RawPointer {
    var withDladdrInfo: String {
        "\(self) -> \(simpleDladdr(self) ?? "n/a")"
    }
}
