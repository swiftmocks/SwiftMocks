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

enum ExistentialDummyError: LocalizedError {
    case noConformancesFound(String)
    case noDecodableConformancesFound(String)
    case unsupportedProtocol(String)

    var errorDescription: String? {
        switch self {
        case let .noConformancesFound(name):
            return "No existing conformances for \(name) found. In order to be able to mock a protocol, SwiftMocks needs to glimpse a sample conformance; to create one, conform any class or struct with internal or public visibility to \(name)."
        case let .noDecodableConformancesFound(name):
            return "No decodable conformances for \(name) found. In order to be able to mock a protocol, SwiftMocks needs to glimpse a sample conformance; to create one, conform any class or struct with internal or public visibility to \(name)."
        case let .unsupportedProtocol(name):
            return "Mocking of \(name) is not supported. This version of SwiftMocks only supports simple protocols without associated types and base class requirement."
        }
    }
}

extension DummyFactory {
    /// Create a dummy of an existential type. This function is only in a separate file because of the size
    ///
    /// Dummies of any existential type are in fact instances of an `ExistentialDummy` class. There is initially nothing special about this class, but as dummies for new existential types are created, we dynamically register new protocol conformances for this class, so that its instances can be cast to the requested existential type.
    ///
    /// Besides dynamically registered conformances, creating an existential dummy requires synthesizing a witness table. Current runtime and type metadata do not contain function type information for protocol methods and vars, so the best we can do is scan currently loaded images for conformances to the same protocol, and extract method information from them.
    ///
    /// - Parameters:
    ///   - metadata: Type metadata
    ///   - storage: Memory to store the result, at least `metadata.valueWitnesses.size` bytes big
    ///   - witnessCreator: Function that creates witnesses based on `InvocationDescriptor`s
    func _existentialDummy(of metadata: ExistentialTypeMetadata, into storage: RawPointer, witnessCreator: (InvocationDescriptor) -> RawPointer) throws {
        if metadata == Metadata.of(Error.self) || metadata == Metadata.of(LocalizedError.self) || metadata == Metadata.of(CustomNSError.self) {
            let dummy = ErrorDummy()
            metadata.initialize(storage, withCopyOf: dummy)
            return
        }

        let dummyObject = ExistentialDummy()

        let dummyMetadata = Metadata.of(ExistentialDummy.self) as! ClassMetadata

        let witnessTables: [WitnessTable] = try getOrCreateWitnessTables(for: dummyMetadata, conformingTo: metadata.protocols, witnessCreator: witnessCreator)

        switch metadata.representation {
        case .opaque:
            let box = OpaqueExistentialBox(storage, numberOfWitnessTables: metadata.numberOfProtocols)
            box.container.buffer.asRawPointers[0] = Unmanaged.passRetained(dummyObject).toOpaque()
            box.container.type = Metadata.of(ExistentialDummy.self)
            box.witnessTables = witnessTables
        case .class:
            let box = ClassExistentialBox(storage, numberOfWitnessTables: metadata.numberOfProtocols)
            box.container.value = Unmanaged.passRetained(dummyObject).toOpaque()
            box.witnessTables = witnessTables
        case .error:
            notImplemented("existentials for error types")
        }
    }

    private func getOrCreateWitnessTables(for metadata: ClassMetadata, conformingTo protocols: [ProtocolDescriptor], witnessCreator: (InvocationDescriptor) -> RawPointer) throws -> [WitnessTable] {
        try protocols.map { proto -> WitnessTable in
            let key: CacheKey = CacheKey(proto: proto, metadata: metadata)
            if let cached = Self.cache[key] {
                return cached
            }

            let ret: WitnessTable = try createWitnessTable(for: metadata, conformingTo: proto, witnessCreator: witnessCreator)

            Self.cache[key] = ret

            return ret
        }
    }

    private func createWitnessTable(for metadata: ClassMetadata, conformingTo proto: ProtocolDescriptor, witnessCreator: (InvocationDescriptor) -> RawPointer) throws -> WitnessTable {
        if !proto.isSupportedProtocol {
            throw ExistentialDummyError.unsupportedProtocol(proto.name)
        }

        let type = TypeFactory.from(metadata: metadata)

        // since there is no runtime information about protocol methods, try to find existing conformances from which that information can be extracted
        let existingConformances = images.flatMap { $0.protocolConformances }.filter { $0.protocol == proto }
        guard !existingConformances.isEmpty else {
            throw ExistentialDummyError.noConformancesFound(proto.name)
        }

        // we cannot yet decode some conformances, like the ones for private or local classes, so let's try one by one to see if we can find one that we can decode
        for conformance in existingConformances {
            do {
                guard let witnesses = conformance.witnessTablePattern?.witnesses else {
                    continue
                }
                var baseWitnessTables = [WitnessTable]()
                var witnessDescriptors = [InvocationDescriptor]()
                for (i, req) in proto.requirements.enumerated() {
                    switch req.kind {
                    case .baseProtocol:
                        guard let baseProtocolWitnessTable = simpleDladdr(witnesses[i]) ?? simpleDladdr(proto.requirements[i].defaultImplementation) else {
                            unreachable()
                        }
                        let demangled = try? Mangle.demangleSymbol(mangledName: baseProtocolWitnessTable)
                        if let proto = try demangled?.asProtocolInWitnessTableBaseProtocolRequirement() {
                            // this is a pointer to a base protocol witness table
                            let baseWitnessTable = try createWitnessTable(for: metadata, conformingTo: proto, witnessCreator: witnessCreator)
                            baseWitnessTables.append(baseWitnessTable)
                        }

                    case .method,
                         .`init`,
                         .getter,
                         .setter,
                         .readCoroutine,
                         .modifyCoroutine,
                         .associatedTypeAccessFunction,
                         .associatedConformanceAccessFunction:
                        // TODO: default implementation is not tested, because I don't seem to ever see default implementation being non-nil, even in protocols with actual default implementations. Resilient protocols?
                        guard let mangledName = simpleDladdr(witnesses[i]) ?? simpleDladdr(proto.requirements[i].defaultImplementation) else {
                            unreachable()
                        }
                        let invocationDescriptor = try InvocationDescriptor(mangledName: mangledName, genericTypeParamReplacement: type)
                        witnessDescriptors.append(invocationDescriptor)
                    }
                }

                // ok, so now we have descriptors for all methods we need to synthesize for this witness table, and/or base witness tables.
                // one last thing that can throw, and then it's all smooth sail
                let (_, witnessTable) = try ProtocolConformanceDescriptor.registerConformance(of: metadata.typeContextDescriptor, conformingTo: proto, numberOfWitnesses: baseWitnessTables.count + witnessDescriptors.count)

                for (i, baseWitnessTable) in baseWitnessTables.enumerated() {
                    witnessTable.witnesses[i] = baseWitnessTable.pointer
                }
                for (i, invocationDescriptor) in witnessDescriptors.enumerated() {
                    witnessTable.witnesses[baseWitnessTables.count + i] = witnessCreator(invocationDescriptor)
                }

                return witnessTable
            } catch {
                // print(error)
                // oh well, can't decode this conformance
            }
        }

        throw ExistentialDummyError.noDecodableConformancesFound(proto.name)
    }

    private struct CacheKey: Hashable {
        let proto: ProtocolDescriptor
        let metadata: ClassMetadata
    }

    // needs to be static because we don't want to register duplicates of a conformance
    private static var cache = [CacheKey: WitnessTable]()
}

// allocation and deallocation
extension ProtocolConformanceDescriptor {
    /// Register a conformance of a type to a protocol.
    ///
    /// Since `ProtocolConformanceDescriptor` does not, in fact, support indirectable pointers for type references (crashes somewhere deep in the conformances lookup code), a relative *direct* pointer needs to be used. Therefore, the conformance needs to be allocated in the `__TEXT` segment, so that a relative direct pointer can reach the pointed-to type context descriptor, which is located there. To achieve that, a fixed amount of storage slots (`NUMBER_OF_PROTOCOL_CONFORMANCES`) is reserved in that segment during compile time.
    ///
    /// - Parameters:
    ///   - typeContextDescriptor: Descriptor of the conforming type
    ///   - proto: Protocol conformed to
    ///   - numberOfWitnesses: The number of witness pointers (excluding the first pointer, which points to conformance descriptor)
    static func registerConformance(of typeContextDescriptor: TypeContextDescriptor, conformingTo proto: ProtocolDescriptor, numberOfWitnesses: Int) throws -> (ProtocolConformanceDescriptor, WitnessTable) {
        // Reserve the necessary storage in the data section. We need to store conformance descriptor, witness table [pattern] and protocol conformance record; they will be laid out as follows:
        // - WitnessTable (N+1) * MemoryLayout<RawPointer>.size, namely:
        //   - WitnessTable.Pointee /* Pointer<TargetProtocolConformanceDescriptor> really */
        //   - numberOfWitnesses x MemoryLayout<RawPointer>.size
        // - ProtocolConformanceDescriptor.Pointee (16 bytes)
        // - ProtocolConformanceRecord (4 bytes)

        let used: Int = {
            var result = 0
            result += MemoryLayout<WitnessTable.Pointee>.size
            result += numberOfWitnesses * MemoryLayout<RawPointer>.size
            result.align(MemoryLayout<ProtocolConformanceDescriptor.Pointee>.alignment)
            result += MemoryLayout<ProtocolConformanceDescriptor.Pointee>.size
            result.align(MemoryLayout<ProtocolConformanceRecord>.alignment)
            result += MemoryLayout<ProtocolConformanceRecord>.size
            return result
        }()

        let storage = reserveDataSectionStorage(byteCount: used, alignment: max(MemoryLayout<ProtocolConformanceRecord>.alignment, MemoryLayout<RawPointer>.alignment, MemoryLayout<WitnessTable.Pointee>.alignment))

        let witnessTablePtr = storage.reinterpret(WitnessTable.Pointee.self)
        let conformanceDescriptorPtr = (witnessTablePtr.raw + MemoryLayout<WitnessTable.Pointee>.size + numberOfWitnesses * MemoryLayout<RawPointer>.size).reinterpret(ProtocolConformanceDescriptor.Pointee.self)
        let recordPtr = (conformanceDescriptorPtr.raw +  MemoryLayout<ProtocolConformanceDescriptor.Pointee>.size).reinterpret(ProtocolConformanceRecord.self)

        // first, set up the record to point to conformance descriptor
        conformanceDescriptorPtr.assign(to: &recordPtr.pointee)

        let descriptor = ProtocolConformanceDescriptor(conformanceDescriptorPtr)
        let witnessTable = WitnessTable(pointer: witnessTablePtr)

        // conformance descriptor and witness table [pattern] point to each other:
        witnessTablePtr.pointee.description = conformanceDescriptorPtr.raw
        witnessTablePtr.assign(to: &conformanceDescriptorPtr.pointee.witnessTablePattern)

        // finish with the descriptor
        assert(descriptor.flags.hasGenericWitnessTable == false)
        assert(descriptor.flags.hasResilientWitnesses == false)
        assert(descriptor.flags.isRetroactive == false)
        assert(descriptor.flags.isSynthesizedNonUnique == false)
        assert(descriptor.flags.numberOfConditionalRequirements == 0)

        descriptor.setProtocol(proto)
        descriptor.setTypeReference(.typeDescriptor(typeContextDescriptor))

        Runtime.registerProtocolConformanceRecords(begin: recordPtr, end: recordPtr + 1)
        return (descriptor, witnessTable)
    }

    private func setTypeReference(_ typeReference: TypeReference) {
        switch typeReference {
        case let .typeDescriptor(typeDescriptor):
            flags.typeReferenceKind = .directTypeDescriptor
            typeDescriptor.pointer.assign(to: &typedPointer.pointee.typeRef)
            // note: indirectable doesn't work here, crashing :(
        default:
            notImplemented()
        }
    }

    private func setProtocol(_ proto: ProtocolDescriptor) {
        pointee.protocolPtr.Offset = Int32(proto.pointer - pointer)
        // here, indirectable works, but what's the point if the type reference doesn't
        // pointee.ProtocolPtr.Offset = Int32(-MemoryLayout<Pointee>.offset(of: \__ProtocolConformanceDescriptor.ProtocolPtr)! - MemoryLayout<RawPointer>.size) | 1 /* indirectable */
        // (pointer - MemoryLayout<RawPointer>.size).reinterpret(RawPointer.self).pointee = newValue.pointer
    }

    /// If there's no initializer, no private storage, and all requirements are present, we don't have to instantiate anything.
    private var doesNotRequireInstantiation: Bool {
        guard let genericWitnessTable = genericWitnessTable else {
            return true
        }

        if genericWitnessTable.requiresInstantiation {
            return false
        }

        if !resilientWitnesses.isEmpty {
            return false
        }

        if genericWitnessTable.witnessTableSizeInWords != `protocol`.numberOfRequirements + Int(WitnessTableFirstRequirementOffset) {
            return false
        }

        if genericWitnessTable.instantiator != nil && genericWitnessTable.witnessTablePrivateSizeInWords > 0 {
            return false
        }

        return true
    }
}

private extension ProtocolDescriptor {
    /// Returns whether a protocol has no requirements in signature, or has a single one which is a class constraint
    var isSupportedProtocol: Bool {
        if numberOfRequirementsInSignature == 0 { return true }
        return hasOnlyProtocolOrClassLayoutRequirementSignature
    }

    private var hasOnlyProtocolOrClassLayoutRequirementSignature: Bool {
        !requirementSignature.contains {
            switch $0.kind {
            case .sameType:
                return true
            case .baseClass:
                return true
            case .protocol:
                return false
            case let .layout(kind):
                return kind != .class
            }
        }
    }
}

// if it ever becomes equatable, check the filters in the dsl
internal class ExistentialDummy {}

internal class ErrorDummy: Error, LocalizedError, CustomNSError {}
