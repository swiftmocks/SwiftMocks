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

class IRGenModule {
    unowned var silModule: SILModule!
    let types = IRTypeConverter()

    init() {
        types.igm = self
    }

    func getSignature(fn: SILFunctionType) -> IRSignature {
        let sigInfo = getFuncSignatureInfoForLowered(fn: fn)
        return sigInfo.getSignature(module: self)
    }

    private func getFuncSignatureInfoForLowered(fn: SILFunctionType) -> FuncSignatureInfo {
        let sigInfo = getTypeInfoForLowered(CanType(type: fn))
        return sigInfo as! FuncSignatureInfo
    }

    func getStorageType(_ type: SILType) -> LLVMType {
        getStorageType(lowered: type.getASTType().type)
    }

    func getStorageType(lowered type: AType) -> LLVMType {
        types.getTypeEntry(type).storageType
    }

    /// Get the fragile type information for the given type, which is known to have undergone SIL type lowering (or be one of the types for which that lowering is the identity function).
    func getTypeInfo(_ type: SILType) -> TypeInfo {
        getTypeInfoForLowered(type.getASTType())
    }

    func getTypeInfo(_ type: AType) -> TypeInfo {
        getTypeInfoForLowered(CanType(type: type))
    }

    /// Get the fragile type information for the given type.
    func getTypeInfoForLowered(_ type: CanType) -> TypeInfo {
        types.getCompleteTypeInfo(type)
    }

    func cappedAlignment(align: Int) -> Int {
        min(align, maximumAlignment)
    }

    /// Use the best fitting "normal" integer size for the enum tag, given the number of bits required. Though LLVM theoretically supports integer types of arbitrary bit width, in practice, types other than i1 or power-of-two-byte sizes like i8, i16, etc. inhibit FastISel and expose backend bugs. This function, therefore, returns one of i1, i8, i16, i32, i64
    static func getIntegerBitSizeForTag(tagBits: Int) -> Int {
        // i1 is used to represent bool in C so is fairly well supported.
        if tagBits == 1 {
            return 1
        }
        // Otherwise, round the physical size in bytes up to the next power of two.
        var tagBytes = (tagBits + 7) / 8
        if !tagBytes.isPowerOf2 {
            tagBytes = tagBytes.nextPowerOf2
        }

        return tagBytes * 8
    }

    let hasObjCInterop = true

    let voidTy: LLVMType = .void
    let int1Ty: LLVMType = .i1
    let int8Ty: LLVMType = .i8
    let int16Ty: LLVMType = .i16
    let int32Ty: LLVMType = .i32
    let int32PtrTy: LLVMType = LLVMType.i32.pointerTo
    let int64Ty: LLVMType = .i64
    let int8PtrTy: LLVMType = .pointer
    let int8PtrPtrTy: LLVMType = LLVMType.pointer.pointerTo
    let sizeTy: LLVMType = .i64
    let relativeAddressTy: LLVMType = .i32
    let relativeAddressPtrTy: LLVMType = LLVMType.i32.pointerTo

    let integerLiteralTy: LLVMType = .struct([.i64])
    let floatTy: LLVMType = .float
    let doubleTy: LLVMType = .double

    let pointerSize: Int = 8
    let pointerAlignment: Int = 8 // We always use the pointer's width as its swift ABI alignment.

    /// A fixed-size buffer is always three pointers in size and pointer-aligned.
    let fixedBufferSize: Int = 24 /* 3 * pointer size */
    let fixedBufferAlignment: Int = 8 /* pointerAlignment */
    let fixedBufferTy: LLVMType = .array(.pointer, 3)

    let errorPtrTy: LLVMType = .pointer
    let opaqueTy: LLVMType = .struct([])
    let opaquePtrTy: LLVMType = .pointer
    let functionPtrTy: LLVMType = .pointer
    let functionPairTy: LLVMType = .struct([.pointer, .pointer])
    let noEscapeFunctionPairTy: LLVMType = .struct([.pointer, .pointer])
    let witnessTablePtrTy: LLVMType = .pointer
    let typeMetadataPtrTy: LLVMType = .pointer
    let refCountedPtrTy: LLVMType = .pointer
}

protocol FuncSignatureInfo {
    var formalType: SILFunctionType { get }
    func getSignature(module: IRGenModule) -> IRSignature
}
