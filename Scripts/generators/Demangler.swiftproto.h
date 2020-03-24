// clang -E -P Demangler.swiftproto.h | sed '/^$/d' > Demangler.swift

enum Kind: UInt16 {
#define NODE(ID) case ID
#include "DemangleNodes.def"
}

func isContext(kind: Node.Kind) -> Bool {
#define NODE(ID)
#define CONTEXT_NODE(ID)                                                \
    kind == .ID ||
#include "DemangleNodes.def"
      false /* we need to neutralise the trailing || */
}

private func decodeValueWitnessKind(code: String) throws -> Int {
#define VALUE_WITNESS(MANGLING, NAME) \
  if code == #MANGLING { return ValueWitnessKind.NAME.rawValue }
#include "ValueWitnessMangling.def"
  throw failure
}

private func createStandardSubstitution(char subst) throws -> Node {
#define STANDARD_TYPE(KIND, MANGLING, TYPENAME)                   \
  if Subst == #MANGLING.unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .KIND, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text(#TYPENAME))])) }
  #include "StandardTypesMangling.def"
  throw failure
}

#define REF_STORAGE(Name, ...) \
case .Name:
    #include "ReferenceStorage.def"


// Remangler
#define NODE(ID) case .ID: return mangle##ID(node)
#include "DemangleNodes.def"

#define VALUE_WITNESS(MANGLING, NAME) \
  case .NAME: Code = #MANGLING
#include "ValueWitnessMangling.def"

