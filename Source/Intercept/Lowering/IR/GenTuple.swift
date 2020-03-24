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
    func convertTupleType(_ type: TupleType) -> TypeInfo {
        let builder = TupleTypeBuilder(igm: igm, type: type)
        return builder.layout(astFields: type.elements)
    }
}

// MARK: - Private implementation

private struct TupleFieldInfo: RecordField {
    var layout: ElementLayout
    var begin: Int = 0
    var end: Int = 0
}

private class LoadableTupleTypeInfo: LoadableTypeInfo {
    let fields: [TupleFieldInfo]

    init(fields: [TupleFieldInfo], storageType: LLVMType, size: Int, alignment: Int) {
        self.fields = fields
        super.init(storage: storageType, size: size, alignment: alignment)
    }

    override func addToAggLowering(igm: IRGenModule, lowering: inout SwiftAggLowering, offset: Int) {
        for field in fields {
            let fieldOffset = offset + field.fixedByteOffset
            (field.typeInfo as! LoadableTypeInfo).addToAggLowering(igm: igm, lowering: &lowering, offset: fieldOffset)
        }
    }
}

private class TupleTypeBuilder: RecordTypeBuilder<TupleFieldInfo> {
    let tupleType: TupleType

    init(igm: IRGenModule, type: TupleType) {
        self.tupleType = type
        super.init(igm: igm)
    }

    override func fieldTypeInfo(index: Int) -> LoadableTypeInfo {
        // let substType = structType.fieldTypes[index]
        // let origType = AbstractionPattern(origType: CanType(type: substType), signature: nil)
        let type: AType = igm.silModule.types.getTypeLowering(tupleType.elements[index], expansion: .maximal).loweredType.getASTType().type //.getLoweredRValueType(origType: origType, substType: substType) // FIXME: why commented out?
        guard let ret = igm.getTypeInfoForLowered(CanType(type: type)) as? LoadableTypeInfo else {
            LoweringError.unreachable("non-loadable field in a loadable struct?")
        }
        return ret
    }

    override func fieldInfo(index: Int, type: AType, ti: TypeInfo) -> TupleFieldInfo {
        TupleFieldInfo(layout: ElementLayout.getIncomplete(ti))
    }

    override func performLayout(_ fields: [TypeInfo]) -> StructLayout {
        StructLayout(igm: igm, fields: fields)
    }

    override func createLoadable(fields: [TupleFieldInfo], layout: StructLayout, explosionSize: Int) -> TypeInfo {
        LoadableTupleTypeInfo(fields: fields, storageType: layout.ty, size: layout.minimumSize, alignment: layout.minimumAlign)
    }
}
