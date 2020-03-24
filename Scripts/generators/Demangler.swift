enum Kind: UInt16 {
case Allocator
case AnonymousContext
case AnyProtocolConformanceList
case ArgumentTuple
case AssociatedType
case AssociatedTypeRef
case AssociatedTypeMetadataAccessor
case DefaultAssociatedTypeMetadataAccessor
case AssociatedTypeWitnessTableAccessor
case BaseWitnessTableAccessor
case AutoClosureType
case BoundGenericClass
case BoundGenericEnum
case BoundGenericStructure
case BoundGenericProtocol
case BoundGenericOtherNominalType
case BoundGenericTypeAlias
case BoundGenericFunction
case BuiltinTypeName
case CFunctionPointer
case Class
case ClassMetadataBaseOffset
case ConcreteProtocolConformance
case Constructor
case CoroutineContinuationPrototype
case Deallocator
case DeclContext
case DefaultArgumentInitializer
case DependentAssociatedConformance
case DependentAssociatedTypeRef
case DependentGenericConformanceRequirement
case DependentGenericParamCount
case DependentGenericParamType
case DependentGenericSameTypeRequirement
case DependentGenericLayoutRequirement
case DependentGenericSignature
case DependentGenericType
case DependentMemberType
case DependentPseudogenericSignature
case DependentProtocolConformanceRoot
case DependentProtocolConformanceInherited
case DependentProtocolConformanceAssociated
case Destructor
case DidSet
case Directness
case DynamicAttribute
case DirectMethodReferenceAttribute
case DynamicSelf
case DynamicallyReplaceableFunctionImpl
case DynamicallyReplaceableFunctionKey
case DynamicallyReplaceableFunctionVar
case Enum
case EnumCase
case ErrorType
case EscapingAutoClosureType
case NoEscapeFunctionType
case ExistentialMetatype
case ExplicitClosure
case Extension
case FieldOffset
case FullTypeMetadata
case Function
case FunctionSignatureSpecialization
case FunctionSignatureSpecializationParam
case FunctionSignatureSpecializationReturn
case FunctionSignatureSpecializationParamKind
case FunctionSignatureSpecializationParamPayload
case FunctionType
case GenericPartialSpecialization
case GenericPartialSpecializationNotReAbstracted
case GenericProtocolWitnessTable
case GenericProtocolWitnessTableInstantiationFunction
case ResilientProtocolWitnessTable
case GenericSpecialization
case GenericSpecializationNotReAbstracted
case GenericSpecializationParam
case InlinedGenericFunction
case GenericTypeMetadataPattern
case Getter
case Global
case GlobalGetter
case Identifier
case Index
case IVarInitializer
case IVarDestroyer
case ImplEscaping
case ImplConvention
case ImplFunctionAttribute
case ImplFunctionType
case ImplicitClosure
case ImplParameter
case ImplResult
case ImplErrorResult
case InOut
case InfixOperator
case Initializer
case KeyPathGetterThunkHelper
case KeyPathSetterThunkHelper
case KeyPathEqualsThunkHelper
case KeyPathHashThunkHelper
case LazyProtocolWitnessTableAccessor
case LazyProtocolWitnessTableCacheVariable
case LocalDeclName
case MaterializeForSet
case MergedFunction
case Metatype
case MetatypeRepresentation
case Metaclass
case MethodLookupFunction
case ObjCMetadataUpdateFunction
case ObjCResilientClassStub
case FullObjCResilientClassStub
case ModifyAccessor
case Module
case NativeOwningAddressor
case NativeOwningMutableAddressor
case NativePinningAddressor
case NativePinningMutableAddressor
case NominalTypeDescriptor
case NonObjCAttribute
case Number
case ObjCAttribute
case ObjCBlock
case OtherNominalType
case OwningAddressor
case OwningMutableAddressor
case PartialApplyForwarder
case PartialApplyObjCForwarder
case PostfixOperator
case PrefixOperator
case PrivateDeclName
case PropertyDescriptor
case Protocol
case ProtocolSymbolicReference
case ProtocolConformance
case ProtocolConformanceRefInTypeModule
case ProtocolConformanceRefInProtocolModule
case ProtocolConformanceRefInOtherModule
case ProtocolDescriptor
case ProtocolConformanceDescriptor
case ProtocolList
case ProtocolListWithClass
case ProtocolListWithAnyObject
case ProtocolSelfConformanceDescriptor
case ProtocolSelfConformanceWitness
case ProtocolSelfConformanceWitnessTable
case ProtocolWitness
case ProtocolWitnessTable
case ProtocolWitnessTableAccessor
case ProtocolWitnessTablePattern
case ReabstractionThunk
case ReabstractionThunkHelper
case ReabstractionThunkHelperWithSelf
case ReadAccessor
case RelatedEntityDeclName
case RetroactiveConformance
case ReturnType
case Shared
case Owned
case SILBoxType
case SILBoxTypeWithLayout
case SILBoxLayout
case SILBoxMutableField
case SILBoxImmutableField
case Setter
case SpecializationPassID
case IsSerialized
case Static
case Structure
case Subscript
case Suffix
case ThinFunctionType
case Tuple
case TupleElement
case TupleElementName
case Type
case TypeSymbolicReference
case TypeAlias
case TypeList
case TypeMangling
case TypeMetadata
case TypeMetadataAccessFunction
case TypeMetadataCompletionFunction
case TypeMetadataInstantiationCache
case TypeMetadataInstantiationFunction
case TypeMetadataSingletonInitializationCache
case TypeMetadataLazyCache
case UncurriedFunctionType
case UnknownIndex
case Weak
case Unowned
case Unmanaged
case UnsafeAddressor
case UnsafeMutableAddressor
case ValueWitness
case ValueWitnessTable
case Variable
case VTableThunk
case VTableAttribute
case WillSet
case ReflectionMetadataBuiltinDescriptor
case ReflectionMetadataFieldDescriptor
case ReflectionMetadataAssocTypeDescriptor
case ReflectionMetadataSuperclassDescriptor
case GenericTypeParamDecl
case CurryThunk
case DispatchThunk
case MethodDescriptor
case ProtocolRequirementsBaseDescriptor
case AssociatedConformanceDescriptor
case DefaultAssociatedConformanceAccessor
case BaseConformanceDescriptor
case AssociatedTypeDescriptor
case ThrowsAnnotation
case EmptyList
case FirstElementMarker
case VariadicMarker
case OutlinedBridgedMethod
case OutlinedCopy
case OutlinedConsume
case OutlinedRetain
case OutlinedRelease
case OutlinedInitializeWithTake
case OutlinedInitializeWithCopy
case OutlinedAssignWithTake
case OutlinedAssignWithCopy
case OutlinedDestroy
case OutlinedVariable
case AssocTypePath
case LabelList
case ModuleDescriptor
case ExtensionDescriptor
case AnonymousDescriptor
case AssociatedTypeGenericParamRef
case SugaredOptional
case SugaredArray
case SugaredDictionary
case SugaredParen
case AccessorFunctionReference
case OpaqueType
case OpaqueTypeDescriptorSymbolicReference
case OpaqueTypeDescriptor
case OpaqueTypeDescriptorAccessor
case OpaqueTypeDescriptorAccessorImpl
case OpaqueTypeDescriptorAccessorKey
case OpaqueTypeDescriptorAccessorVar
case OpaqueReturnType
case OpaqueReturnTypeOf
}
func isContext(kind: Node.Kind) -> Bool {
kind == .Allocator ||
kind == .AnonymousContext ||
kind == .Class ||
kind == .Constructor ||
kind == .Deallocator ||
kind == .DefaultArgumentInitializer ||
kind == .Destructor ||
kind == .DidSet ||
kind == .Enum ||
kind == .ExplicitClosure ||
kind == .Extension ||
kind == .Function ||
kind == .Getter ||
kind == .GlobalGetter ||
kind == .IVarInitializer ||
kind == .IVarDestroyer ||
kind == .ImplicitClosure ||
kind == .Initializer ||
kind == .MaterializeForSet ||
kind == .ModifyAccessor ||
kind == .Module ||
kind == .NativeOwningAddressor ||
kind == .NativeOwningMutableAddressor ||
kind == .NativePinningAddressor ||
kind == .NativePinningMutableAddressor ||
kind == .OtherNominalType ||
kind == .OwningAddressor ||
kind == .OwningMutableAddressor ||
kind == .Protocol ||
kind == .ProtocolSymbolicReference ||
kind == .ReadAccessor ||
kind == .Setter ||
kind == .Static ||
kind == .Structure ||
kind == .Subscript ||
kind == .TypeSymbolicReference ||
kind == .TypeAlias ||
kind == .UnsafeAddressor ||
kind == .UnsafeMutableAddressor ||
kind == .Variable ||
kind == .WillSet ||
kind == .OpaqueReturnTypeOf ||
 false
}
private func decodeValueWitnessKind(code: String) throws -> Int {
if code == "al" { return ValueWitnessKind.AllocateBuffer.rawValue }
if code == "ca" { return ValueWitnessKind.AssignWithCopy.rawValue }
if code == "ta" { return ValueWitnessKind.AssignWithTake.rawValue }
if code == "de" { return ValueWitnessKind.DeallocateBuffer.rawValue }
if code == "xx" { return ValueWitnessKind.Destroy.rawValue }
if code == "XX" { return ValueWitnessKind.DestroyBuffer.rawValue }
if code == "Xx" { return ValueWitnessKind.DestroyArray.rawValue }
if code == "CP" { return ValueWitnessKind.InitializeBufferWithCopyOfBuffer.rawValue }
if code == "Cp" { return ValueWitnessKind.InitializeBufferWithCopy.rawValue }
if code == "cp" { return ValueWitnessKind.InitializeWithCopy.rawValue }
if code == "Tk" { return ValueWitnessKind.InitializeBufferWithTake.rawValue }
if code == "tk" { return ValueWitnessKind.InitializeWithTake.rawValue }
if code == "pr" { return ValueWitnessKind.ProjectBuffer.rawValue }
if code == "TK" { return ValueWitnessKind.InitializeBufferWithTakeOfBuffer.rawValue }
if code == "Cc" { return ValueWitnessKind.InitializeArrayWithCopy.rawValue }
if code == "Tt" { return ValueWitnessKind.InitializeArrayWithTakeFrontToBack.rawValue }
if code == "tT" { return ValueWitnessKind.InitializeArrayWithTakeBackToFront.rawValue }
if code == "xs" { return ValueWitnessKind.StoreExtraInhabitant.rawValue }
if code == "xg" { return ValueWitnessKind.GetExtraInhabitantIndex.rawValue }
if code == "ug" { return ValueWitnessKind.GetEnumTag.rawValue }
if code == "up" { return ValueWitnessKind.DestructiveProjectEnumData.rawValue }
if code == "ui" { return ValueWitnessKind.DestructiveInjectEnumTag.rawValue }
if code == "et" { return ValueWitnessKind.GetEnumTagSinglePayload.rawValue }
if code == "st" { return ValueWitnessKind.StoreEnumTagSinglePayload.rawValue }
 throw failure
}
private func createStandardSubstitution(char subst) throws -> Node {
if Subst == "A".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("AutoreleasingUnsafeMutablePointer"))])) }
if Subst == "a".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("Array"))])) }
if Subst == "b".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("Bool"))])) }
if Subst == "c".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("UnicodeScalar"))])) }
if Subst == "D".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("Dictionary"))])) }
if Subst == "d".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("Double"))])) }
if Subst == "f".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("Float"))])) }
if Subst == "h".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("Set"))])) }
if Subst == "I".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("DefaultIndices"))])) }
if Subst == "i".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("Int"))])) }
if Subst == "J".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("Character"))])) }
if Subst == "N".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("ClosedRange"))])) }
if Subst == "n".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("Range"))])) }
if Subst == "O".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("ObjectIdentifier"))])) }
if Subst == "P".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("UnsafePointer"))])) }
if Subst == "p".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("UnsafeMutablePointer"))])) }
if Subst == "R".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("UnsafeBufferPointer"))])) }
if Subst == "r".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("UnsafeMutableBufferPointer"))])) }
if Subst == "S".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("String"))])) }
if Subst == "s".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("Substring"))])) }
if Subst == "u".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("UInt"))])) }
if Subst == "V".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("UnsafeRawPointer"))])) }
if Subst == "v".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("UnsafeMutableRawPointer"))])) }
if Subst == "W".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("UnsafeRawBufferPointer"))])) }
if Subst == "w".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Structure, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("UnsafeMutableRawBufferPointer"))])) }
if Subst == "q".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Enum, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("Optional"))])) }
if Subst == "B".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("BinaryFloatingPoint"))])) }
if Subst == "E".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("Encodable"))])) }
if Subst == "e".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("Decodable"))])) }
if Subst == "F".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("FloatingPoint"))])) }
if Subst == "G".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("RandomNumberGenerator"))])) }
if Subst == "H".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("Hashable"))])) }
if Subst == "j".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("Numeric"))])) }
if Subst == "K".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("BidirectionalCollection"))])) }
if Subst == "k".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("RandomAccessCollection"))])) }
if Subst == "L".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("Comparable"))])) }
if Subst == "l".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("Collection"))])) }
if Subst == "M".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("MutableCollection"))])) }
if Subst == "m".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("RangeReplaceableCollection"))])) }
if Subst == "Q".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("Equatable"))])) }
if Subst == "T".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("Sequence"))])) }
if Subst == "t".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("IteratorProtocol"))])) }
if Subst == "U".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("UnsignedInteger"))])) }
if Subst == "X".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("RangeExpression"))])) }
if Subst == "x".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("Strideable"))])) }
if Subst == "Y".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("RawRepresentable"))])) }
if Subst == "y".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("StringProtocol"))])) }
if Subst == "Z".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("SignedInteger"))])) }
if Subst == "z".unicodeScalars.first { return Node(kind: .Type, child: Node(kind: .Protocol, children: [Node(kind: .Module, payload: .Text(stdlibName)), Node(kind: .Identifier, payload: .Text("BinaryInteger"))])) }
 throw failure
}
case .Weak:
case .Unowned:
case .Unmanaged:
case .Allocator: return mangleAllocator(node)
case .AnonymousContext: return mangleAnonymousContext(node)
case .AnyProtocolConformanceList: return mangleAnyProtocolConformanceList(node)
case .ArgumentTuple: return mangleArgumentTuple(node)
case .AssociatedType: return mangleAssociatedType(node)
case .AssociatedTypeRef: return mangleAssociatedTypeRef(node)
case .AssociatedTypeMetadataAccessor: return mangleAssociatedTypeMetadataAccessor(node)
case .DefaultAssociatedTypeMetadataAccessor: return mangleDefaultAssociatedTypeMetadataAccessor(node)
case .AssociatedTypeWitnessTableAccessor: return mangleAssociatedTypeWitnessTableAccessor(node)
case .BaseWitnessTableAccessor: return mangleBaseWitnessTableAccessor(node)
case .AutoClosureType: return mangleAutoClosureType(node)
case .BoundGenericClass: return mangleBoundGenericClass(node)
case .BoundGenericEnum: return mangleBoundGenericEnum(node)
case .BoundGenericStructure: return mangleBoundGenericStructure(node)
case .BoundGenericProtocol: return mangleBoundGenericProtocol(node)
case .BoundGenericOtherNominalType: return mangleBoundGenericOtherNominalType(node)
case .BoundGenericTypeAlias: return mangleBoundGenericTypeAlias(node)
case .BoundGenericFunction: return mangleBoundGenericFunction(node)
case .BuiltinTypeName: return mangleBuiltinTypeName(node)
case .CFunctionPointer: return mangleCFunctionPointer(node)
case .Class: return mangleClass(node)
case .ClassMetadataBaseOffset: return mangleClassMetadataBaseOffset(node)
case .ConcreteProtocolConformance: return mangleConcreteProtocolConformance(node)
case .Constructor: return mangleConstructor(node)
case .CoroutineContinuationPrototype: return mangleCoroutineContinuationPrototype(node)
case .Deallocator: return mangleDeallocator(node)
case .DeclContext: return mangleDeclContext(node)
case .DefaultArgumentInitializer: return mangleDefaultArgumentInitializer(node)
case .DependentAssociatedConformance: return mangleDependentAssociatedConformance(node)
case .DependentAssociatedTypeRef: return mangleDependentAssociatedTypeRef(node)
case .DependentGenericConformanceRequirement: return mangleDependentGenericConformanceRequirement(node)
case .DependentGenericParamCount: return mangleDependentGenericParamCount(node)
case .DependentGenericParamType: return mangleDependentGenericParamType(node)
case .DependentGenericSameTypeRequirement: return mangleDependentGenericSameTypeRequirement(node)
case .DependentGenericLayoutRequirement: return mangleDependentGenericLayoutRequirement(node)
case .DependentGenericSignature: return mangleDependentGenericSignature(node)
case .DependentGenericType: return mangleDependentGenericType(node)
case .DependentMemberType: return mangleDependentMemberType(node)
case .DependentPseudogenericSignature: return mangleDependentPseudogenericSignature(node)
case .DependentProtocolConformanceRoot: return mangleDependentProtocolConformanceRoot(node)
case .DependentProtocolConformanceInherited: return mangleDependentProtocolConformanceInherited(node)
case .DependentProtocolConformanceAssociated: return mangleDependentProtocolConformanceAssociated(node)
case .Destructor: return mangleDestructor(node)
case .DidSet: return mangleDidSet(node)
case .Directness: return mangleDirectness(node)
case .DynamicAttribute: return mangleDynamicAttribute(node)
case .DirectMethodReferenceAttribute: return mangleDirectMethodReferenceAttribute(node)
case .DynamicSelf: return mangleDynamicSelf(node)
case .DynamicallyReplaceableFunctionImpl: return mangleDynamicallyReplaceableFunctionImpl(node)
case .DynamicallyReplaceableFunctionKey: return mangleDynamicallyReplaceableFunctionKey(node)
case .DynamicallyReplaceableFunctionVar: return mangleDynamicallyReplaceableFunctionVar(node)
case .Enum: return mangleEnum(node)
case .EnumCase: return mangleEnumCase(node)
case .ErrorType: return mangleErrorType(node)
case .EscapingAutoClosureType: return mangleEscapingAutoClosureType(node)
case .NoEscapeFunctionType: return mangleNoEscapeFunctionType(node)
case .ExistentialMetatype: return mangleExistentialMetatype(node)
case .ExplicitClosure: return mangleExplicitClosure(node)
case .Extension: return mangleExtension(node)
case .FieldOffset: return mangleFieldOffset(node)
case .FullTypeMetadata: return mangleFullTypeMetadata(node)
case .Function: return mangleFunction(node)
case .FunctionSignatureSpecialization: return mangleFunctionSignatureSpecialization(node)
case .FunctionSignatureSpecializationParam: return mangleFunctionSignatureSpecializationParam(node)
case .FunctionSignatureSpecializationReturn: return mangleFunctionSignatureSpecializationReturn(node)
case .FunctionSignatureSpecializationParamKind: return mangleFunctionSignatureSpecializationParamKind(node)
case .FunctionSignatureSpecializationParamPayload: return mangleFunctionSignatureSpecializationParamPayload(node)
case .FunctionType: return mangleFunctionType(node)
case .GenericPartialSpecialization: return mangleGenericPartialSpecialization(node)
case .GenericPartialSpecializationNotReAbstracted: return mangleGenericPartialSpecializationNotReAbstracted(node)
case .GenericProtocolWitnessTable: return mangleGenericProtocolWitnessTable(node)
case .GenericProtocolWitnessTableInstantiationFunction: return mangleGenericProtocolWitnessTableInstantiationFunction(node)
case .ResilientProtocolWitnessTable: return mangleResilientProtocolWitnessTable(node)
case .GenericSpecialization: return mangleGenericSpecialization(node)
case .GenericSpecializationNotReAbstracted: return mangleGenericSpecializationNotReAbstracted(node)
case .GenericSpecializationParam: return mangleGenericSpecializationParam(node)
case .InlinedGenericFunction: return mangleInlinedGenericFunction(node)
case .GenericTypeMetadataPattern: return mangleGenericTypeMetadataPattern(node)
case .Getter: return mangleGetter(node)
case .Global: return mangleGlobal(node)
case .GlobalGetter: return mangleGlobalGetter(node)
case .Identifier: return mangleIdentifier(node)
case .Index: return mangleIndex(node)
case .IVarInitializer: return mangleIVarInitializer(node)
case .IVarDestroyer: return mangleIVarDestroyer(node)
case .ImplEscaping: return mangleImplEscaping(node)
case .ImplConvention: return mangleImplConvention(node)
case .ImplFunctionAttribute: return mangleImplFunctionAttribute(node)
case .ImplFunctionType: return mangleImplFunctionType(node)
case .ImplicitClosure: return mangleImplicitClosure(node)
case .ImplParameter: return mangleImplParameter(node)
case .ImplResult: return mangleImplResult(node)
case .ImplErrorResult: return mangleImplErrorResult(node)
case .InOut: return mangleInOut(node)
case .InfixOperator: return mangleInfixOperator(node)
case .Initializer: return mangleInitializer(node)
case .KeyPathGetterThunkHelper: return mangleKeyPathGetterThunkHelper(node)
case .KeyPathSetterThunkHelper: return mangleKeyPathSetterThunkHelper(node)
case .KeyPathEqualsThunkHelper: return mangleKeyPathEqualsThunkHelper(node)
case .KeyPathHashThunkHelper: return mangleKeyPathHashThunkHelper(node)
case .LazyProtocolWitnessTableAccessor: return mangleLazyProtocolWitnessTableAccessor(node)
case .LazyProtocolWitnessTableCacheVariable: return mangleLazyProtocolWitnessTableCacheVariable(node)
case .LocalDeclName: return mangleLocalDeclName(node)
case .MaterializeForSet: return mangleMaterializeForSet(node)
case .MergedFunction: return mangleMergedFunction(node)
case .Metatype: return mangleMetatype(node)
case .MetatypeRepresentation: return mangleMetatypeRepresentation(node)
case .Metaclass: return mangleMetaclass(node)
case .MethodLookupFunction: return mangleMethodLookupFunction(node)
case .ObjCMetadataUpdateFunction: return mangleObjCMetadataUpdateFunction(node)
case .ObjCResilientClassStub: return mangleObjCResilientClassStub(node)
case .FullObjCResilientClassStub: return mangleFullObjCResilientClassStub(node)
case .ModifyAccessor: return mangleModifyAccessor(node)
case .Module: return mangleModule(node)
case .NativeOwningAddressor: return mangleNativeOwningAddressor(node)
case .NativeOwningMutableAddressor: return mangleNativeOwningMutableAddressor(node)
case .NativePinningAddressor: return mangleNativePinningAddressor(node)
case .NativePinningMutableAddressor: return mangleNativePinningMutableAddressor(node)
case .NominalTypeDescriptor: return mangleNominalTypeDescriptor(node)
case .NonObjCAttribute: return mangleNonObjCAttribute(node)
case .Number: return mangleNumber(node)
case .ObjCAttribute: return mangleObjCAttribute(node)
case .ObjCBlock: return mangleObjCBlock(node)
case .OtherNominalType: return mangleOtherNominalType(node)
case .OwningAddressor: return mangleOwningAddressor(node)
case .OwningMutableAddressor: return mangleOwningMutableAddressor(node)
case .PartialApplyForwarder: return manglePartialApplyForwarder(node)
case .PartialApplyObjCForwarder: return manglePartialApplyObjCForwarder(node)
case .PostfixOperator: return manglePostfixOperator(node)
case .PrefixOperator: return manglePrefixOperator(node)
case .PrivateDeclName: return manglePrivateDeclName(node)
case .PropertyDescriptor: return manglePropertyDescriptor(node)
case .Protocol: return mangleProtocol(node)
case .ProtocolSymbolicReference: return mangleProtocolSymbolicReference(node)
case .ProtocolConformance: return mangleProtocolConformance(node)
case .ProtocolConformanceRefInTypeModule: return mangleProtocolConformanceRefInTypeModule(node)
case .ProtocolConformanceRefInProtocolModule: return mangleProtocolConformanceRefInProtocolModule(node)
case .ProtocolConformanceRefInOtherModule: return mangleProtocolConformanceRefInOtherModule(node)
case .ProtocolDescriptor: return mangleProtocolDescriptor(node)
case .ProtocolConformanceDescriptor: return mangleProtocolConformanceDescriptor(node)
case .ProtocolList: return mangleProtocolList(node)
case .ProtocolListWithClass: return mangleProtocolListWithClass(node)
case .ProtocolListWithAnyObject: return mangleProtocolListWithAnyObject(node)
case .ProtocolSelfConformanceDescriptor: return mangleProtocolSelfConformanceDescriptor(node)
case .ProtocolSelfConformanceWitness: return mangleProtocolSelfConformanceWitness(node)
case .ProtocolSelfConformanceWitnessTable: return mangleProtocolSelfConformanceWitnessTable(node)
case .ProtocolWitness: return mangleProtocolWitness(node)
case .ProtocolWitnessTable: return mangleProtocolWitnessTable(node)
case .ProtocolWitnessTableAccessor: return mangleProtocolWitnessTableAccessor(node)
case .ProtocolWitnessTablePattern: return mangleProtocolWitnessTablePattern(node)
case .ReabstractionThunk: return mangleReabstractionThunk(node)
case .ReabstractionThunkHelper: return mangleReabstractionThunkHelper(node)
case .ReabstractionThunkHelperWithSelf: return mangleReabstractionThunkHelperWithSelf(node)
case .ReadAccessor: return mangleReadAccessor(node)
case .RelatedEntityDeclName: return mangleRelatedEntityDeclName(node)
case .RetroactiveConformance: return mangleRetroactiveConformance(node)
case .ReturnType: return mangleReturnType(node)
case .Shared: return mangleShared(node)
case .Owned: return mangleOwned(node)
case .SILBoxType: return mangleSILBoxType(node)
case .SILBoxTypeWithLayout: return mangleSILBoxTypeWithLayout(node)
case .SILBoxLayout: return mangleSILBoxLayout(node)
case .SILBoxMutableField: return mangleSILBoxMutableField(node)
case .SILBoxImmutableField: return mangleSILBoxImmutableField(node)
case .Setter: return mangleSetter(node)
case .SpecializationPassID: return mangleSpecializationPassID(node)
case .IsSerialized: return mangleIsSerialized(node)
case .Static: return mangleStatic(node)
case .Structure: return mangleStructure(node)
case .Subscript: return mangleSubscript(node)
case .Suffix: return mangleSuffix(node)
case .ThinFunctionType: return mangleThinFunctionType(node)
case .Tuple: return mangleTuple(node)
case .TupleElement: return mangleTupleElement(node)
case .TupleElementName: return mangleTupleElementName(node)
case .Type: return mangleType(node)
case .TypeSymbolicReference: return mangleTypeSymbolicReference(node)
case .TypeAlias: return mangleTypeAlias(node)
case .TypeList: return mangleTypeList(node)
case .TypeMangling: return mangleTypeMangling(node)
case .TypeMetadata: return mangleTypeMetadata(node)
case .TypeMetadataAccessFunction: return mangleTypeMetadataAccessFunction(node)
case .TypeMetadataCompletionFunction: return mangleTypeMetadataCompletionFunction(node)
case .TypeMetadataInstantiationCache: return mangleTypeMetadataInstantiationCache(node)
case .TypeMetadataInstantiationFunction: return mangleTypeMetadataInstantiationFunction(node)
case .TypeMetadataSingletonInitializationCache: return mangleTypeMetadataSingletonInitializationCache(node)
case .TypeMetadataLazyCache: return mangleTypeMetadataLazyCache(node)
case .UncurriedFunctionType: return mangleUncurriedFunctionType(node)
case .UnknownIndex: return mangleUnknownIndex(node)
case .Weak: return mangleWeak(node)
case .Unowned: return mangleUnowned(node)
case .Unmanaged: return mangleUnmanaged(node)
case .UnsafeAddressor: return mangleUnsafeAddressor(node)
case .UnsafeMutableAddressor: return mangleUnsafeMutableAddressor(node)
case .ValueWitness: return mangleValueWitness(node)
case .ValueWitnessTable: return mangleValueWitnessTable(node)
case .Variable: return mangleVariable(node)
case .VTableThunk: return mangleVTableThunk(node)
case .VTableAttribute: return mangleVTableAttribute(node)
case .WillSet: return mangleWillSet(node)
case .ReflectionMetadataBuiltinDescriptor: return mangleReflectionMetadataBuiltinDescriptor(node)
case .ReflectionMetadataFieldDescriptor: return mangleReflectionMetadataFieldDescriptor(node)
case .ReflectionMetadataAssocTypeDescriptor: return mangleReflectionMetadataAssocTypeDescriptor(node)
case .ReflectionMetadataSuperclassDescriptor: return mangleReflectionMetadataSuperclassDescriptor(node)
case .GenericTypeParamDecl: return mangleGenericTypeParamDecl(node)
case .CurryThunk: return mangleCurryThunk(node)
case .DispatchThunk: return mangleDispatchThunk(node)
case .MethodDescriptor: return mangleMethodDescriptor(node)
case .ProtocolRequirementsBaseDescriptor: return mangleProtocolRequirementsBaseDescriptor(node)
case .AssociatedConformanceDescriptor: return mangleAssociatedConformanceDescriptor(node)
case .DefaultAssociatedConformanceAccessor: return mangleDefaultAssociatedConformanceAccessor(node)
case .BaseConformanceDescriptor: return mangleBaseConformanceDescriptor(node)
case .AssociatedTypeDescriptor: return mangleAssociatedTypeDescriptor(node)
case .ThrowsAnnotation: return mangleThrowsAnnotation(node)
case .EmptyList: return mangleEmptyList(node)
case .FirstElementMarker: return mangleFirstElementMarker(node)
case .VariadicMarker: return mangleVariadicMarker(node)
case .OutlinedBridgedMethod: return mangleOutlinedBridgedMethod(node)
case .OutlinedCopy: return mangleOutlinedCopy(node)
case .OutlinedConsume: return mangleOutlinedConsume(node)
case .OutlinedRetain: return mangleOutlinedRetain(node)
case .OutlinedRelease: return mangleOutlinedRelease(node)
case .OutlinedInitializeWithTake: return mangleOutlinedInitializeWithTake(node)
case .OutlinedInitializeWithCopy: return mangleOutlinedInitializeWithCopy(node)
case .OutlinedAssignWithTake: return mangleOutlinedAssignWithTake(node)
case .OutlinedAssignWithCopy: return mangleOutlinedAssignWithCopy(node)
case .OutlinedDestroy: return mangleOutlinedDestroy(node)
case .OutlinedVariable: return mangleOutlinedVariable(node)
case .AssocTypePath: return mangleAssocTypePath(node)
case .LabelList: return mangleLabelList(node)
case .ModuleDescriptor: return mangleModuleDescriptor(node)
case .ExtensionDescriptor: return mangleExtensionDescriptor(node)
case .AnonymousDescriptor: return mangleAnonymousDescriptor(node)
case .AssociatedTypeGenericParamRef: return mangleAssociatedTypeGenericParamRef(node)
case .SugaredOptional: return mangleSugaredOptional(node)
case .SugaredArray: return mangleSugaredArray(node)
case .SugaredDictionary: return mangleSugaredDictionary(node)
case .SugaredParen: return mangleSugaredParen(node)
case .AccessorFunctionReference: return mangleAccessorFunctionReference(node)
case .OpaqueType: return mangleOpaqueType(node)
case .OpaqueTypeDescriptorSymbolicReference: return mangleOpaqueTypeDescriptorSymbolicReference(node)
case .OpaqueTypeDescriptor: return mangleOpaqueTypeDescriptor(node)
case .OpaqueTypeDescriptorAccessor: return mangleOpaqueTypeDescriptorAccessor(node)
case .OpaqueTypeDescriptorAccessorImpl: return mangleOpaqueTypeDescriptorAccessorImpl(node)
case .OpaqueTypeDescriptorAccessorKey: return mangleOpaqueTypeDescriptorAccessorKey(node)
case .OpaqueTypeDescriptorAccessorVar: return mangleOpaqueTypeDescriptorAccessorVar(node)
case .OpaqueReturnType: return mangleOpaqueReturnType(node)
case .OpaqueReturnTypeOf: return mangleOpaqueReturnTypeOf(node)
case .AllocateBuffer: Code = "al"
case .AssignWithCopy: Code = "ca"
case .AssignWithTake: Code = "ta"
case .DeallocateBuffer: Code = "de"
case .Destroy: Code = "xx"
case .DestroyBuffer: Code = "XX"
case .DestroyArray: Code = "Xx"
case .InitializeBufferWithCopyOfBuffer: Code = "CP"
case .InitializeBufferWithCopy: Code = "Cp"
case .InitializeWithCopy: Code = "cp"
case .InitializeBufferWithTake: Code = "Tk"
case .InitializeWithTake: Code = "tk"
case .ProjectBuffer: Code = "pr"
case .InitializeBufferWithTakeOfBuffer: Code = "TK"
case .InitializeArrayWithCopy: Code = "Cc"
case .InitializeArrayWithTakeFrontToBack: Code = "Tt"
case .InitializeArrayWithTakeBackToFront: Code = "tT"
case .StoreExtraInhabitant: Code = "xs"
case .GetExtraInhabitantIndex: Code = "xg"
case .GetEnumTag: Code = "ug"
case .DestructiveProjectEnumData: Code = "up"
case .DestructiveInjectEnumTag: Code = "ui"
case .GetEnumTagSinglePayload: Code = "et"
case .StoreEnumTagSinglePayload: Code = "st"
