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

extension IRTypeConverter {
    func convertFunctionType(_ type: SILFunctionType) -> TypeInfo {
        switch type.representation {
        case .thin,
             .method,
             .witnessMethod,
             .closure:
            return ThinFuncTypeInfo(formalType: type, storage: igm.functionPtrTy, size: igm.pointerSize, alignment: igm.pointerAlignment)

        case .thick:
            if type.isNoEscape {
                // @noescape thick functions are trivial types.
                return FuncTypeInfo(formalType: type, storage: igm.noEscapeFunctionPairTy, size: igm.pointerSize * 2, alignment: igm.pointerAlignment)
            }
            return FuncTypeInfo(formalType: type, storage: igm.functionPairTy, size: igm.pointerSize * 2, alignment: igm.pointerAlignment)
        }
    }

    func convertBlockStorageType(_ type: SILBlockStorageType) -> TypeInfo {
        LoweringError.unreachable("we don't support Objective-C blocks")
    }
}

private class ThinFuncTypeInfo: PODSingleScalarTypeInfo, FuncSignatureInfo {
    private var cachedSignature: IRSignature?
    let formalType: SILFunctionType

    init(formalType: SILFunctionType, storage: LLVMType, size: Int, alignment: Int) {
        self.formalType = formalType
        super.init(storage: storage, size: size, alignment: alignment)
    }

    func getSignature(module: IRGenModule) -> IRSignature {
        if let cachedSignature = cachedSignature {
            return cachedSignature
        }

        let ret: IRSignature = .getUncached(module: module, formalType: formalType)
        cachedSignature = ret
        return ret
    }
}

private class FuncTypeInfo: ReferenceTypeInfo, FuncSignatureInfo {
    private var cachedSignature: IRSignature?
    let formalType: SILFunctionType

    init(formalType: SILFunctionType, storage: LLVMType, size: Int, alignment: Int) {
        self.formalType = formalType
        super.init(storage: storage, size: size, alignment: alignment)
    }

    func getSignature(module: IRGenModule) -> IRSignature {
        if let cachedSignature = cachedSignature {
            return cachedSignature
        }

        let ret: IRSignature = .getUncached(module: module, formalType: formalType)
        cachedSignature = ret
        return ret
    }

    override func addToAggLowering(igm: IRGenModule, lowering: inout SwiftAggLowering, offset: Int) {
        guard case let .struct(types) = storageType else {
            preconditionFailure()
        }
        FuncTypeInfo.addScalarToAggLowering(igm: igm, lowering: &lowering, type: types[0], offset: offset, storageSize: igm.pointerSize)
        FuncTypeInfo.addScalarToAggLowering(igm: igm, lowering: &lowering, type: types[1], offset: offset + igm.pointerSize, storageSize: igm.pointerSize)
    }
}
