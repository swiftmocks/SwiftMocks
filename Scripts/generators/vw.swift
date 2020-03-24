typealias ValueBufferPointer = Pointer<__ValueBuffer>
typealias ConstValueBufferPointer = Pointer<__ValueBuffer>
typealias OpaquePointer = Pointer<__Opaque>
typealias ConstOpaquePointer = Pointer<__Opaque>
typealias ConstMetadataPointer = Pointer<__Metadata>
typealias ValueWitnessInitializeBufferWithCopyOfBuffer = @convention(c) (ValueBufferPointer, ValueBufferPointer, ConstMetadataPointer) -> OpaquePointer
typealias ValueWitnessDestroy = @convention(c) (OpaquePointer, ConstMetadataPointer) -> Void
typealias ValueWitnessInitializeWithCopy = @convention(c) (OpaquePointer, OpaquePointer, ConstMetadataPointer) -> OpaquePointer
typealias ValueWitnessAssignWithCopy = @convention(c) (OpaquePointer, OpaquePointer, ConstMetadataPointer) -> OpaquePointer
typealias ValueWitnessInitializeWithTake = @convention(c) (OpaquePointer, OpaquePointer, ConstMetadataPointer) -> OpaquePointer
typealias ValueWitnessAssignWithTake = @convention(c) (OpaquePointer, OpaquePointer, ConstMetadataPointer) -> OpaquePointer
typealias ValueWitnessGetEnumTagSinglePayload = @convention(c) (ConstOpaquePointer, UInt, ConstMetadataPointer) -> UInt
typealias ValueWitnessStoreEnumTagSinglePayload = @convention(c) (OpaquePointer, UInt, UInt, ConstMetadataPointer) -> Void
typealias ValueWitnessGetEnumTag = @convention(c) (ConstOpaquePointer, ConstMetadataPointer) -> Int
typealias ValueWitnessDestructiveProjectEnumData = @convention(c) (OpaquePointer, ConstMetadataPointer) -> Void
typealias ValueWitnessDestructiveInjectEnumTag = @convention(c) (OpaquePointer, UInt, ConstMetadataPointer) -> Void
struct RequiredValueWitnesses {
let initializeBufferWithCopyOfBuffer: Pointer<ValueWitnessInitializeBufferWithCopyOfBuffer>
let destroy: Pointer<ValueWitnessDestroy>
let initializeWithCopy: Pointer<ValueWitnessInitializeWithCopy>
let assignWithCopy: Pointer<ValueWitnessAssignWithCopy>
let initializeWithTake: Pointer<ValueWitnessInitializeWithTake>
let assignWithTake: Pointer<ValueWitnessAssignWithTake>
let getEnumTagSinglePayload: Pointer<ValueWitnessGetEnumTagSinglePayload>
let storeEnumTagSinglePayload: Pointer<ValueWitnessStoreEnumTagSinglePayload>
let size: ValueWitnessSize
let stride: ValueWitnessStride
let flags: ValueWitnessFlags
let extraInhabitantCount: ValueWitnessExtraInhabitantCount
}
struct AllValueWitnesses {
let initializeBufferWithCopyOfBuffer: Pointer<ValueWitnessInitializeBufferWithCopyOfBuffer>
let destroy: Pointer<ValueWitnessDestroy>
let initializeWithCopy: Pointer<ValueWitnessInitializeWithCopy>
let assignWithCopy: Pointer<ValueWitnessAssignWithCopy>
let initializeWithTake: Pointer<ValueWitnessInitializeWithTake>
let assignWithTake: Pointer<ValueWitnessAssignWithTake>
let getEnumTagSinglePayload: Pointer<ValueWitnessGetEnumTagSinglePayload>
let storeEnumTagSinglePayload: Pointer<ValueWitnessStoreEnumTagSinglePayload>
let size: ValueWitnessSize
let stride: ValueWitnessStride
let flags: ValueWitnessFlags
let extraInhabitantCount: ValueWitnessExtraInhabitantCount
let getEnumTag: Pointer<ValueWitnessGetEnumTag>
let destructiveProjectEnumData: Pointer<ValueWitnessDestructiveProjectEnumData>
let destructiveInjectEnumTag: Pointer<ValueWitnessDestructiveInjectEnumTag>
}
