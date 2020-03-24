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

class AnyGenericType: AType {
    let parent: AType?

    init(kind: TypeKind, parent: AType?) {
        self.parent = parent
        super.init(kind: kind)
    }
}

class NominalOrBoundGenericNominalType: AnyGenericType {
    let isResilient: Bool = false
}

class NominalType: NominalOrBoundGenericNominalType, ATypeEquatable, AlwaysHasMetadata {
    let metadata: Metadata

    init(kind: TypeKind, metadata: Metadata, parent: AType?) {
        self.metadata = metadata
        super.init(kind: kind, parent: parent)
    }

    func isEqual(to other: AType) -> Bool {
        guard let other = other as? NominalType else {
            return false
        }
        return other.metadata == metadata
    }
}

class BoundGenericType: NominalOrBoundGenericNominalType, ATypeEquatable, CanComputeMetadata {
    /// Generic parameter types for this generic type. For example, for `Array<Int>` this would contain `AType` for `Int`.
    let genericParams: [AType]
    let typeContextDescriptor: TypeContextDescriptor

    /// Generally, `Runtime.getGenericMetadata()` in addtion to generic params metadata, requires witness tables, if the requested type's generic signature contains any protocol conformance requirements. However almost all of our bound generic types come with complete runtime metadata, meaning that we have generic arguments out of the box, so extracting witness tables seems like too much trouble for no benefit. Manually constructed optionals are an exception, however we know that they don't have conformance requirements. Therefore, we just keep the `genericArguments` from runtime metadata for metadata (re-)computation purposes (except for optionals), and `genericParams` for all other purposes.
    /// TODO: it is however possible that a single generic param type may have multiple conformances to the same protocol in different modules, which would result in different metadata for the resulting generic type, so this is something that needs to be fixed at some point. Reference: `SubstGenericParametersFromMetadata`, `GenericMetadataCache`.
    let genericArguments: BufferPointer<RawPointer>?

    lazy var computedMetadata: Metadata = {
        if let genericArgumentsPtr = genericArguments {
            return Runtime.getGenericMetadata(descriptor: typeContextDescriptor, genericArguments: genericArgumentsPtr)
        } else {
            // the only exception where we don't keep pre-made genericArgumentsPtr is for optionals, since they can be dynamically created during lowering
            assert(typeContextDescriptor == EnumDescriptor.optionalTypeDescriptor)
            return Runtime.getGenericMetadata(descriptor: typeContextDescriptor, genericParams: genericParams.map { TypeFactory.convert($0) }, conformanceWitnessTables: [])
        }
    }()

    fileprivate init(kind: TypeKind, typeContextDescriptor: TypeContextDescriptor, genericParams: [AType], genericArguments: BufferPointer<RawPointer>?, parent: AType?) {
        self.typeContextDescriptor = typeContextDescriptor
        self.genericParams = genericParams
        self.genericArguments = genericArguments
        super.init(kind: kind, parent: parent)
    }

    // see TODO note above; we need to account for different conformances of the same conforming type and protocols
    func isEqual(to other: AType) -> Bool {
        guard let other = other as? BoundGenericType else {
            return false
        }
        return other.genericParams == genericParams && other.typeContextDescriptor == typeContextDescriptor
    }
}

// MARK: - Struct

class StructType: NominalType {
    let typeInfoHelper: CompositeTypeInfoHelper

    private init(typeInfoHelper: CompositeTypeInfoHelper, metadata: StructMetadata, parent: AType?) {
        self.typeInfoHelper = typeInfoHelper
        super.init(kind: .struct, metadata: metadata, parent: parent)
    }

    static func _get(typeInfoHelper: CompositeTypeInfoHelper, metadata: StructMetadata, parent: AType? = nil) -> StructType {
        StructType(typeInfoHelper: typeInfoHelper, metadata: metadata, parent: parent)
    }
}

class BoundGenericStructType: BoundGenericType {
    let typeInfoHelper: CompositeTypeInfoHelper

    private init(typeInfoHelper: CompositeTypeInfoHelper, typeContextDescriptor: TypeContextDescriptor, genericParams: [AType], genericArguments: BufferPointer<RawPointer>?, parent: AType?) {
        self.typeInfoHelper = typeInfoHelper
        super.init(kind: .boundGenericStruct, typeContextDescriptor: typeContextDescriptor, genericParams: genericParams, genericArguments: genericArguments, parent: parent)
    }

    /// To be used only by `TypeFactory`
    static func _get(typeInfoHelper: CompositeTypeInfoHelper, typeContextDescriptor: TypeContextDescriptor, genericParams: [AType], genericArguments: BufferPointer<RawPointer>?, parent: AType? = nil) -> BoundGenericStructType {
        BoundGenericStructType(typeInfoHelper: typeInfoHelper, typeContextDescriptor: typeContextDescriptor, genericParams: genericParams, genericArguments: genericArguments, parent: parent)
    }
}

// MARK: - Class

class ClassType: NominalType {
    let typeInfoHelper: CompositeTypeInfoHelper

    private init(typeInfoHelper: CompositeTypeInfoHelper, metadata: ClassMetadata, parent: AType?) {
        self.typeInfoHelper = typeInfoHelper
        super.init(kind: .class, metadata: metadata, parent: parent)
    }

    static func _get(typeInfoHelper: CompositeTypeInfoHelper, metadata: ClassMetadata, parent: AType? = nil) -> ClassType {
        ClassType(typeInfoHelper: typeInfoHelper, metadata: metadata, parent: parent)
    }
}

class BoundGenericClassType: BoundGenericType {
    let typeInfoHelper: CompositeTypeInfoHelper

    private init(typeInfoHelper: CompositeTypeInfoHelper, typeContextDescriptor: TypeContextDescriptor, genericParams: [AType], genericArguments: BufferPointer<RawPointer>?, parent: AType?) {
        self.typeInfoHelper = typeInfoHelper
        super.init(kind: .boundGenericClass, typeContextDescriptor: typeContextDescriptor, genericParams: genericParams, genericArguments: genericArguments, parent: parent)
    }

    /// To be used only by `TypeFactory`
    static func _get(typeInfoHelper: CompositeTypeInfoHelper, typeContextDescriptor: TypeContextDescriptor, genericParams: [AType], genericArguments: BufferPointer<RawPointer>?, parent: AType? = nil) -> BoundGenericClassType {
        BoundGenericClassType(typeInfoHelper: typeInfoHelper, typeContextDescriptor: typeContextDescriptor, genericParams: genericParams, genericArguments: genericArguments, parent: parent)
    }
}

// MARK: - Enum

class EnumType: NominalType {
    let typeInfoHelper: CompositeTypeInfoHelper

    var numberOfElements: Int {
        typeInfoHelper.fields.count
    }

    private init(typeInfoHelper: CompositeTypeInfoHelper, metadata: EnumMetadata, parent: AType?) {
        self.typeInfoHelper = typeInfoHelper
        super.init(kind: .enum, metadata: metadata, parent: parent)
    }

    /// To be used only by `TypeFactory`
    static func _get(typeInfoHelper: CompositeTypeInfoHelper, metadata: EnumMetadata, parent: AType? = nil) -> EnumType {
        EnumType(typeInfoHelper: typeInfoHelper, metadata: metadata, parent: parent)
    }
}

class BoundGenericEnumType: BoundGenericType {
    let typeInfoHelper: CompositeTypeInfoHelper

    var numberOfElements: Int {
        typeInfoHelper.fields.count
    }

    private init(typeInfoHelper: CompositeTypeInfoHelper, typeContextDescriptor: TypeContextDescriptor, genericParams: [AType], genericArguments: BufferPointer<RawPointer>?, parent: AType?) {
        self.typeInfoHelper = typeInfoHelper
        super.init(kind: .boundGenericEnum, typeContextDescriptor: typeContextDescriptor, genericParams: genericParams, genericArguments: genericArguments, parent: parent)
    }

    override var optionalObjectType: AType? {
        typeContextDescriptor == EnumDescriptor.optionalTypeDescriptor ? genericParams[0] : nil
    }

    /// To be used only by `TypeFactory`
    static func _get(typeInfoHelper: CompositeTypeInfoHelper, typeContextDescriptor: TypeContextDescriptor, genericParams: [AType], genericArguments: BufferPointer<RawPointer>?, parent: AType? = nil) -> BoundGenericEnumType {
        BoundGenericEnumType(typeInfoHelper: typeInfoHelper, typeContextDescriptor: typeContextDescriptor, genericParams: genericParams, genericArguments: genericArguments, parent: parent)
    }
}

// MARK: - Protocol

class ProtocolType: NominalType {
    private let existentialMetadata: ExistentialTypeMetadata

    var requiresClass: Bool {
        existentialMetadata.requiresClass
    }

    var isObjC: Bool {
        existentialMetadata.isObjC
    }

    var hasExplicitAnyObject: Bool {
        existentialMetadata.isClassBounded
    }

    var numberOfProtocols: Int {
        existentialMetadata.numberOfProtocols
    }

    var representation: ExistentialTypeRepresentation {
        existentialMetadata.representation
    }

    private init(metadata: ExistentialTypeMetadata) {
        precondition(metadata.numberOfProtocols < 2)
        self.existentialMetadata = metadata
        super.init(kind: .protocol, metadata: metadata, parent: nil)
    }

    /// To be used only by `TypeFactory`
    static func _get(metadata: ExistentialTypeMetadata) -> ProtocolType {
        ProtocolType(metadata: metadata)
    }
}
