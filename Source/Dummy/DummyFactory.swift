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

public enum DummyError: LocalizedError {
    case notImplemented(String)

    public var errorDescription: String? {
        "\(Self.self).\(self)"
    }
}

class DummyFactory {
    private let interceptor: Interceptor
    let images: [MachImage]

    init(interceptor: Interceptor, images: [MachImage]) {
        self.images = images
        self.interceptor = interceptor
    }

    /// Creates a dummy instance of (almost) any type.
    ///
    /// - Important
    /// When called for a class, even when `unique` is specified, the returned object will be held in the internal pool (unrelated to any caches). Periodically, the client code should call `gcDummies()` to dispose of those objects in a safe manner.
    ///
    /// **Rationale.** In the general case, it is impossile to create a dummy that will work nicely with the `deinit` of an arbitrary class. Especially in the stdlib, where COW is done via storage classes that rely on manually allocated memory (via unsafe pointers and buffers), it is impossible to know what to assign to that pointer to keep deinit happy.
    ///
    /// **Solution.** In `gcDummies()`, every object in the pool cache which has retain count of 1 is turned into a pumpkin by assigning it a metadata whose `deinit` is known to not touch any vars — and then it is removed from the pool. This causes immediate deallocation, which uses the safe `deinit`.
    ///
    /// **Further improvement.** The contents of the vars will leak, since there is no one to take care of them. The next step would be to iterate through the vars and use VWT->destroy() to dispose of that content.
    public func dummyInstance<T>(of type: T.Type = T.self) throws -> T {
        let storage: Pointer<T> = Pointer.allocateWithZeroFill(size: 1)
        defer {
            storage.deallocate()
        }

        let metadata = Metadata.of(type)
        try dummyInstance(of: metadata, into: storage)

        return storage.move()
    }

    public func dummy(of metadata: Metadata) throws -> Any {
        let storage: RawPointer = RawPointer.allocateWithZeroFill(size: metadata.valueWitnesses.size, alignment: metadata.valueWitnesses.alignmentMask + 1)
        defer {
            storage.deallocate()
        }

        try dummyInstance(of: metadata, into: storage)

        let ret = metadata.copy(from: storage) // FIXME: this leaks memory
        return ret
    }

    public func gcDummies() {
        let toGC = dummyObjectsPool.filter { Runtime.retainCount($0) == 1 }
        guard !toGC.isEmpty else {
            return
        }

        dummyObjectsPool = dummyObjectsPool.filter { Runtime.retainCount($0) != 1 }

        for pointer in toGC {
            // replace metadata
            pointer.reinterpret(RawPointer.self).pointee = classWithoutVarsMetadata.pointer
            Runtime.release(pointer)
        }
    }

    private var dummyObjectsPool = Set<RawPointer>()

    private func dummyInstance(of metadata: Metadata, into storage: RawPointer) throws {
        if commonDummy(of: metadata, into: storage) {
            return
        }

        switch metadata {
        case is OpaqueMetadata:
            // do nothing, all builtins are good to go with just the initial zero-fill.
            // almost.
            break
        case let metadata as StructMetadata:
            try structDummyInstance(of: metadata, into: storage)
        case let metadata as ClassMetadata:
            let dummy = try classDummyInstance(of: metadata, into: storage)
            if !dummyObjectsPool.contains(dummy) {
                Runtime.retain(dummy)
                dummyObjectsPool.insert(dummy)
            }
        case let existentialTypeMetadata as ExistentialTypeMetadata:
            try existentialDummy(of: existentialTypeMetadata, into: storage)
        case let metadata as EnumMetadata:
            try enumDummy(of: metadata, into: storage)
        case let metadata as TupleTypeMetadata:
            try tupleDummy(of: metadata, into: storage)
        case is FunctionTypeMetadata:
            // nothing to do. these functions should never be called, so no point in filling the contents
            break
        case let metadata as MetatypeMetadata:
            storage.reinterpret(RawPointer.self).pointee = metadata.instanceType.pointer
        case let metadata as ExistentialMetatypeMetadata:
            storage.reinterpret(RawPointer.self).pointee = metadata.instanceType.pointer
        default:
            throw DummyError.notImplemented("\(#function) for: \(metadata)).")
        }
    }

    internal var cachedStructDummyInstances = [StructMetadata: Any]()

    internal func structDummyInstance(of metadata: StructMetadata, into storage: RawPointer) throws {
        if let cached = cachedStructDummyInstances[metadata] {
            metadata.initialize(storage, withCopyOf: cached)
            return
        }

        try fillInFields(storage, fields: metadata.description.fields, offsets: metadata.fieldOffsets, parent: metadata)

        let cached = metadata.copy(from: storage)
        cachedStructDummyInstances[metadata] = cached
    }

    private func classDummyInstance(of metadata: ClassMetadata, into storage: RawPointer) throws -> RawPointer {
        let instance = Runtime.allocObject(metadata: metadata, size: metadata.instanceSize, alignment: metadata.instanceAlignMask + 1)

        try fillInFields(instance, fields: metadata.description.fields, offsets: metadata.fieldOffsets, parent: metadata)

        // returned at +1, so no additional retain necessary
        storage.reinterpret(RawPointer.self).pointee = instance

        return instance
    }

    private func fillInFields<O: BinaryInteger>(_ p: RawPointer, fields: [FieldRecord], offsets: [O], parent metadata: Metadata) throws {
        for (field, offset) in zip(fields, offsets) {
            guard let (fieldType, ownership) = field.resolveTypeAndReferenceOwnership(contextDescriptor: metadata.typeContextDescriptor!, genericArguments: metadata.genericArgumentsPointer) else { fatalError("Type of \(field.name) is nil in metadata \(metadata)") }
            if ownership == .strong {
                // we only care to fill in normal strong vars. The rest of ownership types can be nil, so we leave them zeroed out
                try dummyInstance(of: Metadata.of(fieldType), into: p.advanced(by: offset))
            }
        }
    }

    private func existentialDummy(of metadata: ExistentialTypeMetadata, into storage: RawPointer) throws {
        var indicesAndDescriptors = [(index: Int, descriptor: InvocationDescriptor)]()
        try _existentialDummy(of: metadata, into: storage) { descriptor -> RawPointer in
            // We cannot immediately provide a complete implementation of the witness, because its parameters or results may require creating a dummy instance of the existential type that is currently being constructed, leading to infinite recursion. Therefore, here we only return the address of a reserved slot ...
            let (index, witness) = Trampoline.permanentSlots.reserve(descriptor: descriptor)
            indicesAndDescriptors.append((index: index, descriptor: descriptor))
            return witness
        }
        // ... and only here we can create actual implementations of the witnesses
        for (index, descriptor) in indicesAndDescriptors {
            if descriptor.silFunctionType.isCoroutine {
                let ty = descriptor.silFunctionType.yields[0].type.type
                let metadata = TypeFactory.convert(ty)

                let box = Runtime.allocBox(metadata: metadata)

                try self.dummyInstance(of: metadata, into: box.buffer)

                let impl: (InvocationSnapshot) -> Void = { snapshot in
                    let handler = InvocationHandler(descriptor: descriptor, snapshot: snapshot)
                    handler.inject(yield: box.buffer, box: box.object)
                }
                Trampoline.permanentSlots.setImplementation(impl, at: index)
            } else {
                let ty = descriptor.loweredInterfaceType.resultType
                let metadata = TypeFactory.convert(ty)

                let dummyResult = try self.dummy(of: metadata)
                let impl: (InvocationSnapshot) -> Void = { snapshot in
                    let handler = InvocationHandler(descriptor: descriptor, snapshot: snapshot)
                    do {
                        try handler.inject(result: dummyResult)
                    } catch {
                        // if this default implementation throws, there's no meaningful way to recover, since we can't even return properly
                        fatalError("\(error)")
                    }
                }
                Trampoline.permanentSlots.setImplementation(impl, at: index)
            }
        }
    }

    private func enumDummy(of metadata: EnumMetadata, into storage: RawPointer) throws {
        let descriptor = metadata.typeContextDescriptor

        if descriptor.numberOfPayloadCases == 0 {
            return
        }

        let payloadTypes = descriptor.fields.compactMap { $0.resolveType(contextDescriptor: descriptor, genericArguments: metadata.genericArgumentsPointer) }
        guard !payloadTypes.isEmpty else {
            return
        }

        // if there are non-payload cases, inject the tag corresponding to non-payload case(s) and be done
        if descriptor.numberOfEmptyCases > 0 {
            assert(metadata.valueWitnesses.hasEnumWitnesses)
            // for single-payload enums, it is 1, for multi-payload ones it's 0
            if descriptor.numberOfPayloadCases == 1 {
                metadata.valueWitnesses.destructiveInjectEnumTag(obj: storage, tag: 1)
            } else {
                metadata.valueWitnesses.destructiveInjectEnumTag(obj: storage, tag: 0)
            }
            return
        }

        // enums with payloads are zext-layout-compatible with their first payload
        try dummyInstance(of: Metadata.of(payloadTypes[0]), into: storage)
    }

    private func tupleDummy(of metadata: TupleTypeMetadata, into storage: RawPointer) throws {
        for element in metadata.elements {
            try dummyInstance(of: element.metadata, into: storage + element.offset)
        }
    }

    // fast path for some known types
    private func commonDummy(of metadata: Metadata, into storage: RawPointer) -> Bool {
        if let contextDescriptor = metadata.typeContextDescriptor, (contextDescriptor.parent as? ModuleContextDescriptor)?.name == "Swift" {
            // empty sets, dictionaries and arrays, all have the same empty singleton storage, so it's safe to do this
            switch contextDescriptor.name {
            case "Array":
                storage.reinterpret([Int].self).initialize(to: emptyArray)
                return true
            case "Set":
                storage.reinterpret(Set<Int>.self).initialize(to: emptySet)
                return true
            case "Dictionary":
                storage.reinterpret([Int: Int].self).initialize(to: emptyDictionary)
                return true
            case "String":
                Metadata.of(String.self).initialize(storage, withCopyOf: "")
            default:
                break
            }
        }

        return false
    }
}

// these are declared vars so that they can be passed to withUnsafePointer, but they must never be modified
private var emptyArray = [Int]()
private var emptySet = Set<Int>()
private var emptyDictionary = [Int: Int]()

private final class ClassWithoutVars {}
private let classWithoutVarsMetadata: Metadata = Metadata.of(ClassWithoutVars.self)
