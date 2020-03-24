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

class TypeInfo {
    let storageType: LLVMType
    let alignment: Int

    init(type: LLVMType, alignment: Int) {
        self.storageType = type
        self.alignment = alignment
    }

      /// Get the native (abi) convention for a return value of this type.
    func nativeReturnValueSchema(_ igm: IRGenModule) -> NativeConventionSchema {
        NativeConventionSchema(igm: igm, ti: self, isResult: true)
    }

    /// Get the native (abi) convention for a parameter value of this type.
    func nativeParameterValueSchema(_ igm: IRGenModule) -> NativeConventionSchema {
        NativeConventionSchema(igm: igm, ti: self, isResult: false)
    }
}

class FixedTypeInfo: TypeInfo {
    let size: Int

    init(storage: LLVMType, size: Int, alignment: Int) {
        self.size = size
        super.init(type: storage, alignment: alignment)
    }
}

class IndirectTypeInfo: FixedTypeInfo {}

class LoadableTypeInfo: FixedTypeInfo {
    var explosionSize: Int {
        switch storageType {
        case .void:
            return 0
        case let .struct(explosion):
            return explosion.count
        case .array:
            LoweringError.unreachable("we never lower to arrays")
        default:
            return 1
        }
    }

    func addToAggLowering(igm: IRGenModule, lowering: inout SwiftAggLowering, offset: Int) {
        LoweringError.abstract()
    }

    static func addScalarToAggLowering(igm: IRGenModule, lowering: inout SwiftAggLowering, type: LLVMType, offset: Int, storageSize: Int) {
        lowering.addTypedData(type, begin: offset, end: offset + storageSize)
    }
}

class ReferenceTypeInfo: LoadableTypeInfo {}

class ScalarTypeInfo: LoadableTypeInfo {
    var scalarType: LLVMType {
        storageType
    }
}

class SingleScalarTypeInfo: ScalarTypeInfo {
    override func addToAggLowering(igm: IRGenModule, lowering: inout SwiftAggLowering, offset: Int) {
      // Can't use getFixedSize because it returns the alloc size not the store size.
        LoadableTypeInfo.addScalarToAggLowering(igm: igm, lowering: &lowering, type: scalarType, offset: offset, storageSize: scalarType.size)
    }
}

class PODSingleScalarTypeInfo: SingleScalarTypeInfo {}

class HeapTypeInfo: SingleScalarTypeInfo {
    var optionalIntType: LLVMType {
        LLVMType.getInteger(bitWidth: size * 8)
    }
}
