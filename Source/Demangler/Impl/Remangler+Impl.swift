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

extension Remangler {
    func mangleImpl(_ node: Node) {
        // see generators
        switch node.kind {
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
        }
    }
}

extension Remangler {
    func getSingleChild(of node: Node) -> Node {
        precondition(node.children.count == 1)
        return node.children[0]
    }

    func getSingleChild(of node: Node, kind: Node.Kind) -> Node {
        let child = getSingleChild(of: node)
        precondition(child.kind == kind)
        return child
    }

    func skipType(_ node: Node) -> Node {
        if node.kind == .Type {
            return getSingleChild(of: node)
        }
        return node
    }

    func getChildOfType(_ node: Node) -> Node {
        precondition(node.kind == .Type)
        return getSingleChild(of: node)
    }

    func mangleIndex(_ value: Node.IndexType) {
        if value == 0 {
            buffer << "_"
        } else {
            buffer << (value - 1)
            buffer << "_"
        }
    }

    func mangleDependentConformanceIndex(_ node: Node) {
        precondition(node.kind == .Index || node.kind == .UnknownIndex)
        precondition(node.hasIndex == (node.kind == .Index))
        mangleIndex(node.hasIndex ? node.index + 2 : 1)
    }

    func mangleChildNodes(_ node: Node) {
        mangleNodes(nodes: node.children)
    }

    func mangleChildNodesReversed(_ node: Node) {
        for index in (0..<node.children.count).reversed() {
            mangleChildNode(node, index: index)
        }
    }

    func mangleListSeparator(isFirstListItem: inout Bool) {
        if isFirstListItem {
            buffer << "_"
            isFirstListItem = false
        }
    }

    func mangleEndOfList(isFirstListItem: Bool) {
        if isFirstListItem {
            buffer << "y"
        }
    }

    func mangleNodes(nodes: [Node]) {
        for node in nodes {
            mangle(node)
        }
    }

    func mangleSingleChildNode(_ node: Node) {
        mangle(getSingleChild(of: node))
    }

    func mangleChildNode(_ node: Node, index: Int) {
        mangle(node.children[index])
    }

    func manglePureProtocol(_ proto: Node) {
        let proto = skipType(proto)
        if mangleStandardSubstitution(proto) {
            return
        }
        mangleChildNodes(proto)
    }

    func mangleIdentifierImpl(_ node: Node, isOperator: Bool) {
        var entry: SubstitutionEntry?
        if trySubstitution(node, entry: &entry, treatAsIdentifier: true) { return }
        if (isOperator) {
            SwiftMocks.mangle(identifier: node.text.translatingOperators, buffer: &buffer, words: &words)
        } else {
            SwiftMocks.mangle(identifier: node.text, buffer: &buffer, words: &words)
        }
        addSubstitution(entry: entry!)
    }

    func mangleStandardSubstitution(_ node: Node) -> Bool {
        if node.kind != .Structure && node.kind != .Enum && node.kind != .Protocol {
            return false
        }

        let context = node.children[0]
        if context.kind != .Module || context.text != STDLIB_NAME {
            return false
        }

        // Ignore private stdlib names
        if node.children[1].kind != .Identifier {
            return false
        }

        if let subst = getStandardTypeSubst(typeName: node.children[1].text) {
            if (!substMerging.tryMergeSubst(subst: subst, /*isStandardSubst*/ isStandardSubst: true, buffer: &buffer)) {
                buffer << "S"
                buffer << subst
            }
            return true
        }
        return false
    }

    func mangleDependentGenericParamIndex(_ node: Node, nonZeroPrefix: String = "", zeroOp: UnicodeScalar = "z") {
        let depth = node.children[0].index
        let index = node.children[1].index

        if depth != 0 {
            buffer << nonZeroPrefix
            buffer << "d"
            mangleIndex(depth - 1)
            mangleIndex(index)
            return
        }
        if (index != 0) {
            buffer << nonZeroPrefix
            mangleIndex(index - 1)
            return
        }
        // depth == index == 0
        buffer << zeroOp
    }

    func mangleConstrainedType(_ node: Node) -> (Int, Node?) {
        var node = node
        if node.kind == .Type {
            node = getChildOfType(node)
        }

        var entry: SubstitutionEntry?
        if trySubstitution(node, entry: &entry) {
            return (-1, nil)
        }

        var chain = [Node]()
        while node.kind == .DependentMemberType {
            chain.append(node.children[1])
            node = getChildOfType(node.children[0])
        }
        precondition(node.kind == .DependentGenericParamType)

        var listSeparator = chain.count > 1 ? "_" : ""
        let n: Int = chain.count
        if !chain.isEmpty {
            for i in 1...n {
                let depAssocTyRef = chain[n - i]
                mangle(depAssocTyRef)
                buffer << listSeparator
                listSeparator = ""
            }
        }
        if !chain.isEmpty {
            addSubstitution(entry: entry!)
        }
        return (chain.count, node)
    }

    func mangleFunctionSignature(_ funcType: Node) {
        mangleChildNodesReversed(funcType)
    }

    func mangleAnyNominalType(_ node: Node) {
        if (node.isSpecialized) {
            var entry: SubstitutionEntry?
            if trySubstitution(node, entry: &entry) {
                return
            }

            let unboundType = node.getUnspecialized()
            mangleAnyNominalType(unboundType)
            var Separator = "y"
            mangleGenericArgs(node, separator: &Separator)

            if node.children.count == 3 {
                // Retroactive conformances.
                let listNode = node.children[2]
                for Idx in 0..<listNode.children.count {
                    mangle(listNode.children[Idx])
                }
            }

            buffer << "G"
            addSubstitution(entry: entry!)
            return
        }
        switch node.kind {
        case .Structure: return mangleAnyGenericType(node, typeOp: "V")
        case .Enum: return mangleAnyGenericType(node, typeOp: "O")
        case .Class: return mangleAnyGenericType(node, typeOp: "C")
        case .OtherNominalType: return mangleAnyGenericType(node, typeOp: "XY")
        case .TypeAlias: return mangleAnyGenericType(node, typeOp: "a")
        default:
            unreachable("bad nominal type kind")
        }
    }

    func mangleAnyGenericType(_ node: Node, typeOp: String) {
        var entry: SubstitutionEntry?
        if trySubstitution(node, entry: &entry) { return }
        mangleChildNodes(node)
        buffer << typeOp
        addSubstitution(entry: entry!)
    }

    func mangleGenericArgs(_ node: Node, separator: inout String, fullSubstitutionMap: Bool = false) {
        var fullSubstitutionMap = fullSubstitutionMap
        switch node.kind {
        case .Structure: fallthrough
        case .Enum: fallthrough
        case .Class: fallthrough
        case .TypeAlias:
            if node.kind == .TypeAlias {
                fullSubstitutionMap = true
            }

            mangleGenericArgs(node.children[0], separator: &separator, fullSubstitutionMap: fullSubstitutionMap)
            buffer << separator
            separator = "_"
            break

        case .Function: fallthrough
        case .Getter: fallthrough
        case .Setter: fallthrough
        case .WillSet: fallthrough
        case .DidSet: fallthrough
        case .ReadAccessor: fallthrough
        case .ModifyAccessor: fallthrough
        case .UnsafeAddressor: fallthrough
        case .UnsafeMutableAddressor: fallthrough
        case .Allocator: fallthrough
        case .Constructor: fallthrough
        case .Destructor: fallthrough
        case .Variable: fallthrough
        case .Subscript: fallthrough
        case .ExplicitClosure: fallthrough
        case .ImplicitClosure: fallthrough
        case .DefaultArgumentInitializer: fallthrough
        case .Initializer:
            if !fullSubstitutionMap {
                break
            }

            mangleGenericArgs(node.children[0], separator: &separator, fullSubstitutionMap: fullSubstitutionMap)
            if nodeConsumesGenericArgs(node: node) {
                buffer << separator
                separator = "_"
            }

        case .BoundGenericOtherNominalType: fallthrough
        case .BoundGenericStructure: fallthrough
        case .BoundGenericEnum: fallthrough
        case .BoundGenericClass: fallthrough
        case .BoundGenericProtocol: fallthrough
        case .BoundGenericTypeAlias:
            if node.kind == .BoundGenericTypeAlias {
                fullSubstitutionMap = true
            }

            let unboundType = node.children[0]
            precondition(unboundType.kind == .Type)
            let nominalType = unboundType.children[0]
            let parentOrModule = nominalType.children[0]
            mangleGenericArgs(parentOrModule, separator: &separator, fullSubstitutionMap: fullSubstitutionMap)
            buffer << separator
            separator = "_"
            mangleChildNodes(node.children[1])

        case .BoundGenericFunction:
            fullSubstitutionMap = true

            let unboundFunction = node.children[0]
            precondition(unboundFunction.kind == .Function || unboundFunction.kind == .Constructor)
            let parentOrModule = unboundFunction.children[0]
            mangleGenericArgs(parentOrModule, separator: &separator, fullSubstitutionMap: fullSubstitutionMap)
            buffer << separator
            separator = "_"
            mangleChildNodes(node.children[1])

        case .Extension:
            mangleGenericArgs(node.children[1], separator: &separator, fullSubstitutionMap: fullSubstitutionMap)
            break

        default:
            break
        }
    }

    func mangleAnyConstructor(_ node: Node, kindOp: String) {
        mangleChildNodes(node)
        buffer << "f"
        buffer << kindOp
    }

    func mangleAbstractStorage(_ node: Node, accessorCode: String) {
        mangleChildNodes(node)
        switch node.kind {
        case .Subscript: buffer << "i"
        case .Variable: buffer << "v"
        default: unreachable("Not a storage node")
        }
        buffer << accessorCode
    }

    func mangleAnyProtocolConformance(_ node: Node) {
        switch node.kind {
        case .ConcreteProtocolConformance:
            return mangleConcreteProtocolConformance(node)
        case .DependentProtocolConformanceRoot:
            return mangleDependentProtocolConformanceRoot(node)
        case .DependentProtocolConformanceInherited:
            return mangleDependentProtocolConformanceInherited(node)
        case .DependentProtocolConformanceAssociated:
            return mangleDependentProtocolConformanceAssociated(node)
        default:
            break
        }
    }

    func mangleAllocator(_ node: Node) {
        mangleAnyConstructor(node, kindOp: "C")
    }

    func mangleArgumentTuple(_ node: Node) {
        let Child = skipType(getSingleChild(of: node))
        if (Child.kind == .Tuple && Child.children.count == 0) {
            buffer << "y"
            return
        }
        mangle(Child)
    }

    func mangleAssociatedType(_ node: Node) {
        unreachable("unsupported node")
    }

    func mangleAssociatedTypeRef(_ node: Node) {
        var entry: SubstitutionEntry?
        if trySubstitution(node, entry: &entry) { return }
        mangleChildNodes(node)
        buffer << "Qa"
        addSubstitution(entry: entry!)
    }

    func mangleAssociatedTypeDescriptor(_ node: Node) {
        mangleChildNodes(node)
        buffer << "Tl"
    }

    func mangleAssociatedConformanceDescriptor(_ node: Node) {
        mangle(node.children[0])
        mangle(node.children[1])
        manglePureProtocol(node.children[2])
        buffer << "Tn"
    }

    func mangleDefaultAssociatedConformanceAccessor(_ node: Node) {
        mangle(node.children[0])
        mangle(node.children[1])
        manglePureProtocol(node.children[2])
        buffer << "TN"
    }

    func mangleBaseConformanceDescriptor(_ node: Node) {
        mangle(node.children[0])
        manglePureProtocol(node.children[1])
        buffer << "Tb"
    }

    func mangleAssociatedTypeMetadataAccessor(_ node: Node) {
        mangleChildNodes(node) // protocol conformance, identifier
        buffer << "Wt"
    }

    func mangleDefaultAssociatedTypeMetadataAccessor(_ node: Node) {
        mangleChildNodes(node) // protocol conformance, identifier
        buffer << "TM"
    }

    func mangleAssociatedTypeWitnessTableAccessor(_ node: Node) {
        mangleChildNodes(node) // protocol conformance, type, protocol
        buffer << "WT"
    }

    func mangleBaseWitnessTableAccessor(_ node: Node) {
        mangleChildNodes(node) // protocol conformance, protocol
        buffer << "Wb"
    }

    func mangleAutoClosureType(_ node: Node) {
        mangleChildNodesReversed(node) // argument tuple, result type
        buffer << "XK"
    }

    func mangleEscapingAutoClosureType(_ node: Node) {
        mangleChildNodesReversed(node) // argument tuple, result type
        buffer << "XA"
    }

    func mangleNoEscapeFunctionType(_ node: Node) {
        mangleChildNodesReversed(node) // argument tuple, result type
        buffer << "XE"
    }

    func mangleBoundGenericClass(_ node: Node) {
        mangleAnyNominalType(node)
    }

    func mangleBoundGenericEnum(_ node: Node) {
        let Enum = node.children[0].children[0]
        precondition(Enum.kind == .Enum)
        let mod = Enum.children[0]
        let id = Enum.children[1]
        if mod.kind == .Module && mod.text == STDLIB_NAME && id.kind == .Identifier && id.text == "Optional" {
            var entry: SubstitutionEntry?
            if trySubstitution(node, entry: &entry) {
                return
            }
            mangleSingleChildNode(node.children[1])
            buffer << "Sg"
            addSubstitution(entry: entry!)
            return
        }
        mangleAnyNominalType(node)
    }

    func mangleBoundGenericStructure(_ node: Node) {
        mangleAnyNominalType(node)
    }

    func mangleBoundGenericOtherNominalType(_ node: Node) {
        mangleAnyNominalType(node)
    }

    func mangleBoundGenericProtocol(_ node: Node) {
        mangleAnyNominalType(node)
    }

    func mangleBoundGenericTypeAlias(_ node: Node) {
        mangleAnyNominalType(node)
    }

    func mangleBoundGenericFunction(_ node: Node) {
        var entry: SubstitutionEntry?
        if trySubstitution(node, entry: &entry) {
            return
        }

        let unboundFunction = node.getUnspecialized()
        mangleFunction(unboundFunction)
        var separator = "y"
        mangleGenericArgs(node, separator: &separator)
        buffer << "G"
        addSubstitution(entry: entry!)
    }

    func mangleBuiltinTypeName(_ node: Node) {
        buffer << "B"
        var text = node.text

        if text == BUILTIN_TYPE_NAME_BRIDGEOBJECT {
            buffer << "b"
        } else if text == BUILTIN_TYPE_NAME_UNSAFEVALUEBUFFER {
            buffer << "B"
        } else if text == BUILTIN_TYPE_NAME_UNKNOWNOBJECT {
            buffer << "O"
        } else if text == BUILTIN_TYPE_NAME_NATIVEOBJECT {
            buffer << "o"
        } else if text == BUILTIN_TYPE_NAME_RAWPOINTER {
            buffer << "p"
        } else if text == BUILTIN_TYPE_NAME_SILTOKEN {
            buffer << "t"
        } else if text == BUILTIN_TYPE_NAME_INTLITERAL {
            buffer << "I"
        } else if text == BUILTIN_TYPE_NAME_WORD {
            buffer << "w"
        } else if text.consumeFront(BUILTIN_TYPE_NAME_INT) {
            buffer << "i"
            buffer << text
            buffer << "_"
        } else if text.consumeFront(BUILTIN_TYPE_NAME_FLOAT) {
            buffer << "f"
            buffer << text
            buffer << "_"
        } else if text.consumeFront(BUILTIN_TYPE_NAME_VEC) {
            let split = text.split(separator: "x")
            var element = String(split[1])
            if element == "RawPointer" {
                buffer << "p"
            } else if element.consumeFront("FPIEEE") {
                buffer << "f"
                buffer << element
                buffer << "_"
            } else if element.consumeFront("Int") {
                buffer << "i"
                buffer << element
                buffer << "_"
            } else {
                unreachable("unexpected builtin vector type")
            }
            buffer << "Bv"
            buffer << String(split[0])
            buffer << "_"
        } else {
            unreachable("unexpected builtin type")
        }
    }

    func mangleCFunctionPointer(_ node: Node) {
        mangleChildNodesReversed(node) // argument tuple, result type
        buffer << "XC"
    }

    func mangleClass(_ node: Node) {
        mangleAnyNominalType(node)
    }

    func mangleAnyConstructor(_ node: Node, kindOp: UnicodeScalar) {
        mangleChildNodes(node)
        buffer << "f"
        buffer << kindOp
    }

    func mangleConstructor(_ node: Node) {
        mangleAnyConstructor(node, kindOp: "c")
    }

    func mangleCoroutineContinuationPrototype(_ node: Node) {
        mangleChildNodes(node)
        buffer << "TC"
    }

    func mangleDeallocator(_ node: Node) {
        mangleChildNodes(node)
        buffer << "fD"
    }

    func mangleDeclContext(_ node: Node) {
        mangleSingleChildNode(node)
    }

    func mangleDefaultArgumentInitializer(_ node: Node) {
        mangleChildNode(node, index: 0)
        buffer << "fA"
        mangleChildNode(node, index: 1)
    }

    func mangleDependentAssociatedTypeRef(_ node: Node) {
        mangleIdentifier(node.children[0])
        if node.children.count > 1 {
            mangleChildNode(node, index: 1)
        }
    }

    func mangleDependentGenericConformanceRequirement(_ node: Node) {
        let protoOrClass = node.children[1]
        if protoOrClass.children[0].kind == .Protocol {
            manglePureProtocol(protoOrClass)
            let NumMembersAndParamIdx = mangleConstrainedType(node.children[0])
            switch NumMembersAndParamIdx.0 {
            case -1: buffer << "RQ"
            return // substitution
            case 0: buffer << "R"
            case 1: buffer << "Rp"
            default: buffer << "RP"
            }
            mangleDependentGenericParamIndex(NumMembersAndParamIdx.1!)
            return
        }
        mangle(protoOrClass)
        let numMembersAndParamIdx = mangleConstrainedType(node.children[0])
        switch numMembersAndParamIdx.0 {
        case -1: buffer << "RB"
        return // substitution
        case 0: buffer << "Rb"
        case 1: buffer << "Rc"
        default: buffer << "RC"
        }
        mangleDependentGenericParamIndex(numMembersAndParamIdx.1!)
    }

    func mangleDependentGenericParamCount(_ node: Node) {
        unreachable("handled inline in DependentGenericSignature")
    }

    func mangleDependentGenericParamType(_ node: Node) {
        if node.children[0].index == 0 && node.children[1].index == 0 {
            buffer << "x"
            return
        }
        buffer << "q"
        mangleDependentGenericParamIndex(node)
    }

    func mangleDependentGenericSameTypeRequirement(_ node: Node) {
        mangleChildNode(node, index: 1)
        let numMembersAndParamIdx = mangleConstrainedType(node.children[0])
        switch numMembersAndParamIdx.0 {
        case -1: buffer << "RS"
        return // substitution
        case 0: buffer << "Rs"
        case 1: buffer << "Rt"
        default: buffer << "RT"
        }
        mangleDependentGenericParamIndex(numMembersAndParamIdx.1!)
    }

    func mangleDependentGenericLayoutRequirement(_ node: Node) {
        let numMembersAndParamIdx = mangleConstrainedType(node.children[0])
        switch numMembersAndParamIdx.0 {
        case -1: buffer << "RL" // substitution
        case 0: buffer << "Rl"
        case 1: buffer << "Rm"
        default: buffer << "RM"
        }
        // If not a substitution, mangle the dependent generic param index.
        if numMembersAndParamIdx.0 != -1 {
            mangleDependentGenericParamIndex(numMembersAndParamIdx.1!)
        }
        precondition(node.children[1].kind == .Identifier)
        precondition(node.children[1].text.count == 1)
        buffer << node.children[1].text.unicodeScalars.first!
        if node.children.count >= 3 {
            mangleChildNode(node, index: 2)
        }
        if node.children.count >= 4 {
            mangleChildNode(node, index: 3)
        }
    }

    func mangleDependentGenericSignature(_ node: Node) {
        var paramCountEnd = 0
        for idx in 0..<node.children.count {
            let Child = node.children[idx]
            if (Child.kind == .DependentGenericParamCount) {
                paramCountEnd = idx + 1
            } else {
                // requirement
                mangleChildNode(node, index: idx)
            }
        }
        // If there"s only one generic param, mangle nothing.
        if paramCountEnd == 1 && node.children[0].index == 1 {
            buffer << "l"
            return
        }

        // Remangle generic params.
        buffer << "r"
        for idx in 0..<paramCountEnd {
            let Count = node.children[idx]
            if (Count.index) > 0 {
                mangleIndex(Count.index - 1)
            } else {
                buffer << "z"
            }
        }
        buffer << "l"
    }

    func mangleDependentGenericType(_ node: Node) {
        mangleChildNodesReversed(node) // type, generic signature
        buffer << "u"
    }

    func mangleDependentMemberType(_ node: Node) {
        let numMembersAndParamIdx = mangleConstrainedType(node)
        switch numMembersAndParamIdx.0 {
        case -1:
        break // substitution
        case 0:
            unreachable("wrong dependent member type")
        case 1:
            buffer << "Q"
            mangleDependentGenericParamIndex(numMembersAndParamIdx.1!, nonZeroPrefix: "y", zeroOp: "z")
            break
        default:
            buffer << "Q"
            mangleDependentGenericParamIndex(numMembersAndParamIdx.1!, nonZeroPrefix: "Y", zeroOp: "Z")
            break
        }
    }

    func mangleDependentPseudogenericSignature(_ node: Node) {
        unreachable("handled inline")
    }

    func mangleDestructor(_ node: Node) {
        mangleChildNodes(node)
        buffer << "fd"
    }

    func mangleDidSet(_ node: Node) {
        mangleAbstractStorage(node.children[0], accessorCode: "W")
    }

    func mangleDirectness(_ node: Node) {
        if (node.index == Directness.Direct.rawValue) {
            buffer << "d"
        } else {
            precondition(node.index == Directness.Indirect.rawValue)
            buffer << "i"
        }
    }

    func mangleDynamicAttribute(_ node: Node) {
        buffer << "TD"
    }

    func mangleDirectMethodReferenceAttribute(_ node: Node) {
        buffer << "Td"
    }

    func mangleDynamicSelf(_ node: Node) {
        mangleSingleChildNode(node) // type
        buffer << "XD"
    }

    func mangleEnum(_ node: Node) {
        mangleAnyNominalType(node)
    }

    func mangleErrorType(_ node: Node) {
        buffer << "Xe"
    }

    func mangleExistentialMetatype(_ node: Node) {
        if (node.children[0].kind == .MetatypeRepresentation) {
            mangleChildNode(node, index: 1)
            buffer << "Xm"
            mangleChildNode(node, index: 0)
        } else {
            mangleSingleChildNode(node)
            buffer << "Xp"
        }
    }

    func mangleExplicitClosure(_ node: Node) {
        mangleChildNode(node, index: 0) // context
        mangleChildNode(node, index: 2) // type
        buffer << "fU"
        mangleChildNode(node, index: 1) // index
    }

    func mangleExtension(_ node: Node) {
        mangleChildNode(node, index: 1)
        mangleChildNode(node, index: 0)
        if node.children.count == 3 {
            mangleChildNode(node, index: 2) // generic signature
        }
        buffer << "E"
    }

    func mangleAnonymousContext(_ node: Node) {
        mangleChildNode(node, index: 1)
        mangleChildNode(node, index: 0)
        if node.children.count >= 3 {
            mangleTypeList(node.children[2])
        }
        buffer << "XZ"
    }

    func mangleFieldOffset(_ node: Node) {
        mangleChildNode(node, index: 1) // variable
        buffer << "Wv"
        mangleChildNode(node, index: 0) // directness
    }

    func mangleEnumCase(_ node: Node) {
        mangleSingleChildNode(node) // enum case
        buffer << "WC"
    }

    func mangleFullTypeMetadata(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "Mf"
    }

    func mangleFunction(_ node: Node) {
        mangleChildNode(node, index: 0) // context
        mangleChildNode(node, index: 1) // name

        let hasLabels = node.children[2].kind == .LabelList
        let funcType = getSingleChild(of: node.children[hasLabels ? 3 : 2])

        if hasLabels {
            mangleChildNode(node, index: 2) // parameter labels
        }

        if (funcType.kind == .DependentGenericType) {
            mangleFunctionSignature(getSingleChild(of: funcType.children[1]))
            mangleChildNode(funcType, index: 0) // generic signature
        } else {
            mangleFunctionSignature(funcType)
        }

        buffer << "F"
    }

    func mangleFunctionSignatureSpecialization(_ node: Node) {
        for param in node.children {
            if (param.kind == .FunctionSignatureSpecializationParam && param.children.count > 0) {
                let kindNd = param.children[0]
                switch FunctionSigSpecializationParamKind(rawValue: kindNd.index) {
                case .ConstantPropFunction: fallthrough
                case .ConstantPropGlobal:
                    mangleIdentifier(param.children[1])
                    break
                case .ConstantPropString:
                    var TextNd = param.children[2]
                    let Text = TextNd.text
                    if !Text.isEmpty && Text.unicodeScalars.first!.isDigit || Text.unicodeScalars.first! == "_" {
                        var Buffer = "_"
                        Buffer << Text
                        TextNd = Node(kind: .Identifier, payload: .Text(Buffer))
                    }
                    mangleIdentifier(TextNd)
                case .ClosureProp:
                    mangleIdentifier(param.children[1])
                    for i in 2..<param.children.count {
                        mangleType(param.children[i])
                    }
                    break
                default:
                    break
                }
            }
        }
        buffer << "Tf"
        var returnValMangled = false
        for child in node.children {
            if (child.kind == .FunctionSignatureSpecializationReturn) {
                buffer << "_"
                returnValMangled = true
            }
            mangle(child)

            if child.kind == .SpecializationPassID, node.hasIndex {
                buffer << node.index
            }
        }
        if !returnValMangled {
            buffer << "_n"
        }
    }

    func mangleFunctionSignatureSpecializationReturn(_ node: Node) {
        mangleFunctionSignatureSpecializationParam(node)
    }

    func mangleFunctionSignatureSpecializationParam(_ node: Node) {
        if node.children.isEmpty {
            buffer << "n"
            return
        }

        // The first child is always a kind that specifies the type of param that we
        // have.
        let kindNd = node.children[0]
        let kindValue = kindNd.index
        let kind = FunctionSigSpecializationParamKind(rawValue: kindValue)

        switch kind {
        case .ConstantPropFunction:
            buffer << "pf"
            return
        case .ConstantPropGlobal:
            buffer << "pg"
            return
        case .ConstantPropInteger:
            buffer << "pi"
            buffer << node.children[1].text
            return
        case .ConstantPropFloat:
            buffer << "pd"
            buffer << node.children[1].text
            return
        case .ConstantPropString:
            buffer << "ps"
            let encodingStr = node.children[1].text
            if (encodingStr == "u8") {
                buffer << "b"
            } else if (encodingStr == "u16") {
                buffer << "w"
            } else if (encodingStr == "objc") {
                buffer << "c"
            } else {
                unreachable("Unknown encoding")
            }
            return
        case .ClosureProp:
            buffer << "c"
            return
        case .BoxToValue:
            buffer << "i"
            return
        case .BoxToStack:
            buffer << "s"
            return
        case .SROA:
            buffer << "x"
            return
        default:
            if (kindValue & FunctionSigSpecializationParamKind.ExistentialToGeneric.rawValue) != 0 {
                buffer << "e"
                if (kindValue & FunctionSigSpecializationParamKind.Dead.rawValue) != 0 {
                    buffer << "D"
                }
                if (kindValue & FunctionSigSpecializationParamKind.OwnedToGuaranteed.rawValue) != 0 {
                    buffer << "G"
                }
                if (kindValue & FunctionSigSpecializationParamKind.GuaranteedToOwned.rawValue) != 0 {
                    buffer << "O"
                }
            } else if (kindValue & FunctionSigSpecializationParamKind.Dead.rawValue) != 0 {
                buffer << "d"
                if (kindValue & FunctionSigSpecializationParamKind.OwnedToGuaranteed.rawValue) != 0 {
                    buffer << "G"
                }
                if (kindValue & FunctionSigSpecializationParamKind.GuaranteedToOwned.rawValue) != 0 {
                    buffer << "O"
                }
            } else if (kindValue & FunctionSigSpecializationParamKind.OwnedToGuaranteed.rawValue) != 0 {
                buffer << "g"
            } else if (kindValue & FunctionSigSpecializationParamKind.GuaranteedToOwned.rawValue) != 0 {
                buffer << "o"
            }
            if (kindValue & FunctionSigSpecializationParamKind.SROA.rawValue) != 0 {
                buffer << "X"
            }
            return
        }
    }

    func mangleFunctionSignatureSpecializationParamKind(_ node: Node) {
        unreachable("handled inline")
    }

    func mangleFunctionSignatureSpecializationParamPayload(_ node: Node) {
        unreachable("handled inline")
    }

    func mangleFunctionType(_ node: Node) {
        mangleFunctionSignature(node)
        buffer << "c"
    }

    func mangleGenericProtocolWitnessTable(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "WG"
    }

    func mangleGenericProtocolWitnessTableInstantiationFunction(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "WI"
    }

    func mangleResilientProtocolWitnessTable(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "Wr"
    }

    func mangleGenericPartialSpecialization(_ node: Node) {
        for child in node.children {
            if child.kind == .GenericSpecializationParam {
                mangleChildNode(child, index: 0)
                break
            }
        }
        buffer << (node.kind == .GenericPartialSpecializationNotReAbstracted ? "TP" : "Tp")
        for child in node.children {
            if child.kind != .GenericSpecializationParam {
                mangle(child)
            }
        }
    }

    func mangleGenericPartialSpecializationNotReAbstracted(_ node: Node) {
        mangleGenericPartialSpecialization(node)
    }

    func mangleGenericSpecialization(_ node: Node) {
        var firstParam = true
        for child in node.children {
            if child.kind == .GenericSpecializationParam {
                mangleChildNode(child, index: 0)
                mangleListSeparator(isFirstListItem: &firstParam)
            }
        }
        precondition(!firstParam, "generic specialization with no substitutions")

        switch (node.kind) {
        case .GenericSpecialization:
            buffer << "Tg"
            break
        case .GenericSpecializationNotReAbstracted:
            buffer << "TG"
            break
        case .InlinedGenericFunction:
            buffer << "Ti"
            break
        default:
            unreachable("unsupported node")
        }

        for child in node.children {
            if child.kind != .GenericSpecializationParam {
                mangle(child)
            }
        }
    }

    func mangleGenericSpecializationNotReAbstracted(_ node: Node) {
        mangleGenericSpecialization(node)
    }

    func mangleInlinedGenericFunction(_ node: Node) {
        mangleGenericSpecialization(node)
    }


    func mangleGenericSpecializationParam(_ node: Node) {
        unreachable("handled inline")
    }

    func mangleGenericTypeMetadataPattern(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "MP"
    }

    func mangleGenericTypeParamDecl(_ node: Node) {
        mangleChildNodes(node)
        buffer << "fp"
    }

    func mangleGetter(_ node: Node) {
        mangleAbstractStorage(node.children[0], accessorCode: "g")
    }

    func mangleGlobal(_ node: Node) {
        buffer << MANGLING_PREFIX
        var mangleInReverseOrder = false
        for (index, Child) in node.children.enumerated() {
            switch (Child.kind) {
            case .FunctionSignatureSpecialization,
                 .GenericSpecialization,
                 .GenericSpecializationNotReAbstracted,
                 .InlinedGenericFunction,
                 .GenericPartialSpecialization,
                 .GenericPartialSpecializationNotReAbstracted,
                 .OutlinedBridgedMethod,
                 .OutlinedVariable,
                 .ObjCAttribute,
                 .NonObjCAttribute,
                 .DynamicAttribute,
                 .VTableAttribute,
                 .DirectMethodReferenceAttribute,
                 .MergedFunction,
                 .DynamicallyReplaceableFunctionKey,
                 .DynamicallyReplaceableFunctionImpl,
                 .DynamicallyReplaceableFunctionVar:
                mangleInReverseOrder = true
            default:
                mangle(Child)
                if mangleInReverseOrder {
                    for Iter in (0..<index).reversed() {
                        mangle(node.children[Iter])
                    }
                    mangleInReverseOrder = false
                }
                break
            }
        }
    }

    func mangleGlobalGetter(_ node: Node) {
        mangleAbstractStorage(node.children[0], accessorCode: "G")
    }

    func mangleIdentifier(_ node: Node) {
        mangleIdentifierImpl(node, /*isOperator*/ isOperator: false)
    }

    func mangleIndex(_ node: Node) {
        unreachable("handled inline")
    }

    func mangleUnknownIndex(_ node: Node) {
        unreachable("handled inline")
    }

    func mangleIVarInitializer(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "fe"
    }

    func mangleIVarDestroyer(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "fE"
    }

    func mangleImplEscaping(_ node: Node) {
        buffer << "e"
    }

    func mangleImplConvention(_ node: Node) {
        let conventionChar: String
        switch node.text {
        case "@callee_unowned": conventionChar = "y"
        case "@callee_guaranteed": conventionChar = "g"
        case "@callee_owned": conventionChar = "x"
        default: unreachable("invalid impl callee convention")
        }
        buffer << conventionChar
    }

    func mangleImplFunctionAttribute(_ node: Node) {
        unreachable("handled inline")
    }

    func mangleImplFunctionType(_ node: Node) {
        var pseudoGeneric = ""
        var genSig: Node? = nil
        for child in node.children {
            switch child.kind {
            case .ImplParameter: fallthrough
            case .ImplResult: fallthrough
            case .ImplErrorResult:
                mangleChildNode(child, index: 1)
                break
            case .DependentPseudogenericSignature:
                pseudoGeneric = "P"
                fallthrough
            case .DependentGenericSignature:
                genSig = child
                break
            default:
                break
            }
        }
        if let genSig = genSig {
            mangle(genSig)
        }

        buffer << "I"
        buffer << pseudoGeneric
        for child in node.children {
            switch child.kind {
            case .ImplEscaping:
                buffer << "e"
                break
            case .ImplConvention:
                let convCh: String
                switch child.text {
                case "@callee_unowned": convCh = "y"
                case "@callee_guaranteed": convCh = "g"
                case "@callee_owned": convCh = "x"
                case "@convention(thin)": convCh = "t"
                default:
                    unreachable("invalid impl callee convention")
                }
                buffer << convCh
            case .ImplFunctionAttribute:
                var funcAttr: String
                switch child.text {
                case "@convention(block)": funcAttr = "B"
                case "@convention(c)": funcAttr = "C"
                case "@convention(method)": funcAttr = "M"
                case "@convention(objc_method)": funcAttr = "O"
                case "@convention(closure)": funcAttr = "K"
                case "@convention(witness_method)": funcAttr = "W"
                default:
                    unreachable("invalid impl function attribute")
                }
                buffer << funcAttr
            case .ImplParameter:
                let convCh: String
                switch child.children[0].text {
                case "@in": convCh = "i"
                case "@inout": convCh = "l"
                case "@inout_aliasable": convCh = "b"
                case "@in_guaranteed": convCh = "n"
                case "@in_constant": convCh = "c"
                case "@owned": convCh = "x"
                case "@guaranteed": convCh = "g"
                case "@deallocating": convCh = "e"
                case "@unowned": convCh = "y"
                default: unreachable("invalid impl parameter convention")
                }
                buffer << convCh
            case .ImplErrorResult:
                buffer << "z"
                fallthrough
            case .ImplResult:
                let convCh: String
                switch child.children[0].text {
                case "@out": convCh = "r"
                case "@owned": convCh = "o"
                case "@unowned": convCh = "d"
                case "@unowned_inner_pointer": convCh = "u"
                case "@autoreleased": convCh = "a"
                default: unreachable("invalid impl parameter convention")
                }
                buffer << convCh
            default:
                break
            }
        }
        buffer << "_"
    }

    func mangleImplicitClosure(_ node: Node) {
        mangleChildNode(node, index: 0) // context
        mangleChildNode(node, index: 2) // type
        buffer << "fu"
        mangleChildNode(node, index: 1) // index
    }

    func mangleImplParameter(_ node: Node) {
        unreachable("handled inline")
    }

    func mangleImplResult(_ node: Node) {
        unreachable("handled inline")
    }

    func mangleImplErrorResult(_ node: Node) {
        unreachable("handled inline")
    }

    func mangleInOut(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "z"
    }

    func mangleShared(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "h"
    }

    func mangleOwned(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "n"
    }

    func mangleInfixOperator(_ node: Node) {
        mangleIdentifierImpl(node, /*isOperator*/ isOperator: true)
        buffer << "oi"
    }

    func mangleInitializer(_ node: Node) {
        mangleChildNodes(node)
        buffer << "fi"
    }

    func mangleLazyProtocolWitnessTableAccessor(_ node: Node) {
        mangleChildNodes(node)
        buffer << "Wl"
    }

    func mangleLazyProtocolWitnessTableCacheVariable(_ node: Node) {
        mangleChildNodes(node)
        buffer << "WL"
    }

    func mangleLocalDeclName(_ node: Node) {
        mangleChildNode(node, index: 1) // identifier
        buffer << "L"
        mangleChildNode(node, index: 0) // index
    }

    func mangleMaterializeForSet(_ node: Node) {
        mangleAbstractStorage(node.children[0], accessorCode: "m")
    }

    func mangleMetatype(_ node: Node) {
        if (node.children[0].kind == .MetatypeRepresentation) {
            mangleChildNode(node, index: 1)
            buffer << "XM"
            mangleChildNode(node, index: 0)
        } else {
            mangleSingleChildNode(node)
            buffer << "m"
        }
    }

    func mangleMetatypeRepresentation(_ node: Node) {
        if (node.text == "@thin") {
            buffer << "t"
        } else if (node.text == "@thick") {
            buffer << "T"
        } else if (node.text == "@objc_metatype") {
            buffer << "o"
        } else {
            unreachable("wrong metatype representation")
        }
    }

    func mangleMetaclass(_ node: Node) {
        mangleChildNodes(node)
        buffer << "Mm"
    }

    func mangleModifyAccessor(_ node: Node) {
        mangleAbstractStorage(node.children[0], accessorCode: "M")
    }

    func mangleModule(_ node: Node) {
        if (node.text == STDLIB_NAME) {
            buffer << "s"
        } else if (node.text == MANGLING_MODULE_OBJC) {
            buffer << "So"
        } else if (node.text == MANGLING_MODULE_CLANG_IMPORTER) {
            buffer << "SC"
        } else {
            mangleIdentifier(node)
        }
    }

    func mangleNativeOwningAddressor(_ node: Node) {
        mangleAbstractStorage(node.children[0], accessorCode: "lo")
    }

    func mangleNativeOwningMutableAddressor(_ node: Node) {
        mangleAbstractStorage(node.children[0], accessorCode: "ao")
    }

    func mangleNativePinningAddressor(_ node: Node) {
        mangleAbstractStorage(node.children[0], accessorCode: "lp")
    }

    func mangleNativePinningMutableAddressor(_ node: Node) {
        mangleAbstractStorage(node.children[0], accessorCode: "aP")
    }

    func mangleClassMetadataBaseOffset(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "Mo"
    }

    func mangleNominalTypeDescriptor(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "Mn"
    }

    func mangleOpaqueTypeDescriptor(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "MQ"
    }

    func mangleOpaqueTypeDescriptorAccessor(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "Mg"
    }

    func mangleOpaqueTypeDescriptorAccessorImpl(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "Mh"
    }

    func mangleOpaqueTypeDescriptorAccessorKey(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "Mj"
    }

    func mangleOpaqueTypeDescriptorAccessorVar(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "Mk"
    }

    func manglePropertyDescriptor(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "MV"
    }

    func mangleNonObjCAttribute(_ node: Node) {
        buffer << "TO"
    }

    func mangleTuple(_ node: Node) {
        mangleTypeList(node)
        buffer << "t"
    }

    func mangleNumber(_ node: Node) {
        mangleIndex(node.index)
    }

    func mangleObjCAttribute(_ node: Node) {
        buffer << "To"
    }

    func mangleObjCBlock(_ node: Node) {
        mangleChildNodesReversed(node)
        buffer << "XB"
    }

    func mangleOwningAddressor(_ node: Node) {
        mangleAbstractStorage(node.children[0], accessorCode: "lO")
    }

    func mangleOwningMutableAddressor(_ node: Node) {
        mangleAbstractStorage(node.children[0], accessorCode: "aO")
    }

    func manglePartialApplyForwarder(_ node: Node) {
        mangleChildNodesReversed(node)
        buffer << "TA"
    }

    func manglePartialApplyObjCForwarder(_ node: Node) {
        mangleChildNodesReversed(node)
        buffer << "Ta"
    }

    func mangleMergedFunction(_ node: Node) {
        buffer << "Tm"
    }

    func mangleDynamicallyReplaceableFunctionImpl(_ node: Node) {
        buffer << "TI"
    }

    func mangleDynamicallyReplaceableFunctionKey(_ node: Node) {
        buffer << "Tx"
    }

    func mangleDynamicallyReplaceableFunctionVar(_ node: Node) {
        buffer << "TX"
    }

    func manglePostfixOperator(_ node: Node) {
        mangleIdentifierImpl(node, /*isOperator*/ isOperator: true)
        buffer << "oP"
    }

    func manglePrefixOperator(_ node: Node) {
        mangleIdentifierImpl(node, /*isOperator*/ isOperator: true)
        buffer << "op"
    }

    func manglePrivateDeclName(_ node: Node) {
        mangleChildNodesReversed(node)
        buffer << (node.children.count == 1 ? "Ll" : "LL")
    }

    func mangleProtocol(_ node: Node) {
        mangleAnyGenericType(node, typeOp: "P")
    }

    func mangleRetroactiveConformance(_ node: Node) {
        mangleAnyProtocolConformance(node.children[1])
        buffer << "g"
        mangleIndex(node.children[0].index)
    }

    func mangleProtocolConformance(_ node: Node) {
        var ty = getChildOfType(node.children[0])
        var genSig: Node? = nil
        if ty.kind == .DependentGenericType {
            genSig = ty.children[0]
            ty = ty.children[1]
        }
        mangle(ty)
        if node.children.count == 4 {
            mangleChildNode(node, index: 3)
        }
        manglePureProtocol(node.children[1])
        mangleChildNode(node, index: 2)
        if let GenSig = genSig {
            mangle(GenSig)
        }
    }

    func mangleProtocolConformanceRefInTypeModule(_ node: Node) {
        manglePureProtocol(node.children[0])
        buffer << "HP"
    }

    func mangleProtocolConformanceRefInProtocolModule(_ node: Node) {
        manglePureProtocol(node.children[0])
        buffer << "Hp"
    }

    func mangleProtocolConformanceRefInOtherModule(_ node: Node) {
        manglePureProtocol(node.children[0])
        mangleChildNode(node, index: 1)
    }

    func mangleConcreteProtocolConformance(_ node: Node) {
        mangleType(node.children[0])
        mangle(node.children[1])
        if (node.children.count > 2) {
            mangleAnyProtocolConformanceList(node.children[2])
        } else {
            buffer << "y"
        }
        buffer << "HC"
    }

    func mangleDependentProtocolConformanceRoot(_ node: Node) {
        mangleType(node.children[0])
        manglePureProtocol(node.children[1])
        buffer << "HD"
        mangleDependentConformanceIndex(node.children[2])
    }

    func mangleDependentProtocolConformanceInherited(_ node: Node) {
        mangleAnyProtocolConformance(node.children[0])
        manglePureProtocol(node.children[1])
        buffer << "HI"
        mangleDependentConformanceIndex(node.children[2])
    }

    func mangleDependentAssociatedConformance(_ node: Node) {
        mangleType(node.children[0])
        manglePureProtocol(node.children[1])
    }

    func mangleDependentProtocolConformanceAssociated(_ node: Node) {
        mangleAnyProtocolConformance(node.children[0])
        mangleDependentAssociatedConformance(node.children[1])
        buffer << "HA"
        mangleDependentConformanceIndex(node.children[2])
    }

    func mangleAnyProtocolConformanceList(_ node: Node) {
        var firstElem = true
        for child in node.children {
            mangleAnyProtocolConformance(child)
            mangleListSeparator(isFirstListItem: &firstElem)
        }
        mangleEndOfList(isFirstListItem: firstElem)
    }

    func mangleProtocolDescriptor(_ node: Node) {
        manglePureProtocol(getSingleChild(of: node))
        buffer << "Mp"
    }

    func mangleProtocolRequirementsBaseDescriptor(_ node: Node) {
        manglePureProtocol(getSingleChild(of: node))
        buffer << "TL"
    }

    func mangleProtocolSelfConformanceDescriptor(_ node: Node) {
        manglePureProtocol(node.children[0])
        buffer << "MS"
    }

    func mangleProtocolConformanceDescriptor(_ node: Node) {
        mangleProtocolConformance(node.children[0])
        buffer << "Mc"
    }

    func mangleProtocolList(_ node: Node, superclass: Node?, hasExplicitAnyObject: Bool) {
        let protocols = getSingleChild(of: node, kind: .TypeList)
        var firstElem = true
        for child in protocols.children {
            manglePureProtocol(child)
            mangleListSeparator(isFirstListItem: &firstElem)
        }
        mangleEndOfList(isFirstListItem: firstElem)
        if let superclass = superclass {
            mangleType(superclass)
            buffer << "Xc"
            return
        } else if (hasExplicitAnyObject) {
            buffer << "Xl"
            return
        }
        buffer << "p"
    }

    func mangleProtocolList(_ node: Node) {
        mangleProtocolList(node, superclass: nil, hasExplicitAnyObject: false)
    }

    func mangleProtocolListWithClass(_ node: Node) {
        mangleProtocolList(node.children[0], superclass: node.children[1], hasExplicitAnyObject: false)
    }

    func mangleProtocolListWithAnyObject(_ node: Node) {
        mangleProtocolList(node.children[0], superclass: nil, hasExplicitAnyObject: true)
    }

    func mangleProtocolSelfConformanceWitness(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "TS"
    }

    func mangleProtocolWitness(_ node: Node) {
        mangleChildNodes(node)
        buffer << "TW"
    }

    func mangleProtocolSelfConformanceWitnessTable(_ node: Node) {
        manglePureProtocol(node.children[0])
        buffer << "WS"
    }

    func mangleProtocolWitnessTable(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "WP"
    }

    func mangleProtocolWitnessTablePattern(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "Wp"
    }

    func mangleProtocolWitnessTableAccessor(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "Wa"
    }

    func mangleReabstractionThunk(_ node: Node) {
        mangleChildNodesReversed(node)
        buffer << "Tr"
    }

    func mangleReabstractionThunkHelper(_ node: Node) {
        mangleChildNodesReversed(node)
        buffer << "TR"
    }

    func mangleReabstractionThunkHelperWithSelf(_ node: Node) {
        mangleChildNodesReversed(node)
        buffer << "Ty"
    }

    func mangleReadAccessor(_ node: Node) {
        mangleAbstractStorage(node.children[0], accessorCode: "r")
    }

    func mangleKeyPathThunkHelper(_ node: Node, op: String) {
        for child in node.children {
            if (child.kind != .IsSerialized) {
                mangle(child)
            }

        }
        buffer << op
        for child in node.children {
            if child.kind == .IsSerialized {
                mangle(child)
            }
        }
    }

    func mangleKeyPathGetterThunkHelper(_ node: Node) {
        mangleKeyPathThunkHelper(node, op: "TK")
    }

    func mangleKeyPathSetterThunkHelper(_ node: Node) {
        mangleKeyPathThunkHelper(node, op: "Tk")
    }

    func mangleKeyPathEqualsThunkHelper(_ node: Node) {
        mangleKeyPathThunkHelper(node, op: "TH")
    }

    func mangleKeyPathHashThunkHelper(_ node: Node) {
        mangleKeyPathThunkHelper(node, op: "Th")
    }

    func mangleReturnType(_ node: Node) {
        mangleArgumentTuple(node)
    }

    func mangleRelatedEntityDeclName(_ node: Node) {
        mangleChildNode(node, index: 1)
        let kindNode =  node.children[0]
        if kindNode.text.count != 1 {
            unreachable("cannot handle multi-byte related entities")
        }
        buffer << "L"
        buffer << kindNode.text
    }

    func mangleSILBoxType(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "Xb"
    }

    func mangleSetter(_ node: Node) {
        mangleAbstractStorage(node.children[0], accessorCode: "s")
    }

    func mangleSpecializationPassID(_ node: Node) {
        buffer << node.index
    }

    func mangleIsSerialized(_ node: Node) {
        buffer << "q"
    }

    func mangleStatic(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "Z"
    }

    func mangleOtherNominalType(_ node: Node) {
        mangleAnyNominalType(node)
    }

    func mangleStructure(_ node: Node) {
        mangleAnyNominalType(node)
    }

    func mangleSubscript(_ node: Node) {
        mangleAbstractStorage(node, accessorCode: "p")
    }

    func mangleSuffix(_ node: Node) {
        // Just add the suffix back on.
        buffer << node.text
    }

    func mangleThinFunctionType(_ node: Node) {
        mangleFunctionSignature(node)
        buffer << "Xf"
    }

    func mangleTupleElement(_ node: Node) {
        mangleChildNodesReversed(node); // tuple type, element name?
    }

    func mangleTupleElementName(_ node: Node) {
        mangleIdentifier(node)
    }

    func mangleType(_ node: Node) {
        mangleSingleChildNode(node)
    }

    func mangleTypeAlias(_ node: Node) {
        mangleAnyNominalType(node)
    }

    func mangleTypeList(_ node: Node) {
        var firstElem = true
        for idx in 0..<node.children.count {
            mangleChildNode(node, index: idx)
            mangleListSeparator(isFirstListItem: &firstElem)
        }
        mangleEndOfList(isFirstListItem: firstElem)
    }

    func mangleLabelList(_ node: Node) {
        if node.children.count == 0 {
            buffer << "y"
        } else {
            mangleChildNodes(node)
        }
    }

    func mangleTypeMangling(_ node: Node) {
        mangleChildNodes(node)
        buffer << "D"
    }

    func mangleTypeMetadata(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "N"
    }

    func mangleTypeMetadataAccessFunction(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "Ma"
    }

    func mangleTypeMetadataInstantiationCache(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "MI"
    }

    func mangleTypeMetadataInstantiationFunction(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "Mi"
    }

    func mangleTypeMetadataSingletonInitializationCache(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "Ml"
    }

    func mangleTypeMetadataCompletionFunction(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "Mr"
    }

    func mangleTypeMetadataLazyCache(_ node: Node) {
        mangleChildNodes(node)
        buffer << "ML"
    }

    func mangleUncurriedFunctionType(_ node: Node) {
        mangleFunctionSignature(node)
        // Mangle as regular function type (there is no "uncurried function type"
        // in the new mangling scheme).
        buffer << "c"
    }

    func mangleUnsafeAddressor(_ node: Node) {
        mangleAbstractStorage(node.children[0], accessorCode: "lu")
    }

    func mangleUnsafeMutableAddressor(_ node: Node) {
        mangleAbstractStorage(node.children[0], accessorCode: "au")
    }

    func mangleValueWitness(_ node: Node) {
        mangleChildNode(node, index: 1) // type
        let code: String
        switch ValueWitnessKind(rawValue: node.children[0].index)! {
        case .allocateBuffer: code = "al"
        case .assignWithCopy: code = "ca"
        case .assignWithTake: code = "ta"
        case .deallocateBuffer: code = "de"
        case .destroy: code = "xx"
        case .destroyBuffer: code = "XX"
        case .destroyArray: code = "Xx"
        case .initializeBufferWithCopyOfBuffer: code = "CP"
        case .initializeBufferWithCopy: code = "Cp"
        case .initializeWithCopy: code = "cp"
        case .initializeBufferWithTake: code = "Tk"
        case .initializeWithTake: code = "tk"
        case .projectBuffer: code = "pr"
        case .initializeBufferWithTakeOfBuffer: code = "TK"
        case .initializeArrayWithCopy: code = "Cc"
        case .initializeArrayWithTakeFrontToBack: code = "Tt"
        case .initializeArrayWithTakeBackToFront: code = "tT"
        case .storeExtraInhabitant: code = "xs"
        case .getExtraInhabitantIndex: code = "xg"
        case .getEnumTag: code = "ug"
        case .destructiveProjectEnumData: code = "up"
        case .destructiveInjectEnumTag: code = "ui"
        case .getEnumTagSinglePayload: code = "et"
        case .storeEnumTagSinglePayload: code = "st"
        }
        buffer << "w"
        buffer << code
    }

    func mangleValueWitnessTable(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "WV"
    }

    func mangleVariable(_ node: Node) {
        mangleAbstractStorage(node, accessorCode: "p")
    }

    func mangleVTableAttribute(_ node: Node) {
        unreachable("Old-fashioned vtable thunk in new mangling format")
    }

    func mangleVTableThunk(_ node: Node) {
        mangleChildNodes(node)
        buffer << "TV"
    }

    func mangleWeak(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "Xw"
    }

    func mangleUnowned(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "Xo"
    }

    func mangleUnmanaged(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "Xu"
    }

    func mangleWillSet(_ node: Node) {
        mangleAbstractStorage(node.children[0], accessorCode: "w")
    }

    func mangleReflectionMetadataBuiltinDescriptor(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "MB"
    }

    func mangleReflectionMetadataFieldDescriptor(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "MF"
    }

    func mangleReflectionMetadataAssocTypeDescriptor(_ node: Node) {
        mangleSingleChildNode(node); // protocol-conformance
        buffer << "MA"
    }

    func mangleReflectionMetadataSuperclassDescriptor(_ node: Node) {
        mangleSingleChildNode(node); // protocol-conformance
        buffer << "MC"
    }

    func mangleCurryThunk(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "Tc"
    }

    func mangleDispatchThunk(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "Tj"
    }

    func mangleMethodDescriptor(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "Tq"
    }

    func mangleMethodLookupFunction(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "Mu"
    }

    func mangleObjCMetadataUpdateFunction(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "MU"
    }

    func mangleObjCResilientClassStub(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "Ms"
    }

    func mangleFullObjCResilientClassStub(_ node: Node) {
        mangleSingleChildNode(node)
        buffer << "Mt"
    }

    func mangleThrowsAnnotation(_ node: Node) {
        buffer << "K"
    }

    func mangleEmptyList(_ node: Node) {
        buffer << "y"
    }

    func mangleFirstElementMarker(_ node: Node) {
        buffer << "_"
    }

    func mangleVariadicMarker(_ node: Node) {
        buffer << "d"
    }

    func mangleOutlinedCopy(_ node: Node) {
        mangleChildNodes(node)
        buffer << "WOy"
    }

    func mangleOutlinedConsume(_ node: Node) {
        mangleChildNodes(node)
        buffer << "WOe"
    }

    func mangleOutlinedRetain(_ node: Node) {
        mangleChildNodes(node)
        buffer << "WOr"
    }

    func mangleOutlinedRelease(_ node: Node) {
        mangleChildNodes(node)
        buffer << "WOs"
    }

    func mangleOutlinedInitializeWithTake(_ node: Node) {
        mangleChildNodes(node)
        buffer << "WOb"
    }

    func mangleOutlinedInitializeWithCopy(_ node: Node) {
        mangleChildNodes(node)
        buffer << "WOc"
    }

    func mangleOutlinedAssignWithTake(_ node: Node) {
        mangleChildNodes(node)
        buffer << "WOd"
    }

    func mangleOutlinedAssignWithCopy(_ node: Node) {
        mangleChildNodes(node)
        buffer << "WOf"
    }

    func mangleOutlinedDestroy(_ node: Node) {
        mangleChildNodes(node)
        buffer << "WOh"
    }

    func mangleOutlinedVariable(_ node: Node) {
        buffer << "Tv"
        mangleIndex(node.index)
    }

    func mangleOutlinedBridgedMethod(_ node: Node) {
        buffer << "Te"
        buffer << node.text
        buffer << "_"
    }

    func mangleSILBoxTypeWithLayout(_ node: Node) {
        precondition(node.children.count == 1 || node.children.count == 3)
        precondition(node.children[0].kind == .SILBoxLayout)
        let layout = node.children[0]
        var layoutTypeList = Node(kind: .TypeList)
        for i in 0..<layout.children.count {
            precondition(layout.children[i].kind == .SILBoxImmutableField || layout.children[i].kind == .SILBoxMutableField)
            let field = layout.children[i]
            precondition(field.children.count == 1 && field.children[0].kind == .Type)
            var fieldType = field.children[0]
            // "inout" mangling is used to represent mutable fields.
            if (field.kind == .SILBoxMutableField) {
                var `inout` = Node(kind: .InOut)
                `inout`.children.append(fieldType.children[0])
                fieldType = Node(kind: .Type)
                fieldType.children.append(`inout`)
            }
            layoutTypeList.children.append(fieldType)
        }
        mangleTypeList(layoutTypeList)

        if (node.children.count == 3) {
            let signature = node.children[1]
            let genericArgs = node.children[2]
            precondition(signature.kind == .DependentGenericSignature)
            precondition(genericArgs.kind == .TypeList)
            mangleTypeList(genericArgs)
            mangleDependentGenericSignature(signature)
            buffer << "XX"
        } else {
            buffer << "Xx"
        }
    }

    func mangleSILBoxLayout(_ node: Node) {
        unreachable("should be part of SILBoxTypeWithLayout")
    }

    func mangleSILBoxMutableField(_ node: Node) {
        unreachable("should be part of SILBoxTypeWithLayout")
    }

    func mangleSILBoxImmutableField(_ node: Node) {
        unreachable("should be part of SILBoxTypeWithLayout")
    }

    func mangleAssocTypePath(_ node: Node) {
        var firstElem = true
        for child in node.children {
            mangle(child)
            mangleListSeparator(isFirstListItem: &firstElem)
        }
    }

    func mangleModuleDescriptor(_ node: Node) {
        mangle(node.children[0])
        buffer << "MXM"
    }

    func mangleExtensionDescriptor(_ node: Node) {
        mangle(node.children[0])
        buffer << "MXE"
    }

    func mangleAnonymousDescriptor(_ node: Node) {
        mangle(node.children[0])
        if (node.children.count == 1) {
            buffer << "MXX"
        } else {
            mangleIdentifier(node.children[1])
            buffer << "MXY"
        }
    }

    func mangleAssociatedTypeGenericParamRef(_ node: Node) {
        mangleType(node.children[0])
        mangleAssocTypePath(node.children[1])
        buffer << "MXA"
    }

    func mangleTypeSymbolicReference(_ node: Node) {
        return mangle(resolver(.Context, UnsafeRawPointer(bitPattern: UInt(node.index))!))
    }

    func mangleProtocolSymbolicReference(_ node: Node) {
        return mangle(resolver(.Context, UnsafeRawPointer(bitPattern: UInt(node.index))!))
    }

    func mangleOpaqueTypeDescriptorSymbolicReference(_ node: Node) {
        return mangle(resolver(.Context, UnsafeRawPointer(bitPattern: UInt(node.index))!))
    }

    func mangleSugaredOptional(_ node: Node) {
        mangleType(node.children[0])
        buffer << "XSq"
    }

    func mangleSugaredArray(_ node: Node) {
        mangleType(node.children[0])
        buffer << "XSa"
    }

    func mangleSugaredDictionary(_ node: Node) {
        mangleType(node.children[0])
        mangleType(node.children[1])
        buffer << "XSD"
    }

    func mangleSugaredParen(_ node: Node) {
        mangleType(node.children[0])
        buffer << "XSp"
    }

    func mangleOpaqueReturnType(_ node: Node) {
        buffer << "Qr"
    }

    func mangleOpaqueReturnTypeOf(_ node: Node) {
        mangle(node.children[0])
        buffer << "QO"
    }

    func mangleOpaqueType(_ node: Node) {
        var entry: SubstitutionEntry?
        if trySubstitution(node, entry: &entry) { return }

        mangle(node.children[0])
        let boundGenerics = node.children[2]
        for i in 0..<boundGenerics.children.count {
            buffer << (i == 0 ? "y" : "_")
            mangleChildNodes(boundGenerics.children[i])
        }
        if node.children.count >= 4 {
            let retroactiveConformances = node.children[3]
            for i in 0..<retroactiveConformances.children.count {
                mangle(retroactiveConformances.children[i])
            }
        }
        buffer << "Qo"
        mangleIndex(node.children[1].index)

        addSubstitution(entry: entry!)
    }

    func mangleAccessorFunctionReference(_ node: Node) {
        unreachable("can't remangle")
    }
}

extension Remangler {
    // Find a substitution and return its index.
    // Returns nil if no substitution is found.
    func findSubstitution(entry: SubstitutionEntry) -> Int? { substitutions.firstIndex(of: entry) }

    func addSubstitution(entry: SubstitutionEntry) {
        precondition(findSubstitution(entry: entry) == nil)
        substitutions.append(entry)
    }

    // XXX: this function's signature is super weird in swift
    func trySubstitution(_ node: Node, entry: inout SubstitutionEntry?, treatAsIdentifier: Bool = false) -> Bool {
        if mangleStandardSubstitution(node) {
            return true
        }

        // Go ahead and initialize the substitution entry.
        entry = SubstitutionEntry(node: node, treatAsIdentifier: treatAsIdentifier)

        guard let Idx = findSubstitution(entry: entry!) else { return false }

        if Idx >= 26 {
            buffer << "A"
            mangleIndex(Node.IndexType(Idx - 26))
            return true
        }
        let subst = UnicodeScalar(Idx + "A")!
        if !substMerging.tryMergeSubst(subst: subst, isStandardSubst: false, buffer: &buffer) {
            buffer << "A"
            buffer << subst
        }
        return true
    }
}

extension Remangler {
    private func unreachable(_ message: String, file: StaticString = #file, line: UInt = #line) -> Never {
        fatalError(message, file: file, line: line)
    }
}

private extension String {
    mutating func consumeFront(_ prefix: String) -> Bool {
        if !hasPrefix(prefix) {
            return false
        }
        self = String(dropFirst(prefix.count))
        return true
    }
}
