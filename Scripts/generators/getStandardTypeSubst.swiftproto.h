// clang -E -P getStandardTypeSubst.swiftproto.h | sed '/^$/d' > getStandardTypeSubst.swift

func getStandardTypeSubst(typeName: String) -> UnicodeScalar? {
#define STANDARD_TYPE(KIND, MANGLING, TYPENAME)      \
  if (typeName == #TYPENAME) {                       \
    return #MANGLING                                 \
  }

#include "StandardTypesMangling.def"

  fatalError("Unknown typename")
}

