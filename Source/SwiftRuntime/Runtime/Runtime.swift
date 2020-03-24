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

/// Namespace for functions provided by Swift runtime, adapted for easier use
public enum Runtime {}

// MARK: - Alloc, retain, release

public extension Runtime {
    struct BoxPair {
        let object: RawPointer
        let buffer: RawPointer
    }

    static func allocBox(metadata: Metadata) -> BoxPair { my_allocBox(metadata.pointer) }
    static func allocObject(metadata: Metadata, size: Int, alignment: Int) -> RawPointer { my_allocObject(metadata.pointer, size, alignment) }

    static func retain(_ o: AnyObject) { _ = my_retain(Unmanaged.passUnretained(o).toOpaque()) }
    static func retain(_ p: RawPointer) { _ = my_retain(p) }

    static func release(_ o: AnyObject) { my_release(Unmanaged.passUnretained(o).toOpaque()) }
    static func release(_ p: RawPointer) { my_release(p) }

    static func retainCount(_ o: AnyObject) -> UInt { my_getRetainCount(Unmanaged.passUnretained(o).toOpaque()) }
    static func retainCount(_ p: RawPointer) -> UInt { my_getRetainCount(p) }

    static func unownedRetainCount(_ o: AnyObject) -> UInt { my_getUnownedRetainCount(Unmanaged.passUnretained(o).toOpaque()) }
    static func unownedRetainCount(_ p: RawPointer) -> UInt { my_getUnownedRetainCount(p) }

    static func weakRetainCount(_ o: AnyObject) -> UInt { my_getWeakRetainCount(Unmanaged.passUnretained(o).toOpaque()) }
    static func weakRetainCount(_ p: RawPointer) -> UInt { my_getWeakRetainCount(p) }

    static func errorRetain(_ e: Error) { _ = my_errorRetain(unsafeBitCast(e, to: RawPointer.self)) /* FIXME */ }
    static func errorRetain(_ p: RawPointer) { _ = my_errorRetain(p) }

    static func errorRelease(_ e: Error) { my_errorRelease(unsafeBitCast(e, to: RawPointer.self)) }
    static func errorRelease(_ p: RawPointer) { my_errorRelease(p) }

    static func registerProtocolConformanceRecords(begin: Pointer<ProtocolConformanceRecord>, end: Pointer<ProtocolConformanceRecord>) { my_registerProtocolConformances(begin, end) }
    static func registerProtocolConformanceRecord(_ recordPtr: Pointer<ProtocolConformanceRecord>) { my_registerProtocolConformances(recordPtr, recordPtr + 1) }
}

// MARK: - Dynamic replacement

public extension Runtime {
    /// A very poorly named function. What it in fact does is it tells the dynamic replacement machinery that the imminent call to dynamically replaceable function does not need to be routed to a replacement, even if one exists. So normally if a dynamically replaceable function has address 0x1234, then calling it by that address will tailcall a replacement if one exists, but if `swift_getOrigOfReplaceable()` is called right before it, the original implementation will be invoked.
    static func getOrigOfReplaceable(origFnPtr: Pointer<RawPointer>) -> RawPointer {
        my_getOrigOfReplaceable(origFnPtr)
    }
}

// MARK: - Demangle

public extension Runtime {
    static func demangle(_ mangledName: String) -> String? {
        let length = mangledName.count
        let allocatedBufferSize = 4096
        var bufferSize: size_t = allocatedBufferSize
        let buffer = Pointer<CChar>.allocate(capacity: allocatedBufferSize)
        defer {
            buffer.deallocate()
        }
        let success = mangledName.utf8CString.withContiguousStorageIfAvailable { mangledNameCStr -> Bool in
            let ret = my_swift_demangle(mangledNameCStr.baseAddress!, length, buffer, &bufferSize, 0)
            return ret != nil
        }
        guard success == true else { return nil }
        return String(cString: buffer)
    }
}

// MARK: - Metadata lookup

public extension Runtime {
    static func getTypeByMangledNameInContext(name: Pointer<CChar>, contextDescriptor: ContextDescriptor? = nil, genericArguments: BufferPointer<RawPointer>? = nil) -> Any.Type? {
        let nameLength = UInt(mangledNameLength(name.raw))
        let result = my_getTypeByMangledNameInContext(name.reinterpret(UInt8.self), nameLength, genericContext: contextDescriptor?.pointer, genericArguments: genericArguments?.baseAddress)
        return result
    }

    // a shortcut for getTypeByMangledNameInContext
    static func getNonGenericTypeByMangledName(name: String) -> Any.Type? {
        name.withCString {
            let ret = getTypeByMangledNameInContext(name: Pointer(mutating: $0), contextDescriptor: nil, genericArguments: nil)
            return ret
        }
    }

    /// Fetch a uniqued metadata object for a generic nominal type.
    static func getGenericMetadata(descriptor: TypeContextDescriptor, genericArguments: BufferPointer<RawPointer>) -> Metadata {
        precondition(genericArguments.count > 0)
        let request = MetadataRequest.completeBlocking
        let response = my_getGenericMetadata(request: request, arguments: genericArguments.baseAddress!, descriptor: descriptor.pointer)
        let ret = Metadata.from(response.value)
        return ret
    }

    /// Fetch a uniqued metadata object for a generic nominal type.
    static func getGenericMetadata(descriptor: TypeContextDescriptor, genericParams: [Metadata], conformanceWitnessTables: [WitnessTable]) -> Metadata {
        let genericArguments = BufferPointer<RawPointer>.allocate(capacity: genericParams.count + conformanceWitnessTables.count)
        defer {
            genericArguments.deallocate()
        }

        var i = 0
        for metadata in genericParams {
            genericArguments[i] = metadata.pointer
            i += 1
        }
        for witnessTable in conformanceWitnessTables {
            genericArguments[i] = witnessTable.pointer
        }

        return getGenericMetadata(descriptor: descriptor, genericArguments: genericArguments)
    }

    static func getFunctionTypeMetadata(convention: FunctionMetadataConvention, parameters: [Metadata], result: Metadata) -> Metadata {
        let metadatas = BufferPointer<RawPointer>.allocate(capacity: parameters.count)
        defer {
            metadatas.deallocate()
        }

        for (index, parameter) in parameters.enumerated() {
            metadatas[index] = parameter.pointer
        }

        var flags = FunctionTypeFlags()
        flags.convention = convention
        flags.numberOfParameters = parameters.count
        let p = my_getFunctionTypeMetadata(flags: flags, parameters: metadatas.baseAddress!, parameterFlags: nil, resultMetadata: result.pointer)
        return Metadata.from(p)
    }

    static func getTupleTypeMetadata(elements: [Metadata]) -> Metadata {
        let metadatas = BufferPointer<RawPointer>.allocate(capacity: elements.count)
        defer {
            metadatas.deallocate()
        }

        for (index, metadata) in elements.enumerated() {
            metadatas[index] = metadata.pointer
        }

        let request = MetadataRequest.completeBlocking
        let flags = TupleTypeFlags.with(numberOfElements: elements.count)
        let response = my_getTupleTypeMetadata(request: request, flags: flags, elements: metadatas.baseAddress!, labels: nil, proposedWitnesses: nil)
        let ret = Metadata.from(response.value)
        return ret
    }

    static func getMetatypeMetadata(instanceType: Metadata) -> MetatypeMetadata {
        let p = my_getMetatypeMetadata(instanceType: instanceType.pointer)
        return Metadata.from(p) as! MetatypeMetadata
    }

    static func getExistentialMetatypeMetadata(instanceType: Metadata) -> ExistentialMetatypeMetadata {
        let p = my_getExistentialMetatypeMetadata(instanceType: instanceType.pointer)
        return Metadata.from(p) as! ExistentialMetatypeMetadata
    }

    private static func mangledNameLength(_ mangledName: RawPointer) -> Int {
        let start: Pointer<UInt8> = mangledName.assumingMemoryBound(to: UInt8.self)
        var end = start
        while end.pointee != 0 {
            // Skip over symbolic references.
            if end.pointee >= 0x1 && end.pointee <= 0x17 {
                end += MemoryLayout<UInt32>.size
            } else if end.pointee >= 0x18 && end.pointee <= 0x1F {
                end += MemoryLayout<UnsafeRawPointer>.size
            }
            end += 1
        }
        return end - start
    }
}

// MARK: - Casting

public extension Runtime {
    static func dynamicCast(dest: RawPointer, src: RawPointer, srcType: Metadata, targetType: Metadata) -> Bool {
        my_dynamicCast(dest, src, srcType.pointer, targetType.pointer, 0)
    }

    static func conformsToProtocol(metadata: Metadata, proto: ProtocolDescriptor) -> WitnessTable? {
        guard let p = my_conformsToProtocol(metadata.pointer, proto.pointer) else {
            return nil
        }
        return WitnessTable(pointer: p)
    }
}

@_silgen_name("swift_allocBox")
private func my_allocBox(_ metadata: RawPointer) -> Runtime.BoxPair
@_silgen_name("swift_allocObject")
private func my_allocObject(_ metadata: RawPointer, _ size: size_t, _ alignment: size_t) -> RawPointer
@_silgen_name("swift_retain")
private func my_retain(_ object: RawPointer) -> RawPointer
@_silgen_name("swift_release")
private func my_release(_ object: RawPointer)
@_silgen_name("swift_retainCount")
private func my_getRetainCount(_ object: RawPointer) -> UInt
@_silgen_name("swift_unownedRetainCount")
private func my_getUnownedRetainCount(_ object : RawPointer) -> UInt
@_silgen_name("swift_weakRetainCount")
private func my_getWeakRetainCount(_ object: RawPointer) -> UInt
@_silgen_name("swift_errorRetain")
private func my_errorRetain(_ error: RawPointer) -> RawPointer
@_silgen_name("swift_errorRelease")
private func my_errorRelease(_ error: RawPointer)
@_silgen_name("swift_registerProtocolConformances")
private func my_registerProtocolConformances(_ begin: Pointer<ProtocolConformanceRecord>, _ end: Pointer<ProtocolConformanceRecord>)

// Dynamic replacement
@_silgen_name("swift_getOrigOfReplaceable")
private func my_getOrigOfReplaceable(_ origFnPtr: Pointer<RawPointer>) -> RawPointer

// Demangle
@_silgen_name("swift_demangle")
private func my_swift_demangle(_ mangledName: UnsafeRawPointer, _ mangledNameLength: size_t, _ outputBuffer: UnsafeRawPointer, _ outputBufferSize: inout size_t, _ flags: UInt32) -> RawPointer?

// Metadata lookup
@_silgen_name("swift_getTypeByMangledNameInContext")
private func my_getTypeByMangledNameInContext(_ mangledName: RawPointer, _ mangledNameLength: UInt, genericContext: RawPointer?, genericArguments: RawPointer?) -> Any.Type?

// technically it's not swift_cc, but it's compatible enough to work
@_silgen_name("swift_getFunctionTypeMetadata0")
private func my_getFunctionTypeMetadata0(flags: FunctionTypeFlags, resultMetadata: RawPointer) -> RawPointer

// technically it's not swift_cc, but it's compatible enough to work
@_silgen_name("swift_getFunctionTypeMetadata")
private func my_getFunctionTypeMetadata(flags: FunctionTypeFlags, parameters: Pointer<RawPointer>, parameterFlags: RawPointer?, resultMetadata: RawPointer) -> RawPointer

@_silgen_name("swift_getTupleTypeMetadata")
private func my_getTupleTypeMetadata(request: MetadataRequest, flags: TupleTypeFlags, elements: Pointer<RawPointer>, labels: Pointer<CChar>?, proposedWitnesses: RawPointer?) -> MetadataResponse

/// Fetch a uniqued metadata object for a nominal type which requires
/// singleton metadata initialization.
@_silgen_name("swift_getSingletonMetadata")
private func swift_getSingletonMetadata(request: MetadataRequest, descriptor: RawPointer) -> MetadataResponse

/// Fetch a uniqued metadata object for a generic nominal type.
@_silgen_name("swift_getGenericMetadata")
private func my_getGenericMetadata(request: MetadataRequest, arguments: Pointer<RawPointer>, descriptor: RawPointer) -> MetadataResponse

@_silgen_name("swift_getMetatypeMetadata")
private func my_getMetatypeMetadata(instanceType: RawPointer) -> RawPointer

/// Fetch a uniqued metadata for an existential metatype type.
@_silgen_name("swift_getExistentialMetatypeMetadata")
private func my_getExistentialMetatypeMetadata(instanceType: RawPointer) -> RawPointer

// MARK: - Casting
@_silgen_name("swift_dynamicCast")
private func my_dynamicCast(_ dest: RawPointer, _ src: RawPointer, _ srcType: RawPointer, _ targetType: RawPointer, _ flags: UInt) -> Bool

@_silgen_name("swift_conformsToProtocol")
private func my_conformsToProtocol(_ metadata: RawPointer, _ proto: RawPointer) -> RawPointer?
