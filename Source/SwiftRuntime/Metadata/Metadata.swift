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

// PRAGMA MARK: - Metadata

/// The common structure of all type metadata.
public class Metadata: Equatable, Hashable {
    public let pointer: RawPointer
    private struct Pointee {
        var kind: StoredPointer
    }

    internal init(_ pointer: RawPointer) {
        self.pointer = pointer
    }

    public var kind: MetadataKind {
        let rawKind = pointer.reinterpret(UInt32.self).pointee
        return rawKind > MetadataKind.lastEnumerated ? .class : MetadataKind(rawValue: rawKind)!
    }

    /// Is this a class object--the metadata record for a Swift class (which also serves as the class object), or the class object for an ObjC class (which is not metadata)?
    public var isClassObject: Bool { kind == .class }

    public var isAnyExistentialType: Bool { kind == .existential || kind == .existentialMetatype }

    public var isAnyKindOfClass: Bool { kind == .class || kind == .objCClassWrapper || kind == .foreignClass }

    public var valueWitnesses: ValueWitnessTable { ValueWitnessTable(pointer: pointer.reinterpret(RawPointer.self).advanced(by: -1).pointee, metadata: self) }

    /// Get the nominal type descriptor if this metadata describes a nominal type, or return null if it does not.
    public var typeContextDescriptor: TypeContextDescriptor? {
        switch kind {
        case .class:
            guard let classMetadata = self as? ClassMetadata else { return nil }
            guard classMetadata.isTypeMetadata == true /* && !isArtificialSubclass */ else { return nil }
            return classMetadata.description
        case .struct: fallthrough
        case .enum: fallthrough
        case .optional:
            return (self as! ValueMetadata).description
        default: return nil
        }
    }

    /// Retrieve the generic arguments of this type, if it has any, in the form suitable for passing to `Runtime.getTypeByMangledNameInContext()`
    public var genericArgumentsPointer: BufferPointer<RawPointer>? {
        guard let typeContextDescriptor = typeContextDescriptor,
            typeContextDescriptor.isGeneric else { return nil }
        return BufferPointer(start: pointer.advanced(by: Int(typeContextDescriptor.genericArgumentOffset) * MemoryLayout<StoredPointer>.size).reinterpret(RawPointer.self), count: Int(typeContextDescriptor.numberOfGenericParameters)) // FIXME: this includes witness tables, not only generic params
    }

    /// Retrieve the generic parameters of this type, if it has any.
    public var genericParameters: [Metadata] {
        guard let first = genericArgumentsPointer, let numberOfGenericParameters = typeContextDescriptor?.numberOfGenericParameters else { return [] }
        return (0..<Int(numberOfGenericParameters)).map { Metadata.from(first[$0]) }
    }

    public static func of(_ type: Any.Type) -> Metadata {
        // TODO: make it work with ObjC
        let p = unsafeBitCast(type, to: Pointer<Pointee>.self)
        return from(p)
    }

    public static func from(_ p: RawPointer) -> Metadata {
        let metadata = Metadata(p)
        switch metadata.kind {
        case .class: return ClassMetadata(p)
        case .struct: return StructMetadata(p)
        case .enum: return EnumMetadata(p)
        case .optional: return OptionalMetadata(p)
        case .foreignClass: return ForeignClassMetadata(p)
        case .opaque: return OpaqueMetadata(p)
        case .tuple: return TupleTypeMetadata(p)
        case .function: return FunctionTypeMetadata(p)
        case .existential: return ExistentialTypeMetadata(p)
        case .metatype: return MetatypeMetadata(p)
        case .objCClassWrapper: return ObjCClassWrapperMetadata(p)
        case .existentialMetatype: return ExistentialMetatypeMetadata(p)
        // "Non-generic SIL boxes also use the HeapLocalVariable metadata kind, but with a null capture descriptor right now (see FixedBoxTypeInfoBase::allocate)."
        case .heapLocalVariable: return HeapLocalVariableMetadata(p)
        case .heapGenericLocalVariable: notImplemented()
        case .errorObject: notImplemented()
        }
    }

    public var asAnyType: Any.Type? {
        // TODO: make it work with ObjC
        // TODO: even apart from ObjC, not any metadata is a Swift type
        unsafeBitCast(pointer, to: Any.Type.self)
    }

    public static func == (lhs: Metadata, rhs: Metadata) -> Bool {
        lhs.pointer == rhs.pointer
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(pointer)
    }
}

/// The common structure of opaque metadata.  Adds nothing.
public class OpaqueMetadata: Metadata {}


/// The common structure of all metadata for heap-allocated types.
///
/// A pointer to one of these can be retrieved by loading the 'isa' field of any heap object, whether it was managed by Swift or by Objective-C.  However, when loading from an Objective-C object, this metadata may not have the heap-metadata header, and it may not be the Swift type metadata for the object's dynamic type.
public class HeapMetadata: Metadata {
    public var destroy: RawPointer { pointer.advanced(by: -2, of: TargetPointer.self).reinterpret(RawPointer.self).pointee }
}

/// The portion of a class metadata object that is compatible with all classes, even non-Swift ones.
public class AnyClassMetadata: HeapMetadata {
    private struct Pointee {
        var kind: StoredPointer
        var superclass: TargetPointer /* ConstTargetMetadataPointer<Runtime, swift::TargetClassMetadata> */
        /// The cache data is used for certain dynamic lookups; it is owned by the runtime and generally needs to interoperate with Objective-C's use.
        var cacheData_0: TargetPointer /* <Runtime, void> */
        var cacheData_1: TargetPointer /* <Runtime, void> */
        /// The data pointer is used for out-of-line metadata and is generally opaque, except that the compiler sets the low bit in order to indicate that this is a Swift metatype and therefore that the type metadata header is present.
        var data: StoredSize
    };
    private var pointee: Pointee { pointer.reinterpret(Pointee.self).pointee }

    /// The metadata for the superclass.  This is null for the root class.
    public var superclass: ClassMetadata? {
        guard let p = pointee.superclass else { return nil }
        return ClassMetadata(p)
    }

    /// Is this object a valid swift type metadata?  That is, can it be safely downcast to ClassMetadata?
    public var isTypeMetadata: Bool { pointee.data & 2 != 0 /* SWIFT_CLASS_IS_SWIFT_MASK can be 1 or 2, depending on runtime */ }

    /// A different perspective on the same bit
    public var isPureObjC: Bool { !isTypeMetadata }
}

public extension AnyClassMetadata {
    enum Relationship {
        case same
        case parent
        case child
        case unrelated
    }

    func isRelated(to other: AnyClassMetadata) -> Relationship {
        if pointer == other.pointer {
            return .same
        }

        var superclass: AnyClassMetadata

        superclass = self
        while let next = superclass.superclass {
            superclass = next
            if next.pointer == other.pointer {
                return .child
            }
        }

        superclass = other
        while let next = superclass.superclass {
            superclass = next
            if next.pointer == self.pointer {
                return .parent
            }
        }

        return .unrelated
    }
}

/// The structure of all class metadata.  This structure is embedded directly within the class's heap metadata structure and therefore cannot be extended without an ABI break.
/// Note that the layout of this type is compatible with the layout of an Objective-C class.
public class ClassMetadata: AnyClassMetadata {
    private struct Pointee {
        var kind: StoredPointer
        var superclass: TargetPointer /* ConstTargetMetadataPointer<Runtime, swift::TargetClassMetadata> */
        var cacheData_0: TargetPointer /* <Runtime, void> */
        var cacheData_1: TargetPointer /* <Runtime, void> */
        var data: StoredSize
        // The remaining fields are valid only when isTypeMetadata(). The Objective-C runtime knows the offsets to some of these fields. Be careful when accessing them.
        var flags: __ClassFlags
        var instanceAddressPoint: UInt32
        var instanceSize: UInt32
        var instanceAlignMask: UInt16
        var reserved: UInt16
        var classSize: UInt32
        var classAddressPoint: UInt32
        var description: RawPointer /* <Runtime, TargetClassDescriptor> */
        var ivarDestroyer: RawPointer? /* <Runtime, ClassIVarDestroyer> */
        // After this come the class members, laid out as follows:
        //   - class members for the superclass (recursively)
        //   - metadata reference for the parent, if applicable
        //   - generic parameters for this class
        //   - class variables (if we choose to support these)
        //   - "tabulated" virtual methods
    };

    private var pointee: Pointee { pointer.reinterpret(Pointee.self).pointee }

    /// Swift-specific class flags.
    public var flags: ClassFlags { checkIsTypeMetadata(ClassFlags(rawValue: pointee.flags)) }

    /// The address point of instances of this type.
    public var instanceAddressPoint: Int { checkIsTypeMetadata(Int(pointee.instanceAddressPoint)) }

    /// The required size of instances of this type. 'InstanceAddressPoint' bytes go before the address point; 'InstanceSize - InstanceAddressPoint' bytes go after it.
    public var instanceSize: Int { checkIsTypeMetadata(Int(pointee.instanceSize)) }

    /// The alignment mask of the address point of instances of this type.
    public var instanceAlignMask: Int { checkIsTypeMetadata(Int(pointee.instanceAlignMask))}

    /// The total size of the class object, including prefix and suffix extents.
    public var classSize: UInt32 { checkIsTypeMetadata(pointee.classSize) }

    /// The offset of the address point within the class object.
    public var classAddressPoint: UInt32 { checkIsTypeMetadata(pointee.classAddressPoint) }

    /// An out-of-line Swift-specific description of the type, or null if this is an artificial subclass.  We currently provide no supported mechanism for making a non-artificial subclass dynamically.
    public var description: ClassDescriptor { checkIsTypeMetadata(ClassDescriptor(pointee.description)) }

    /// A function for destroying instance variables, used to clean up after an early return from a constructor. If null, no clean up will be performed and all ivars must be trivial.
    public var ivarDestroyer: RawPointer? { pointee.ivarDestroyer }

    public var fieldOffsets: [StoredPointer] { // note: it's different from struct?
        precondition(isTypeMetadata)
        guard description.fieldOffsetVectorOffset != 0 else { return [] }
        let first = pointer
            .advanced(by: description.fieldOffsetVectorOffset, of: StoredPointer.self)
            .reinterpret(StoredPointer.self)
        return (0..<description.numFields).map { first.advanced(by: $0).pointee }
    }

    public override var typeContextDescriptor: ClassDescriptor { checkIsTypeMetadata(super.typeContextDescriptor as! ClassDescriptor) }
    public override var asAnyType: Any.Type { super.asAnyType! }

    // After this come the class members, laid out as follows:
    //   - class members for the superclass (recursively)
    //   - metadata reference for the parent, if applicable
    //   - generic parameters for this class
    //   - class variables (if we choose to support these)
    //   - "tabulated" virtual methods
}

extension ClassMetadata {
    internal var vtableStart: RawPointer? {
        guard description.hasVTable else { return nil }
        return pointer.advanced(by: Int(description.vtableOffset) * MemoryLayout<StoredPointer>.size)
    }

    public var vtable: [RawPointer]? {
        guard description.hasVTable else { return nil }
        let result = (0..<description.vtableSize).map {
            vtableStart!
                .advanced(by: $0, of: RawPointer.self)
                .reinterpret(RawPointer.self)
                .pointee
        }
        return result
    }
}

/// The common structure of metadata for structs and enums.
public class ValueMetadata: Metadata {
    private struct Pointee {
        var kind: StoredPointer
        var description: RawPointer /* <Runtime, TargetValueTypeDescriptor> */
    }
    private var pointee: Pointee { pointer.reinterpret(Pointee.self).pointee }

    public var description: ValueTypeDescriptor { ValueTypeDescriptor(pointee.description) }

    public override var asAnyType: Any.Type { super.asAnyType! }
}

struct StructMetadataPointee { // FIXME: used by descriptor so can't make private
    var kind: StoredPointer
    var description: RawPointer /* <Runtime, TargetValueTypeDescriptor> */
}

public class StructMetadata: ValueMetadata {
    private typealias Pointee = StructMetadataPointee
    private var pointee: Pointee { pointer.reinterpret(Pointee.self).pointee }

    public override var description: StructDescriptor { StructDescriptor(pointee.description) }

    public var fieldOffsets: [UInt32] {
        guard description.fieldOffsetVectorOffset != 0 else { return [] }
        let first = pointer
            .advanced(by: description.fieldOffsetVectorOffset, of: StoredPointer.self)
            .reinterpret(UInt32.self)
        return (0..<description.numberOfFields).map { first.advanced(by: $0).pointee }
    }

    public override var typeContextDescriptor: StructDescriptor { super.typeContextDescriptor as! StructDescriptor }
}

struct EnumMetadataPointee { // FIXME: used by descriptor so can't make private
    var kind: StoredPointer
    var description: RawPointer /* <Runtime, TargetValueTypeDescriptor> */
}

public class EnumMetadata: ValueMetadata {
    private typealias Pointee = EnumMetadataPointee
    private var pointee: Pointee { pointer.reinterpret(Pointee.self).pointee }

    public override var description: EnumDescriptor { EnumDescriptor(pointee.description) }

    /// True if the metadata records the size of the payload area.
    public var hasPayloadSize: Bool { description.payloadSizeOffset != 0 }

    /// Retrieve the size of the payload area. `hasPayloadSize` must be true for this to be valid.
    public var payloadSize: StoredSize {
        precondition(hasPayloadSize)
        return pointer.reinterpret(StoredSize.self).advanced(by: description.payloadSizeOffset).pointee
    }

    public override var typeContextDescriptor: EnumDescriptor { super.typeContextDescriptor as! EnumDescriptor }
}

public extension EnumMetadata {
    /// Return the type of this single-payload enum, or nil if it's not single payload
    var singlePayloadType: Any.Type? {
        let descriptor = typeContextDescriptor
        if descriptor.numberOfPayloadCases != 1 {
            return nil
        }
        let type = descriptor.fields.compactMap { $0.resolveType(contextDescriptor: descriptor, genericArguments: genericArgumentsPointer) }.first
        return type
    }
}

/// Marker class; doesn't add anything to `EnumMetadata`
public class OptionalMetadata: EnumMetadata {
    public static var descriptor: EnumDescriptor = EnumDescriptor.optionalTypeDescriptor
}

/// The structure of tuple type metadata.
public class TupleTypeMetadata: Metadata {
    private struct Pointee {
        var kind: StoredPointer
        var numElements: StoredSize
        var labels: TargetPointer /* <Runtime, const char> */
    }
    private var pointee: Pointee { pointer.reinterpret(Pointee.self).pointee }

    public struct Element {
        public let pointer: RawPointer
        public struct Pointee {
            /// The type of the element.
            var type: RawPointer /* <Runtime, swift::TargetMetadata> */

            /// The offset of the tuple element within the tuple.
            #if __APPLE__
            var offset: StoredSize
            #else
            var offset: UInt32
            #endif
        }

        private var pointee: Pointee { pointer.reinterpret(Pointee.self).pointee }

        init(_ pointer: RawPointer) {
            self.pointer = pointer
        }

        public var metadata: Metadata { Metadata.from(pointee.type) }

        public var offset: Int { Int(pointee.offset) }
    }

    public var numberOfElements: Int { Int(pointee.numElements) }

    // returns space-separated list of labels
    public var labelsAsString: String? {
        guard let p = pointee.labels else { return nil }
        return String(cString: p.assumingMemoryBound(to: CChar.self))
    }

    public var labels: [String]? {
        guard let labelsAsString = labelsAsString else { return nil }
        return labelsAsString.split(separator: " ").map { String($0) }
    }

    public var elements: [Element] {
        let first = pointer.advanced(by: 1, of: TupleTypeMetadata.Pointee.self).reinterpret(TupleTypeMetadata.Element.Pointee.self)
        return (0..<numberOfElements).map { Element(first.advanced(by: $0).raw) }
    }

    public override var asAnyType: Any.Type { super.asAnyType! }
}

extension TupleTypeMetadata {
    public static var void: TupleTypeMetadata = { Metadata.of(Void.self) as! TupleTypeMetadata }()
}

/// The possible physical representations of existential types.
public enum ExistentialTypeRepresentation {
    /// The type uses an opaque existential representation.
    case opaque
    /// The type uses a class existential representation.
    case `class`
    /// The type uses the Error boxed existential representation.
    case error
}

/// The structure of existential type metadata.
public class ExistentialTypeMetadata: Metadata {
    private struct __ExistentialTypeMetadata {
        var kind: StoredPointer
        var flags: __ExistentialTypeFlags
        var numProtocols: UInt32
        // : TrailingObjects<TargetExistentialTypeMetadata<Runtime>,ConstTargetMetadataPointer<Runtime, TargetMetadata>,TargetProtocolDescriptorRef<Runtime>>
    }
    private var pointee: __ExistentialTypeMetadata { pointer.reinterpret(__ExistentialTypeMetadata.self).pointee }

    public var numberOfProtocols: Int { Int(pointee.numProtocols) }

    public var flags: ExistentialTypeFlags { ExistentialTypeFlags(data: pointee.flags) }

    public var representation: ExistentialTypeRepresentation {
        if flags.specialProtocol == .error { return .error }
        if flags.classConstraint == .class { return .class}
        return .opaque
    }

    internal var trailingObjectsBase: RawPointer { pointer.advanced(by: 1, of: __ExistentialTypeMetadata.self) }

    public var isObjC: Bool { isClassBounded && flags.numberOfWitnessTables == 0 }

    public var isClassBounded: Bool { flags.classConstraint == .class }

    public var protocols: [ProtocolDescriptor] {
        let first = trailingObjectsBase
            .advanced(by: flags.hasSuperclassConstraint ? 1 : 0, of: RawPointer.self)
            .reinterpret(StoredPointer.self)
        return (0..<Int(numberOfProtocols)).map {
            let protocolDescriptorRef = ProtocolDescriptorRef(pointer: first + $0)
            #if SWIFT_OBJC_INTEROP
            if protocolDescriptorRef.isObjC { notImplemented() }
            #endif
            return protocolDescriptorRef.swiftProtocol
        }
    }

    public var superclassConstraint: Metadata? {
        guard flags.hasSuperclassConstraint else { return nil }
        let metadataPointer = trailingObjectsBase.reinterpret(RawPointer.self).pointee
        return Metadata(metadataPointer)
    }

    public override var asAnyType: Any.Type {
        super.asAnyType!
    }
}

public extension ExistentialTypeMetadata {
    var requiresClass: Bool {
        if isClassBounded || superclassConstraint != nil {
            return true
        }
        return protocols.contains { $0.hasClassConstraint }
    }
}

public class FunctionTypeMetadata: Metadata {
    private struct Pointee {
        var kind: StoredPointer
        var flags: __TargetFunctionTypeFlags /* <StoredSize> */
        var resultType: RawPointer /* <Runtime, swift::TargetMetadata> */
    }
    private var pointee: Pointee { pointer.reinterpret(Pointee.self).pointee }

    public var flags: FunctionTypeFlags { FunctionTypeFlags(value: pointee.flags) }

    public var parameters: [Metadata] {
        let first = pointer
            .advanced(by: 1, of: Pointee.self)
            .reinterpret(RawPointer.self)
        return (0..<flags.numberOfParameters).map { Metadata.from(first.advanced(by: $0).pointee) }
    }

    public var parameterFlags: [ParameterFlags] {
        precondition(flags.hasParameterFlags)
        let first = pointer
            .advanced(by: 1, of: Pointee.self)
            .advanced(by: flags.numberOfParameters, of: RawPointer.self)
        return (0..<flags.numberOfParameters).map { ParameterFlags(first.reinterpret(UInt32.self).advanced(by: $0)) }
    }

    public var resultType: Metadata { Metadata.from(pointee.resultType)}

    override public var asAnyType: Any.Type { super.asAnyType! }
}

public class MetatypeMetadata: Metadata {
    private struct Pointee {
        var kind: StoredPointer
        var instanceType: RawPointer /* <Runtime, swift::TargetMetadata> */
    }

    private var pointee: Pointee { pointer.reinterpret(Pointee.self).pointee }

    public var instanceType: Metadata { Metadata.from(pointee.instanceType) }

    override public var asAnyType: Any.Type { super.asAnyType! }
}

/// The structure of wrapper metadata for Objective-C classes.  This is used as a type metadata pointer when the actual class isn't Swift-compiled.
public class ObjCClassWrapperMetadata: Metadata {
    private struct Pointee {
        var kind: StoredPointer
        var `class`: RawPointer /* <Runtime, TargetClassMetadata> */
    }

    private var pointee: Pointee { pointer.reinterpret(Pointee.self).pointee }

    // Note: returned `ClassMetadata` is an Obj-C class
    public var classMetadata: ClassMetadata { Metadata.from(pointee.class) as! ClassMetadata }
}

public class ExistentialMetatypeMetadata: Metadata {
    private struct Pointee {
        var kind: StoredPointer
        var instanceType: RawPointer /* <Runtime, swift::TargetMetadata> */
        var flags: __ExistentialTypeFlags
    }

    private var pointee: Pointee { pointer.reinterpret(Pointee.self).pointee }

    /// The type metadata for the element.
    public var instanceType: Metadata { Metadata.from(pointee.instanceType) }

    /// The number of witness tables and class-constrained-ness of the underlying type.
    public var flags: ExistentialTypeFlags { ExistentialTypeFlags(data: pointee.flags) }

    override public var asAnyType: Any.Type { super.asAnyType! }
}

/// The structure of metadata for heap-allocated local variables. This is non-type metadata.
public class HeapLocalVariableMetadata: Metadata {
    private struct Pointee {
        var kind: StoredPointer
        var offsetToFirstCapture: UInt32
        var captureDescription: TargetPointer /* <Runtime, const char> */
    }
    private var pointee: Pointee { pointer.reinterpret(Pointee.self).pointee }

    public var offsetToFirstCapture: Int { Int(pointee.offsetToFirstCapture) }

    public var captureDescription: String? {
        guard let p = pointee.captureDescription else { return nil }
        return String(cString: p.reinterpret(CChar.self))
    }
}

public struct ValueWitnessTable {
    private enum FlagsMasks {
        static let AlignmentMask: UInt32 = 0x000000FF
        // unused 0x0000FF00
        static let IsNonPOD: UInt32 = 0x00010000
        static let IsNonInline: UInt32 = 0x00020000
        // unused 0x00040000
        static let HasSpareBits: UInt32 = 0x00080000
        static let IsNonBitwiseTakable: UInt32 = 0x00100000
        static let HasEnumWitnesses: UInt32 = 0x00200000
        static let Incomplete: UInt32 = 0x00400000
        // unused 0xFF800000

        static let MaxNumExtraInhabitants = 0x7FFFFFFF;
    }

    public struct Pointee {
        public typealias InitializeBufferWithCopyOfBuffer = @convention(c) (RawPointer, RawPointer, RawPointer) -> RawPointer
        public typealias Destroy = @convention(c) (RawPointer, RawPointer) -> Void
        public typealias InitializeWithCopy = @convention(c) (RawPointer, RawPointer, RawPointer) -> RawPointer
        public typealias WithCopy = @convention(c) (RawPointer, RawPointer, RawPointer) -> RawPointer
        public typealias InitializeWithTake = @convention(c) (RawPointer, RawPointer, RawPointer) -> RawPointer
        public typealias AssignWithTake = @convention(c) (RawPointer, RawPointer, RawPointer) -> RawPointer
        public typealias GetEnumTagSinglePayload = @convention(c) (RawPointer, UInt, RawPointer) -> UInt
        public typealias StoreEnumTagSinglePayload = @convention(c) (RawPointer, UInt, UInt, RawPointer) -> Void
        public typealias GetEnumTag = @convention(c) (RawPointer, RawPointer) -> Int
        public typealias DestructiveProjectEnumData = @convention(c) (RawPointer, RawPointer) -> Void
        public typealias DestructiveInjectEnumTag = @convention(c) (RawPointer, UInt, RawPointer) -> Void

        public let initializeBufferWithCopyOfBuffer: InitializeBufferWithCopyOfBuffer
        public let destroy: Destroy
        public let initializeWithCopy: InitializeWithCopy
        public let assignWithCopy: WithCopy
        public let initializeWithTake: InitializeWithTake
        public let assignWithTake: AssignWithTake
        public let getEnumTagSinglePayload: GetEnumTagSinglePayload
        public let storeEnumTagSinglePayload: StoreEnumTagSinglePayload
        public let size: ValueWitnessSize
        public let stride: ValueWitnessStride
        public let flags: ValueWitnessFlags
        public let extraInhabitantCount: ValueWitnessExtraInhabitantCount
    }

    public struct EVWTPointee {
        public typealias InitializeBufferWithCopyOfBuffer = @convention(c) (RawPointer, RawPointer, RawPointer) -> RawPointer
        public typealias Destroy = @convention(c) (RawPointer, RawPointer) -> Void
        public typealias InitializeWithCopy = @convention(c) (RawPointer, RawPointer, RawPointer) -> RawPointer
        public typealias WithCopy = @convention(c) (RawPointer, RawPointer, RawPointer) -> RawPointer
        public typealias InitializeWithTake = @convention(c) (RawPointer, RawPointer, RawPointer) -> RawPointer
        public typealias AssignWithTake = @convention(c) (RawPointer, RawPointer, RawPointer) -> RawPointer
        public typealias GetEnumTagSinglePayload = @convention(c) (RawPointer, UInt, RawPointer) -> UInt
        public typealias StoreEnumTagSinglePayload = @convention(c) (RawPointer, UInt, UInt, RawPointer) -> Void
        public typealias GetEnumTag = @convention(c) (RawPointer, RawPointer) -> Int
        public typealias DestructiveProjectEnumData = @convention(c) (RawPointer, RawPointer) -> Void
        public typealias DestructiveInjectEnumTag = @convention(c) (RawPointer, UInt, RawPointer) -> Void

        public let initializeBufferWithCopyOfBuffer: InitializeBufferWithCopyOfBuffer
        public let destroy: Destroy
        public let initializeWithCopy: InitializeWithCopy
        public let assignWithCopy: WithCopy
        public let initializeWithTake: InitializeWithTake
        public let assignWithTake: AssignWithTake
        public let getEnumTagSinglePayload: GetEnumTagSinglePayload
        public let storeEnumTagSinglePayload: StoreEnumTagSinglePayload
        public let size: ValueWitnessSize
        public let stride: ValueWitnessStride
        public let flags: ValueWitnessFlags
        public let extraInhabitantCount: ValueWitnessExtraInhabitantCount
        /// This value is only valid if `hasEnumWitnesses == true`
        public let getEnumTag: GetEnumTag
        /// This value is only valid if `hasEnumWitnesses == true`
        public let destructiveProjectEnumData: DestructiveProjectEnumData
        /// This value is only valid if `hasEnumWitnesses == true`
        public let destructiveInjectEnumTagPtr: DestructiveInjectEnumTag
    }
    public let pointer: RawPointer
    public var pointee: Pointee { pointer.reinterpret(Pointee.self).pointee }
    public var evwtPointee: EVWTPointee {
        precondition(hasEnumWitnesses)
        return pointer.reinterpret(EVWTPointee.self).pointee
    }

    public let metadata: Metadata

    public var flags: ValueWitnessFlags { pointee.flags }

    /// The required alignment of the first byte of an object of this type, expressed as a mask of the low bits that must not be set in the pointer.
    /// For example, if the type needs to be 8-byte aligned, the appropriate alignment mask should be 0x7.
    public var alignmentMask: Int { Int(pointee.flags & FlagsMasks.AlignmentMask) }

    /// True if the type requires out-of-line allocation of its storage. This can be the case because the value requires more storage or if it is not bitwise takable.
    public var isValueInline: Bool { pointee.flags & FlagsMasks.IsNonInline == 0 }

    /// True if values of this type can be copied with memcpy and destroyed with a no-op.
    public var isPOD: Bool { pointee.flags & FlagsMasks.IsNonPOD == 0 }

    /// True if values of this type can be taken with memcpy. Unlike C++ 'move', 'take' is a destructive operation that invalidates the source object, so most types can be taken with a simple bitwise copy.
    /// Only types with side table references, like @weak references, or types with opaque value semantics, like imported C++ types, are not bitwise-takable.
    public var isBitwiseTakable: Bool { pointee.flags & FlagsMasks.IsNonBitwiseTakable == 0 }

    /// True if this type's binary representation is that of an enum, and the enum value witness table entries are available in this type's value witness table.
    public var hasEnumWitnesses: Bool { pointee.flags & FlagsMasks.HasEnumWitnesses != 0 }

    /// True if the type with this value-witness table is incomplete, meaning that its external layout (size, etc.) is meaningless pending completion of the metadata layout.
    public var isIncomplete: Bool { pointee.flags & FlagsMasks.Incomplete != 0 }

    /// Return the size of this type.  Unlike in C, this has not been padded up to the alignment; that value is maintained as `stride`.
    public var size: ValueWitnessSize { pointee.size }

    /// Return the stride of this type.  This is the size rounded up to be a multiple of the alignment.
    public var stride: ValueWitnessSize { pointee.stride }

    /// The number of extra inhabitants, that is, bit patterns that do not form valid values of the type, in this type's binary representation.
    public var numberOfExtraInhabitants: ValueWitnessExtraInhabitantCount { pointee.extraInhabitantCount }

    /// Given an invalid buffer, initialize it as a copy of the object in the source buffer.
    func initializeBufferWithCopyOfBuffer(dest: RawPointer, src: RawPointer) -> RawPointer {
        pointee.initializeBufferWithCopyOfBuffer(dest, src, metadata.pointer)
    }

    /// Given a valid object of this type, destroy it, leaving it as an invalid object.  This is useful when generically destroying an object which has been allocated in-line, such as an array, struct, or tuple element.
    func destroy(object: RawPointer) -> Void {
        pointee.destroy(object, metadata.pointer)
    }

    /// Given an invalid object of this type, initialize it as a copy of the source object.  Returns the dest object.
    func initializeWithCopy(dest: RawPointer, src: RawPointer) -> RawPointer {
        pointee.initializeWithCopy(dest, src, metadata.pointer)
    }

    /// Given a valid object of this type, change it to be a copy of the source object.  Returns the dest object.
    func assignWithCopy(dest: RawPointer, src: RawPointer) -> RawPointer {
        pointee.assignWithCopy(dest, src, metadata.pointer)
    }

    /// Given an invalid object of this type, initialize it by taking the value of the source object.  The source object becomes invalid.  Returns the dest object.
    func initializeWithTake(dest: RawPointer, src: RawPointer) -> RawPointer {
        pointee.initializeWithTake(dest, src, metadata.pointer)
    }

    /// Given a valid object of this type, change it to be a copy of the source object.  The source object becomes invalid.  Returns the dest object.
    func assignWithTake(dest: RawPointer, src: RawPointer) -> RawPointer {
        pointee.assignWithTake(dest, src, metadata.pointer)
    }

    /// Given an instance of valid single payload enum with a payload of this witness table's type (e.g Optional<ThisType>) , get the tag of the enum.
    func getEnumTagSinglePayload(`enum`: RawPointer, emptyCases: UInt) -> UInt {
        pointee.getEnumTagSinglePayload(`enum`, emptyCases, metadata.pointer)
    }

    /// Given uninitialized memory for an instance of a single payload enum with a payload of this witness table's type (e.g Optional<ThisType>), store the tag.
    func storeEnumTagSinglePayload(`enum`: RawPointer, whichCase: UInt, emptyCases: UInt) -> Void {
        pointee.storeEnumTagSinglePayload(`enum`, whichCase, emptyCases, metadata.pointer)
    }

    /// Given a valid object of this enum type, extracts the tag value indicating which case of the enum is inhabited. Returned values are in the range [0..NumElements-1].
    func getEnumTag(`enum`: RawPointer) -> Int {
        evwtPointee.getEnumTag(`enum`, metadata.pointer)
    }

    /// Given a valid object of this enum type, destructively extracts the associated payload.
    func destructiveProjectEnumData(obj: RawPointer) -> Void {
        evwtPointee.destructiveProjectEnumData(obj, metadata.pointer)
    }

    /// Given an enum case tag and a valid object of case's payload type, destructively inserts the tag into the payload. The given tag value must be in the range [-ElementsWithPayload..ElementsWithNoPayload-1].
    func destructiveInjectEnumTag(obj: RawPointer, tag: UInt) -> Void {
        evwtPointee.destructiveInjectEnumTagPtr(obj, tag, metadata.pointer)
    }
}

/// A reference to a protocol within the runtime, which may be either a Swift protocol or (when Objective-C interoperability is enabled) an Objective-C protocol.
///
/// This type always contains a single target pointer, whose lowest bit is used to distinguish between a Swift protocol referent and an Objective-C protocol referent.
public struct ProtocolDescriptorRef: PointeeFacade {
    public let pointer: RawPointer
    public struct Pointee {
        var storage: StoredPointer
    }

    /// A direct pointer to a protocol descriptor for either an Objective-C protocol (if the low bit is set) or a Swift protocol (if the low bit is clear).
    public var storage: StoredPointer { pointee.storage }

    var name: String {
        #if SWIFT_OBJC_INTEROP
        notImplemented()
        #endif
        return swiftProtocol.name
    }

    var dispatchStrategy: ProtocolDispatchStrategy {
        #if SWIFT_OBJC_INTEROP
        if isOjbC {
            return .objC
        }
        #endif
        return .swift
    }

    var classConstraint: ProtocolClassConstraint {
        #if SWIFT_OBJC_INTEROP
        if isOjbC {
            return .class
        }
        #endif
        return swiftProtocol.hasClassConstraint ? .class : .any
    }

    var needsWitnessTable: Bool {
        #if SWIFT_OBJC_INTEROP
        if isOjbC {
            return false
        }
        #endif
        return true
    }

    var specialProtocol: SpecialProtocol {
        #if SWIFT_OBJC_INTEROP
        if isOjbC {
            return .none
        }
        #endif
        return swiftProtocol.specialProtocol
    }

    var swiftProtocol: ProtocolDescriptor {
        let p: UInt = UInt(pointee.storage) & UInt(bitPattern: ~Int(IsObjCBit))
        return ProtocolDescriptor(RawPointer(bitPattern: p)!)
    }

    private let IsObjCBit = 1
    #if SWIFT_OBJC_INTEROP
    var isObjC: Bool { dataSectionStorage & IsObjCBit != 0 }
    #endif
}

/// A protocol requirement descriptor. This describes a single protocol requirement in a protocol descriptor. The index of the requirement in the descriptor determines the offset of the witness in a witness table for this protocol.
public struct ProtocolRequirement: PointeeFacade {
    public struct Pointee {
        var flags: __ProtocolRequirementFlags
        var defaultImplementation: TargetRelativeDirectPointer /* <void, nullable true> */
    }

    public let pointer: RawPointer

    public var kind: ProtocolRequirementKind { ProtocolRequirementKind(rawValue: pointee.flags & UInt32(ProtocolRequirementFlags.kindMask))! }

    /// Is the method an instance member? Note that 'init' is not considered an instance member.
    public var isInstance: Bool { pointee.flags & ProtocolRequirementFlags.isInstanceMask != 0 }

    /// The optional default implementation of the protocol.
    public var defaultImplementation: RawPointer? { RawPointer(relative: &typedPointer.pointee.defaultImplementation) }
}

/// A witness table for a protocol.
///
/// With the exception of the initial protocol conformance descriptor, the layout of a witness table is dependent on the protocol being represented.
public struct WitnessTable: PointeeFacade {
    public struct Pointee {
        var description: RawPointer /* <Runtime, TargetProtocolConformanceDescriptor> */
    }

    public let pointer: RawPointer

    /// The protocol conformance descriptor from which this witness table was generated.
    public var descriptor: ProtocolConformanceDescriptor {
        get { ProtocolConformanceDescriptor(pointee.description) }
        nonmutating set { pointee.description = newValue.pointer }
    }

    public var witnesses: BufferPointer<RawPointer?> { BufferPointer(start: pointer.advanced(by: 1, of: Pointee.self).reinterpret(RawPointer?.self), count: descriptor.protocol.numberOfRequirements) }
}

public extension WitnessTable {
    static func createEmpty(conformanceDescriptor: ProtocolConformanceDescriptor) -> WitnessTable {
        let numberOfRequirements = conformanceDescriptor.protocol.numberOfRequirements
        let p = RawPointer.allocateWithZeroFill(size: MemoryLayout<WitnessTable.Pointee>.size + numberOfRequirements * MemoryLayout<RawPointer>.size, alignment: MemoryLayout<WitnessTable.Pointee>.alignment)
        let ret = WitnessTable(p)
        ret.descriptor = conformanceDescriptor
        return ret
    }

    func deallocate() {
        pointer.deallocate()
    }
}

/// The control structure of a generic or resilient protocol
/// conformance, which is embedded in the protocol conformance descriptor.
///
/// Witness tables need to be instantiated at runtime in these cases:
/// - For a generic conforming type, associated type requirements might be
///   dependent on the conforming type.
/// - For a type conforming to a resilient protocol, the runtime size of
///   the witness table is not known because default requirements can be
///   added resiliently.
///
/// One per conformance.
public struct GenericWitnessTable: PointeeFacade {
    public struct Pointee {
        var witnessTableSizeInWords: UInt16
        var witnessTablePrivateSizeInWordsAndRequiresInstantiation: UInt16
        var instantiator: TargetRelativeDirectPointer /* <void(TargetWitnessTable<Runtime> *instantiatedTable, const TargetMetadata<Runtime> *type, const void * const *instantiationArgs), / *nullable* / true>*/
        /// Private data for the instantiator.  Out-of-line so that the rest of this structure can be constant.
        var privateData: TargetRelativeDirectPointer /* <PrivateDataType> */
    }

    public let pointer: RawPointer

    /// The size of the witness table in words.  This amount is copied from the witness table template into the instantiated witness table.
    public var witnessTableSizeInWords: Int { Int(pointee.witnessTableSizeInWords) }

    /// The amount of private storage to allocate before the address point, in words. This memory is zeroed out in the instantiated witness table template.
    ///
    /// The low bit is used to indicate whether this witness table is known to require instantiation.
    public var witnessTablePrivateSizeInWords: Int { Int(pointee.witnessTablePrivateSizeInWordsAndRequiresInstantiation >> 1) }

    public var requiresInstantiation: Bool { pointee.witnessTablePrivateSizeInWordsAndRequiresInstantiation & 1 != 0 }

    /// The instantiation function, which is called after the template is copied.
    public var instantiator: RawPointer? { RawPointer(relative: &pointee.instantiator) }

    /// Private data for the instantiator.  Out-of-line so that the rest of this structure can be constant.
    public var privateData: BufferPointer<UInt>? {
        guard let p = RawPointer(relative: &typedPointer.pointee.privateData) else { return nil }
        return BufferPointer(start: p.reinterpret(UInt.self), count: Int(16 /* __NumGenericMetadataPrivateDataWords */))
    }
}

/// The control structure of a generic or resilient protocol
/// conformance witness.
///
/// Resilient conformances must use a pattern where new requirements
/// with default implementations can be added and the order of existing
/// requirements can be changed.
///
/// This is accomplished by emitting an order-independent series of
/// relative pointer pairs, consisting of a protocol requirement together
/// with a witness. The requirement is identified by an indirectable relative
/// pointer to the protocol requirement descriptor.
public struct ResilientWitness: PointeeFacade {
    public struct Pointee {
        var requirement: TargetRelativeIndirectablePointer /* <TargetProtocolRequirement<Runtime>> */
        var witness: TargetRelativeDirectPointer /* <void> */
    }

    public let pointer: RawPointer

    public var requirement: ProtocolRequirement { ProtocolRequirement(RawPointer(relative: &typedPointer.pointee.requirement)!) }

    public var witness: RawPointer { RawPointer(relative: &typedPointer.pointee.witness)! }
}

/// A reference to a type.
/// ```
///struct TypeReference {
///    union {
///        /// A direct reference to a TypeContextDescriptor or ProtocolDescriptor.
///        TargetRelativeDirectPointer /* <TargetContextDescriptor<Runtime>> */ DirectTypeDescriptor;
///
///        /// An indirect reference to a TypeContextDescriptor or ProtocolDescriptor.
///        TargetRelativeDirectPointer /* <ConstTargetMetadataPointer<Runtime, TargetContextDescriptor>> */ IndirectTypeDescriptor;
///
///        /// An indirect reference to an Objective-C class.
///        TargetRelativeDirectPointer /*<ConstTargetMetadataPointer<Runtime, TargetClassMetadata>> */ IndirectObjCClass;
///
///        /// A direct reference to an Objective-C class name.
///        TargetRelativeDirectPointer /*<const char> */ DirectObjCClassName;
///    };
///};
///```
typealias __TypeReference = TargetRelativeDirectPointer

/// The structure of a protocol conformance. This contains enough static information to recover the witness table for a type's conformance to a protocol.
public struct ProtocolConformanceDescriptor: PointeeFacade {
    public struct Pointee {
        var protocolPtr: TargetRelativeIndirectablePointer /* <ProtocolDescriptor> */
        var typeRef: __TypeReference
        var witnessTablePattern: TargetRelativeDirectPointer /*<const TargetWitnessTable<Runtime>, nullable true> */
        var flags: __ConformanceFlags
        // : TrailingObjects<
        //      TargetProtocolConformanceDescriptor<Runtime>,
        //      RelativeContextPointer<Runtime>,
        //      TargetGenericRequirementDescriptor<Runtime>,
        //      TargetResilientWitnessesHeader<Runtime>,
        //      TargetResilientWitness<Runtime>,
        //      TargetGenericWitnessTable<Runtime>>
    }
    public let pointer: RawPointer

    /// The protocol being conformed to.
    public var `protocol`: ProtocolDescriptor { ProtocolDescriptor(RawPointer(relative: &typedPointer.pointee.protocolPtr)!) }

    // Reference to the type that conforms to the protocol.
    public var typeReference: TypeReference {
        // note: due to the way union'ised struct fields are imported, the shortcut notation of &typedPointer.pointee.Something does not work for those fields; hence calculating absolute pointers manually
        let relativePointer = (pointer + MemoryLayout<ProtocolConformanceDescriptor.Pointee>.offset(of: \ProtocolConformanceDescriptor.Pointee.typeRef)!).reinterpret(TargetRelativeDirectPointer.self) // it's the same for all cases
        guard let resolvedPointer = RawPointer(relative: relativePointer) else { fatalError("Relative pointer resolved to nil for \(flags.typeReferenceKind)") }
        switch flags.typeReferenceKind {
        case .directTypeDescriptor:
            return .typeDescriptor(ContextDescriptor.from(resolvedPointer))
        case .indirectTypeDescriptor:
            return .typeDescriptor(ContextDescriptor.from(resolvedPointer.reinterpret(RawPointer.self).pointee))
        case .directObjCClassName:
            return .objCClassName(String(cString: resolvedPointer.reinterpret(CChar.self)))
        case .indirectObjCClass:
            return .objCClass(Metadata(resolvedPointer.reinterpret(RawPointer.self).pointee))
        }
    }

    /// The witness table pattern, which may also serve as the witness table.
    public var witnessTablePattern: WitnessTable? {
        let p = RawPointer(relative: &typedPointer.pointee.witnessTablePattern)
        return WitnessTable(p)
    }

    /// Various flags, including the kind of conformance.
    public var flags: ConformanceFlags { ConformanceFlags(&typedPointer.pointee.flags) }

    internal var trailingObjectsBase: RawPointer { pointer.advanced(by: 1, of: Pointee.self) }

    public var retroactiveContext: ContextDescriptor? {
        guard flags.isRetroactive else { return nil }
        return ContextDescriptor.from(RawPointer(relative: trailingObjectsBase.reinterpret(TargetRelativeIndirectablePointer.self))!)
    }

    public var genericRequirements: [GenericRequirementDescriptor] {
        guard flags.numberOfConditionalRequirements > 0 else { return [] }
        let first = trailingObjectsBase
            .advanced(by: flags.isRetroactive ? 1 : 0, of: TargetRelativeIndirectablePointer.self)
            .reinterpret(GenericRequirementDescriptor.Pointee.self)
        return (0..<flags.numberOfConditionalRequirements).map { GenericRequirementDescriptor((first + $0).raw) }
    }

    public var numberOfWitnesses: Int {
        guard flags.hasResilientWitnesses else { return 0 }
        let p = trailingObjectsBase
            .advanced(by: flags.isRetroactive ? 1 : 0, of: TargetRelativeIndirectablePointer.self)
            .advanced(by: flags.numberOfConditionalRequirements, of: GenericRequirementDescriptor.Pointee.self)
            .reinterpret(__ResilientWitnessesHeader.self)
        return Int(p.pointee.numWitnesses)
    }

    public var resilientWitnesses: [ResilientWitness] {
        guard flags.hasResilientWitnesses else { return [] }
        let first = trailingObjectsBase
            .advanced(by: flags.isRetroactive ? 1 : 0, of: TargetRelativeIndirectablePointer.self)
            .advanced(by: flags.numberOfConditionalRequirements, of: GenericRequirementDescriptor.Pointee.self)
            .advanced(by: flags.hasResilientWitnesses ? 1 : 0, of: __ResilientWitnessesHeader.self)
            .reinterpret(ResilientWitness.Pointee.self)
        return (0..<numberOfWitnesses).map { ResilientWitness((first + $0).raw) }
    }

    public var genericWitnessTable: GenericWitnessTable? {
        guard flags.hasGenericWitnessTable else { return nil }
        let p = trailingObjectsBase
            .advanced(by: flags.isRetroactive ? 1 : 0, of: TargetRelativeIndirectablePointer.self)
            .advanced(by: flags.numberOfConditionalRequirements, of: GenericRequirementDescriptor.Pointee.self)
            .advanced(by: flags.hasResilientWitnesses ? 1 : 0, of: __ResilientWitnessesHeader.self)
            .advanced(by: numberOfWitnesses, of: ResilientWitness.Pointee.self)
        return GenericWitnessTable(p)
    }
}

public typealias ProtocolConformanceRecord = TargetRelativeDirectPointer
public typealias ProtocolRecord = RelativeIndirectablePointerIntPair

public enum TypeReference {
    case typeDescriptor(ContextDescriptor) // both direct and indirect, because client code doesn't care
    case objCClassName(String)
    case objCClass(Metadata)
}

struct TypeMetadataRecord: PointeeFacade {
    internal struct Pointee {
        //union {
        //    /// A direct reference to a nominal type descriptor.
        //    RelativeDirectPointerIntPair /*<TargetContextDescriptor<Runtime>, TypeReferenceKind> */ DirectNominalTypeDescriptor;
        //    /// An indirect reference to a nominal type descriptor.
        //    RelativeDirectPointerIntPair /* <TargetContextDescriptor<Runtime> * const, TypeReferenceKind> */ IndirectNominalTypeDescriptor;
        //};
        var maybeIndirectNominalTypeDescriptor: RelativeDirectPointerIntPair
    }
    let pointer: RawPointer

    var contextDescriptor: ContextDescriptor {
        let clean = pointee.maybeIndirectNominalTypeDescriptor.RelativeOffsetPlusInt & ~1
        let isIndirect = pointee.maybeIndirectNominalTypeDescriptor.RelativeOffsetPlusInt & 1 != 0
        var resolved = pointer.advanced(by: clean)
        if isIndirect {
            resolved = resolved.reinterpret(RawPointer.self).pointee
        }
        let ret = ContextDescriptor.from(resolved)
        return ret
    }
}

/// Header containing information about the resilient witnesses in a protocol conformance descriptor.
struct __ResilientWitnessesHeader {
    var numWitnesses: UInt32
}

private extension AnyClassMetadata {
    func checkIsTypeMetadata<T>(_ value: T) -> T {
        precondition(isTypeMetadata)
        return value
    }
}

// MARK: -

/// A fixed-size buffer for local values.  It is capable of owning
/// (possibly in side-allocated memory) the storage necessary
/// to hold a value of an arbitrary type.  Because it is fixed-size,
/// it can be allocated in places that must be agnostic to the
/// actual type: for example, within objects of existential type,
/// or for local variables in generic functions.
///
/// The context dictates its type, which ultimately means providing
/// access to a value witness table by which the value can be
/// accessed and manipulated.
///
/// A buffer can directly store three pointers and is pointer-aligned.
/// Three pointers is a sweet spot for Swift, because it means we can
/// store a structure containing a pointer, a size, and an owning
/// object, which is a common pattern in code due to ARC.  In a GC
/// environment, this could be reduced to two pointers without much loss.
///
/// A buffer can be in one of three states:
///  - An unallocated buffer has a completely unspecified state.
///  - An allocated buffer has been initialized so that it
///    owns uninitialized value storage for the stored type.
///  - An initialized buffer is an allocated buffer whose value
///    storage has been initialized.
public struct ValueBuffer: PointeeFacade {
    public struct Pointee {
        // NumWords_ValueBuffer
        let word0: UInt
        let word1: UInt
        let word2: UInt
    }
    public let pointer: RawPointer

    public var asRawPointers: BufferPointer<RawPointer> { BufferPointer(start: pointer.reinterpret(RawPointer.self), count: NumWords_ValueBuffer) }

    public var asInts: BufferPointer<Int> { BufferPointer(start: pointer.reinterpret(Int.self), count: NumWords_ValueBuffer) }

    public static func canBeInline(isBitwiseTakable: Bool, size: Int, alignment: Int) -> Bool { isBitwiseTakable && size <= MemoryLayout<ValueBuffer>.size &&
        alignment <= MemoryLayout<ValueBuffer>.alignment }
}
public typealias ValueBufferPointer = RawPointer // cannot use Pointer<ValueBuffer.Pointee> because value witness functions are declared as @convention(c)
public typealias ConstValueBufferPointer = RawPointer // cannot use Pointer<ValueBuffer.Pointee> because value witness functions are declared as @convention(c)

// use allocateValueBuffer with it
