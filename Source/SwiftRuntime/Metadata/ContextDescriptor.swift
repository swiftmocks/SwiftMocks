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

public class ContextDescriptor: Equatable, Hashable {
    public let pointer: RawPointer

    internal init(_ pointer: RawPointer) {
        self.pointer = pointer
    }

    private var flags: UInt32 { pointer.reinterpret(UInt32.self).pointee }

    public var kind: ContextDescriptorKind {
        ContextDescriptorKind(rawValue: UInt8(flags & 0x1F)) ?? { fatalError("Unknown descriptor kind") }()
    }

    public var isGeneric: Bool { flags & 0x80 != 0 }

    public var isUnique: Bool { flags & 0x40 != 0 }

    public var version: UInt8 { UInt8((flags >> 8) & 0xFF) }

    public var kindSpecificFlags: UInt16 { UInt16((flags >> 16) & 0xFFFF) }

    public var parent: ContextDescriptor? {
        /// Base class for all context descriptors.
        struct __ContextDescriptor {
            /// Flags describing the context, including its kind and format version.
            var Flags: __ContextDescriptorFlags
            /// The parent context, or null if this is a top-level context.
            var Parent: TargetRelativeIndirectablePointer /* RelativeContextPointer<TargetContextDescriptor> */ 
        }

        guard let pparent = RawPointer(relative: &pointer.reinterpret(__ContextDescriptor.self).pointee.Parent) else {
            return nil
        }
        return ContextDescriptor.from(pparent)
    }

    public static func from(_ pointer: RawPointer) -> ContextDescriptor {
        switch ContextDescriptor(pointer).kind {
        case .module: return ModuleContextDescriptor(pointer)
        case .extension: return ExtensionContextDescriptor(pointer)
        case .anonymous: return AnonymousContextDescriptor(pointer)
        case .protocol: return ProtocolDescriptor(pointer)
        case .opaqueType: return OpaqueTypeDescriptor(pointer)
        case .class: return ClassDescriptor(pointer)
        case .struct: return StructDescriptor(pointer)
        case .enum: return EnumDescriptor(pointer)
        }
    }
}

extension ContextDescriptor {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(pointer)
    }
}

extension ContextDescriptor {
    public static func == (lhs: ContextDescriptor, rhs: ContextDescriptor) -> Bool {
        lhs.pointer == rhs.pointer
    }
}

protocol GenericContext {
    var isGeneric: Bool { get }
    var genericContextPointer: RawPointer { get }

    var numberOfGenericParameters: UInt16 { get }
    var numberOfGenericRequirements: UInt16 { get }
    var numberOfGenericKeyArguments: UInt16 { get }
    var numberOfGenericExtraArguments: UInt16 { get }

    var genericParams: [GenericParamDescriptor] { get }
    var genericRequirements: [GenericRequirementDescriptor]? { get }
}

struct __GenericContextDescriptorHeader {
    var NumParams: UInt16
    var NumRequirements: UInt16
    var NumKeyArguments: UInt16
    var NumExtraArguments: UInt16
}

extension GenericContext {
    internal var genericContextDescriptorHeader: __GenericContextDescriptorHeader { genericContextPointer.reinterpret(__GenericContextDescriptorHeader.self).pointee }

    public var numberOfGenericParameters: UInt16 { genericContextDescriptorHeader.NumParams }
    public var numberOfGenericRequirements: UInt16 { genericContextDescriptorHeader.NumRequirements }
    public var numberOfGenericKeyArguments: UInt16 { genericContextDescriptorHeader.NumKeyArguments }
    public var numberOfGenericExtraArguments: UInt16 { genericContextDescriptorHeader.NumExtraArguments }

    public var genericParams: [GenericParamDescriptor] {
        guard isGeneric else { fatalError("This is not a generic context: \(self)") }
        let first = genericContextPointer
            .advanced(by: 1, of: __GenericContextDescriptorHeader.self)
            .reinterpret(__GenericParamDescriptor.self)
        return (0..<numberOfGenericParameters).map { GenericParamDescriptor(first.advanced(by: $0).pointee) }
    }

    public var genericRequirements: [GenericRequirementDescriptor]? {
        guard isGeneric else { fatalError("This is not a generic context: \(self)") }
        let first = genericContextPointer
            .advanced(by: 1, of: __GenericContextDescriptorHeader.self)
            .advanced(by: numberOfGenericParameters, of: __GenericParamDescriptor.self)
            .reinterpret(GenericRequirementDescriptor.Pointee.self)
        return (0..<numberOfGenericRequirements).map {
            GenericRequirementDescriptor(first.advanced(by: $0))
        }
    }
}

protocol TypeGenericContext: GenericContext {}

struct __TypeGenericContextDescriptorHeader {
    /// The metadata instantiation cache.
    var instantiationCache: TargetRelativeDirectPointer /* <Runtime, TargetGenericMetadataInstantiationCache<Runtime>> */
    /// The default instantiation pattern.
    var defaultInstantiationPattern: TargetRelativeDirectPointer /* <Runtime, TargetGenericMetadataPattern<Runtime>> */
    /// The base header.  Must always be the final member.
    // struct GenericContextDescriptorHeader Base;
    var numParams: UInt16
    var numRequirements: UInt16
    var numKeyArguments: UInt16
    var numExtraArguments: UInt16
}

extension TypeGenericContext {
    internal var typeGenericContextDescriptorHeader: __TypeGenericContextDescriptorHeader { genericContextPointer.reinterpret(__TypeGenericContextDescriptorHeader.self).pointee }
}

public class TypeContextDescriptor: ContextDescriptor, TypeGenericContext {
    private struct Pointee {
        var flags: __ContextDescriptorFlags
        var parent: TargetRelativeIndirectablePointer /* RelativeContextPointer<TargetContextDescriptor> */
        var name: TargetRelativeDirectPointer /* <Runtime, const char, nullable=false> */
        var accessFunctionPtr: TargetRelativeDirectPointer /* <Runtime, MetadataResponse(...), Nullable=true> */
        var fields: TargetRelativeDirectPointer /* <Runtime, const reflection::FieldDescriptor, nullable=true> */
    }

    /// The name of the type.
    public var name: String { String(relativeDirectPointer: &pointer.reinterpret(Pointee.self).pointee.name) }

    /// A pointer to the metadata access function for this type.
    public var accessFunction: RawPointer {
        RawPointer(relative: &pointer.reinterpret(Pointee.self).pointee.accessFunctionPtr)!
    }

    private var fieldDescriptorPointer: Pointer<FieldDescriptor.Pointee>? {
        Pointer(relative: &pointer.reinterpret(Pointee.self).pointee.fields)
    }

    public var fieldDescriptor: FieldDescriptor? { FieldDescriptor(fieldDescriptorPointer) }

    public var fields: [FieldRecord] {
        guard let fieldDescriptorPointer = fieldDescriptorPointer, let numberOfFields = fieldDescriptor?.numberOfFields else { return [] }

        let first = fieldDescriptorPointer
            .advanced(by: 1)
            .reinterpret(FieldRecord.Pointee.self)
        return (0..<numberOfFields).map { FieldRecord(pointer: first.advanced(by: $0)) }
    }

    internal var metadataInitialization: MetadataInitializationKind { MetadataInitializationKind(rawValue: Int((kindSpecificFlags >> TypeContextDescriptorFlags.metadataInitialization) & TypeContextDescriptorFlags.metadataInitialization_width))! }

    internal var hasSingletonMetadataInitialization: Bool { metadataInitialization == .singletonMetadataInitialization }

    internal var hasForeignMetadataInitialization: Bool { metadataInitialization == .foreignMetadataInitialization }

    public var genericArgumentOffset: Int32 { fatalError("Must be implemented in a subclass") }

    internal var genericContextPointer: RawPointer { fatalError("Must be implemented in a subclass") }

    internal var afterGenericContext: RawPointer {
        guard isGeneric else {
            return genericContextPointer
        }
        return genericContextPointer
            .advanced(by: 1, of: __TypeGenericContextDescriptorHeader.self)
            .advanced(by: numberOfGenericParameters, of: __GenericParamDescriptor.self)
            .advanced(by: numberOfGenericRequirements, of: GenericRequirementDescriptor.Pointee.self)
    }

    public var numberOfGenericParameters: UInt16 { typeGenericContextDescriptorHeader.numParams }
    public var numberOfGenericRequirements: UInt16 { typeGenericContextDescriptorHeader.numRequirements }
    public var numberOfGenericKeyArguments: UInt16 { typeGenericContextDescriptorHeader.numKeyArguments }
    public var numberOfGenericExtraArguments: UInt16 { typeGenericContextDescriptorHeader.numExtraArguments }

    public var genericParams: [GenericParamDescriptor] {
        guard isGeneric else { fatalError("This is not a generic context: \(self)") }
        let first = genericContextPointer
            .advanced(by: 1, of: __TypeGenericContextDescriptorHeader.self)
            .reinterpret(__GenericParamDescriptor.self)
        return (0..<numberOfGenericParameters).map { GenericParamDescriptor(first.advanced(by: $0).pointee) }
    }

    public var genericRequirements: [GenericRequirementDescriptor]? {
        guard isGeneric else { fatalError("This is not a generic context: \(self)") }
        let first = genericContextPointer
            .advanced(by: 1, of: __TypeGenericContextDescriptorHeader.self)
            .advanced(by: numberOfGenericParameters, of: __GenericParamDescriptor.self)
            .reinterpret(GenericRequirementDescriptor.Pointee.self)
        return (0..<numberOfGenericRequirements).map {
            GenericRequirementDescriptor(first.advanced(by: $0))
        }
    }
}

public class ClassDescriptor: TypeContextDescriptor {
    private struct Pointee {
        var flags: __ContextDescriptorFlags
        var parent: TargetRelativeIndirectablePointer /* RelativeContextPointer<TargetContextDescriptor> */
        var name: TargetRelativeDirectPointer /* <Runtime, const char, nullable=false> */
        var accessFunctionPtr: TargetRelativeDirectPointer /* <Runtime, MetadataResponse(...), Nullable=true> */
        var fields: TargetRelativeDirectPointer /* <Runtime, const reflection::FieldDescriptor, nullable=true> */

        var superclassType: TargetRelativeDirectPointer /* <Runtime, const char> */

        private var metadataNegativeSizeInWordsOrResilientMetadataBounds: UInt32 /* a.k.a. union */
        /// If this descriptor does not have a resilient superclass, this is the negative size of metadata objects of this class (in words).
        var metadataNegativeSizeInWords: UInt32 { metadataNegativeSizeInWordsOrResilientMetadataBounds }
        /// If this descriptor has a resilient superclass, this is a reference to a cache holding the metadata's extents.
        var resilientMetadataBounds: TargetRelativeDirectPointer /* <Runtime, TargetStoredClassMetadataBounds<Runtime>> */ { TargetRelativeDirectPointer(Offset: Int32(bitPattern: metadataNegativeSizeInWordsOrResilientMetadataBounds)) }

        private var metadataPositiveSizeInWordsOrExtraClassFlags: UInt32 /* a.k.a. union */
        /// If this descriptor does not have a resilient superclass, this is the positive size of metadata objects of this class (in words).
        var metadataPositiveSizeInWords: UInt32 { metadataPositiveSizeInWordsOrExtraClassFlags }
        /// Otherwise, these flags are used to do things like indicating the presence of an Objective-C resilient class stub.
        var extraClassFlags: __ExtraClassDescriptorFlags { metadataPositiveSizeInWordsOrExtraClassFlags }

        /// The number of additional members added by this class to the class metadata.  This data is opaque by default to the runtime, other than as exposed in other members; it's really just NumImmediateMembers * sizeof(void*) bytes of data. Whether those bytes are added before or after the address point depends on areImmediateMembersNegative().
        var numImmediateMembers: UInt32

        /// The number of stored properties in the class, not including its superclasses. If there is a field offset vector, this is its length.
        var numFields: UInt32

        /// The offset of the field offset vector for this class's stored properties in its metadata, in words. 0 means there is no field offset vector. If this class has a resilient superclass, this offset is relative to the size of the resilient superclass metadata. Otherwise, it is absolute.
        var fieldOffsetVectorOffset: UInt32

        //  :    public TrailingGenericContextObjects<TargetClassDescriptor<Runtime>,
        //                              TargetTypeGenericContextDescriptorHeader,
        //                              /*additional trailing objects:*/
        //                              TargetResilientSuperclass<Runtime>,
        //                              TargetForeignMetadataInitialization<Runtime>,
        //                              TargetSingletonMetadataInitialization<Runtime>,
        //                              TargetVTableDescriptorHeader<Runtime>,
        //                              TargetMethodDescriptor<Runtime>,
        //                              TargetOverrideTableHeader<Runtime>,
        //                              TargetMethodOverrideDescriptor<Runtime>,
        //                              TargetObjCResilientClassStubInfo<Runtime>>
    }

    private struct ResilientSuperclass {
        /// The superclass of this class.  This pointer can be interpreted using the superclass reference kind stored in the type context descriptor flags.  It is null if the class has no formal superclass. Note that SwiftObject, the implicit superclass of all Swift root classes when building with ObjC compatibility, does not appear here.
        var superclass: TargetRelativeDirectPointer /* <Runtime, const void, nullable=true> */
    }

    private var pointee: Pointee { typedPointer.pointee }
    private var typedPointer: Pointer<Pointee> { pointer.reinterpret(Pointee.self) }

    /// The type of the superclass, expressed as a mangled type name that can refer to the generic arguments of the subclass type.
    public var superclassTypeMangledName: Pointer<CChar>? { Pointer(relative: &typedPointer.pointee.superclassType) }

    public var numImmediateMembers: UInt32 { pointee.numImmediateMembers }

    internal var immediateMembersSize: StoredSize { StoredSize(numImmediateMembers) * StoredSize(MemoryLayout<StoredPointer>.size) }

    internal var areImmediateMembersNegative: Bool { (kindSpecificFlags >> TypeContextDescriptorFlags.class_AreImmediateMembersNegative) & 1 != 0 }

    public var numFields: UInt32 { pointee.numFields }

    public var fieldOffsetVectorOffset: UInt32 {
        if hasResilientSuperclass {
            notImplemented("resilient superclasses")
        }
        return pointee.fieldOffsetVectorOffset
    }

    public var hasVTable: Bool { (kindSpecificFlags >> TypeContextDescriptorFlags.class_HasVTable) & 1 != 0 }

    public var hasOverrideTable: Bool { (kindSpecificFlags >> TypeContextDescriptorFlags.class_HasOverrideTable) & 1 != 0 }

    public var hasResilientSuperclass: Bool { (kindSpecificFlags >> TypeContextDescriptorFlags.class_HasResilientSuperclass) & 1 != 0 }

    public var resilientSuperclassReferenceKind: TypeReferenceKind { TypeReferenceKind(rawValue: UInt((kindSpecificFlags >> TypeContextDescriptorFlags.class_ResilientSuperclassReferenceKind) & TypeContextDescriptorFlags.class_ResilientSuperclassReferenceKind_width))! }

    public override var genericArgumentOffset: Int32 {
        if hasResilientSuperclass {
            return resilientImmediateMembersOffset
        }
        return nonResilientGenericArgumentOffset
    }

    private var nonResilientGenericArgumentOffset: Int32 {
        areImmediateMembersNegative ? -Int32(pointee.metadataNegativeSizeInWords) : Int32(pointee.metadataPositiveSizeInWords - numImmediateMembers)
    }

    private var resilientImmediateMembersOffset: Int32 { notImplemented("resilient superclasses") }

    override var genericContextPointer: RawPointer { typedPointer.advanced(by: 1).raw.aligned(__TypeGenericContextDescriptorHeader.self) }

    public var resilientSuperclass: RawPointer? {
        hasResilientSuperclass ? RawPointer(relative: afterGenericContext.reinterpret(TargetRelativeDirectPointer.self)) : nil
    }

    internal var vtableStart: RawPointer {
        afterGenericContext
            .reinterpret(ResilientSuperclass.self)
            .advanced(by: hasResilientSuperclass ? 1 : 0)
            .reinterpret(__ForeignMetadataInitialization.self)
            .advanced(by: hasForeignMetadataInitialization ? 1 : 0)
            .reinterpret(__SingletonMetadataInitialization.self)
            .advanced(by: hasSingletonMetadataInitialization ? 1 : 0)
            .raw
    }

    /// Header for a class vtable descriptor. This is a variable-sized structure that describes how to find and parse a vtable within the type metadata for a class.
    private struct VTableDescriptorHeader {
        var vtableOffset: UInt32
        var vtableSize: UInt32
    }

    /// The offset of the vtable for this class in its metadata, if any, in words. If this class has a resilient superclass, this offset is relative to the start of the immediate class's metadata. Otherwise, it is relative to the metadata address point.
    public var vtableOffset: UInt32 {
        guard hasVTable else { return 0 }
        return vtableStart.reinterpret(VTableDescriptorHeader.self).pointee.vtableOffset
    }

    /// The number of vtable entries. This is the number of MethodDescriptor records following the vtable header in the class's nominal type descriptor, which is equal to the number of words this subclass's vtable entries occupy in instantiated class metadata.
    public var vtableSize: UInt32 {
        guard hasVTable else { return 0 }
        return vtableStart.reinterpret(VTableDescriptorHeader.self).pointee.vtableSize
    }

    fileprivate var overrideTableStart: RawPointer {
        guard hasVTable else { return vtableStart }
        return vtableStart
            .reinterpret(VTableDescriptorHeader.self)
            .advanced(by: 1)
            .reinterpret(MethodDescriptor.Pointee.self)
            .advanced(by: vtableSize)
            .raw
    }

    /// Header for a class vtable override descriptor. This is a variable-sized structure that provides implementations for overrides of methods defined in superclasses.
    private struct __OverrideTableHeader {
        var NumEntries: UInt32
    }

    /// The number of MethodOverrideDescriptor records following the vtable override header in the class's nominal type descriptor.
    public var numberOfOverrideTableEntries: UInt32 {
        guard hasOverrideTable else { return 0 }
        return overrideTableStart.reinterpret(__OverrideTableHeader.self).pointee.NumEntries
    }

    public var hasObjCResilientClassStub: Bool {
        guard hasResilientSuperclass else { return false }
        return pointee.extraClassFlags & ExtraClassDescriptorFlags.hasObjCResilientClassStub != 0
    }
}

extension ClassDescriptor {
    public func resolveSuperclass(genericArguments: BufferPointer<RawPointer>?) -> Any.Type? {
        guard let superclassTypeMangledName = superclassTypeMangledName else { return nil }
        return Runtime.getTypeByMangledNameInContext(name: superclassTypeMangledName, contextDescriptor: self, genericArguments: genericArguments)
    }

    public var vtableMethods: [MethodDescriptor] {
        guard hasVTable else { return [] }
        let first = vtableStart
            .advanced(by: 1, of: VTableDescriptorHeader.self)
            .reinterpret(MethodDescriptor.Pointee.self)
        return (0..<vtableSize).map { MethodDescriptor(first.advanced(by: $0)) }
    }

    public var overrideMethods: [MethodOverrideDescriptor] {
        guard hasOverrideTable else { return [] }
        let first = overrideTableStart
            .reinterpret(__OverrideTableHeader.self)
            .advanced(by: 1)
            .reinterpret(MethodOverrideDescriptor.Pointee.self)
        return (0..<numberOfOverrideTableEntries).map { MethodOverrideDescriptor(first.advanced(by: $0)) }
    }
}

public class ValueTypeDescriptor: TypeContextDescriptor {}

public class StructDescriptor: ValueTypeDescriptor {
    private struct Pointee {
        var flags: __ContextDescriptorFlags
        var parent: TargetRelativeIndirectablePointer /* RelativeContextPointer<TargetContextDescriptor> */
        var name: TargetRelativeDirectPointer /* <Runtime, const char, nullable=false> */
        var accessFunctionPtr: TargetRelativeDirectPointer /* <Runtime, MetadataResponse(...), Nullable=true> */
        var fields: TargetRelativeDirectPointer /* <Runtime, const reflection::FieldDescriptor, nullable=true> */
        var numFields: UInt32
        var fieldOffsetVectorOffset: UInt32
        // : public TrailingGenericContextObjects<TargetStructDescriptor<Runtime>,
        //                            TargetTypeGenericContextDescriptorHeader,
        //                            /*additional trailing objects*/
        //                            TargetForeignMetadataInitialization<Runtime>,
        //                            TargetSingletonMetadataInitialization<Runtime>>

    }
    private var typedPointer: Pointer<Pointee> { pointer.reinterpret(Pointee.self) }
    private var pointee: Pointee { typedPointer.pointee }

    /// The number of stored properties in the struct. If there is a field offset vector, this is its length.
    public var numberOfFields: UInt32 { pointee.numFields }

    /// The offset of the field offset vector for this struct's stored properties in its metadata, if any. 0 means there is no field offset vector.
    public var fieldOffsetVectorOffset: UInt32 { pointee.fieldOffsetVectorOffset }

    public override var genericArgumentOffset: Int32 { Int32(MemoryLayout<StructMetadataPointee>.size) / Int32(MemoryLayout<StoredSize>.size) }

    override var genericContextPointer: RawPointer { typedPointer.advanced(by: 1).raw.aligned(__TypeGenericContextDescriptorHeader.self) }
}

public class EnumDescriptor: ValueTypeDescriptor {
    private struct Pointee {
        var flags: __ContextDescriptorFlags
        var parent: TargetRelativeIndirectablePointer /* RelativeContextPointer<TargetContextDescriptor> */
        var name: TargetRelativeDirectPointer /* <Runtime, const char, nullable=false> */
        var accessFunctionPtr: TargetRelativeDirectPointer /* <Runtime, MetadataResponse(...), Nullable=true> */
        var fields: TargetRelativeDirectPointer /* <Runtime, const reflection::FieldDescriptor, nullable=true> */
        var numPayloadCasesAndPayloadSizeOffset: UInt32
        var numEmptyCases: UInt32
        // :      public TrailingGenericContextObjects<TargetEnumDescriptor<Runtime>,
        //                            TargetTypeGenericContextDescriptorHeader,
        //                            /*additional trailing objects*/
        //                            TargetForeignMetadataInitialization<Runtime>,
        //                            TargetSingletonMetadataInitialization<Runtime>>
    }
    private var typedPointer: Pointer<Pointee> { pointer.reinterpret(Pointee.self) }
    private var pointee: Pointee { typedPointer.pointee }

    /// The number of non-empty cases in the enum are in the low 24 bits; the offset of the payload size in the metadata record in words, if any, is stored in the high 8 bits.
    private var numberOfPayloadCasesAndPayloadSizeOffset: UInt32 { pointee.numPayloadCasesAndPayloadSizeOffset }

    public var numberOfEmptyCases: UInt32 { pointee.numEmptyCases }

    public var numberOfPayloadCases: UInt32 { numberOfPayloadCasesAndPayloadSizeOffset & 0x00FFFFFF }

    public var numberOfCases: UInt32 { numberOfPayloadCases + numberOfEmptyCases }

    public var payloadSizeOffset: Int { Int(bitPattern: UInt(numberOfPayloadCasesAndPayloadSizeOffset >> 24) & 0xFF000000) }

    public override var genericArgumentOffset: Int32 { Int32(MemoryLayout<EnumMetadataPointee>.size) / Int32(MemoryLayout<StoredSize>.size) }

    override var genericContextPointer: RawPointer { typedPointer.advanced(by: 1).raw.aligned(__TypeGenericContextDescriptorHeader.self) }
}

public extension EnumDescriptor {
    static var optionalTypeDescriptor = Metadata.of(Int?.self).typeContextDescriptor as! EnumDescriptor
}

/// A protocol descriptor.
///
/// Protocol descriptors contain information about the contents of a protocol: it's name, requirements, requirement signature, context, and so on. They are used both to identify a protocol and to reason about its contents.
///
/// Only Swift protocols are defined by a protocol descriptor, whereas Objective-C (including protocols defined in Swift as @objc) use the Objective-C protocol layout.
public class ProtocolDescriptor: ContextDescriptor {
    private struct Pointee {
        var flags: __ContextDescriptorFlags
        var parent: TargetRelativeIndirectablePointer /* RelativeContextPointer<TargetContextDescriptor> */
        var name: TargetRelativeDirectPointer /* <Runtime, const char, nullable=false> */
        var numRequirementsInSignature: UInt32
        var numRequirements: UInt32
        /// Associated type names, as a space-separated list in the same order as the requirements.
        var associatedTypeNames: TargetRelativeDirectPointer /* <const char, Nullable=true> */

        // : swift::ABI::TrailingObjects<TargetProtocolDescriptor<Runtime>,
        //    TargetGenericRequirementDescriptor<Runtime>,
        //    TargetProtocolRequirement<Runtime>>

    }
    private var typedPointer: Pointer<Pointee> { pointer.reinterpret(Pointee.self) }
    private var pointee: Pointee { typedPointer.pointee }

    public var name: String { String(relativeDirectPointer: &typedPointer.pointee.name) }

    /// The number of generic requirements in the requirement signature of the protocol.
    public var numberOfRequirementsInSignature: Int { Int(pointee.numRequirementsInSignature) }

    /// The number of requirements in the protocol.
    /// If any requirements beyond MinimumWitnessTableSizeInWords are present in the witness table template, they will be not be overwritten with defaults.
    public var numberOfRequirements: Int { Int(pointee.numRequirements) }

    /// Associated type names, as a space-separated list in the same order as the requirements.
    public var associatedTypeNames: [String] {
        guard let spaceSeparated = String(nullableRelativeDirectPointer: &typedPointer.pointee.associatedTypeNames) else { return [] }
        return spaceSeparated.trimmingCharacters(in: CharacterSet.whitespaces).components(separatedBy: " ")
    }

    /// The protocol is class-constrained, so only class types can conform to it. This must be 0 for ABI compatibility with Objective-C protocol_t records.
    public var hasClassConstraint: Bool { (kindSpecificFlags >> ProtocolContextDescriptorFlags.hasClassConstraint) & ProtocolContextDescriptorFlags.hasClassConstraint_width == 0 }

    public var isResilient: Bool { kindSpecificFlags >> ProtocolContextDescriptorFlags.isResilient != 0 }

    public var specialProtocol: SpecialProtocol { SpecialProtocol(rawValue: UInt8((kindSpecificFlags >> ProtocolContextDescriptorFlags.specialProtocolKind) & ProtocolContextDescriptorFlags.specialProtocolKind_width))! }

    internal var trailingObjectsBase: RawPointer { pointer.advanced(by: 1, of: Pointee.self) }

    /// Retrieve the requirements that make up the requirement signature of this protocol.
    public var requirementSignature: [GenericRequirementDescriptor] {
        let first = trailingObjectsBase
        return (0..<Int(numberOfRequirementsInSignature)).map { GenericRequirementDescriptor(first.advanced(by: $0, of: GenericRequirementDescriptor.Pointee.self)) }
    }

    /// Retrieve the requirements of this protocol.
    public var requirements: [ProtocolRequirement] {
        let first = trailingObjectsBase
            .advanced(by: numberOfRequirementsInSignature, of: GenericRequirementDescriptor.Pointee.self)
        return (0..<numberOfRequirements).map { ProtocolRequirement(first.advanced(by: $0, of: ProtocolRequirement.Pointee.self)) }
    }
}

public class ModuleContextDescriptor: ContextDescriptor {
    private struct Pointee {
        var flags: __ContextDescriptorFlags
        var parent: TargetRelativeIndirectablePointer /* RelativeContextPointer<TargetContextDescriptor> */
        var name: TargetRelativeDirectPointer /* <const char, nullable=false> */
    }
    private var pointee: Pointee { typedPointer.pointee }
    private var typedPointer: Pointer<Pointee> { pointer.reinterpret(Pointee.self) }

    /// The module name.
    public var name: String { String(relativeDirectPointer: &typedPointer.pointee.name) }
}

public class ExtensionContextDescriptor: ContextDescriptor, GenericContext {
    private struct Pointee {
        var flags: __ContextDescriptorFlags
        var parent: TargetRelativeIndirectablePointer /* RelativeContextPointer<TargetContextDescriptor> */
        var extendedContext: TargetRelativeDirectPointer /* <const char> */
        // : TrailingGenericContextObjects<TargetExtensionContextDescriptor<Runtime>>
    }
    private var typedPointer: Pointer<Pointee> { pointer.reinterpret(Pointee.self) }
    private var pointee: Pointee { pointer.reinterpret(Pointee.self).pointee }

    internal var genericContextPointer: RawPointer { pointer + MemoryLayout<Pointee>.size }

    /// A mangling of the `Self` type context that the extension extends.
    ///
    /// The mangled name represents the type in the generic context encoded by this descriptor. For example, a nongeneric nominal type extension will encode the nominal type name. A generic nominal type extension will encode the instance of the type with any generic arguments bound.
    ///
    /// Note that the Parent of the extension will be the module context the extension is declared inside.
    public var mangledExtendedContextTypeName: Pointer<CChar>? { Pointer(relative: &typedPointer.pointee.extendedContext) }
}

extension ExtensionContextDescriptor {
    public func resolveExtendedContextType(genericArguments: BufferPointer<RawPointer>?) -> Any.Type? {
        guard let mangledExtendedContextTypeName = mangledExtendedContextTypeName else { return nil }
        return Runtime.getTypeByMangledNameInContext(name: mangledExtendedContextTypeName, contextDescriptor: self, genericArguments: genericArguments)
    }
}

public class AnonymousContextDescriptor: ContextDescriptor, GenericContext {
    private struct Pointee {
        var flags: __ContextDescriptorFlags
        var parent: TargetRelativeIndirectablePointer /* RelativeContextPointer<TargetContextDescriptor> */
        //     : TargetContextDescriptor<Runtime>,
        //       TrailingGenericContextObjects<TargetAnonymousContextDescriptor<Runtime>,
        //       TargetGenericContextDescriptorHeader,
        //       TargetMangledContextName<Runtime>>
    }

    private struct MangledContextName {
        /// The mangled name of the context.
        var name: TargetRelativeDirectPointer // <Runtime, const char, nullable=false>
    }

    internal var genericContextPointer: RawPointer { pointer + MemoryLayout<Pointee>.size }

    public var hasMangledContextName: Bool { (UInt32(kindSpecificFlags) >> AnonymousContextDescriptorFlags.hasMangledName) & 1 != 0 }

    private var mangledContextNamePointer: Pointer<MangledContextName> {
        precondition(hasMangledContextName)
        guard isGeneric else { return genericContextPointer.reinterpret(MangledContextName.self) }
        return genericContextPointer
            .advanced(by: 1, of: __GenericContextDescriptorHeader.self)
            .advanced(by: numberOfGenericParameters, of: __GenericParamDescriptor.self)
            .advanced(by: numberOfGenericRequirements, of: GenericRequirementDescriptor.Pointee.self)
            .reinterpret(MangledContextName.self)
    }

    public var mangledContextName: String { String(relativeDirectPointer: &mangledContextNamePointer.pointee.name) }
}

public class OpaqueTypeDescriptor: ContextDescriptor {}

// PRAGMA MARK: -

public struct GenericRequirementDescriptor: PointeeFacade {
    public struct Pointee {
        var flags: __GenericRequirementFlags
        /// The type that's constrained, described as a mangled name.
        var param: TargetRelativeDirectPointer /* <const char, nullable=false> */
        var _union: UInt32
    }

    public let pointer: RawPointer

    internal var flags: UInt32 { pointee.flags }

    public var hasKeyArgument: Bool { pointee.flags & 0x80 != 0}

    public var hasExtraArgument: Bool { pointee.flags & 0x40 != 0}

    public var kind: GenericRequirementKind {
        // note: due to the way union'ised struct fields are imported, the shortcut notation of &typedPointer.pointee.Something does not work for those fields; hence calculating absolute pointers manually
        let detailsPointer = pointer + MemoryLayout<__GenericRequirementFlags>.size + MemoryLayout<TargetRelativeDirectPointer>.size
        switch flags & 0x1F {
        case 0:
            var isObjCProtocol: UInt8 = 0
            let protocolDescriptor = RawPointer(relative: detailsPointer.reinterpret(RelativeIndirectablePointerIntPair.self), int: &isObjCProtocol)!
            return .protocol(isObjCProtocol == 0 ? ProtocolDescriptor(protocolDescriptor) : nil)
        case 1:
            let mangledName = RawPointer(relative: detailsPointer.reinterpret(TargetRelativeDirectPointer.self))!/* always nonnull */.reinterpret(CChar.self)
            return .sameType(mangledName)
        case 2:
            let mangledName = RawPointer(relative: detailsPointer.reinterpret(TargetRelativeDirectPointer.self))!/* always nonnull */.reinterpret(CChar.self)
            return .baseClass(mangledName)
        case 0x1F:
            let rawValue = detailsPointer.reinterpret(__GenericRequirementLayoutKind.self).pointee
            let layoutKind = GenericRequirementLayoutKind(rawValue: rawValue)!
            return .layout(layoutKind)
        default:
            fatalError("Unknown \(GenericRequirementKind.self) value: \(flags & 0x1F)")
        }
    }

    public var mangledTypeName: Pointer<CChar> { Pointer(relative: &typedPointer.pointee.param)! /* non-nullable */ }

    public func resolveType(contextDescriptor: ContextDescriptor?, genericArguments: BufferPointer<RawPointer>?) -> Any.Type? {
        Runtime.getTypeByMangledNameInContext(name: mangledTypeName, contextDescriptor: contextDescriptor, genericArguments: genericArguments)
    }
}

/// An opaque descriptor describing a class or protocol method. References to these descriptors appear in the method override table of a class context descriptor, or a resilient witness table pattern, respectively.
///
/// Clients should not assume anything about the contents of this descriptor other than it having 4 byte alignment.
public struct MethodDescriptor: PointeeFacade {
    public struct Pointee {
        var flags: __MethodDescriptorFlags
        var impl: TargetRelativeDirectPointer/*<Runtime, void>*/
    }
    public let pointer: RawPointer

    public var kind: MethodDescriptorKind { MethodDescriptorKind(rawValue: pointee.flags & MethodDescriptorFlags.kindMask)! }

    public var isInstance: Bool { pointee.flags & MethodDescriptorFlags.isInstanceMask != 0 }

    public var isDynamic: Bool { pointee.flags & MethodDescriptorFlags.isDynamicMask != 0 }

    public var impl: RawPointer? { RawPointer(relative: &typedPointer.pointee.impl) }
}

/// An entry in the method override table, referencing a method from one of our ancestor classes, together with an implementation.
public struct MethodOverrideDescriptor: PointeeFacade {
    public struct Pointee {
        var `class`: TargetRelativeIndirectablePointer/*<Runtime, TargetClassDescriptor<Runtime>, true>*/
        var method: TargetRelativeIndirectablePointer/*<Runtime, TargetMethodDescriptor<Runtime>, true>*/
        var impl: TargetRelativeDirectPointer/*<Runtime, void, nullable true>*/
    }
    public let pointer: RawPointer

    /// The class containing the base method.
    public var `class`: ClassDescriptor? {
        guard let p = RawPointer(relative: &typedPointer.pointee.class) else { return nil }
        return ClassDescriptor(p)
    }

    /// The base method.
    public var method: MethodDescriptor? { MethodDescriptor(RawPointer(relative: &typedPointer.pointee.method)) } // XXX: why/when can it be nil?

    /// The implementation of the override.
    public var impl: RawPointer? { RawPointer(&typedPointer.pointee.impl) } // XXX: why/when can it be nil?
}
