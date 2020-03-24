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

class BuiltinType: AType, ATypeEquatable, AlwaysHasMetadata {
    let opaqueMetadata: OpaqueMetadata

    var metadata: Metadata {
        opaqueMetadata
    }

    fileprivate init(kind: TypeKind, metadata: OpaqueMetadata) {
        self.opaqueMetadata = metadata
        super.init(kind: kind)
    }

    func isEqual(to other: AType) -> Bool {
        guard let other = other as? BuiltinType else {
            return false
        }
        return other.metadata == metadata
    }
}

class BuiltinRawPointerType: BuiltinType {
    fileprivate init() {
        super.init(kind: .builtinRawPointer, metadata: OpaqueMetadata.Builtin.RawPointer)
    }
}

class BuiltinNativeObjectType: BuiltinType {
    fileprivate init() {
        super.init(kind: .builtinNativeObject, metadata: OpaqueMetadata.Builtin.NativeObject)
    }
}

class BuiltinBridgeObjectType: BuiltinType {
    fileprivate init() {
        super.init(kind: .builtinBridgeObject, metadata: OpaqueMetadata.Builtin.BridgeObject)
    }
}

class BuiltinUnknownObjectType: BuiltinType {
    fileprivate init() {
        super.init(kind: .builtinUnknownObject, metadata: OpaqueMetadata.Builtin.UnknownObject)
    }
}

class BuiltinUnsafeValueBufferType: BuiltinType {
    fileprivate init() {
        super.init(kind: .builtinUnsafeValueBuffer, metadata: OpaqueMetadata.Builtin.UnsafeValueBuffer)
    }
}

class BuiltinVectorType: BuiltinType {
    fileprivate init() {
        LoweringError.notImplemented("builtin vector types")
    }
}

class AnyBuiltinIntegerType: BuiltinType {}

class BuiltinIntegerType: AnyBuiltinIntegerType {
    let sizeInBits: Int

    fileprivate init(metadata: OpaqueMetadata, sizeInBits: Int) {
        self.sizeInBits = sizeInBits
        super.init(kind: .builtinInteger, metadata: metadata)
    }

    static func i1() -> BuiltinIntegerType {
        BuiltinIntegerType(metadata: OpaqueMetadata.Builtin.Int1, sizeInBits: 1)
    }
    static func i8() -> BuiltinIntegerType {
        BuiltinIntegerType(metadata: OpaqueMetadata.Builtin.Int8, sizeInBits: 8)
    }
    static func i16() -> BuiltinIntegerType {
        BuiltinIntegerType(metadata: OpaqueMetadata.Builtin.Int16, sizeInBits: 16)
    }
    static func i32() -> BuiltinIntegerType {
        BuiltinIntegerType(metadata: OpaqueMetadata.Builtin.Int32, sizeInBits: 32)
    }
    static func i64() -> BuiltinIntegerType {
        BuiltinIntegerType(metadata: OpaqueMetadata.Builtin.Int64, sizeInBits: 64)
    }
}

class BuiltinFloatType: BuiltinType {
    enum FPKind {
        case IEEE16, IEEE32, IEEE64, IEEE80, IEEE128, /// IEEE floating point types.
        PPC128   /// PowerPC "double double" type.
    }

    let fpKind: FPKind

    fileprivate init(kind: FPKind) {
        let metadata: OpaqueMetadata
        switch kind {
        case .IEEE16:
            metadata = OpaqueMetadata.Builtin.FPIEEE16
        case .IEEE32:
            metadata = OpaqueMetadata.Builtin.FPIEEE32
        case .IEEE64:
            metadata = OpaqueMetadata.Builtin.FPIEEE64
        case .IEEE80:
            metadata = OpaqueMetadata.Builtin.FPIEEE80
        case .IEEE128:
            metadata = OpaqueMetadata.Builtin.FPIEEE128
        case .PPC128:
            LoweringError.notImplemented("PPC128 float format")
        }
        fpKind = kind
        super.init(kind: .builtinFloat, metadata: metadata)
    }
}


extension BuiltinType {
    /// To be used only by `TypeFactory`
    static func from(metadata: OpaqueMetadata) -> BuiltinType? {
        guard let kind = OpaqueMetadata.Builtin.kind(of: metadata) else {
            return nil
        }
        switch kind {
        case .UnsafeValueBuffer:
            return BuiltinUnsafeValueBufferType()
        case .UnknownObject:
            return BuiltinUnknownObjectType()
        case .BridgeObject:
            return BuiltinBridgeObjectType()
        case .FPIEEE128:
            return BuiltinFloatType.init(kind: .IEEE128)
        case .FPIEEE16:
            return BuiltinFloatType.init(kind: .IEEE16)
        case .FPIEEE32:
            return BuiltinFloatType.init(kind: .IEEE32)
        case .FPIEEE64:
            return BuiltinFloatType.init(kind: .IEEE64)
        case .FPIEEE80:
            return BuiltinFloatType.init(kind: .IEEE80)
        case .Int16:
            return BuiltinIntegerType.i16()
        case .Int1:
            return BuiltinIntegerType.i1()
        case .Int32:
            return BuiltinIntegerType.i32()
        case .Int8:
            return BuiltinIntegerType.i8()
        case .NativeObject:
            return BuiltinNativeObjectType()
        case .RawPointer:
            return BuiltinRawPointerType()

        case .Word: fallthrough
        case .Int64:
            return BuiltinIntegerType.i64()

        case .Int128:
            LoweringError.notImplemented("Builtin.int128")
        case .Int256:
            LoweringError.notImplemented("Builtin.int256")
        case .Int7:
            LoweringError.notImplemented("Builtin.int7")
        case .Int512:
            LoweringError.notImplemented("Builtin.int512")
        case .Int63:
            LoweringError.notImplemented("Builtin.int63")


        case .Vec16xFPIEEE32,
             .Vec2xFPIEEE32,
             .Vec32xFPIEEE32,
             .Vec3xFPIEEE32,
             .Vec4xFPIEEE32,
             .Vec64xFPIEEE32,
             .Vec8xFPIEEE32,
             .Vec16xFPIEEE64,
             .Vec2xFPIEEE64,
             .Vec32xFPIEEE64,
             .Vec3xFPIEEE64,
             .Vec4xFPIEEE64,
             .Vec64xFPIEEE64,
             .Vec8xFPIEEE64,
             .Vec16xInt16,
             .Vec2xInt16,
             .Vec32xInt16,
             .Vec3xInt16,
             .Vec4xInt16,
             .Vec64xInt16,
             .Vec8xInt16,
             .Vec16xInt32,
             .Vec2xInt32,
             .Vec32xInt32,
             .Vec3xInt32,
             .Vec4xInt32,
             .Vec64xInt32,
             .Vec8xInt32,
             .Vec16xInt64,
             .Vec2xInt64,
             .Vec32xInt64,
             .Vec3xInt64,
             .Vec4xInt64,
             .Vec64xInt64,
             .Vec8xInt64,
             .Vec16xInt8,
             .Vec2xInt8,
             .Vec32xInt8,
             .Vec3xInt8,
             .Vec4xInt8,
             .Vec64xInt8,
             .Vec8xInt8:
            LoweringError.notImplemented("native vector types")
        }
    }
}
