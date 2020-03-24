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

/// Heap metadata for a box, which may have been generated statically by the compiler or by the runtime.
public class BoxHeapMetadata: HeapMetadata {
    private struct Pointee {
        // : _HeapMetadata
        // : Metadata
        var kind: StoredPointer
        /// The offset from the beginning of a box to its value.
        var Offset: UInt32
    }
}

/// Heap metadata for runtime-instantiated generic boxes.
public class GenericBoxHeapMetadata: BoxHeapMetadata {
    private struct Pointee {
        // : BoxHeapMetadata<Runtime>
        // : _HeapMetadata
        // : Metadata
        var kind: StoredPointer
        var Offset: UInt32 // [?]
        /// The type inside the box.
        var BoxedType: RawPointer /* <Runtime, swift::TargetMetadata> */
    }
}

/// The structure of metadata for foreign types where the source language doesn't provide any sort of more interesting metadata for us to use.
public class ForeignTypeMetadata: Metadata {
    private struct Pointee {
        // : Metadata
        var kind: StoredPointer
    }
}

/// The structure of metadata objects for foreign class types.
/// A foreign class is a foreign type with reference semantics and
/// Swift-supported reference counting.  Generally this requires
/// special logic in the importer.
///
/// We assume for now that foreign classes are entirely opaque
/// to Swift introspection.
public class ForeignClassMetadata: ForeignTypeMetadata {
    private struct Pointee {
        // : ForeignTypeMetadata
        // : Metadata
        var kind: StoredPointer
        /// An out-of-line description of the type.
        var description: RawPointer /* <Runtime, TargetClassDescriptor> */
        /// The superclass of the foreign class, if any.
        var superclass: RawPointer? /* <Runtime, TargetForeignClassMetadata> */
        /// Reserved space.  For now, this should be zero-initialized. If this is used for anything in the future, at least some of these first bits should be flags.
        var reserved: StoredPointer
    }
}

/// The basic layout of an existential metatype type.
struct ExistentialMetatypeContainer: PointeeFacade {
    struct Pointee {
        var Value: RawPointer /* <Runtime, TargetMetadata> */
    }
    let pointer: RawPointer
}

// PRAGMA MARK: -

/// A structure that stores a reference to an Objective-C class stub. This is not the class stub itself; it is part of a class context descriptor.
struct ObjCResilientClassStubInfo {
    /// A relative pointer to an Objective-C resilient class stub.
    ///
    /// We do not declare a struct type for class stubs since the Swift runtime does not need to interpret them. The class stub struct is part of the Objective-C ABI, and is laid out as follows:
    /// - isa pointer, always 1
    /// - an update callback, of type 'Class (*)(Class *, objc_class_stub *)'
    ///
    /// Class stubs are used for two purposes:
    /// - Objective-C can reference class stubs when calling static methods.
    /// - Objective-C and Swift can reference class stubs when emitting
    ///   categories (in Swift, extensions with @objc members).
    var Stub: TargetRelativeDirectPointer /* <Runtime, const void> */
}

#if SWIFT_OBJC_INTEROP
/// Layout of a small prefix of an Objective-C protocol, used only to directly extract the name of the protocol.
struct __ObjCProtocolPrefix {
    /// Unused by the Swift runtime.
    var _ObjC_Isa: TargetPointer /* <Runtime, const void> */
    /// The mangled name of the protocol.
    var Name: TargetPointer /* <Runtime, const char> */
};
#endif

struct MetadataBounds: PointeeFacade {
    struct Pointee {
        /// The negative extent of the metadata, in words.
        var NegativeSizeInWords: UInt32
        /// The positive extent of the metadata, in words.
        var PositiveSizeInWords: UInt32
    }
    let pointer: RawPointer

    var negativeSizeInWords: UInt32 { pointee.NegativeSizeInWords }
    var positiveSizeInWords: UInt32 { pointee.PositiveSizeInWords }

    /// Return the total size of the metadata in bytes, including both
    /// negatively- and positively-offset members.
    var totalSizeInBytes: StoredSize {
        StoredSize(pointee.NegativeSizeInWords) + StoredSize(pointee.PositiveSizeInWords) * StoredSize(PointerSize)
    }

    /// Return the offset of the address point of the metadata from its
    /// start, in bytes.
    var addressPointInBytes: StoredSize {
        StoredSize(pointee.NegativeSizeInWords) * StoredSize(PointerSize)
    }
}

struct ClassMetadataBounds: PointeeFacade {
    let pointer: RawPointer

    /// The bounds of a class metadata object.
    ///
    /// This type is a currency type and is not part of the ABI. See TargetStoredClassMetadataBounds for the type of the class metadata bounds variable.
    struct Pointee {
        // : MetadataBounds
        var NegativeSizeInWords: UInt32
        var PositiveSizeInWords: UInt32
        /// The offset from the address point of the metadata to the immediate members.
        var ImmediateMembersOffset: StoredPointerDifference
    }
}

/// Storage for class metadata bounds.  This is the variable returned
/// by getAddrOfClassMetadataBounds in the compiler.
///
/// This storage is initialized before the allocation of any metadata
/// for the class to which it belongs.  In classes without resilient
/// superclasses, it is initialized statically with values derived
/// during compilation.  In classes with resilient superclasses, it
/// is initialized dynamically, generally during the allocation of
/// the first metadata of this class's type.  If metadata for this
/// class is available to you to use, you must have somehow synchronized
/// with the thread which allocated the metadata, and therefore the
/// complete initialization of this variable is also ordered before
/// your access.  That is why you can safely access this variable,
/// and moreover access it without further atomic accesses.  However,
/// since this variable may be accessed in a way that is not dependency-
/// ordered on the metadata pointer, it is important that you do a full
/// synchronization and not just a dependency-ordered (consume)
/// synchronization when sharing class metadata pointers between
/// threads.  (There are other reasons why this is true; for example,
/// field offset variables are also accessed without dependency-ordering.)
///
/// If you are accessing this storage without such a guarantee, you
/// should be aware that it may be lazily initialized, and moreover
/// it may be getting lazily initialized from another thread.  To ensure
/// correctness, the fields must be read in the correct order: the
/// immediate-members offset is initialized last with a store-release,
/// so it must be read first with a load-acquire, and if the result
/// is non-zero then the rest of the variable is known to be valid.
/// (No locking is required because racing initializations should always
/// assign the same values to the storage.)
struct StoredClassMetadataBounds {
    /// The offset to the immediate members.  This value is in bytes so that clients don't have to sign-extend it. It is not necessary to use atomic-ordered loads when accessing this variable just to read the immediate-members offset when drilling to the immediate members of an already-allocated metadata object. The proper initialization of this variable is always ordered before any allocation of metadata for this class.
    // std::atomic<StoredPointerDifference> ImmediateMembersOffset;
    var ImmediateMembersOffset: StoredPointerDifference

    /// The positive and negative bounds of the class metadata.
    var Bounds: MetadataBounds.Pointee
};

struct ResilientWitnessTable: PointeeFacade {
    struct Pointee {
        var NumWitnesses: UInt32
        // : TrailingObjects<TargetResilientWitnessTable<Runtime>, TargetResilientWitness<Runtime>>
    }
    let pointer: RawPointer
}

struct GenericEnvironment: PointeeFacade {
    struct Pointee {
        var Flags: __GenericEnvironmentFlags
        // : swift::ABI::TrailingObjects<TargetGenericEnvironment<Runtime>,
        //                              uint16_t, GenericParamDescriptor,
        //                              TargetGenericRequirementDescriptor<Runtime>>
    }
    let pointer: RawPointer
}

/// The instantiation cache for generic metadata.  This must be guaranteed to zero-initialized before it is first accessed.  Its contents are private to the runtime.
struct GenericMetadataInstantiationCache: PointeeFacade {
    struct Pointee {
        /// Data that the runtime can use for its own purposes.  It is guaranteed to be zero-filled by the compiler.
        var privateData: TargetPointer /*<Runtime, void> *PrivateData[__NumGenericMetadataPrivateDataWords] */
    }

    let pointer: RawPointer
}

/// The opaque completion context of a metadata completion function. A completion function that needs to report a completion dependency can use this to figure out where it left off and thus avoid redundant work when re-invoked.  It will be zero on first entry for a type, and the runtime is free to copy it to a different location between invocations.
struct MetadataCompletionContext: PointeeFacade {
    struct Pointee {
        var data: RawPointer // void *Data[__NumWords_MetadataCompletionContext];
    }
    let pointer: RawPointer
}

/// A function that instantiates metadata.  This function is required to succeed.
///
/// In general, the metadata returned by this function should have all the basic structure necessary to identify itself: that is, it must have a type descriptor and generic arguments.  However, it does not need to be fully functional as type metadata; for example, it does not need to have a meaningful value witness table, v-table entries, or a superclass.
///
/// Operations which may fail (due to e.g. recursive dependencies) but which must be performed in order to prepare the metadata object to be fully functional as type metadata should be delayed until the completion function.
// using MetadataInstantiator =
//  Metadata *(const TargetTypeContextDescriptor<InProcess> *type,
//             const void *arguments,
//             const TargetGenericMetadataPattern<InProcess> *pattern);


struct GenericMetadataPattern: PointeeFacade {
    struct Pointee {
        /// The function to call to instantiate the template.
        var InstantiationFunction: TargetRelativeDirectPointer /* <Runtime, MetadataInstantiator> */
        /// The function to call to complete the instantiation.  If this is null, the instantiation function must always generate complete metadata.
        var CompletionFunction: TargetRelativeDirectPointer /* <Runtime, MetadataCompleter, nullable=true> */
        /// Flags describing the layout of this instantiation pattern.
        var PatternFlags: __GenericMetadataPatternFlags
    }
    let pointer: RawPointer
}

struct GenericMetadataPartialPattern: PointeeFacade {
    struct Pointee {
        /// A reference to the pattern.  The pattern must always be at least word-aligned.
        var Pattern: TargetRelativeDirectPointer /* <Runtime, typename Runtime::StoredPointer> */
        /// The offset into the section into which to copy this pattern, in words.
        var OffsetInWords: UInt16
        /// The size of the pattern, in words.
        var SizeInWords: UInt16
    }
    let pointer: RawPointer
}

/// The control structure for performing non-trivial initialization of
/// singleton foreign metadata.
struct __ForeignMetadataInitialization {
    /// The completion function.  The pattern will always be null.
    var CompletionFunction: TargetRelativeDirectPointer /* <Runtime, MetadataCompleter, nullable=true> */
}

/// The control structure for performing non-trivial initialization of singleton value metadata, which is required when e.g. a non-generic value type has a resilient component type.
public struct __SingletonMetadataInitialization {
    /// The initialization cache.  Out-of-line because mutable.
    var InitializationCache: TargetRelativeDirectPointer /* <Runtime, TargetSingletonMetadataCache<Runtime>> */

    var IncompleteMetadataOrResilientPattern: TargetRelativeDirectPointer /* a.k.a. union */
    /// The incomplete metadata, for structs, enums and classes without resilient ancestry.
    var IncompleteMetadata: TargetRelativeDirectPointer /* <Runtime, TargetMetadata<Runtime>> */ { IncompleteMetadataOrResilientPattern }
    /// If the class descriptor's hasResilientSuperclass() flag is set, this field instead points at a pattern used to allocate and initialize metadata for this class, since it's size and contents is not known at compile time.
    var ResilientPattern: TargetRelativeDirectPointer /* <Runtime, TargetResilientClassMetadataPattern<Runtime>> */ { IncompleteMetadataOrResilientPattern }

    /// The completion function.  The pattern will always be null, even for a resilient class.
    var CompletionFunction: TargetRelativeDirectPointer /* <Runtime, MetadataCompleter> */
}

/// An instantiation pattern for non-generic resilient class metadata.
///
/// Used for classes with resilient ancestry, that is, where at least one ancestor is defined in a different resilience domain.
///
/// The hasResilientSuperclass() flag in the class context descriptor is set in this case, and hasSingletonMetadataInitialization() must be set as well.
///
/// The pattern is referenced from the SingletonMetadataInitialization record in the class context descriptor.
struct __ResilientClassMetadataPattern {
    /// A function that allocates metadata with the correct size at runtime.
    ///
    /// If this is null, the runtime instead calls swift_relocateClassMetadata(),
    /// passing in the class descriptor and this pattern.
    var RelocationFunction: TargetRelativeDirectPointer /* <Runtime, MetadataRelocator, nullable=true> */

    /// The heap-destructor function.
    var Destroy: TargetRelativeDirectPointer /* <Runtime, HeapObjectDestroyer> */

    /// The ivar-destructor function.
    var IVarDestroyer: TargetRelativeDirectPointer /* <Runtime, ClassIVarDestroyer, nullable=true> */

    /// The class flags.
    var Flags: __ClassFlags

    // The following fields are only present in ObjC interop.

    /// Our ClassROData.
    var Data: TargetRelativeDirectPointer /* <Runtime, void> */

    /// Our metaclass.
    var Metaclass: TargetRelativeDirectPointer /*<Runtime, TargetAnyClassMetadata<Runtime>> */
}

/// The cache structure for non-trivial initialization of singleton value metadata.
struct __SingletonMetadataCache {
    /// The metadata pointer.  Clients can do dependency-ordered loads from this, and if they see a non-zero value, it's a Complete metadata.
    var Metadata: RawPointer // std::atomic<TargetMetadataPointer<Runtime, TargetMetadata>> Metadata;

    /// The private cache data.
    var Private: TargetPointer // std::atomic<TargetPointer<Runtime, void>> Private;
}

/// An instantiation pattern for generic value metadata.
struct __GenericValueMetadataPattern {
    // : GenericMetadataPattern<Runtime>
    var InstantiationFunction: TargetRelativeDirectPointer /* <Runtime, MetadataInstantiator> */
    var CompletionFunction: TargetRelativeDirectPointer /* <Runtime, MetadataCompleter, nullable=true> */
    var PatternFlags: __GenericMetadataPatternFlags
    /// The value-witness table.  Indirectable so that we can re-use tables from other libraries if that seems wise.
    var ValueWitnesses: TargetRelativeIndirectablePointer /* <Runtime, const ValueWitnessTable> */
    //      TargetGenericMetadataPatternTrailingObjects<Runtime, TargetGenericValueMetadataPattern<Runtime>>
}

/// An instantiation pattern for generic class metadata.
struct __GenericClassMetadataPattern {
    //  : GenericMetadataPattern<Runtime>,
    var InstantiationFunction: TargetRelativeDirectPointer /* <Runtime, MetadataInstantiator> */
    var CompletionFunction: TargetRelativeDirectPointer /* <Runtime, MetadataCompleter, nullable=true> */
    var PatternFlags: __GenericMetadataPatternFlags
    /// The heap-destructor function.
    var Destroy: TargetRelativeDirectPointer /* <Runtime, HeapObjectDestroyer> */
    /// The ivar-destructor function.
    var IVarDestroyer: TargetRelativeDirectPointer /* <Runtime, ClassIVarDestroyer, nullable=true> */
    /// The class flags.
    var Flags: __ClassFlags
    // The following fields are only present in ObjC interop.
    /// The offset of the class RO-data within the extra data pattern,
    /// in words.
    var ClassRODataOffset: UInt16
    /// The offset of the metaclass object within the extra data pattern, in words.
    var MetaclassObjectOffset: UInt16
    /// The offset of the metaclass RO-data within the extra data pattern, in words.
    var MetaclassRODataOffset: UInt16
    var Reserved: UInt16
    //  :    TargetGenericMetadataPatternTrailingObjects<Runtime, TargetGenericClassMetadataPattern<Runtime>>
}

// PRAGMA MARK: -

/// An entry in the chain of dynamic replacement functions.
struct DynamicReplacementChainEntry: PointeeFacade {
    struct Pointee {
        var implementationFunction: RawPointer
        var next: Pointer<Pointee>
    }
    let pointer: RawPointer
}

public struct DynamicReplacementKey: PointeeFacade {
    public struct Pointee {
        var root: TargetRelativeDirectPointer /* <DynamicReplacementChainEntry, false> */
        var flags: UInt32
    }
    public let pointer: RawPointer
}

/// A record describing a dynamic function replacement.
struct DynamicReplacementDescriptor: PointeeFacade {
    struct Pointee {
        var replacedFunctionKey: TargetRelativeIndirectablePointer /* <DynamicReplacementKey, false> */
        var replacementFunction: TargetRelativeDirectPointer /* <void, false> */
        var chainEntry: TargetRelativeDirectPointer /* <DynamicReplacementChainEntry, false> */
        var flags: UInt32
        static let EnableChainingMask = 0x1
    }
    let pointer: RawPointer
}

/// A collection of dynamic replacement records.
struct DynamicReplacementScope: PointeeFacade {
    struct Pointee {
        var flags: UInt32
        var numReplacements: UInt32
        // : swift::ABI::TrailingObjects<DynamicReplacementScope, DynamicReplacementDescriptor>
    }
    let pointer: RawPointer
}

// MARK: - MetadataValues.h

/// Flags used by generic metadata patterns.
public enum GenericMetadataPatternFlags {
    // All of these values are bit offsets or widths. General flags build up from 0. Kind-specific flags build down from 31.

    /// Does this pattern have an extra-data pattern?
    public static let HasExtraDataPattern: UInt32 = 0

    // Class-specific flags.

    /// Does this pattern have an immediate-members pattern?
    public static let Class_HasImmediateMembersPattern: UInt32 = 31

    // Value-specific flags.

    /// For value metadata: the metadata kind of the type.
    public static let Value_MetadataKind: UInt32 = 21
    public static let Value_MetadataKind_width: UInt32 = 11
}

public enum GenericEnvironmentFlags {
    public static let NumGenericParameterLevelsMask: UInt32 = 0xFFF
    public static let NumGenericRequirementsShift: UInt32 = 12
    public static let NumGenericRequirementsMask: UInt32 = 0xFFFF << NumGenericRequirementsShift
}

public enum FieldType {
    public static let Indirect = 1
    public static let Weak = 2
    public static let TypeMask = uintptr_t(bitPattern: -1) & ~(0 /* _Alignof(void*) - 1 */)
}

///// Flags for exclusivity-checking operations.
public enum ExclusivityFlags {
    public static let Read             = 0x0
    public static let Modify           = 0x1
    // ActionMask can grow without breaking the ABI because the runtime controls how these flags are encoded in the "value buffer".
    // However, any additional actions must be compatible with the original behavior for the old, smaller ActionMask (older runtimes will continue to treat them as either a simple Read or Modify).
    public static let ActionMask       = 0x1

    // The runtime should track this access to check against subsequent accesses.
    public static let Tracking         = 0x20
}

public enum StructLayoutFlags {
    /// Reserve space for 256 layout algorithms.
    public static let AlgorithmMask: uintptr_t     = 0xff

    /// The ABI baseline algorithm, i.e. the algorithm implemented in Swift 5.
    public static let Swift5Algorithm: uintptr_t   = 0x00

    /// Is the value-witness table mutable in place, or does layout need to clone it?
    public static let IsVWTMutable: uintptr_t      = 0x100
}

public enum ClassLayoutFlags {
    /// Reserve space for 256 layout algorithms.
    public static let AlgorithmMask: uintptr_t     = 0xff

    /// The ABI baseline algorithm, i.e. the algorithm implemented in Swift 5.
    public static let Swift5Algorithm: uintptr_t   = 0x00

    /// If true, the vtable for this class and all of its superclasses was emitted
    /// statically in the class metadata. If false, the superclass vtable is
    /// copied from superclass metadata, and the immediate class vtable is
    /// initialized from the type context descriptor.
    public static let HasStaticVTable: uintptr_t   = 0x100
}

public enum EnumLayoutFlags {
    /// Reserve space for 256 layout algorithms.
    public static let AlgorithmMask: uintptr_t     = 0xff

    /// The ABI baseline algorithm, i.e. the algorithm implemented in Swift 5.
    public static let Swift5Algorithm: uintptr_t   = 0x00

    /// Is the value-witness table mutable in place, or does layout need to
    /// clone it?
    public static let IsVWTMutable: uintptr_t      = 0x100
}

public enum IntegerLiteralFlags {
    public static let IsNegativeFlag: size_t    = 0x01
    public static let BitWidthShift: size_t     = 8
}

