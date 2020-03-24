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
    func convertStructType(_ typeInfoHelper: CompositeTypeInfoHelper, isResilient: Bool = false, hasClangNode: Bool = false) -> TypeInfo {
        // All resilient structs have the same opaque lowering, since they are indistinguishable as values --- except that we have to track ABI-accessibility.
        if isResilient {
            LoweringError.notImplemented("resilient structs")
        }
        // Use different rules for types imported from C.
        if hasClangNode {
            LoweringError.notImplemented("imported C types")
        }

        // Register a forward declaration before we look at any of the child types.
        // addForwardDecl(key)

        // Build the type
        let builder = StructTypeBuilder(igm: igm, typeInfoHelper: typeInfoHelper)
        let fieldTypes = typeInfoHelper.fields.compactMap { $0.type }
        assert(fieldTypes.count == typeInfoHelper.fields.count)
        return builder.layout(astFields: fieldTypes)
    }
}

// MARK: - Private implementation

private struct StructFieldInfo: RecordField {
    let type: AType
    var layout: ElementLayout
    var begin: Int = 0
    var end: Int = 0
}

private class StructTypeBuilder: RecordTypeBuilder<StructFieldInfo> {
    let typeInfoHelper: CompositeTypeInfoHelper

    init(igm: IRGenModule, typeInfoHelper: CompositeTypeInfoHelper) {
        self.typeInfoHelper = typeInfoHelper
        super.init(igm: igm)
    }

    override func fieldTypeInfo(index: Int) -> LoadableTypeInfo {
        guard let ty = typeInfoHelper.fields[index].type else {
            LoweringError.unreachable("no type for a struct field?")
        }
        // let substType = structType.fieldTypes[index]
        // let origType = AbstractionPattern(origType: CanType(type: substType), signature: nil)
        let type: AType = igm.silModule.types.getTypeLowering(ty, expansion: .maximal).loweredType.getASTType().type //.getLoweredRValueType(origType: origType, substType: substType)
        guard let ret = igm.getTypeInfoForLowered(CanType(type: type)) as? LoadableTypeInfo else {
            LoweringError.unreachable("non-loadable field in a loadable struct?")
        }
        return ret
    }

    override func fieldInfo(index: Int, type: AType, ti: TypeInfo) -> StructFieldInfo {
        StructFieldInfo(type: type, layout: ElementLayout.getIncomplete(ti))
    }

    override func performLayout(_ fields: [TypeInfo]) -> StructLayout {
        guard let fieldOffsets = typeInfoHelper.fieldOffsets else {
            LoweringError.unreachable("no field offsets for a struct?")
        }
        return StructLayout(fields: fields, fieldOffsets: fieldOffsets, alignment: typeInfoHelper.alignment, size: typeInfoHelper.size)
    }

    override func createLoadable(fields: [StructFieldInfo], layout: StructLayout, explosionSize: Int) -> TypeInfo {
        LoadableStructTypeInfo(fields: fields, storageType: layout.ty, size: layout.minimumSize, alignment: layout.minimumAlign)
    }
}

private class LoadableStructTypeInfo: LoadableTypeInfo {
    let fields: [StructFieldInfo]

    init(fields: [StructFieldInfo], storageType: LLVMType, size: Int, alignment: Int) {
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
