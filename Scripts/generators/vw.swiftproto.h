// clang -E -P vw.swiftproto.h | sed '/^$/d' > vw.swift

typealias ValueBufferPointer = Pointer<__ValueBuffer>
typealias ConstValueBufferPointer = Pointer<__ValueBuffer>
typealias OpaquePointer = Pointer<__Opaque>
typealias ConstOpaquePointer = Pointer<__Opaque>
typealias ConstMetadataPointer = Pointer<__Metadata>

#define WANT_ALL_VALUE_WITNESSES
#define DATA_VALUE_WITNESS(lowerId, upperId, type)
#define FUNCTION_VALUE_WITNESS(lowerId, upperId, returnType, paramTypes) \
  typealias ValueWitness##upperId = @convention(c) paramTypes -> returnType
#define MUTABLE_VALUE_TYPE OpaquePointer
#define IMMUTABLE_VALUE_TYPE ConstOpaquePointer
#define MUTABLE_BUFFER_TYPE ValueBufferPointer
#define IMMUTABLE_BUFFER_TYPE ConstValueBufferPointer
#define TYPE_TYPE ConstMetadataPointer
#define SIZE_TYPE StoredSize
#define INT_TYPE Int
#define UINT_TYPE UInt
#define VOID_TYPE Void
#include "ValueWitness.def"

struct RequiredValueWitnesses {
#define WANT_ONLY_REQUIRED_VALUE_WITNESSES
#define FUNCTION_VALUE_WITNESS(lowerId, upperId, returnType, paramTypes) \
  let lowerId: Pointer<ValueWitness##upperId>
#define DATA_VALUE_WITNESS(LOWER_ID, UPPER_ID, TYPE) \
  let LOWER_ID: ValueWitness##UPPER_ID
#include "ValueWitness.def"
}

struct AllValueWitnesses {
#define WANT_ALL_VALUE_WITNESSES
#define FUNCTION_VALUE_WITNESS(lowerId, upperId, returnType, paramTypes) \
  let lowerId: Pointer<ValueWitness##upperId>
#define DATA_VALUE_WITNESS(LOWER_ID, UPPER_ID, TYPE) \
  let LOWER_ID: ValueWitness##UPPER_ID
#include "ValueWitness.def"
}

