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

// combination of ExistentialContainer.h and ExistentialMetadataImpl.h

import Foundation

// MARK: - Opaque existentials

public struct OpaqueExistentialContainer: PointeeFacade {
    struct Pointee {
        var buffer: ValueBuffer.Pointee
        var type: RawPointer
    }
    public let pointer: RawPointer

    public var buffer: ValueBuffer { ValueBuffer(pointer) }

    public var type: Metadata {
        get { Metadata.from(pointee.type) }
        nonmutating set { pointee.type = newValue.pointer }
    }

    public var isValueInline: Bool { type.valueWitnesses.isValueInline }

    public var projected: RawPointer {
        let vwt = type.valueWitnesses

        if vwt.isValueInline {
            return buffer.pointer
        }

        let alignMask = Int(vwt.alignmentMask)
        let byteOffset: Int = (/* MemoryLayout<__HeapObject>.size */ 2 * MemoryLayout<RawPointer>.size + alignMask) & ~alignMask // FIXME: use runtime functions
        let ret = buffer.asRawPointers[0] + byteOffset
        return ret
    }

    public var witnessTablesPointer: Pointer<WitnessTable> {
        typedPointer.advanced(by: 1).reinterpret(Pointer<RawPointer>.self).pointee.pointee.reinterpret(WitnessTable.self)
    }
}

public struct OpaqueExistentialBox {
    public let pointer: RawPointer
    public let numberOfWitnessTables: Int

    public var container: OpaqueExistentialContainer { OpaqueExistentialContainer(pointer) }

    public var witnessTables: [WitnessTable] {
        get { BufferPointer<RawPointer>(start: pointer.advanced(by: MemoryLayout<OpaqueExistentialContainer.Pointee>.size).reinterpret(RawPointer.self), count: numberOfWitnessTables).map { WitnessTable($0) } }
        nonmutating set {
            let buffer = BufferPointer<RawPointer>(start: pointer.advanced(by: MemoryLayout<OpaqueExistentialContainer.Pointee>.size).reinterpret(RawPointer.self), count: numberOfWitnessTables)
            for (index, wt) in newValue.enumerated() {
                buffer[index] = wt.pointer
            }
        }
    }

    public init(_ pointer: RawPointer, numberOfWitnessTables: Int) {
        self.pointer = pointer
        self.numberOfWitnessTables = numberOfWitnessTables
    }
}

/// `Any` representation. It's really an `OpaqueExistentialBox` with zero witnesses
public struct AnyExistentialBox {
    public let pointer: RawPointer

    public var container: OpaqueExistentialContainer { OpaqueExistentialContainer(pointer) }

    public var projected: RawPointer { container.projected }

    public init(_ pointer: RawPointer) {
        self.pointer = pointer
    }
}

// MARK: - Class existentials

public struct ClassExistentialContainer: PointeeFacade {
    public struct Pointee {
        var value: RawPointer
    }
    public let pointer: RawPointer

    public var value: RawPointer {
        get { pointee.value }
        nonmutating set { pointee.value = newValue }
    }

    public var witnessTables: Pointer<WitnessTable> { typedPointer.advanced(by: 1).reinterpret(Pointer<RawPointer>.self).pointee.pointee.reinterpret(WitnessTable.self) }
}

public struct ClassExistentialBox {
    public let pointer: RawPointer
    public let numberOfWitnessTables: Int

    public var container: ClassExistentialContainer { ClassExistentialContainer(pointer) }

    public var witnessTables: [WitnessTable] {
        get { BufferPointer<RawPointer>(start: pointer.advanced(by: MemoryLayout<ClassExistentialContainer.Pointee>.size).reinterpret(RawPointer.self), count: numberOfWitnessTables).map { WitnessTable($0) } }
        nonmutating set {
            let buffer = BufferPointer<RawPointer>(start: pointer.advanced(by: MemoryLayout<ClassExistentialContainer.Pointee>.size).reinterpret(RawPointer.self), count: numberOfWitnessTables)
            for (index, wt) in newValue.enumerated() {
                buffer[index] = wt.pointer
            }
        }
    }

    public init(_ pointer: RawPointer, numberOfWitnessTables: Int) {
        self.pointer = pointer
        self.numberOfWitnessTables = numberOfWitnessTables
    }
}

/// `AnyObject` representation. It's really an `ClassExistentialBox` with zero witnesses
public struct AnyObjectExistentialBox {
    public let pointer: RawPointer

    public var container: ClassExistentialContainer { ClassExistentialContainer(pointer) }

    public init(_ pointer: RawPointer) {
        self.pointer = pointer
    }
}

