// clang -E -P input.h | sed '/^$/d' > output.h

typedef TargetPointer TargetOpaquePointer;
typedef TargetPointer TargetValueBufferPointer;
typedef TargetPointer ConstTargetOpaquePointer;
typedef TargetPointer ConstTargetValueBufferPointer;

#define WANT_ALL_VALUE_WITNESSES
#define DATA_VALUE_WITNESS(lowerId, upperId, type)
#define FUNCTION_VALUE_WITNESS(lowerId, upperId, returnType, paramTypes) \
  typedef returnType (*ValueWitness##upperId)paramTypes;
#define MUTABLE_VALUE_TYPE TargetOpaquePointer
#define IMMUTABLE_VALUE_TYPE ConstTargetOpaquePointer
#define MUTABLE_BUFFER_TYPE TargetValueBufferPointer
#define IMMUTABLE_BUFFER_TYPE ConstTargetValueBufferPointer
#define TYPE_TYPE ConstTargetMetadataPointer
#define SIZE_TYPE StoredSize
#define INT_TYPE int
#define UINT_TYPE unsigned
#define VOID_TYPE void
#include "ValueWitness.def"

struct RequiredValueWitnesses {
#define WANT_ONLY_REQUIRED_VALUE_WITNESSES
#define VALUE_WITNESS(LOWER_ID, UPPER_ID) \
  ValueWitness##UPPER_ID LOWER_ID;
#include "ValueWitness.def"
};

struct AllValueWitnesses {
#define WANT_ALL_VALUE_WITNESSES
#define VALUE_WITNESS(LOWER_ID, UPPER_ID) \
  ValueWitness##UPPER_ID LOWER_ID;
#include "ValueWitness.def"
};

