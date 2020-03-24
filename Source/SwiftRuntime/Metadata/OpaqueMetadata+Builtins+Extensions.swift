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


public extension OpaqueMetadata.Builtin {
    enum Kind: Hashable {
        case UnsafeValueBuffer
        case UnknownObject
        case BridgeObject
        case FPIEEE128
        case FPIEEE16
        case Vec16xFPIEEE32
        case Vec2xFPIEEE32
        case Vec32xFPIEEE32
        case Vec3xFPIEEE32
        case Vec4xFPIEEE32
        case Vec64xFPIEEE32
        case Vec8xFPIEEE32
        case FPIEEE32
        case Vec16xFPIEEE64
        case Vec2xFPIEEE64
        case Vec32xFPIEEE64
        case Vec3xFPIEEE64
        case Vec4xFPIEEE64
        case Vec64xFPIEEE64
        case Vec8xFPIEEE64
        case FPIEEE64
        case FPIEEE80
        case Int128
        case Vec16xInt16
        case Vec2xInt16
        case Vec32xInt16
        case Vec3xInt16
        case Vec4xInt16
        case Vec64xInt16
        case Vec8xInt16
        case Int16
        case Int1
        case Int256
        case Vec16xInt32
        case Vec2xInt32
        case Vec32xInt32
        case Vec3xInt32
        case Vec4xInt32
        case Vec64xInt32
        case Vec8xInt32
        case Int32
        case Int512
        case Int63
        case Vec16xInt64
        case Vec2xInt64
        case Vec32xInt64
        case Vec3xInt64
        case Vec4xInt64
        case Vec64xInt64
        case Vec8xInt64
        case Int64
        case Int7
        case Vec16xInt8
        case Vec2xInt8
        case Vec32xInt8
        case Vec3xInt8
        case Vec4xInt8
        case Vec64xInt8
        case Vec8xInt8
        case Int8
        case NativeObject
        case RawPointer
        case Word
    }
}

public extension OpaqueMetadata.Builtin {
    static var UnsafeValueBuffer: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBBN") else { fatalError("Symbol $sBBN not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var UnknownObject: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBON") else { fatalError("Symbol $sBON not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var BridgeObject: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBbN") else { fatalError("Symbol $sBbN not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var FPIEEE128: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBf128_N") else { fatalError("Symbol $sBf128_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var FPIEEE16: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBf16_N") else { fatalError("Symbol $sBf16_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec16xFPIEEE32: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBf32_Bv16_N") else { fatalError("Symbol $sBf32_Bv16_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec2xFPIEEE32: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBf32_Bv2_N") else { fatalError("Symbol $sBf32_Bv2_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec32xFPIEEE32: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBf32_Bv32_N") else { fatalError("Symbol $sBf32_Bv32_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec3xFPIEEE32: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBf32_Bv3_N") else { fatalError("Symbol $sBf32_Bv3_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec4xFPIEEE32: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBf32_Bv4_N") else { fatalError("Symbol $sBf32_Bv4_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec64xFPIEEE32: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBf32_Bv64_N") else { fatalError("Symbol $sBf32_Bv64_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec8xFPIEEE32: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBf32_Bv8_N") else { fatalError("Symbol $sBf32_Bv8_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var FPIEEE32: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBf32_N") else { fatalError("Symbol $sBf32_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec16xFPIEEE64: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBf64_Bv16_N") else { fatalError("Symbol $sBf64_Bv16_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec2xFPIEEE64: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBf64_Bv2_N") else { fatalError("Symbol $sBf64_Bv2_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec32xFPIEEE64: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBf64_Bv32_N") else { fatalError("Symbol $sBf64_Bv32_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec3xFPIEEE64: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBf64_Bv3_N") else { fatalError("Symbol $sBf64_Bv3_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec4xFPIEEE64: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBf64_Bv4_N") else { fatalError("Symbol $sBf64_Bv4_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec64xFPIEEE64: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBf64_Bv64_N") else { fatalError("Symbol $sBf64_Bv64_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec8xFPIEEE64: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBf64_Bv8_N") else { fatalError("Symbol $sBf64_Bv8_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var FPIEEE64: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBf64_N") else { fatalError("Symbol $sBf64_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var FPIEEE80: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBf80_N") else { fatalError("Symbol $sBf80_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Int128: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi128_N") else { fatalError("Symbol $sBi128_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec16xInt16: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi16_Bv16_N") else { fatalError("Symbol $sBi16_Bv16_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec2xInt16: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi16_Bv2_N") else { fatalError("Symbol $sBi16_Bv2_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec32xInt16: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi16_Bv32_N") else { fatalError("Symbol $sBi16_Bv32_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec3xInt16: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi16_Bv3_N") else { fatalError("Symbol $sBi16_Bv3_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec4xInt16: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi16_Bv4_N") else { fatalError("Symbol $sBi16_Bv4_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec64xInt16: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi16_Bv64_N") else { fatalError("Symbol $sBi16_Bv64_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec8xInt16: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi16_Bv8_N") else { fatalError("Symbol $sBi16_Bv8_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Int16: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi16_N") else { fatalError("Symbol $sBi16_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Int1: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi1_N") else { fatalError("Symbol $sBi1_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Int256: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi256_N") else { fatalError("Symbol $sBi256_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec16xInt32: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi32_Bv16_N") else { fatalError("Symbol $sBi32_Bv16_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec2xInt32: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi32_Bv2_N") else { fatalError("Symbol $sBi32_Bv2_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec32xInt32: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi32_Bv32_N") else { fatalError("Symbol $sBi32_Bv32_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec3xInt32: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi32_Bv3_N") else { fatalError("Symbol $sBi32_Bv3_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec4xInt32: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi32_Bv4_N") else { fatalError("Symbol $sBi32_Bv4_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec64xInt32: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi32_Bv64_N") else { fatalError("Symbol $sBi32_Bv64_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec8xInt32: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi32_Bv8_N") else { fatalError("Symbol $sBi32_Bv8_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Int32: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi32_N") else { fatalError("Symbol $sBi32_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Int512: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi512_N") else { fatalError("Symbol $sBi512_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Int63: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi63_N") else { fatalError("Symbol $sBi63_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec16xInt64: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi64_Bv16_N") else { fatalError("Symbol $sBi64_Bv16_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec2xInt64: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi64_Bv2_N") else { fatalError("Symbol $sBi64_Bv2_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec32xInt64: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi64_Bv32_N") else { fatalError("Symbol $sBi64_Bv32_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec3xInt64: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi64_Bv3_N") else { fatalError("Symbol $sBi64_Bv3_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec4xInt64: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi64_Bv4_N") else { fatalError("Symbol $sBi64_Bv4_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec64xInt64: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi64_Bv64_N") else { fatalError("Symbol $sBi64_Bv64_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec8xInt64: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi64_Bv8_N") else { fatalError("Symbol $sBi64_Bv8_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Int64: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi64_N") else { fatalError("Symbol $sBi64_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Int7: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi7_N") else { fatalError("Symbol $sBi7_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec16xInt8: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi8_Bv16_N") else { fatalError("Symbol $sBi8_Bv16_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec2xInt8: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi8_Bv2_N") else { fatalError("Symbol $sBi8_Bv2_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec32xInt8: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi8_Bv32_N") else { fatalError("Symbol $sBi8_Bv32_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec3xInt8: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi8_Bv3_N") else { fatalError("Symbol $sBi8_Bv3_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec4xInt8: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi8_Bv4_N") else { fatalError("Symbol $sBi8_Bv4_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec64xInt8: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi8_Bv64_N") else { fatalError("Symbol $sBi8_Bv64_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Vec8xInt8: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi8_Bv8_N") else { fatalError("Symbol $sBi8_Bv8_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Int8: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBi8_N") else { fatalError("Symbol $sBi8_N not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var NativeObject: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBoN") else { fatalError("Symbol $sBoN not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var RawPointer: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBpN") else { fatalError("Symbol $sBpN not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
    static var Word: OpaqueMetadata = {
        guard let p: RawPointer = dlsym(dlopen(nil, 0), "$sBwN") else { fatalError("Symbol $sBwN not found") }
        return Metadata.from(p + MemoryLayout<TypeMetadataHeader.Pointee>.size) as! OpaqueMetadata
    }()
}


internal let cachedOpaqueMetadata: [OpaqueMetadata: OpaqueMetadata.Builtin.Kind] = {
    var result = [OpaqueMetadata: OpaqueMetadata.Builtin.Kind]()
    result[OpaqueMetadata.Builtin.UnsafeValueBuffer] = OpaqueMetadata.Builtin.Kind.UnsafeValueBuffer
    result[OpaqueMetadata.Builtin.UnknownObject] = OpaqueMetadata.Builtin.Kind.UnknownObject
    result[OpaqueMetadata.Builtin.BridgeObject] = OpaqueMetadata.Builtin.Kind.BridgeObject
    result[OpaqueMetadata.Builtin.FPIEEE128] = OpaqueMetadata.Builtin.Kind.FPIEEE128
    result[OpaqueMetadata.Builtin.FPIEEE16] = OpaqueMetadata.Builtin.Kind.FPIEEE16
    result[OpaqueMetadata.Builtin.Vec16xFPIEEE32] = OpaqueMetadata.Builtin.Kind.Vec16xFPIEEE32
    result[OpaqueMetadata.Builtin.Vec2xFPIEEE32] = OpaqueMetadata.Builtin.Kind.Vec2xFPIEEE32
    result[OpaqueMetadata.Builtin.Vec32xFPIEEE32] = OpaqueMetadata.Builtin.Kind.Vec32xFPIEEE32
    result[OpaqueMetadata.Builtin.Vec3xFPIEEE32] = OpaqueMetadata.Builtin.Kind.Vec3xFPIEEE32
    result[OpaqueMetadata.Builtin.Vec4xFPIEEE32] = OpaqueMetadata.Builtin.Kind.Vec4xFPIEEE32
    result[OpaqueMetadata.Builtin.Vec64xFPIEEE32] = OpaqueMetadata.Builtin.Kind.Vec64xFPIEEE32
    result[OpaqueMetadata.Builtin.Vec8xFPIEEE32] = OpaqueMetadata.Builtin.Kind.Vec8xFPIEEE32
    result[OpaqueMetadata.Builtin.FPIEEE32] = OpaqueMetadata.Builtin.Kind.FPIEEE32
    result[OpaqueMetadata.Builtin.Vec16xFPIEEE64] = OpaqueMetadata.Builtin.Kind.Vec16xFPIEEE64
    result[OpaqueMetadata.Builtin.Vec2xFPIEEE64] = OpaqueMetadata.Builtin.Kind.Vec2xFPIEEE64
    result[OpaqueMetadata.Builtin.Vec32xFPIEEE64] = OpaqueMetadata.Builtin.Kind.Vec32xFPIEEE64
    result[OpaqueMetadata.Builtin.Vec3xFPIEEE64] = OpaqueMetadata.Builtin.Kind.Vec3xFPIEEE64
    result[OpaqueMetadata.Builtin.Vec4xFPIEEE64] = OpaqueMetadata.Builtin.Kind.Vec4xFPIEEE64
    result[OpaqueMetadata.Builtin.Vec64xFPIEEE64] = OpaqueMetadata.Builtin.Kind.Vec64xFPIEEE64
    result[OpaqueMetadata.Builtin.Vec8xFPIEEE64] = OpaqueMetadata.Builtin.Kind.Vec8xFPIEEE64
    result[OpaqueMetadata.Builtin.FPIEEE64] = OpaqueMetadata.Builtin.Kind.FPIEEE64
    result[OpaqueMetadata.Builtin.FPIEEE80] = OpaqueMetadata.Builtin.Kind.FPIEEE80
    result[OpaqueMetadata.Builtin.Int128] = OpaqueMetadata.Builtin.Kind.Int128
    result[OpaqueMetadata.Builtin.Vec16xInt16] = OpaqueMetadata.Builtin.Kind.Vec16xInt16
    result[OpaqueMetadata.Builtin.Vec2xInt16] = OpaqueMetadata.Builtin.Kind.Vec2xInt16
    result[OpaqueMetadata.Builtin.Vec32xInt16] = OpaqueMetadata.Builtin.Kind.Vec32xInt16
    result[OpaqueMetadata.Builtin.Vec3xInt16] = OpaqueMetadata.Builtin.Kind.Vec3xInt16
    result[OpaqueMetadata.Builtin.Vec4xInt16] = OpaqueMetadata.Builtin.Kind.Vec4xInt16
    result[OpaqueMetadata.Builtin.Vec64xInt16] = OpaqueMetadata.Builtin.Kind.Vec64xInt16
    result[OpaqueMetadata.Builtin.Vec8xInt16] = OpaqueMetadata.Builtin.Kind.Vec8xInt16
    result[OpaqueMetadata.Builtin.Int16] = OpaqueMetadata.Builtin.Kind.Int16
    result[OpaqueMetadata.Builtin.Int1] = OpaqueMetadata.Builtin.Kind.Int1
    result[OpaqueMetadata.Builtin.Int256] = OpaqueMetadata.Builtin.Kind.Int256
    result[OpaqueMetadata.Builtin.Vec16xInt32] = OpaqueMetadata.Builtin.Kind.Vec16xInt32
    result[OpaqueMetadata.Builtin.Vec2xInt32] = OpaqueMetadata.Builtin.Kind.Vec2xInt32
    result[OpaqueMetadata.Builtin.Vec32xInt32] = OpaqueMetadata.Builtin.Kind.Vec32xInt32
    result[OpaqueMetadata.Builtin.Vec3xInt32] = OpaqueMetadata.Builtin.Kind.Vec3xInt32
    result[OpaqueMetadata.Builtin.Vec4xInt32] = OpaqueMetadata.Builtin.Kind.Vec4xInt32
    result[OpaqueMetadata.Builtin.Vec64xInt32] = OpaqueMetadata.Builtin.Kind.Vec64xInt32
    result[OpaqueMetadata.Builtin.Vec8xInt32] = OpaqueMetadata.Builtin.Kind.Vec8xInt32
    result[OpaqueMetadata.Builtin.Int32] = OpaqueMetadata.Builtin.Kind.Int32
    result[OpaqueMetadata.Builtin.Int512] = OpaqueMetadata.Builtin.Kind.Int512
    result[OpaqueMetadata.Builtin.Int63] = OpaqueMetadata.Builtin.Kind.Int63
    result[OpaqueMetadata.Builtin.Vec16xInt64] = OpaqueMetadata.Builtin.Kind.Vec16xInt64
    result[OpaqueMetadata.Builtin.Vec2xInt64] = OpaqueMetadata.Builtin.Kind.Vec2xInt64
    result[OpaqueMetadata.Builtin.Vec32xInt64] = OpaqueMetadata.Builtin.Kind.Vec32xInt64
    result[OpaqueMetadata.Builtin.Vec3xInt64] = OpaqueMetadata.Builtin.Kind.Vec3xInt64
    result[OpaqueMetadata.Builtin.Vec4xInt64] = OpaqueMetadata.Builtin.Kind.Vec4xInt64
    result[OpaqueMetadata.Builtin.Vec64xInt64] = OpaqueMetadata.Builtin.Kind.Vec64xInt64
    result[OpaqueMetadata.Builtin.Vec8xInt64] = OpaqueMetadata.Builtin.Kind.Vec8xInt64
    result[OpaqueMetadata.Builtin.Int64] = OpaqueMetadata.Builtin.Kind.Int64
    result[OpaqueMetadata.Builtin.Int7] = OpaqueMetadata.Builtin.Kind.Int7
    result[OpaqueMetadata.Builtin.Vec16xInt8] = OpaqueMetadata.Builtin.Kind.Vec16xInt8
    result[OpaqueMetadata.Builtin.Vec2xInt8] = OpaqueMetadata.Builtin.Kind.Vec2xInt8
    result[OpaqueMetadata.Builtin.Vec32xInt8] = OpaqueMetadata.Builtin.Kind.Vec32xInt8
    result[OpaqueMetadata.Builtin.Vec3xInt8] = OpaqueMetadata.Builtin.Kind.Vec3xInt8
    result[OpaqueMetadata.Builtin.Vec4xInt8] = OpaqueMetadata.Builtin.Kind.Vec4xInt8
    result[OpaqueMetadata.Builtin.Vec64xInt8] = OpaqueMetadata.Builtin.Kind.Vec64xInt8
    result[OpaqueMetadata.Builtin.Vec8xInt8] = OpaqueMetadata.Builtin.Kind.Vec8xInt8
    result[OpaqueMetadata.Builtin.Int8] = OpaqueMetadata.Builtin.Kind.Int8
    result[OpaqueMetadata.Builtin.NativeObject] = OpaqueMetadata.Builtin.Kind.NativeObject
    result[OpaqueMetadata.Builtin.RawPointer] = OpaqueMetadata.Builtin.Kind.RawPointer
    result[OpaqueMetadata.Builtin.Word] = OpaqueMetadata.Builtin.Kind.Word
    return result
}()
