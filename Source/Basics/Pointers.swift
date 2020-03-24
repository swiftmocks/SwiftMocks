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

public typealias RawPointer = UnsafeMutableRawPointer

public extension RawPointer {
    /// Align to T's required alignment
    func aligned<T>(_ to: T.Type) -> RawPointer {
        aligned(MemoryLayout<T>.alignment)
    }

    func aligned(_ alignment: Int) -> RawPointer {
        let newSelf: UInt = UInt(bitPattern: self).aligned(alignment)
        return RawPointer(bitPattern: newSelf)!
    }

    func alignedDown(_ alignment: Int) -> RawPointer {
        let newSelf: UInt = UInt(bitPattern: self).alignedDown(alignment)
        return RawPointer(bitPattern: newSelf)!
    }

    func advanced<I: BinaryInteger>(by n: I) -> RawPointer { advanced(by: Int(n)) }

    func advanced<I: BinaryInteger, T>(by n: I, of type: T.Type) -> RawPointer { reinterpret(type, aligned: false).advanced(by: n).raw }

    /// Align to T's required alignment and return Pointer<T>
    func reinterpret<T>(_ type: T.Type, aligned: Bool = true) -> Pointer<T> { return aligned ? self.aligned(T.self).assumingMemoryBound(to: T.self) : assumingMemoryBound(to: T.self) }
}

public typealias ConstRawPointer = UnsafeRawPointer

public extension ConstRawPointer {
    /// Align to T's required alignment
    func aligned<T>(_ to: T.Type) -> ConstRawPointer {
        aligned(MemoryLayout<T>.alignment)
    }

    func aligned(_ alignment: Int) -> ConstRawPointer {
        let newSelf: UInt = UInt(bitPattern: self).aligned(alignment)
        return ConstRawPointer(bitPattern: newSelf)!
    }

    func advanced<I: BinaryInteger>(by n: I) -> ConstRawPointer { advanced(by: Int(n)) }

    func advanced<I: BinaryInteger, T>(by n: I, of type: T.Type) -> ConstRawPointer { reinterpret(type, aligned: false).advanced(by: n).raw }

    /// Align to T's required alignment and return Pointer<T>
    func reinterpret<T>(_ type: T.Type, aligned: Bool = true) -> ConstPointer<T> { return aligned ? self.aligned(T.self).assumingMemoryBound(to: T.self) : assumingMemoryBound(to: T.self) }
}


public typealias Pointer = UnsafeMutablePointer

public extension Pointer {
    var raw: RawPointer { RawPointer(self) }

    /// Align to T's required alignment and return Pointer<T>
    func reinterpret<T>(_ type: T.Type) -> Pointer<T> { raw.aligned(T.self).reinterpret(type) }

    func advanced<I: BinaryInteger>(by n: I) -> Pointer<Pointee> { advanced(by: Int(n)) }
}

public typealias ConstPointer = UnsafePointer

public extension ConstPointer {
    var raw: ConstRawPointer { ConstRawPointer(self) }

    /// Align to T's required alignment and return Pointer<T>
    func reinterpret<T>(_ type: T.Type) -> ConstPointer<T> { raw.aligned(T.self).reinterpret(type) }

    func advanced<I: BinaryInteger>(by n: I) -> ConstPointer<Pointee> { advanced(by: Int(n)) }
}

public typealias BufferPointer = UnsafeMutableBufferPointer
public typealias ConstBufferPointer = UnsafeBufferPointer

// MARK: - Relative pointers

public extension Pointer {
    init?(relative p: Pointer<TargetRelativeDirectPointer>) {
        guard let p = RawPointer(relative: p) else { return nil }
        self = p.reinterpret(Pointee.self)
    }

    init?(relative p: Pointer<TargetRelativeIndirectablePointer>) {
        guard let p = RawPointer(relative: p) else { return nil }
        self = p.reinterpret(Pointee.self)
    }
}

public extension RawPointer {
    init?(relative p: Pointer<TargetRelativeDirectPointer>) {
        let offset = p.pointee.Offset

        guard offset != 0 else { return nil }

        self = p.raw.advanced(by: offset)
    }

    init?(relative p: Pointer<TargetRelativeIndirectablePointer>) {
        let offset = p.pointee.Offset & ~1

        guard offset != 0 else { return nil }

        if p.pointee.Offset & 1 != 0 {
            let offset = p.pointee.Offset & ~1
            self = p.raw.advanced(by: offset).reinterpret(RawPointer.self).pointee
        } else {
            self = p.raw.advanced(by: offset)
        }
    }

    init?(relative p: Pointer<RelativeIndirectablePointerIntPair>, int: inout UInt8) {
        let offsetPlusIndirect = p.pointee.RelativeOffsetPlusIndirectAndInt & ~2 // mask for uint32_t

        guard offsetPlusIndirect != 0 else { return nil }

        int = UInt8((p.pointee.RelativeOffsetPlusIndirectAndInt & 2) >> 1)

        if offsetPlusIndirect & 1 != 0 {
            self = p.raw.advanced(by: offsetPlusIndirect & ~1).reinterpret(RawPointer.self).pointee
        } else {
            self = p.raw.advanced(by: offsetPlusIndirect)
        }
    }
}

extension RawPointer {
    /// Assign the address pointed to by the receiver to the relative pointer `to`.
    ///
    /// Normally assignment is implemented the other way around, where we'd write something like `myRelativePointer = somePointer`. However updating a relative pointer requires knowing its own address, and so the cleanest-looking way to express this in Swift is `somePointer.assign(to: &myRelativePointer)`.
    func assign(to relativeDirectPointer: Pointer<TargetRelativeDirectPointer>) {
        relativeDirectPointer.pointee.Offset = Int32(Int(bitPattern: self) - Int(bitPattern: relativeDirectPointer))
    }
}

extension Pointer {
    /// Assign the address pointed to by the receiver to the relative pointer `to`.
    ///
    /// Normally assignment is implemented the other way around, where we'd write something like `myRelativePointer = somePointer`. However updating a relative pointer requires knowing its own address, and so the cleanest-looking way to express this in Swift is `somePointer.assign(to: &myRelativePointer)`.
    func assign(to relativeDirectPointer: Pointer<TargetRelativeDirectPointer>) {
        relativeDirectPointer.pointee.Offset = Int32(Int(bitPattern: self) - Int(bitPattern: relativeDirectPointer))
    }
}

// MARK: - Allocations
public extension RawPointer {
    static func allocateWithZeroFill(size: Int, alignment: Int) -> RawPointer {
        RawPointer.allocate(byteCount: size, alignment: alignment).initializeMemory(as: UInt8.self, repeating: 0, count: size).raw
    }
}

public extension Pointer {
    static func allocateWithZeroFill(size: Int) -> Pointer<Pointee> {
        RawPointer.allocateWithZeroFill(size: MemoryLayout<Pointee>.size * size, alignment: MemoryLayout<Pointee>.alignment).reinterpret(Pointee.self)
    }
}

public extension BufferPointer {
    static func allocateWithZeroFill(size: Int) -> BufferPointer<Element> {
        let base = RawPointer.allocateWithZeroFill(size: MemoryLayout<Element>.size * size, alignment: MemoryLayout<Element>.alignment)
        return BufferPointer(start: base.reinterpret(Element.self), count: size)
    }
}

// MARK: - Alignment

// FIXME: change to (self + alignment - 1) / alignment
public extension Int {
    /// Aligns the receiver "up"
    @_transparent
    mutating func align(_ alignment: Int) {
        self = aligned(alignment)
    }

    /// Returns an `Int` equal to the receiver aligned "up"
    @_transparent
    func aligned(_ alignment: Int) -> Int {
        let rem = self % alignment
        return rem != 0 ? self + alignment - rem : self
    }

    /// Returns an `Int` equal to the receiver aligned "up"
    @_transparent
    func aligned(_ alignment: UInt8) -> Int {
        let rem = self % Int(alignment)
        return rem != 0 ? self + Int(alignment) - rem : self
    }
}

public extension UInt {
    /// Aligns the receiver "up"
    @_transparent
    mutating func align(_ alignment: Int) {
        self = aligned(alignment)
    }

    /// Returns a `UInt` equal to the receiver aligned "up"
    @_transparent
    func aligned(_ alignment: Int) -> UInt {
        let alignment = UInt(alignment)
        let rem = self % alignment
        return rem != 0 ? self + alignment - rem : self
    }

    /// Returns a `UInt` equal to the receiver aligned "up"
    @_transparent
    func alignedDown(_ alignment: Int) -> UInt {
        let mask = UInt(alignment - 1)
        return self & ~mask
    }
}

public extension String {
    init(relativeDirectPointer p: Pointer<TargetRelativeDirectPointer>) {
        let utf8 = Pointer<CChar>(relative: p)!
        self = String(validatingUTF8: utf8) ?? { fatalError("Could not read UTF-8") }()
    }

    init?(nullableRelativeDirectPointer p: Pointer<TargetRelativeDirectPointer>) {
        guard let utf8 = Pointer<CChar>(relative: p) else { return nil }
        self = String(validatingUTF8: utf8.reinterpret(CChar.self)) ?? { fatalError("Could not read UTF-8") }()
    }

    init(relativeIndirectablePointer p: Pointer<TargetRelativeIndirectablePointer>) {
        let utf8 = Pointer<CChar>(relative: p)!
        self = String(validatingUTF8: utf8) ?? { fatalError("Could not read UTF-8") }()
    }
}
