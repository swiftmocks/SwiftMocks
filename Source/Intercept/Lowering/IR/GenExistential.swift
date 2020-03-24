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
    func convertExistentialMetatypeType(_ T: ExistentialMetatypeType) -> TypeInfo {
        guard let repr = T.representation else {
            preconditionFailure("metatype should have been assigned a representation by SIL")
        }
        precondition(repr != .thin, "existential metatypes cannot have thin representation")

        var instanceT = T.instanceType
        while let emt = instanceT as? ExistentialMetatypeType {
            instanceT = emt.instanceType
        }

        let layout = instanceT.existentialLayout
        return ExistentialMetatypeTypeInfo(igm: igm, numberOfProtocols: layout.numberOfProtocols)
    }

    func convertProtocolType(_ type: ProtocolType) -> TypeInfo {
        createExistentialTypeInfo(kind: type.existentialLayout.kind, numberOfProtocols: type.numberOfProtocols)
    }

    func convertProtocolCompositionType(_ type: ProtocolCompositionType) -> TypeInfo {
        createExistentialTypeInfo(kind: type.existentialLayout.kind, numberOfProtocols: type.numberOfProtocols)
    }

    private func createExistentialTypeInfo(kind: ExistentialLayout.Kind, numberOfProtocols: Int) -> TypeInfo {
        switch kind {
        case .class:
            return ClassExistentialTypeInfo(igm: igm, numberOfProtocols: numberOfProtocols)
        case .error:
            return ErrorExistentialTypeInfo(igm: igm)
        case .opaque:
            // these are always passed indirect, and this result in our code is only used to produce a (typeless) pointer, so it doesn't matter what to return
            return emptyTypeInfo
        }
    }
}

private class ErrorExistentialTypeInfo: HeapTypeInfo {
    let referenceCounting: ReferenceCounting

    init(igm: IRGenModule) {
        self.referenceCounting = !igm.hasObjCInterop ? ReferenceCounting.native : ReferenceCounting.error
        super.init(storage: igm.errorPtrTy, size: igm.pointerSize, alignment: igm.pointerAlignment)
    }
}

private class ClassExistentialTypeInfo: ReferenceTypeInfo {
    let numberOfProtocols: Int

    init(igm: IRGenModule, numberOfProtocols: Int) {
        let components = Array<LLVMType>(repeating: .pointer, count: numberOfProtocols + 1)
        let ty = LLVMType.struct(components)
        self.numberOfProtocols = numberOfProtocols
        super.init(storage: ty, size: (numberOfProtocols + 1) * igm.pointerSize, alignment: igm.pointerAlignment)
    }

    override func addToAggLowering(igm: IRGenModule, lowering: inout SwiftAggLowering, offset: Int) {
        for i in 0..<numberOfProtocols+1 {
            lowering.addTypedData(.pointer, begin: offset + i * igm.pointerSize)
        }
    }
}

private class ExistentialMetatypeTypeInfo: LoadableTypeInfo {
    let numberOfProtocols: Int

    init(igm: IRGenModule, numberOfProtocols: Int) {
        let components = Array<LLVMType>(repeating: .pointer, count: numberOfProtocols + 1)
        let ty = LLVMType.struct(components)
        self.numberOfProtocols = numberOfProtocols
        super.init(storage: ty, size: (numberOfProtocols + 1) * igm.pointerSize, alignment: igm.pointerAlignment)
    }

    override func addToAggLowering(igm: IRGenModule, lowering: inout SwiftAggLowering, offset: Int) {
        for i in 0..<numberOfProtocols+1 {
            lowering.addTypedData(.pointer, begin: offset + i * igm.pointerSize)
        }
    }
}
