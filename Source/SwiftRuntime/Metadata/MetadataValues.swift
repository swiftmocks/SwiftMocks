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

let maximumAlignment = 16
/// The number of words (pointers) in a value buffer.
let NumWords_ValueBuffer = 3
/// The number of words in a metadata completion context.
let NumWords_MetadataCompletionContext = 4
  /// The number of words in a yield-once coroutine buffer.
let NumWords_YieldOnceBuffer = 4
/// The number of words in a yield-many coroutine buffer.
let NumWords_YieldManyBuffer = 8
/// Number of words reserved in generic metadata patterns.
let NumGenericMetadataPrivateDataWords = 16


/// The number of arguments that will be passed directly to a generic nominal type access function. The remaining arguments (if any) will be passed as an array.
/// That array has enough storage for all of the arguments, but only fills in the elements not passed directly. The callee may mutate the array to fill in the direct arguments.
let NumDirectGenericTypeMetadataAccessFunctionArgs: UInt = 3

/// The offset (in pointers) to the first requirement in a witness table.
let WitnessTableFirstRequirementOffset: UInt = 1

public enum MetadataKind: UInt32 {
    /// A class type.
    case `class` = 0

    /// A struct type.
    case `struct`                   = 0x200 // 0 | MetadataKindIsNonHeap

    /// An enum type.
    /// If we add reference enums, that needs to go here.
    case `enum`                     = 0x201 // 1 | MetadataKindIsNonHeap

    /// An optional type.
    case optional                   = 0x202 // 2 | MetadataKindIsNonHeap

    /// A foreign class, such as a Core Foundation class.
    case foreignClass               = 0x203 // 3 | MetadataKindIsNonHeap

    /// A type whose value is not exposed in the metadata system.
    case opaque                     = 0x300 // 0 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap

    /// A tuple.
    case tuple                      = 0x301 // 1 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap

    /// A monomorphic function.
    case function                   = 0x302 // 2 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap

    /// An existential type.
    case existential                = 0x303 // 3 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap

    /// A metatype.
    case metatype                   = 0x304 // 4 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap

    /// An ObjC class wrapper.
    case objCClassWrapper           = 0x305 // 5 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap

    /// An existential metatype.
    case existentialMetatype        = 0x306 // 6 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap

    /// A heap-allocated local variable using statically-generated metadata.
    case heapLocalVariable          = 0x400 // 0 | MetadataKindIsNonType

    /// A heap-allocated local variable using runtime-instantiated metadata.
    case heapGenericLocalVariable   = 0x500 // 0 | MetadataKindIsNonType | MetadataKindIsRuntimePrivate

    /// A native error object.
    case errorObject                = 0x501 // 1 | MetadataKindIsNonType | MetadataKindIsRuntimePrivate

    public static let lastEnumerated = 0x7FF

    public static let isNonType = 0x400
    public static let isNonHeap = 0x200
    // The above two flags are negative because the "class" kind has to be zero, and class metadata is both type and heap metadata.

    /// Runtime-private metadata has this bit set. The compiler must not statically generate metadata objects with these kinds, and external tools should not rely on the stability of these values or the precise binary layout of their associated data structures.
    public static let isRuntimePrivate = 0x100
}

/// Swift class flags. These flags are valid only when isTypeMetadata(). When !isTypeMetadata() these flags will collide with other Swift ABIs.
public struct ClassFlags: OptionSet {
    public let rawValue: UInt32

    public init(rawValue: UInt32) { self.rawValue = rawValue}

    /// Is this a Swift class from the Darwin pre-stable ABI? This bit is clear in stable ABI Swift classes. The Objective-C runtime also reads this bit.
    public static let isSwiftPreStableABI = ClassFlags(rawValue: 0x1)

    /// Does this class use Swift refcounting?
    public static let usesSwiftRefcounting = ClassFlags(rawValue: 0x2)

    /// Has this class a custom name, specified with the @objc attribute?
    public static let hasCustomObjCName = ClassFlags(rawValue: 0x4)
}

public enum MethodDescriptorKind: UInt32 {
    case method = 0
    case `init`
    case getter
    case setter
    case modifyCoroutine
    case readCoroutine
}

enum MethodDescriptorFlags {
    static let kindMask: UInt32 = 0x0F
    static let isInstanceMask: UInt32 = 0x10
    static let isDynamicMask: UInt32 = 0x20
}

public enum ProtocolDispatchStrategy: UInt8 {
    /// Uses ObjC method dispatch. This must be 0 for ABI compatibility with Objective-C protocol_t records.
    case objC
    /// Uses Swift protocol witness table dispatch. To invoke methods of this protocol, a pointer to a protocol witness table corresponding to the protocol conformance must be available.
    case swift
}

public enum ProtocolClassConstraint {
    /// The protocol is class-constrained, so only class types can conform to it.
    case `class`
    /// Any type can conform to the protocol.
    case any
}

/// Identifiers for protocols with special meaning to the Swift runtime.
public enum SpecialProtocol: UInt8 {
    /// Not a special protocol.
    case none = 0
    /// The Error protocol.
    case error
}

public struct ExistentialTypeFlags {
    public let data: UInt32

    public var numberOfWitnessTables: UInt { UInt(data & ExistentialTypeFlags.numWitnessTablesMask) }

    public var classConstraint: ProtocolClassConstraint {
        // For ABI compatibility with Objective-C protocol_t records, `class`-constrained protocol must be 0
        data & ExistentialTypeFlags.classConstraintMask == 0 ? .`class` : .any
    }

    public var hasSuperclassConstraint: Bool { data & ExistentialTypeFlags.hasSuperclassMask != 0 }

    /// Return whether this existential type represents an uncomposed special protocol.
    public var specialProtocol: SpecialProtocol {
        let specialProtocol: UInt8 = UInt8((data & ExistentialTypeFlags.specialProtocolMask) >> ExistentialTypeFlags.specialProtocolShift)
        return SpecialProtocol(rawValue: specialProtocol)!
    }

    private static let numWitnessTablesMask: UInt32 = 0x00FFFFFF
    private static let classConstraintMask: UInt32 = 0x80000000
    private static let hasSuperclassMask: UInt32 = 0x40000000
    private static let specialProtocolMask: UInt32 = 0x3F000000
    private static let specialProtocolShift: UInt32 = 24
}

public enum ContextDescriptorKind: UInt8 {
    /// This context descriptor represents a module.
    case module = 0

    /// This context descriptor represents an extension.
    case `extension` = 1

    /// This context descriptor represents an anonymous possibly-generic context such as a function body.
    case anonymous = 2

    /// This context descriptor represents a protocol context.
    case `protocol` = 3

    /// This context descriptor represents an opaque type alias.
    case opaqueType = 4

    /// This context descriptor represents a class.
    case `class` = 16 /* typeFirst + 0 */

    /// This context descriptor represents a struct.
    case `struct` = 17 /* typeFirst + 1 */

    /// This context descriptor represents an enum.
    case `enum` = 18 /* typeFirst + 2 */

    /// First kind that represents a type of any sort.
    private static let typeFirst = 16

    /// Last kind that represents a type of any sort.
    private static let typeLast = 31
}

/// Flags for nominal type context descriptors. These values are used as the `kindSpecificFlags` of the `ContextDescriptorFlags` for the type.
public enum TypeContextDescriptorFlags {
    // All of these values are bit offsets or widths. Generic flags build upwards from 0. Type-specific flags build downwards from 15.

    /// Whether there's something unusual about how the metadata is
    /// initialized. Meaningful for all type-descriptor kinds.
    public static let metadataInitialization: UInt16 = 0
    public static let metadataInitialization_width: UInt16 = 16

    /// Set if the type has extended import information.
    ///
    /// If true, a sequence of strings follow the null terminator in the descriptor, terminated by an empty string (i.e. by two null
    /// terminators in a row).  See TypeImportInfo for the details of these strings and the order in which they appear.
    ///
    /// Meaningful for all type-descriptor kinds.
    public static let hasImportInfo: UInt16 = 2

    // Type-specific flags:
    /// The kind of reference that this class makes to its resilient superclass descriptor.  A TypeReferenceKind.
    ///
    /// Only meaningful for class descriptors.
    public static let class_ResilientSuperclassReferenceKind: UInt16 = 9
    public static let class_ResilientSuperclassReferenceKind_width: UInt16 = 3

    /// Whether the immediate class members in this metadata are allocated at negative offsets.  For now, we don't use this.
    public static let class_AreImmediateMembersNegative: UInt16 = 12

    /// Set if the context descriptor is for a class with resilient ancestry.
    ///
    /// Only meaningful for class descriptors.
    public static let class_HasResilientSuperclass: UInt16 = 13

    /// Set if the context descriptor includes metadata for dynamically installing method overrides at metadata instantiation time.
    public static let class_HasOverrideTable: UInt16 = 14

    /// Set if the context descriptor includes metadata for dynamically constructing a class's vtables at metadata instantiation time.
    ///
    /// Only meaningful for class descriptors.
    public static let class_HasVTable: UInt16 = 15
}

public enum MetadataInitializationKind: Int {
    /// There are either no special rules for initializing the metadata or the metadata is generic.  (Genericity is set in the non-kind-specific descriptor flags.)
    case noMetadataInitialization

    /// The type requires non-trivial singleton initialization using the "in-place" code pattern.
    case singletonMetadataInitialization

    /// The type requires non-trivial singleton initialization using the "foreign" code pattern.
    case foreignMetadataInitialization

    // We only have two bits here, so if you add a third special kind,
    // include more flag bits in its out-of-line storage.
}

/// Extra flags for resilient classes, since we need more than 16 bits of flags there.
public enum ExtraClassDescriptorFlags {
    /// Set if the context descriptor includes a pointer to an Objective-C resilient class stub structure. See the description of TargetObjCResilientClassStubInfo in Metadata.h for details.
    ///
    /// Only meaningful for class descriptors when Objective-C interop is enabled.
    public static let hasObjCResilientClassStub: UInt32 = 0
}

/// Flags for anonymous type context descriptors. These values are used as the `kindSpecificFlags` of the `ContextDescriptorFlags` for the anonymous context.
public enum AnonymousContextDescriptorFlags {
    public static let hasMangledName: UInt32 = 0
}

public enum GenericParamKind {
    case type

    static let max = 0x3F
}

public struct GenericParamDescriptor {
    private let value: __GenericParamDescriptor
    init(_ value: __GenericParamDescriptor) {
        self.value = value
    }

    public var hasKeyArgument: Bool { value & 0x80 != 0 }
    public var hasExtraArgument: Bool { value & 0x40 != 0 }
    public var kind: GenericParamKind {
        switch value & 0x3F {
        case 0: return .type
        default: fatalError("Unknown GenericParamKind: \(value & 0x3F)")
        }
    }
}

public enum GenericRequirementKind {
    /// A protocol requirement.
    case `protocol`(ProtocolDescriptor? /* if nil, it's objc */) /* = 0 */
    /// A same-type requirement.
    case sameType(Pointer<CChar>) /* = 1 */
    /// A base class requirement.
    case baseClass(Pointer<CChar>) /* = 2 */
    /// A "same-conformance" requirement, implied by a same-type or base-class constraint that binds a parameter with protocol requirements.
    // case sameConformance /* = 3 */ /* currently not generated by the compiler */
    /// A layout constraint.
    case layout(GenericRequirementLayoutKind) /* = 0x1F */
}

public enum GenericRequirementLayoutKind: UInt32 {
    case `class` = 0 // GenericRequirementLayoutKindClass

    case _unknown = 0xFFFFFFFF // this is actually never used, but with just one case, automatically generated debug description is empty
}

public enum ProtocolRequirementKind: UInt32 {
    case baseProtocol
    case method
    case `init`
    case getter
    case setter
    case readCoroutine
    case modifyCoroutine
    case associatedTypeAccessFunction
    case associatedConformanceAccessFunction
}

// just a holder for constants, not a reimplementation
internal enum ProtocolRequirementFlags {
    static let kindMask: UInt32 = 0x0F // 16 kinds should be enough for anybody
    static let isInstanceMask: UInt32 = 0x10

    /// Bit used to indicate that an associated type witness is a pointer to a mangled name (vs. a pointer to metadata).
    static let associatedTypeMangledNameBit: UInt32 = 0x01

    /// Prefix byte used to identify an associated type whose mangled name is relative to the protocol's context rather than the conforming type's context.
    static let associatedTypeInProtocolContextByte: UInt32 = 0xFF
}

public enum ProtocolContextDescriptorFlags {
    public static let hasClassConstraint: UInt16 = 0
    public static let hasClassConstraint_width: UInt16 = 1
    public static let isResilient: UInt16 = 1
    public static let specialProtocolKind: UInt16 = 2
    public static let specialProtocolKind_width: UInt16 = 6
}

/// Kinds of type metadata/protocol conformance records.
public enum TypeReferenceKind: UInt {
    /// The conformance is for a nominal type referenced directly; getTypeDescriptor() points to the type context descriptor.
    case directTypeDescriptor = 0x00

    /// The conformance is for a nominal type referenced indirectly; getTypeDescriptor() points to the type context descriptor.
    case indirectTypeDescriptor = 0x01

    /// The conformance is for an Objective-C class that should be looked up by class name.
    case directObjCClassName = 0x02

    /// The conformance is for an Objective-C class that has no nominal type descriptor. getIndirectObjCClass() points to a variable that contains the pointer to the class object, which then requires a runtime call to get metadata.
    ///
    /// On platforms without Objective-C interoperability, this case is unused.
    case indirectObjCClass = 0x03

    // We only reserve three bits for this in the various places we store it.

    public static let firstKind = TypeReferenceKind.directTypeDescriptor.rawValue
    public static let lastKind = TypeReferenceKind.indirectObjCClass.rawValue
}

public enum FunctionMetadataConvention: UInt8 {
    case swift = 0
    case block = 1
    case thin = 2
    case cFunctionPointer = 3
}

public struct FunctionTypeFlags {
    private(set) public var value: StoredSize

    public init(value: StoredSize = 0) {
        self.value = value
    }

    public var numberOfParameters: Int {
        get {
            Int(value & C.numParametersMask)
        }
        set {
            value = (value & ~C.numParametersMask) | StoredSize(newValue)
        }
    }

    public var convention: FunctionMetadataConvention {
        get {
            FunctionMetadataConvention(rawValue: UInt8((value & C.conventionMask) >> C.conventionShift))!
        }
        set {
            value = (value & ~C.conventionMask) | (StoredSize(newValue.rawValue) << C.conventionShift)
        }
    }

    public var `throws`: Bool {
        get {
            value & C.throwsMask != 0
        }
        set {
            value = (value & ~C.throwsMask) | (newValue ? C.throwsMask : 0)
        }
    }

    public var isEscaping: Bool {
        get {
            value & C.escapingMask != 0
        }
        set {
            value = (value & ~C.escapingMask) | (newValue ? C.escapingMask : 0)
        }
    }

    public var hasParameterFlags: Bool { value & C.paramFlagsMask != 0 }

    private enum C { // putting the constants inside an enum to reduce visual noise in getters and setters
        static let numParametersMask: StoredSize = 0x0000FFFF
        static let conventionMask: StoredSize    = 0x00FF0000
        static let conventionShift: StoredSize   = 16
        static let throwsMask: StoredSize        = 0x01000000
        static let paramFlagsMask: StoredSize    = 0x02000000
        static let escapingMask: StoredSize      = 0x04000000
    }
}

public struct ParameterFlags: PointeeFacade {
    typealias Pointee = UInt32
    public let pointer: RawPointer

    public var ownership: ValueOwnership { ValueOwnership(rawValue: UInt8(pointee & C.valueOwnershipMask))! }

    public var isVariadic: Bool { pointee & C.variadicMask != 0 }

    public var isAutoclosure: Bool { pointee & C.autoClosureMask != 0 }

    private enum C { // putting the constants inside an enum to reduce visual noise in getters and setters
        static let valueOwnershipMask: UInt32   = 0x7F
        static let variadicMask: UInt32         = 0x80
        static let autoClosureMask: UInt32      = 0x100
    }
}

/// Flags that go in a ConformanceDescriptor
public struct ConformanceFlags: PointeeFacade {
    typealias Pointee = UInt32
    let pointer: RawPointer

    public var typeReferenceKind: TypeReferenceKind {
        get { TypeReferenceKind(rawValue: UInt((pointee & C.TypeMetadataKindMask) >> C.TypeMetadataKindShift))! }
        nonmutating set { pointee = (pointee & ~C.TypeMetadataKindMask) | (UInt32(newValue.rawValue) << C.TypeMetadataKindShift) }
    }

    /// Is the conformance "retroactive"?
    ///
    /// A conformance is retroactive when it occurs in a module that is neither the module in which the protocol is defined nor the module in which the conforming type is defined. With retroactive conformance, it is possible to detect a conflict at run time.
    public var isRetroactive: Bool {
        get { pointee & C.IsRetroactiveMask != 0 }
        nonmutating set { pointee = (pointee & ~C.IsRetroactiveMask) | (newValue ? C.IsRetroactiveMask : 0) }
    }

    /// Is the conformance synthesized in a non-unique manner?
    ///
    /// The Swift compiler will synthesize conformances on behalf of some imported entities (e.g., C typedefs with the swift_wrapper attribute). Such conformances are retroactive by nature, but the presence of multiple such conformances is not a conflict because all synthesized conformances will be equivalent.
    public var isSynthesizedNonUnique: Bool {
        get { pointee & C.IsSynthesizedNonUniqueMask != 0 }
        nonmutating set { pointee = (pointee & ~C.IsSynthesizedNonUniqueMask) | (newValue ? C.IsSynthesizedNonUniqueMask : 0)}
    }

    public var numberOfConditionalRequirements: Int {
        get { Int((pointee & C.NumConditionalRequirementsMask) >> C.NumConditionalRequirementsShift) }
        nonmutating set { pointee = (pointee & ~C.NumConditionalRequirementsMask) | (UInt32(newValue) << C.NumConditionalRequirementsShift) }
    }

    public var hasResilientWitnesses: Bool {
        get { pointee & C.HasResilientWitnessesMask != 0 }
        nonmutating set { pointee = (pointee & ~C.HasResilientWitnessesMask) | (newValue ? C.HasResilientWitnessesMask : 0) }
    }

    /// Whether this conformance has a generic witness table that may need to be instantiated.
    /// Note: the only situation where I've seen this being true is for retroactive conformances to resilient interfaces (see tests).
    public var hasGenericWitnessTable: Bool {
        get { pointee & C.HasGenericWitnessTableMask != 0 }
        nonmutating set { pointee = (pointee & ~C.HasGenericWitnessTableMask) | (newValue ? C.HasGenericWitnessTableMask : 0) }
    }

    private enum C { // putting the constants inside an enum to reduce visual noise in getters and setters
        static let UnusedLowBits: UInt32 = 0x07      // historical conformance kind

        static let TypeMetadataKindMask: UInt32 = 0x7 << 3 // 8 type reference kinds
        static let TypeMetadataKindShift: UInt32 = 3

        static let IsRetroactiveMask: UInt32 = 0x01 << 6
        static let IsSynthesizedNonUniqueMask: UInt32 = 0x01 << 7

        static let NumConditionalRequirementsMask: UInt32 = 0xFF << 8
        static let NumConditionalRequirementsShift: UInt32 = 8

        static let HasResilientWitnessesMask: UInt32 = 0x01 << 16
        static let HasGenericWitnessTableMask: UInt32 = 0x01 << 17
    }
}

/// The public state of a metadata.
public enum MetadataState: size_t {
    // The values of this enum are set up to give us some future flexibility
    // in adding states.  The compiler emits unsigned comparisons against
    // these values, so adding states that aren't totally ordered with at
    // least the existing values will pose a problem; but we also use a
    // gradually-shrinking bitset in case it's useful to track states as
    // separate capabilities.  Specific values have been chosen so that a
    // MetadataRequest of 0 represents a blocking complete request, which
    // is the most likely request from ordinary code.  The total size of a
    // state is kept to 8 bits so that a full request, even with additional
    // flags, can be materialized as a single immediate on common ISAs, and
    // so that the state can be extracted with a byte truncation.
    // The spacing between states reflects guesswork about where new
    // states/capabilities are most likely to be added.

    /// The metadata is fully complete.  By definition, this is the end-state of all metadata.  Generally, metadata is expected to be complete before it can be passed to arbitrary code, e.g. as a generic argument to a function or as a metatype value.
    ///
    /// In addition to the requirements of NonTransitiveComplete, certain transitive completeness guarantees must hold.  Most importantly, complete nominal type metadata transitively guarantee the completion of their stored generic type arguments and superclass metadata.
    case metadataStateComplete = 0x00

    /// The metadata is fully complete except for any transitive completeness guarantees.
    ///
    /// In addition to the requirements of LayoutComplete, metadata in this state must be prepared for all basic type operations.  This includes:
    ///   - any sort of internal layout necessary to allocate and work  with concrete values of the type, such as the instance layout
    ///     of a class;
    ///   - any sort of external dynamic registration that might be required for the type, such as the realization of a class by the Objective-C runtime; and
    ///   - the initialization of any other information kept in the metadata object, such as a class's v-table.
    case metadataStateNonTransitiveComplete = 0x01

    /// The metadata is ready for the layout of other types that store values of this type.
    ///
    /// In addition to the requirements of Abstract, metadata in this state must have a valid value witness table, meaning that its size, alignment, and basic type properties (such as POD-ness) have been computed.
    case metadataStateLayoutComplete = 0x3F

    /// The metadata has its basic identity established.  It is possible to determine what formal type it corresponds to.  Among other things, it is possible to use the runtime mangling facilities with the type.
    ///
    /// For example, a metadata for a generic struct has a metadata kind, a type descriptor, and all of its type arguments.  However, it does not necessarily have a meaningful value-witness table.
    ///
    /// References to other types that are not part of the type's basic identity may not yet have been established.  Most crucially, this includes the superclass pointer.
    case metadataStateAbstract = 0xFF
}

public struct MetadataRequest {
    public let value: size_t

    /// Create a blocking request for complete metadata
    public static var completeBlocking: MetadataRequest {
        MetadataRequest(value: 0)
    }

    private enum C {
        static let state_bit: size_t         = 0
        static let state_width: size_t       = 8
        /// A blocking request will not return until the runtime is able to produce metadata with the given kind.  A non-blocking request will return "immediately", producing an abstract metadata and a flag saying that the operation failed.
        ///
        /// An abstract request will never be non-zero.
        static let nonBlocking_bit: size_t   = 8
    }
}

/// The result of requesting type metadata. Generally the return value of a function.
///
/// For performance and ABI matching across Swift/C++, functions returning this type must use `SWIFT_CC` so that the components are returned as separate values.
public struct MetadataResponse {
    /// The requested metadata.
    let value: RawPointer

    /// The current state of the metadata returned.  Always use this instead of trying to inspect the metadata directly to see if it satisfies the request.  An incomplete metadata may be getting initialized concurrently.  But this can generally be ignored if the metadata request was for abstract metadata or if the request is blocking.
    let state: MetadataState
}

public struct TupleTypeFlags {
    public let value: size_t

    public init(value: size_t) {
        self.value = value
    }

    public static func with(numberOfElements: Int) -> TupleTypeFlags {
        TupleTypeFlags(value: size_t(numberOfElements) & C.NumElementsMask)
    }

    private enum C {
        static let NumElementsMask: size_t = 0x0000FFFF
        static let NonConstantLabelsMask: size_t = 0x00010000
    }
}

typealias __GenericParamDescriptor = UInt8
typealias __GenericRequirementFlags = UInt32
typealias __GenericRequirementLayoutKind = UInt32
typealias __NominalTypeKind = UInt32
typealias __ClassFlags = UInt32
typealias __MethodDescriptorFlags = UInt32
typealias __ProtocolRequirementFlags = UInt32
typealias __ExistentialTypeFlags = UInt32
typealias __ContextDescriptorKind = UInt8
typealias __ContextDescriptorFlags = UInt32
typealias __GenericParamKind = UInt8
typealias __TypeReferenceKind = UInt32
typealias __TargetFunctionTypeFlags = StoredSize
typealias __TargetParameterTypeFlags = UInt32
typealias __TypeContextDescriptorFlags = UInt16
typealias __ExtraClassDescriptorFlags = UInt32
typealias __GenericMetadataPatternFlags = UInt32
typealias __ConformanceFlags = UInt32
typealias __GenericEnvironmentFlags = UInt32
typealias __MetadataKind = UInt32

public typealias StoredPointer = UInt64
public typealias StoredSize = UInt64
public typealias StoredPointerDifference = UInt64
public let PointerSize = 8

public struct TargetRelativeDirectPointer { var Offset: Int32 }
public struct TargetRelativeIndirectablePointer { var Offset: Int32 }

public typealias TargetPointer = RawPointer?

public struct RelativeDirectPointerIntPair { var RelativeOffsetPlusInt: Int32 }

public struct RelativeIndirectablePointerIntPair { var RelativeOffsetPlusIndirectAndInt: Int32 }

public typealias ValueWitnessSize = size_t
public typealias ValueWitnessStride = size_t
public typealias ValueWitnessFlags = UInt32
public typealias ValueWitnessExtraInhabitantCount = UInt32

public struct __Opaque {}
