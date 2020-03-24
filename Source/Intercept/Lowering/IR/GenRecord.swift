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

protocol RecordField {
    var layout: ElementLayout { get set }
    var begin: Int { get set }
    var end: Int { get set }

    mutating func completeFrom(elementLayout: ElementLayout)
}

extension RecordField {
    var typeInfo: TypeInfo {
        layout.type
    }

    var isEmpty: Bool {
        layout.isEmpty
    }

    var hasFixedByteOffset: Bool {
        layout.hasByteOffset
    }

    var fixedByteOffset: Int {
        Int(layout.byteOffset!)
    }

    var index: Int {
        Int(layout.index)
    }

    mutating func completeFrom(elementLayout: ElementLayout) {
        layout.completeFrom(other: elementLayout)
    }
}

class RecordTypeBuilder<F: RecordField> {
    let igm: IRGenModule

    init(igm: IRGenModule) {
        self.igm = igm
    }

    func layout(astFields: [AType]) -> TypeInfo {
        var fields = [F]()

        var explosionSize: Int = 0

        // unlike the compiler, we should only ever be here when dealing with loadable types, so if the next line blows up on unwrapping, something is wrong elsewhere
        let typeInfos: [LoadableTypeInfo] = (0..<astFields.count).map { fieldTypeInfo(index: $0) }
        let layout = performLayout(typeInfos)

        for (index, (astField, ti)) in zip(astFields, typeInfos).enumerated() {
            var fi = fieldInfo(index: index, type: astField, ti: ti)

            fi.begin = explosionSize
            explosionSize += ti.explosionSize
            fi.end = explosionSize
            fi.completeFrom(elementLayout: layout.elements[index])

            fields.append(fi)
        }

        return createLoadable(fields: fields, layout: layout, explosionSize: explosionSize)
    }

    func fieldTypeInfo(index: Int) -> LoadableTypeInfo {
        LoweringError.abstract()
    }

    func fieldInfo(index: Int, type: AType, ti: TypeInfo) -> F {
        LoweringError.abstract()
    }

    func performLayout(_ fields: [TypeInfo]) -> StructLayout {
        LoweringError.abstract()
    }

    func createLoadable(fields: [F], layout: StructLayout, explosionSize: Int) -> TypeInfo {
        LoweringError.abstract()
    }
}
