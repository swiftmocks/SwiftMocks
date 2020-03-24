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

public enum Mangle {
    public static func mangledNameLength(_ mangledName: ConstRawPointer) -> Int {
        let start = mangledName.reinterpret(UInt8.self)
        var end = start
        while end.pointee != 0 {
            // Skip over symbolic references.
            if end.pointee >= 0x1 && end.pointee <= 0x17 {
                end += MemoryLayout<UInt32>.size
            } else if end.pointee >= 0x18 && end.pointee <= 0x1F {
                end += MemoryLayout<RawPointer>.size
            }
            end += 1
        }
        return end - start
    }

    public static func demangleSymbol(mangledName: String) throws -> Node {
        try mangledName.withCString { pointer -> Node in
            try demangleSymbol(mangledName: pointer)
        }
    }

    public static func demangleSymbol(mangledName: ConstPointer<CChar>, length: Int? = nil) throws -> Node {
        let length = length ?? mangledNameLength(mangledName.raw)
        var demangler = Demangler(mangledName: mangledName, length: length)
        return try demangler.demangleSymbol()
    }

    public static func demangleType(mangledName: String) throws -> Node {
        try mangledName.withCString { pointer -> Node in
            do {
                return try demangleType(mangledName: pointer)
            } catch {
                throw error
            }
        }
    }

    public static func demangleType(mangledName: ConstPointer<CChar>, length: Int? = nil) throws -> Node {
        let length = length ?? mangledNameLength(mangledName.raw)
        var demangler = Demangler(mangledName: mangledName, length: length)
        demangler.symbolicReferenceResolver = { kind, direct, pointer -> Node in
            var pointer = pointer
            if direct == .Indirect {
                pointer = pointer.reinterpret(ConstRawPointer.self).pointee
            }
            switch kind {
            case .Context:
                let descriptor = ContextDescriptor.from(RawPointer(mutating: pointer))
                return try buildDemanglingForContext(contextDescriptor: descriptor, demangledGenerics: [])
            case .AccessorFunctionReference:
                // Save the pointer to the accessor function. We can't demangle it any further as AST, but the consumer of the demangle tree may be able to invoke the function to resolve the thing they're trying to access.
                return Node(kind: .AccessorFunctionReference, payload: .Index(UInt64(UInt(bitPattern: pointer))))
            }
        }
        return try demangler.demangleType()
    }

    public typealias SymbolicResolver = (SymbolicReferenceKind, UnsafeRawPointer) -> Node

    public static func mangle(node: Node?, resolver: @escaping SymbolicResolver) -> String {
        guard let node = node else { return "" }

        let remangler = Remangler(resolver: resolver)
        remangler.mangle(node)

        return remangler.buffer
    }

    /// Mangle a node tree which is known to not contain symbolic references. If a symbolic reference is found, a `fatalError()` will be invoked.
    public static func mangleNode(node: Node) -> String {
        return mangle(node: node) { (kind: SymbolicReferenceKind, pointer: UnsafeRawPointer) -> Node in
            fatalError("should not try to mangle a symbolic reference; resolve it to a non-symbolic demangling tree instead")
        }
    }

    public static func buildDemanglingForContext(contextDescriptor context: ContextDescriptor, demangledGenerics: [Node]) throws -> Node {
        var usedDemangledGenerics = 0
        var descriptorPath = [ContextDescriptor]()
        var parent: ContextDescriptor? = context
        // Walk up the context tree.
        while let p = parent {
            descriptorPath.append(p)
            parent = p.parent
        }

        func getGenericArgsTypeListForContext(contextDescriptor context: ContextDescriptor) throws -> Node? {
            if demangledGenerics.isEmpty {
                return nil
            }

            if context.kind == .anonymous {
                return nil
            }

            guard let generics = context as? GenericContext else {
                return nil
            }

            let numberOfParameters = generics.numberOfGenericParameters
            if numberOfParameters <= usedDemangledGenerics {
                return nil
            }

            var genericArgsList = Node(kind: .TypeList)
            while usedDemangledGenerics < numberOfParameters {
                genericArgsList.children.append(demangledGenerics[usedDemangledGenerics])
                usedDemangledGenerics += 1
            }

            return genericArgsList
        }

        var node: Node!
        for component in descriptorPath.reversed() {
            switch component {
            case let module as ModuleContextDescriptor:
                assert(node == nil, "module should be top level")
                let name = module.name
                node = Node(kind: .Module, payload: .Text(name))

            case let ext as ExtensionContextDescriptor:
                guard let mangledExtendedContextTypeName = ext.mangledExtendedContextTypeName else {
                    throw DemanglingError.unexpected("mangled name for an extension is nil")
                }
                var selfType = try Mangle.demangleType(mangledName: mangledExtendedContextTypeName)
                if selfType.kind == .Type {
                    selfType = selfType.children[0]
                }

                // Substitute in the generic arguments.
                let genericArgsList = try getGenericArgsTypeListForContext(contextDescriptor: component)

                if selfType.kind == .BoundGenericEnum || selfType.kind == .BoundGenericStructure || selfType.kind == .BoundGenericClass || selfType.kind == .BoundGenericOtherNominalType {
                    if let genericArgsList = genericArgsList {
                        var substSelfType = Node(kind: selfType.kind)
                        substSelfType.children.append(selfType.children[0])
                        substSelfType.children.append(genericArgsList)
                        selfType = substSelfType
                    } else {
                        selfType = selfType.children[0].children[0]
                    }
                }

                var extNode = Node(kind: .Extension)
                extNode.children.append(node)
                extNode.children.append(selfType)

                node = extNode
            case let proto as ProtocolDescriptor:
                let protocolNode = Node(kind: .Protocol, children: [node, Node(kind: .Identifier, payload: .Text(proto.name))], payload: .None)
                return Node(kind: .Type, child: protocolNode)

            default:
                // Form a type context demangling for type contexts.
                if let type = component as? TypeContextDescriptor {
                    let nodeKind: Node.Kind
                    let genericNodeKind: Node.Kind
                    switch type.kind {
                    case .class:
                        nodeKind = .Class
                        genericNodeKind = .BoundGenericClass
                    case .struct:
                        nodeKind = .Structure;
                        genericNodeKind = .BoundGenericStructure
                    case .enum:
                        nodeKind = .Enum
                        genericNodeKind = .BoundGenericEnum
                    default:
                        // We don't know about this kind of type. Use an "other type" mangling for it.
                        nodeKind = .OtherNominalType
                        genericNodeKind = .BoundGenericOtherNominalType
                    }

                    // Override the node kind if this is a Clang-imported type so we give it a stable mangling.
                    // TODO:
                    //  auto identity = ParsedTypeIdentity::parse(type);
                    //  if (identity.isCTypedef()) {
                    //    nodeKind = Node::Kind::TypeAlias;
                    //  } else if (nodeKind != Node::Kind::Structure &&
                    //             _isCImportedTagType(type, identity)) {
                    //    nodeKind = Node::Kind::Structure;
                    //  }

                    var typeNode = Node(kind: nodeKind)
                    typeNode.children.append(node)
                    let nameNode = Node(kind: .Identifier, payload: .Text(type.name) /* identity.getABIName() */)
                    //  if (identity.isAnyRelatedEntity()) {
                    //    auto kindNode = Dem.createNode(Node::Kind::Identifier,
                    //                               identity.getRelatedEntityName());
                    //    auto relatedName = Dem.createNode(Node::Kind::RelatedEntityDeclName);
                    //    relatedName->addChild(kindNode, Dem);
                    //    relatedName->addChild(nameNode, Dem);
                    //    nameNode = relatedName;
                    //  }
                    typeNode.children.append(nameNode)
                    node = typeNode

                    // Apply generic arguments if the context is generic.
                    if let genericArgsList = try getGenericArgsTypeListForContext(contextDescriptor: component) {
                        let unspecializedType = Node(kind: .Type, child: node)

                        var genericNode = Node(kind: genericNodeKind)
                        genericNode.children.append(unspecializedType)
                        genericNode.children.append(genericArgsList)
                        node = genericNode
                    }

                    break
                }

                // This runtime doesn't understand this context, or it's a context with no richer runtime information available about it (such as an anonymous context). Use an unstable mangling to represent the context by its pointer identity.
                let address = String(format: "$%llx", UInt(bitPattern: component.pointer))

                var anonNode = Node(kind: .AnonymousContext)
                let name = Node(kind: .Identifier, payload: .Text(address))
                anonNode.children.append(name)
                anonNode.children.append(node)

                // Collect generic arguments if the context is generic.
                if let genericArgsList = try getGenericArgsTypeListForContext(contextDescriptor: component) {
                    anonNode.children.append(genericArgsList)
                } else {
                    anonNode.children.append(Node(kind: .TypeList))
                }

                node = anonNode
            }
        }

        let top = Node(kind: .Type, child: node)
        return top
    }

    private enum DemanglingError: LocalizedError {
        case unexpected(String)
        case notImplemented(String)

        var errorDescription: String? {
            switch self {
            case let .unexpected(reason), let .notImplemented(reason):
                return "\(Self.self).\(self): \(reason)"
            }
        }
    }
}

public struct Node: Equatable {
    public typealias IndexType = UInt64

    public var kind: Kind
    public var payload: PayloadKind
    public var children: [Node]

    public enum PayloadKind: Equatable {
        case None
        case Text(String)
        case Index(IndexType)
    }

    public init(kind: Kind, children: [Node] = [], payload: PayloadKind = .None) {
        self.kind = kind
        self.children = children
        self.payload = payload
    }

    public enum Kind: UInt16 {
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
        case `Protocol`
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
        case `Type`
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
}

/// Kinds of symbolic reference supported.
public enum SymbolicReferenceKind: UInt8 {
    /// A symbolic reference to a context descriptor, representing the (unapplied generic) context.
    case Context
    /// A symbolic reference to an accessor function, which can be executed in the process to get a pointer to the referenced entity.
    case AccessorFunctionReference
}

public enum FunctionSigSpecializationParamKind : UInt64 {
    // Option Flags use bits 0-5. This give us 6 bits implying 64 entries to work with.
    case ConstantPropFunction = 0
    case ConstantPropGlobal = 1
    case ConstantPropInteger = 2
    case ConstantPropFloat = 3
    case ConstantPropString = 4
    case ClosureProp = 5
    case BoxToValue = 6
    case BoxToStack = 7

    // Option Set Flags use bits 6-31. This gives us 26 bits to use for option flags.
    case Dead = 64
    case OwnedToGuaranteed = 128
    case SROA = 256
    case GuaranteedToOwned = 512
    case ExistentialToGeneric = 1024
}

/// The pass that caused the specialization to occur. We use this to make sure that two passes that generate similar changes do not yield the same mangling. This currently cannot happen, so this is just a safety measure that creates separate name spaces.
public enum SpecializationPass : UInt8 {
    case AllocBoxToStack
    case ClosureSpecializer
    case CapturePromotion
    case CapturePropagation
    case FunctionSignatureOpts
    case GenericSpecializer
}

public enum ValueWitnessKind: UInt64, CustomStringConvertible {
    case allocateBuffer = 0
    case assignWithCopy = 1
    case assignWithTake = 2
    case deallocateBuffer = 3
    case destroy = 4
    case destroyArray = 5
    case destroyBuffer = 6
    case initializeBufferWithCopyOfBuffer = 7
    case initializeBufferWithCopy = 8
    case initializeWithCopy = 9
    case initializeBufferWithTake = 10
    case initializeWithTake = 11
    case projectBuffer = 12
    case initializeBufferWithTakeOfBuffer = 13
    case initializeArrayWithCopy = 14
    case initializeArrayWithTakeFrontToBack = 15
    case initializeArrayWithTakeBackToFront = 16
    case storeExtraInhabitant = 17
    case getExtraInhabitantIndex = 18
    case getEnumTag = 19
    case destructiveProjectEnumData = 20
    case destructiveInjectEnumTag = 21
    case getEnumTagSinglePayload = 22
    case storeEnumTagSinglePayload = 23

    public init?(code: String) {
        switch code {
        case "al": self = .allocateBuffer
        case "ca": self = .assignWithCopy
        case "ta": self = .assignWithTake
        case "de": self = .deallocateBuffer
        case "xx": self = .destroy
        case "XX": self = .destroyBuffer
        case "Xx": self = .destroyArray
        case "CP": self = .initializeBufferWithCopyOfBuffer
        case "Cp": self = .initializeBufferWithCopy
        case "cp": self = .initializeWithCopy
        case "Tk": self = .initializeBufferWithTake
        case "tk": self = .initializeWithTake
        case "pr": self = .projectBuffer
        case "TK": self = .initializeBufferWithTakeOfBuffer
        case "Cc": self = .initializeArrayWithCopy
        case "Tt": self = .initializeArrayWithTakeFrontToBack
        case "tT": self = .initializeArrayWithTakeBackToFront
        case "xs": self = .storeExtraInhabitant
        case "xg": self = .getExtraInhabitantIndex
        case "ug": self = .getEnumTag
        case "up": self = .destructiveProjectEnumData
        case "ui": self = .destructiveInjectEnumTag
        case "et": self = .getEnumTagSinglePayload
        case "st": self = .storeEnumTagSinglePayload
        default: return nil
        }
    }

    public var description: String {
        switch self {
        case .allocateBuffer: return "allocateBuffer"
        case .assignWithCopy: return "assignWithCopy"
        case .assignWithTake: return "assignWithTake"
        case .deallocateBuffer: return "deallocateBuffer"
        case .destroy: return "destroy"
        case .destroyBuffer: return "destroyBuffer"
        case .initializeBufferWithCopyOfBuffer: return "initializeBufferWithCopyOfBuffer"
        case .initializeBufferWithCopy: return "initializeBufferWithCopy"
        case .initializeWithCopy: return "initializeWithCopy"
        case .initializeBufferWithTake: return "initializeBufferWithTake"
        case .initializeWithTake: return "initializeWithTake"
        case .projectBuffer: return "projectBuffer"
        case .initializeBufferWithTakeOfBuffer: return "initializeBufferWithTakeOfBuffer"
        case .destroyArray: return "destroyArray"
        case .initializeArrayWithCopy: return "initializeArrayWithCopy"
        case .initializeArrayWithTakeFrontToBack: return "initializeArrayWithTakeFrontToBack"
        case .initializeArrayWithTakeBackToFront: return "initializeArrayWithTakeBackToFront"
        case .storeExtraInhabitant: return "storeExtraInhabitant"
        case .getExtraInhabitantIndex: return "getExtraInhabitantIndex"
        case .getEnumTag: return "getEnumTag"
        case .destructiveProjectEnumData: return "destructiveProjectEnumData"
        case .destructiveInjectEnumTag: return "destructiveInjectEnumTag"
        case .getEnumTagSinglePayload: return "getEnumTagSinglePayload"
        case .storeEnumTagSinglePayload: return "storeEnumTagSinglePayload"
        }
    }
}

public enum Directness: UInt64, CustomStringConvertible {
    case Direct
    case Indirect

    public var description: String {
        switch self {
        case .Direct: return "direct"
        case .Indirect: return "indirect"
        }
    }
}

extension Node: CustomStringConvertible {
    /// Returns the description of the receiver matching `xcrun swift-demangle` output format
    public var description: String {
        var printer = NodePrinter(options: .default)
        return (try? printer.printRoot(self)) ?? "<invalid node tree>"
    }
}

extension Node: CustomDebugStringConvertible {
    /// Returns the description of the receiver matching `xcrun swift-demangle -tree-only` output format
    public var debugDescription: String {
        var result = "kind=\(kind)"

        switch payload {
        case let .Index(index): result += ", index=\"\(index)\""
        case let .Text(text): result += ", text=\"\(text)\""
        case .None: break
        }

        result += "\n" + children.map { $0.debugDescription.shiftingRight(by: 2) }.joined(separator: "\n")
        return result
    }
}
