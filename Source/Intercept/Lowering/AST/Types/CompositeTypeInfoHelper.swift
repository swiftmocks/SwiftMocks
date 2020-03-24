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

/// A helper for type info computations for composite types (structs, classes, enums and tuples).
///
/// Normally all layout computations happen in IR type lowering and involve quite a lot of meticulous bit calculations (spare bits and extra inhabitant count). All of that information is already available in metadata in some shape or form, and so this helper encapsulates the original metadata and exposes the data helpfully computed for us by the compiler.
///
/// - Note: We cannot precompute `FieldInfo`s in the initialiser, as doing so might lead to infinite recursion (`enum E { case foo(() -> E) }`).
class CompositeTypeInfoHelper {
    struct RawFieldInfo {
        let type: Any.Type? // will be nil for non-payload enum cases
        let isIndirectEnumCase: Bool
        let referenceOwnership: ReferenceOwnership
    }

    typealias FieldInfo = (type: AType?, isIndirectEnumCase: Bool, offset: Int)

    private let rawFields: [RawFieldInfo]

    let size: Int
    let alignment: Int

    let fieldOffsets: [Int]?

    convenience init(metadata: Metadata) {
        let fields = Self.getFieldInfos(metadata: metadata)
        let fieldOffsets: [Int]?
        switch metadata {
        case let metadata as StructMetadata:
            fieldOffsets = metadata.fieldOffsets.map { Int($0) }
        case let metadata as ClassMetadata:
            fieldOffsets = metadata.fieldOffsets.map { Int($0) }
        default:
            fieldOffsets = nil
        }
        self.init(size: metadata.valueWitnesses.size, alignment: metadata.valueWitnesses.alignmentMask + 1, fields: fields, fieldOffsets: fieldOffsets)
    }

    init(size: Int, alignment: Int, fields: [RawFieldInfo], fieldOffsets: [Int]?) {
        self.rawFields = fields
        self.fieldOffsets = fieldOffsets
        self.size = size
        self.alignment = alignment
    }

    lazy var fields: [FieldInfo] = {
        rawFields.enumerated().map { (index, field) -> FieldInfo in
            guard let anyType = field.type else {
                return (nil, field.isIndirectEnumCase, fieldOffsets?.at(index) ?? 0)
            }
            let ty = TypeFactory.createReferenceStorageType(referentType: TypeFactory.from(anyType: anyType), referenceOwnership: field.referenceOwnership)
            return (ty, field.isIndirectEnumCase, fieldOffsets?.at(index) ?? 0)
        }
    }()

    /// Return max of the alignments, in bytes, of all payloads
    lazy var payloadAlignment: Int = {
        fields.map { elt -> Int in
            let (type, isIndirect, _) = elt
            guard let ty = type else {
                return 0
            }
            return isIndirect ? 8 /* 64-bit */ : TypeFactory.convert(ty).valueWitnesses.alignmentMask + 1
        }.max() ?? 0
    }()

    /// Return max of the sizes, in bytes, of all payloads
    lazy var payloadSize: Int = {
        fields.map { elt -> Int in
            let (type, isIndirect, _) = elt
            guard let ty = type else {
                return 0
            }
            return isIndirect ? 8 /* 64-bit */ : TypeFactory.convert(ty).valueWitnesses.size
        }.max() ?? 0
    }()

    private static func getFieldInfos(metadata: Metadata) -> [CompositeTypeInfoHelper.RawFieldInfo] {
        guard let typeContextDescriptor = metadata.typeContextDescriptor else {
            LoweringError.unreachable("non-type metadata in \(#function)")
        }
        return typeContextDescriptor.fields.map { field -> CompositeTypeInfoHelper.RawFieldInfo in
            let fieldTypeAndReferenceOwnership = field.resolveTypeAndReferenceOwnership(contextDescriptor: typeContextDescriptor, genericArguments: metadata.genericArgumentsPointer)
            let ret = CompositeTypeInfoHelper.RawFieldInfo(type: fieldTypeAndReferenceOwnership?.type, isIndirectEnumCase: field.isIndirectEnumCase, referenceOwnership: fieldTypeAndReferenceOwnership?.ownership ?? .strong)
            return ret
        }
    }
}

