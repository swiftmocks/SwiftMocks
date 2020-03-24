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

/// Display style options for the node printer
struct DemangleOptions: OptionSet {
    let rawValue: Int
    init(rawValue: Int) { self.rawValue = rawValue }

    static let SynthesizeSugarOnTypes = DemangleOptions(rawValue: 1 << 0)
    static let DisplayDebuggerGeneratedModule = DemangleOptions(rawValue: 1 << 1)
    static let QualifyEntities = DemangleOptions(rawValue: 1 << 2)
    static let DisplayExtensionContexts = DemangleOptions(rawValue: 1 << 3)
    static let DisplayUnmangledSuffix = DemangleOptions(rawValue: 1 << 4)
    static let DisplayModuleNames = DemangleOptions(rawValue: 1 << 5)
    static let DisplayGenericSpecializations = DemangleOptions(rawValue: 1 << 6)
    static let DisplayProtocolConformances = DemangleOptions(rawValue: 1 << 7)
    static let DisplayWhereClauses = DemangleOptions(rawValue: 1 << 8)
    static let DisplayEntityTypes = DemangleOptions(rawValue: 1 << 9)
    static let ShortenPartialApply = DemangleOptions(rawValue: 1 << 10)
    static let ShortenThunk = DemangleOptions(rawValue: 1 << 11)
    static let ShortenValueWitness = DemangleOptions(rawValue: 1 << 12)
    static let ShortenArchetype = DemangleOptions(rawValue: 1 << 13)
    static let ShowPrivateDiscriminators = DemangleOptions(rawValue: 1 << 14)
    static let ShowFunctionArgumentTypes = DemangleOptions(rawValue: 1 << 15)

    static let `default`: DemangleOptions = [
        .DisplayDebuggerGeneratedModule,
        .QualifyEntities,
        .DisplayExtensionContexts,
        .DisplayUnmangledSuffix,
        .DisplayModuleNames,
        .DisplayGenericSpecializations,
        .DisplayProtocolConformances,
        .DisplayWhereClauses,
        .DisplayEntityTypes,
        .ShowPrivateDiscriminators,
        .ShowFunctionArgumentTypes
    ]

    static let simplified: DemangleOptions = [
        .SynthesizeSugarOnTypes,
        .QualifyEntities,
        .ShortenPartialApply,
        .ShortenThunk,
        .ShortenValueWitness,
        .ShortenArchetype
    ]
}

struct NodePrinter {
    var printer = ""
    let options: DemangleOptions
    var specializationPrefixPrinted = false
    var isValid = true

    init() {
        self.options = .default
    }

    init(options: DemangleOptions) {
        self.options = options
    }

    mutating func printRoot(_ root: Node) throws -> String {
        isValid = true
        print(root)
        try require(isValid)
        return printer
    }

    /// Called when the node tree in valid. The demangler already catches most error cases and mostly produces valid node trees. But some cases are difficult to catch in the demangler and instead the `NodePrinter` bails.
    private mutating func setInvalid() { isValid = false }

    private mutating func printChildren(_ children: [Node], separator: String? = nil) {
        for (index, child) in children.enumerated() {
            print(child)
            if let separator = separator, index != children.count - 1 {
                printer << separator
            }
        }
    }

    private mutating func printChildren(of node: Node, separator: String? = nil) { printChildren(node.children, separator: separator) }

    private func getFirstChildOfKind(node: Node, kind: Node.Kind) throws -> Node {
        try require(node.children.first(where: { $0.kind == kind}))
    }

    private mutating func printBoundGenericNoSugar(node: Node) {
        if node.children.count < 2 {
            return
        }
        let typelist = node.children[1]
        print(node.children[0])
        printer << "<"
        printChildren(of: typelist, separator: ", ")
        printer << ">"
    }

    private mutating func printOptionalIndex(node: Node) {
        precondition(node.kind == .Index || node.kind == .UnknownIndex)
        if node.hasIndex {
            printer << "#"
            printer << node.index
            printer << " "
        }
    }

    private func isSwiftModule(_ node: Node) -> Bool {
        return node.kind == .Module && node.text == STDLIB_NAME
    }

    private mutating func printContext(_ context: Node) -> Bool {
        if !options.contains(.QualifyEntities) {
            return false
        }

        if context.kind == .Module && context.text.starts(with: LLDB_EXPRESSIONS_MODULE_NAME_PREFIX) == true {
            return options.contains(.DisplayDebuggerGeneratedModule)
        }
        return true
    }

    private func isIdentifier(_ node: Node, desired: String) -> Bool {
        return node.kind == .Identifier && node.text == desired
    }

    private enum SugarType {
        case None
        case Optional
        case ImplicitlyUnwrappedOptional
        case Array
        case Dictionary
    }

    private enum TypePrinting {
        case NoType
        case WithColon
        case FunctionStyle
    }

    /// Determine whether this is a "simple" type, from the type-simple production.
    private func isSimpleType(node: Node) -> Bool {
        switch (node.kind) {
        case .AssociatedType: fallthrough
        case .AssociatedTypeRef: fallthrough
        case .BoundGenericClass: fallthrough
        case .BoundGenericEnum: fallthrough
        case .BoundGenericStructure: fallthrough
        case .BoundGenericProtocol: fallthrough
        case .BoundGenericOtherNominalType: fallthrough
        case .BoundGenericTypeAlias: fallthrough
        case .BoundGenericFunction: fallthrough
        case .BuiltinTypeName: fallthrough
        case .Class: fallthrough
        case .DependentGenericType: fallthrough
        case .DependentMemberType: fallthrough
        case .DependentGenericParamType: fallthrough
        case .DynamicSelf: fallthrough
        case .Enum: fallthrough
        case .ErrorType: fallthrough
        case .ExistentialMetatype: fallthrough
        case .Metatype: fallthrough
        case .MetatypeRepresentation: fallthrough
        case .Module: fallthrough
        case .Tuple: fallthrough
        case .Protocol: fallthrough
        case .ProtocolSymbolicReference: fallthrough
        case .ReturnType: fallthrough
        case .SILBoxType: fallthrough
        case .SILBoxTypeWithLayout: fallthrough
        case .Structure: fallthrough
        case .OtherNominalType: fallthrough
        case .TupleElementName: fallthrough
        case .Type: fallthrough
        case .TypeAlias: fallthrough
        case .TypeList: fallthrough
        case .LabelList: fallthrough
        case .TypeSymbolicReference: fallthrough
        case .SugaredOptional: fallthrough
        case .SugaredArray: fallthrough
        case .SugaredDictionary: fallthrough
        case .SugaredParen:
            return true

        case .ProtocolList:
            return node.children[0].children.count <= 1

        case .ProtocolListWithAnyObject:
            return node.children[0].children[0].children.count == 0

        case .ProtocolListWithClass: fallthrough
        case .AccessorFunctionReference: fallthrough
        case .Allocator: fallthrough
        case .ArgumentTuple: fallthrough
        case .AssociatedConformanceDescriptor: fallthrough
        case .AssociatedTypeDescriptor: fallthrough
        case .AssociatedTypeMetadataAccessor: fallthrough
        case .AssociatedTypeWitnessTableAccessor: fallthrough
        case .AutoClosureType: fallthrough
        case .BaseConformanceDescriptor: fallthrough
        case .BaseWitnessTableAccessor: fallthrough
        case .ClassMetadataBaseOffset: fallthrough
        case .CFunctionPointer: fallthrough
        case .Constructor: fallthrough
        case .CoroutineContinuationPrototype: fallthrough
        case .CurryThunk: fallthrough
        case .DispatchThunk: fallthrough
        case .Deallocator: fallthrough
        case .DeclContext: fallthrough
        case .DefaultArgumentInitializer: fallthrough
        case .DefaultAssociatedTypeMetadataAccessor: fallthrough
        case .DefaultAssociatedConformanceAccessor: fallthrough
        case .DependentAssociatedTypeRef: fallthrough
        case .DependentGenericSignature: fallthrough
        case .DependentGenericParamCount: fallthrough
        case .DependentGenericConformanceRequirement: fallthrough
        case .DependentGenericLayoutRequirement: fallthrough
        case .DependentGenericSameTypeRequirement: fallthrough
        case .DependentPseudogenericSignature: fallthrough
        case .Destructor: fallthrough
        case .DidSet: fallthrough
        case .DirectMethodReferenceAttribute: fallthrough
        case .Directness: fallthrough
        case .DynamicAttribute: fallthrough
        case .EscapingAutoClosureType: fallthrough
        case .NoEscapeFunctionType: fallthrough
        case .ExplicitClosure: fallthrough
        case .Extension: fallthrough
        case .EnumCase: fallthrough
        case .FieldOffset: fallthrough
        case .FullObjCResilientClassStub: fallthrough
        case .FullTypeMetadata: fallthrough
        case .Function: fallthrough
        case .FunctionSignatureSpecialization: fallthrough
        case .FunctionSignatureSpecializationParam: fallthrough
        case .FunctionSignatureSpecializationReturn: fallthrough
        case .FunctionSignatureSpecializationParamKind: fallthrough
        case .FunctionSignatureSpecializationParamPayload: fallthrough
        case .FunctionType: fallthrough
        case .GenericProtocolWitnessTable: fallthrough
        case .GenericProtocolWitnessTableInstantiationFunction: fallthrough
        case .GenericPartialSpecialization: fallthrough
        case .GenericPartialSpecializationNotReAbstracted: fallthrough
        case .GenericSpecialization: fallthrough
        case .GenericSpecializationNotReAbstracted: fallthrough
        case .GenericSpecializationParam: fallthrough
        case .InlinedGenericFunction: fallthrough
        case .GenericTypeMetadataPattern: fallthrough
        case .Getter: fallthrough
        case .Global: fallthrough
        case .GlobalGetter: fallthrough
        case .Identifier: fallthrough
        case .Index: fallthrough
        case .IVarInitializer: fallthrough
        case .IVarDestroyer: fallthrough
        case .ImplEscaping: fallthrough
        case .ImplConvention: fallthrough
        case .ImplFunctionAttribute: fallthrough
        case .ImplFunctionType: fallthrough
        case .ImplicitClosure: fallthrough
        case .ImplParameter: fallthrough
        case .ImplResult: fallthrough
        case .ImplErrorResult: fallthrough
        case .InOut: fallthrough
        case .InfixOperator: fallthrough
        case .Initializer: fallthrough
        case .KeyPathGetterThunkHelper: fallthrough
        case .KeyPathSetterThunkHelper: fallthrough
        case .KeyPathEqualsThunkHelper: fallthrough
        case .KeyPathHashThunkHelper: fallthrough
        case .LazyProtocolWitnessTableAccessor: fallthrough
        case .LazyProtocolWitnessTableCacheVariable: fallthrough
        case .LocalDeclName: fallthrough
        case .MaterializeForSet: fallthrough
        case .MergedFunction: fallthrough
        case .Metaclass: fallthrough
        case .MethodDescriptor: fallthrough
        case .MethodLookupFunction: fallthrough
        case .ModifyAccessor: fallthrough
        case .NativeOwningAddressor: fallthrough
        case .NativeOwningMutableAddressor: fallthrough
        case .NativePinningAddressor: fallthrough
        case .NativePinningMutableAddressor: fallthrough
        case .NominalTypeDescriptor: fallthrough
        case .NonObjCAttribute: fallthrough
        case .Number: fallthrough
        case .ObjCAttribute: fallthrough
        case .ObjCBlock: fallthrough
        case .ObjCMetadataUpdateFunction: fallthrough
        case .ObjCResilientClassStub: fallthrough
        case .OpaqueTypeDescriptor: fallthrough
        case .OpaqueTypeDescriptorAccessor: fallthrough
        case .OpaqueTypeDescriptorAccessorImpl: fallthrough
        case .OpaqueTypeDescriptorAccessorKey: fallthrough
        case .OpaqueTypeDescriptorAccessorVar: fallthrough
        case .Owned: fallthrough
        case .OwningAddressor: fallthrough
        case .OwningMutableAddressor: fallthrough
        case .PartialApplyForwarder: fallthrough
        case .PartialApplyObjCForwarder: fallthrough
        case .PostfixOperator: fallthrough
        case .PrefixOperator: fallthrough
        case .PrivateDeclName: fallthrough
        case .PropertyDescriptor: fallthrough
        case .ProtocolConformance: fallthrough
        case .ProtocolConformanceDescriptor: fallthrough
        case .ProtocolDescriptor: fallthrough
        case .ProtocolRequirementsBaseDescriptor: fallthrough
        case .ProtocolSelfConformanceDescriptor: fallthrough
        case .ProtocolSelfConformanceWitness: fallthrough
        case .ProtocolSelfConformanceWitnessTable: fallthrough
        case .ProtocolWitness: fallthrough
        case .ProtocolWitnessTable: fallthrough
        case .ProtocolWitnessTableAccessor: fallthrough
        case .ProtocolWitnessTablePattern: fallthrough
        case .ReabstractionThunk: fallthrough
        case .ReabstractionThunkHelper: fallthrough
        case .ReabstractionThunkHelperWithSelf: fallthrough
        case .ReadAccessor: fallthrough
        case .RelatedEntityDeclName: fallthrough
        case .RetroactiveConformance: fallthrough
        case .Setter: fallthrough
        case .Shared: fallthrough
        case .SILBoxLayout: fallthrough
        case .SILBoxMutableField: fallthrough
        case .SILBoxImmutableField: fallthrough
        case .IsSerialized: fallthrough
        case .SpecializationPassID: fallthrough
        case .Static: fallthrough
        case .Subscript: fallthrough
        case .Suffix: fallthrough
        case .ThinFunctionType: fallthrough
        case .TupleElement: fallthrough
        case .TypeMangling: fallthrough
        case .TypeMetadata: fallthrough
        case .TypeMetadataAccessFunction: fallthrough
        case .TypeMetadataCompletionFunction: fallthrough
        case .TypeMetadataInstantiationCache: fallthrough
        case .TypeMetadataInstantiationFunction: fallthrough
        case .TypeMetadataSingletonInitializationCache: fallthrough
        case .TypeMetadataLazyCache: fallthrough
        case .UncurriedFunctionType: fallthrough

            //#define REF_STORAGE(Name, ...) \
            //case .Name:
        //    #include "swift/AST/ReferenceStorage.def"
        case .Weak: fallthrough
        case .Unowned: fallthrough
        case .Unmanaged: fallthrough

        case .UnknownIndex: fallthrough
        case .UnsafeAddressor: fallthrough
        case .UnsafeMutableAddressor: fallthrough
        case .ValueWitness: fallthrough
        case .ValueWitnessTable: fallthrough
        case .Variable: fallthrough
        case .VTableAttribute: fallthrough
        case .VTableThunk: fallthrough
        case .WillSet: fallthrough
        case .ReflectionMetadataBuiltinDescriptor: fallthrough
        case .ReflectionMetadataFieldDescriptor: fallthrough
        case .ReflectionMetadataAssocTypeDescriptor: fallthrough
        case .ReflectionMetadataSuperclassDescriptor: fallthrough
        case .ResilientProtocolWitnessTable: fallthrough
        case .GenericTypeParamDecl: fallthrough
        case .ThrowsAnnotation: fallthrough
        case .EmptyList: fallthrough
        case .FirstElementMarker: fallthrough
        case .VariadicMarker: fallthrough
        case .OutlinedBridgedMethod: fallthrough
        case .OutlinedCopy: fallthrough
        case .OutlinedConsume: fallthrough
        case .OutlinedRetain: fallthrough
        case .OutlinedRelease: fallthrough
        case .OutlinedInitializeWithTake: fallthrough
        case .OutlinedInitializeWithCopy: fallthrough
        case .OutlinedAssignWithTake: fallthrough
        case .OutlinedAssignWithCopy: fallthrough
        case .OutlinedDestroy: fallthrough
        case .OutlinedVariable: fallthrough
        case .AssocTypePath: fallthrough
        case .ModuleDescriptor: fallthrough
        case .AnonymousDescriptor: fallthrough
        case .AssociatedTypeGenericParamRef: fallthrough
        case .ExtensionDescriptor: fallthrough
        case .AnonymousContext: fallthrough
        case .AnyProtocolConformanceList: fallthrough
        case .ConcreteProtocolConformance: fallthrough
        case .DependentAssociatedConformance: fallthrough
        case .DependentProtocolConformanceAssociated: fallthrough
        case .DependentProtocolConformanceInherited: fallthrough
        case .DependentProtocolConformanceRoot: fallthrough
        case .ProtocolConformanceRefInTypeModule: fallthrough
        case .ProtocolConformanceRefInProtocolModule: fallthrough
        case .ProtocolConformanceRefInOtherModule: fallthrough
        case .DynamicallyReplaceableFunctionKey: fallthrough
        case .DynamicallyReplaceableFunctionImpl: fallthrough
        case .DynamicallyReplaceableFunctionVar: fallthrough
        case .OpaqueType: fallthrough
        case .OpaqueTypeDescriptorSymbolicReference: fallthrough
        case .OpaqueReturnType: fallthrough
        case .OpaqueReturnTypeOf:
            return false
        }
    }

    private mutating func printWithParens(type: Node) {
        let needsParens = !isSimpleType(node: type)
        if needsParens {
            printer << "("
        }
        print(type)
        if needsParens {
            printer << ")"
        }
    }

    private func findSugar(node: Node) -> SugarType {
        if node.children.count == 1 && node.kind == .Type {
            return findSugar(node: node.children[0])
        }

        if node.children.count != 2 {
            return SugarType.None
        }

        if node.kind != .BoundGenericEnum && node.kind != .BoundGenericStructure {
            return SugarType.None
        }

        let unboundType = node.children[0].children[0] // drill through Type
        let typeArgs = node.children[1]

        if node.kind == .BoundGenericEnum {
            // Swift.Optional
            if isIdentifier(unboundType.children[1], desired: "Optional") && typeArgs.children.count == 1 && isSwiftModule(unboundType.children[0]) {
                return SugarType.Optional
            }

            // Swift.ImplicitlyUnwrappedOptional
            if isIdentifier(unboundType.children[1], desired: "ImplicitlyUnwrappedOptional") && typeArgs.children.count == 1 && isSwiftModule(unboundType.children[0]) {
                return SugarType.ImplicitlyUnwrappedOptional
            }

            return SugarType.None
        }

        precondition(node.kind == .BoundGenericStructure)

        // Array
        if isIdentifier(unboundType.children[1], desired: "Array") && typeArgs.children.count == 1 && isSwiftModule(unboundType.children[0]) {
            return SugarType.Array
        }

        // Dictionary
        if isIdentifier(unboundType.children[1], desired: "Dictionary") && typeArgs.children.count == 2 && isSwiftModule(unboundType.children[0]) {
            return SugarType.Dictionary
        }

        return SugarType.None
    }

    private mutating func printBoundGeneric(node: Node) {
        if node.children.count < 2 {
            return
        }

        if node.children.count != 2 {
            printBoundGenericNoSugar(node: node)
            return
        }

        if !options.contains(.SynthesizeSugarOnTypes) || node.kind == .BoundGenericClass {
            // no sugar here
            printBoundGenericNoSugar(node: node)
            return
        }

        // Print the conforming type for a "bound" protocol node "as" the protocol
        // type.
        if node.kind == .BoundGenericProtocol {
            printChildren(of: node.children[1])
            printer << " as "
            print(node.children[0])
            return
        }

        let sugarType = findSugar(node: node)

        switch sugarType {
        case SugarType.None:
            printBoundGenericNoSugar(node: node)
        case SugarType.Optional: fallthrough
        case SugarType.ImplicitlyUnwrappedOptional:
            let type: Node = node.children[1].children[0]
            printWithParens(type: type)
            printer << (sugarType == SugarType.Optional ? "?" : "!")
        case SugarType.Array:
            let type: Node = node.children[1].children[0]
            printer << "["
            print(type)
            printer << "]"
        case SugarType.Dictionary:
            let keyType: Node = node.children[1].children[0]
            let valueType: Node = node.children[1].children[1]
            printer << "["
            print(keyType)
            printer << " : "
            print(valueType)
            printer << "]"
        }
    }

    private func getChildIf(node: Node, kind: Node.Kind) -> Node? {
        node.children.first(where: { $0.kind == kind })
    }

    private mutating func printFunctionParameters(labelList: Node?, parameterType: Node, showTypes: Bool) {
        if parameterType.kind != .ArgumentTuple {
            setInvalid()
            return
        }

        var parameters: Node = parameterType.children[0]
        precondition(parameters.kind == .Type)
        parameters = parameters.children[0]
        if parameters.kind != .Tuple {
            // only a single not-named parameter
            if showTypes {
                printer << "("
                print(parameters)
                printer << ")"
            } else {
                printer << "(_:)"
            }
            return
        }

        func getLabelFor(labelList: Node, Param: Node, Index: Int) -> String {
            let Label = labelList.children[Index]
            precondition(Label.kind == .Identifier || Label.kind == .FirstElementMarker)
            return Label.kind == .Identifier ? Label.text : "_"
        }

        var paramIndex = 0

        printer << "("
        for (index, param) in parameters.children.enumerated() { // a.k.a. interleave
            if index > 0 {
                printer << (showTypes ? ", " : "")
            }
            precondition(param.kind == .TupleElement)

            if let labelList = labelList, !labelList.children.isEmpty {
                self.printer << getLabelFor(labelList: labelList, Param: param, Index: paramIndex)
                self.printer << ":"
            } else if !showTypes {
                if let labelText = self.getChildIf(node: param, kind: .TupleElementName)?.text {
                    self.printer << labelText
                    self.printer << ":"
                } else {
                    self.printer << "_:"
                }
            }

            if labelList?.children.isEmpty == false && showTypes {
                self.printer << " "
            }

            paramIndex += 1

            if showTypes {
                self.print(param)
            }
        }
        printer << ")"
    }

    private mutating func printFunctionType(labelList: Node?, node: Node) {
        if node.children.count != 2 && node.children.count != 3 {
            setInvalid()
            return
        }

        var startIndex = 0
        if node.children[0].kind == .ThrowsAnnotation {
            startIndex = 1
        }

        printFunctionParameters(labelList: labelList, parameterType: node.children[startIndex], showTypes: options.contains(.ShowFunctionArgumentTypes))

        if !options.contains(.ShowFunctionArgumentTypes) {
            return
        }

        if startIndex == 1 {
            printer << " throws"
        }

        print(node.children[startIndex + 1])
    }

    private mutating func printImplFunctionType(_ fn: Node) {
        enum State: Int { case Attrs, Inputs, Results }
        var curState = State.Attrs
        func transitionTo(_ newState: State) {
            precondition(newState.rawValue >= curState.rawValue)
            while curState != newState {
                switch (curState) {
                case .Attrs:
                    printer << "("
                    curState = State(rawValue: curState.rawValue + 1)!
                    continue
                case .Inputs:
                    printer << ") -> ("
                    curState = State(rawValue: curState.rawValue + 1)!
                    continue
                case .Results:
                    unreachable("no state after Results")
                }
            }
        }

        for child in fn.children {
            if child.kind == .ImplParameter {
                if curState == .Inputs { printer << ", " }
                transitionTo(.Inputs)
                print(child)
            } else if child.kind == .ImplResult || child.kind == .ImplErrorResult {
                if curState == .Results { printer << ", " }
                transitionTo(.Results)
                print(child)
            } else {
                precondition(curState == .Attrs)
                print(child)
                printer << " "
            }
        }
        transitionTo(.Results)
        printer << ")"
    }

    private mutating func printFunctionSigSpecializationParams(node: Node) {
        var idx = 0
        let end = node.children.count
        while idx < end {
            let firstChild: Node = node.children[idx]
            let V = firstChild.index
            let K = FunctionSigSpecializationParamKind(rawValue: V)
            switch (K) {
            case .BoxToValue: fallthrough
            case .BoxToStack:
                print(node.children[idx])
                idx += 1
                break
            case .ConstantPropFunction: fallthrough
            case .ConstantPropGlobal:
                printer << "["
                print(node.children[idx])
                idx += 1
                printer << " : "
                let text = node.children[idx].text
                idx += 1
                if let demangledName = (try? Mangle.demangleSymbol(mangledName: text))?.description {
                    printer << demangledName
                } else {
                    printer << text
                }
                printer << "]"
            case .ConstantPropInteger: fallthrough
            case .ConstantPropFloat:
                printer << "["
                print(node.children[idx])
                idx += 1
                printer << " : "
                print(node.children[idx])
                idx += 1
                printer << "]"
            case .ConstantPropString:
                printer << "["
                print(node.children[idx])
                idx += 1
                printer << " : "
                print(node.children[idx])
                idx += 1
                printer << "'"
                print(node.children[idx])
                idx += 1
                printer << "'"
                printer << "]"
            case .ClosureProp:
                printer << "["
                print(node.children[idx])
                idx += 1
                printer << " : "
                print(node.children[idx])
                idx += 1
                printer << ", Argument Types : ["
                let e = node.children.count
                while idx < e {
                    let child: Node = node.children[idx]
                    // Until we no longer have a type node, keep demangling.
                    if child.kind != .Type {
                        break
                    }
                    print(child)
                    idx += 1

                    // If we are not done, print the ", ".
                    if idx < e && node.children[idx].hasText {
                        printer << ", "
                    }
                }
                printer << "]"
            default:
                precondition( (V & UInt64(FunctionSigSpecializationParamKind.OwnedToGuaranteed.rawValue) != 0) ||
                    (V & UInt64(FunctionSigSpecializationParamKind.GuaranteedToOwned.rawValue) != 0) ||
                    (V & UInt64(FunctionSigSpecializationParamKind.SROA.rawValue) != 0) ||
                    (V & UInt64(FunctionSigSpecializationParamKind.Dead.rawValue) != 0) ||
                    (V & UInt64(FunctionSigSpecializationParamKind.ExistentialToGeneric.rawValue) != 0)
                )
                print(node.children[idx])
                idx += 1
            }
        }
    }

    private mutating func printSpecializationPrefix(_ node: Node, description: String, paramPrefix: String = "") {
        if !options.contains(.DisplayGenericSpecializations) {
            if !specializationPrefixPrinted {
                printer << "specialized "
                specializationPrefixPrinted = true
            }
            return
        }
        printer << description
        printer << " <"
        var separator = ""
        var argNum = 0
        for child in node.children {
            switch child.kind {
            case .SpecializationPassID:
                // We skip the SpecializationPassID since it does not contain any
                // information that is useful to our users.
                break

            case .IsSerialized:
                printer << separator
                separator = ", "
                print(child)

            default:
                // Ignore empty specializations.
                if child.children.count > 0 {
                    printer << separator
                    printer << paramPrefix
                    separator = ", "
                    switch (child.kind) {
                    case .FunctionSignatureSpecializationParam:
                        printer << "Arg["
                        printer << argNum
                        printer << "] = "
                        printFunctionSigSpecializationParams(node: child)
                    case .FunctionSignatureSpecializationReturn:
                        printer << "Return = "
                        printFunctionSigSpecializationParams(node: child)
                    default:
                        print(child)
                    }
                }
                argNum += 1
                break
            }
        }
        printer << "> of "
    }

    /// The main big print function.
    @discardableResult
    private mutating func print(_ node: Node, asPrefixContext: Bool = false) -> Node? {
        switch node.kind {
        case .Static:
            printer << "static "
            print(node.children[0])
            return nil
        case .CurryThunk:
            printer << "curry thunk of "
            print(node.children[0])
            return nil
        case .DispatchThunk:
            printer << "dispatch thunk of "
            print(node.children[0])
            return nil
        case .MethodDescriptor:
            printer << "method descriptor for "
            print(node.children[0])
            return nil
        case .MethodLookupFunction:
            printer << "method lookup function for "
            print(node.children[0])
            return nil
        case .ObjCMetadataUpdateFunction:
            printer << "ObjC metadata update function for "
            print(node.children[0])
            return nil
        case .ObjCResilientClassStub:
            printer << "ObjC resilient class stub for "
            print(node.children[0])
            return nil
        case .FullObjCResilientClassStub:
            printer << "full ObjC resilient class stub for "
            print(node.children[0])
            return nil
        case .OutlinedBridgedMethod:
            printer << "outlined bridged method ("
            printer << node.text
            printer << ") of "
            return nil
        case .OutlinedCopy:
            printer << "outlined copy of "
            print(node.children[0])
            if node.children.count > 1 {
                print(node.children[1])
            }
            return nil
        case .OutlinedConsume:
            printer << "outlined consume of "
            print(node.children[0])
            if node.children.count > 1 {
                print(node.children[1])
            }
            return nil
        case .OutlinedRetain:
            printer << "outlined retain of "
            print(node.children[0])
            return nil
        case .OutlinedRelease:
            printer << "outlined release of "
            print(node.children[0])
            return nil
        case .OutlinedInitializeWithTake:
            printer << "outlined init with take of "
            print(node.children[0])
            return nil
        case .OutlinedInitializeWithCopy:
            printer << "outlined init with copy of "
            print(node.children[0])
            return nil
        case .OutlinedAssignWithTake:
            printer << "outlined assign with take of "
            print(node.children[0])
            return nil
        case .OutlinedAssignWithCopy:
            printer << "outlined assign with copy of "
            print(node.children[0])
            return nil
        case .OutlinedDestroy:
            printer << "outlined destroy of "
            print(node.children[0])
            return nil
        case .OutlinedVariable:
            printer << "outlined variable #"
            printer << node.index
            printer << " of "
            return nil
        case .Directness:
            printer << Directness(rawValue: node.index)!.description
            printer << " "
            return nil
        case .AnonymousContext:
            if options.contains(.QualifyEntities) && options.contains(.DisplayExtensionContexts) {
                print(node.children[1])
                printer << ".(unknown context at "
                print(node.children[0])
                printer << ")"
                if node.children.count >= 3 && node.children[2].children.count > 0 {
                    printer << "<"
                    print(node.children[2])
                    printer << ">"
                }
            }
            return nil
        case .Extension:
            precondition(node.children.count == 2 || node.children.count == 3, "Extension expects 2 or 3 children.")
            if options.contains(.QualifyEntities) && options.contains(.DisplayExtensionContexts) {
                printer << "(extension in "
                // Print the module where extension is defined.
                print(node.children[0], asPrefixContext: true)
                printer << "):"
            }
            print(node.children[1])
            if node.children.count == 3 {
                print(node.children[2])
            }
            return nil
        case .Variable:
            return printEntity(node, asPrefixContext: asPrefixContext, typePr: .WithColon, /*hasName*/ hasName: true)
        case .Function: fallthrough
        case .BoundGenericFunction:
            return printEntity(node, asPrefixContext: asPrefixContext, typePr: .FunctionStyle, /*hasName*/ hasName: true)
        case .Subscript:
            return printEntity(node, asPrefixContext: asPrefixContext, typePr: .FunctionStyle, /*hasName*/ hasName: false, overwriteName: "subscript")
        case .GenericTypeParamDecl:
            return printEntity(node, asPrefixContext: asPrefixContext, typePr: .NoType, /*hasName*/hasName: true)
        case .ExplicitClosure:
            return printEntity(node, asPrefixContext: asPrefixContext, typePr: options.contains(.ShowFunctionArgumentTypes) ? .FunctionStyle : .NoType, /*hasName*/hasName: false, extraName: "closure #", extraIndex: node.children[1].index + 1)
        case .ImplicitClosure:
            return printEntity(node, asPrefixContext: asPrefixContext, typePr: options.contains(.ShowFunctionArgumentTypes) ? .FunctionStyle : .NoType, /*hasName*/hasName: false, extraName: "implicit closure #", extraIndex: node.children[1].index + 1)
        case .Global:
            printChildren(of: node)
            return nil
        case .Suffix:
            if options.contains(.DisplayUnmangledSuffix) {
                printer << " with unmangled suffix "
                printer << String.Quoted(node.text)
            }
            return nil
        case .Initializer:
            return printEntity(node, asPrefixContext: asPrefixContext, typePr: .NoType, /*hasName*/hasName: false, extraName: "variable initialization expression")
        case .DefaultArgumentInitializer:
            return printEntity(node, asPrefixContext: asPrefixContext, typePr: .NoType, /*hasName*/hasName: false, extraName: "default argument ", extraIndex: node.children[1].index)
        case .DeclContext:
            print(node.children[0])
            return nil
        case .Type:
            print(node.children[0])
            return nil
        case .TypeMangling:
            if node.children[0].kind == .LabelList {
                printFunctionType(labelList: node.children[0], node: node.children[1].children[0])
            } else {
                print(node.children[0])
            }
            return nil
        case .Class: fallthrough
        case .Structure: fallthrough
        case .Enum: fallthrough
        case .Protocol: fallthrough
        case .TypeAlias: fallthrough
        case .OtherNominalType:
            return printEntity(node, asPrefixContext: asPrefixContext, typePr: .NoType, /*hasName*/hasName: true)
        case .LocalDeclName:
            print(node.children[1])
            printer << " #"
            printer << (node.children[0].index + 1)
            return nil
        case .PrivateDeclName:
            if node.children.count > 1 {
                if options.contains(.ShowPrivateDiscriminators) {
                    printer << "("
                }

                print(node.children[1])

                if options.contains(.ShowPrivateDiscriminators) {
                    printer << " in "
                    printer << node.children[0].text
                    printer << ")"
                }
            } else {
                if options.contains(.ShowPrivateDiscriminators) {
                    printer << "(in "
                    printer << node.children[0].text
                    printer << ")"
                }
            }
            return nil
        case .RelatedEntityDeclName:
            printer << "related decl '"
            printer << node.children[0].text
            printer << "' for "
            print(node.children[1])
            return nil
        case .Module:
            if options.contains(.DisplayModuleNames) {
                printer << node.text
            }
            return nil
        case .Identifier:
            printer << node.text
            return nil
        case .Index:
            printer << node.index
            return nil
        case .UnknownIndex:
            printer << "unknown index"
            return nil
        case .NoEscapeFunctionType:
            printFunctionType(labelList: nil, node: node)
            return nil
        case .EscapingAutoClosureType:
            printer << "@autoclosure "
            printFunctionType(labelList: nil, node: node)
            return nil
        case .AutoClosureType:
            printer << "@autoclosure "
            printFunctionType(labelList: nil, node: node)
            return nil
        case .ThinFunctionType:
            printer << "@convention(thin) "
            printFunctionType(labelList: nil, node: node)
            return nil
        case .FunctionType: fallthrough
        case .UncurriedFunctionType:
            printFunctionType(labelList: nil, node: node)
            return nil
        case .ArgumentTuple:
            printFunctionParameters(labelList: nil, parameterType: node, showTypes: options.contains(.ShowFunctionArgumentTypes))
            return nil
        case .Tuple:
            printer << "("
            printChildren(of: node, separator: ", ")
            printer << ")"
            return nil
        case .TupleElement:
            if let label = getChildIf(node: node, kind: .TupleElementName) {
                printer << label.text
                printer << ": "
            }

            guard let type = getChildIf(node: node, kind: .Type) else {
                unreachable("malformed .TupleElement")
            }

            print(type)

            if getChildIf(node: node, kind: .VariadicMarker) != nil {
                printer << "..."
            }
            return nil
        case .TupleElementName:
            printer << node.text
            printer << ": "
            return nil
        case .ReturnType:
            if node.children.count == 0 {
                printer << " -> "
                printer << node.text
            } else {
                printer << " -> "
                printChildren(of: node)
            }
            return nil
        case .RetroactiveConformance:
            if node.children.count != 2 {
                return nil
            }

            printer << "retroactive @ "
            print(node.children[0])
            print(node.children[1])
            return nil
        case .Weak:
            printer << "weak "
            printChildren(of: node)
            return nil
        case .Unowned:
            printer << "unowned "
            printChildren(of: node)
            return nil
        case .Unmanaged:
            printer << "unowned(unsafe) "
            printChildren(of: node)
            return nil

        case .InOut:
            printer << "inout "
            print(node.children[0])
            return nil
        case .Shared:
            printer << "__shared "
            print(node.children[0])
            return nil
        case .Owned:
            printer << "__owned "
            print(node.children[0])
            return nil
        case .NonObjCAttribute:
            printer << "@nonobjc "
            return nil
        case .ObjCAttribute:
            printer << "@objc "
            return nil
        case .DirectMethodReferenceAttribute:
            printer << "super "
            return nil
        case .DynamicAttribute:
            printer << "dynamic "
            return nil
        case .VTableAttribute:
            printer << "override "
            return nil
        case .FunctionSignatureSpecialization:
            printSpecializationPrefix(node, description: "function signature specialization")
            return nil
        case .GenericPartialSpecialization:
            printSpecializationPrefix(node, description: "generic partial specialization", paramPrefix: "Signature = ")
            return nil
        case .GenericPartialSpecializationNotReAbstracted:
            printSpecializationPrefix(node, description: "generic not-reabstracted partial specialization", paramPrefix: "Signature = ")
            return nil
        case .GenericSpecialization:
            printSpecializationPrefix(node, description: "generic specialization")
            return nil
        case .GenericSpecializationNotReAbstracted:
            printSpecializationPrefix(node, description: "generic not re-abstracted specialization")
            return nil
        case .InlinedGenericFunction:
            printSpecializationPrefix(node, description: "inlined generic function")
            return nil
        case .IsSerialized:
            printer << "serialized"
            return nil
        case .GenericSpecializationParam:
            print(node.children[0])
            for i in 1..<node.children.count {
                if i == 1 {
                    printer << " with "
                } else {
                    printer << " and "
                }
                print(node.children[i])
            }
            return nil
        case .FunctionSignatureSpecializationReturn: fallthrough
        case .FunctionSignatureSpecializationParam:
            unreachable("should be handled in printSpecializationPrefix")
        case .FunctionSignatureSpecializationParamPayload:
            if let demangledName = (try? Mangle.demangleSymbol(mangledName: node.text))?.description {
                printer << demangledName
            } else {
                printer << node.text
            }
            return nil
        case .FunctionSignatureSpecializationParamKind:
            let raw = node.index

            var printedOptionSet = false
            if raw & FunctionSigSpecializationParamKind.ExistentialToGeneric.rawValue != 0 {
                printedOptionSet = true
                printer << "Existential To Protocol Constrained Generic"
            }

            if raw & FunctionSigSpecializationParamKind.Dead.rawValue != 0 {
                if printedOptionSet {
                    printer << " and "
                }
                printedOptionSet = true
                printer << "Dead"
            }
            if raw & FunctionSigSpecializationParamKind.OwnedToGuaranteed.rawValue != 0 {
                if printedOptionSet {
                    printer << " and "
                }
                printedOptionSet = true
                printer << "Owned To Guaranteed"
            }

            if raw & FunctionSigSpecializationParamKind.GuaranteedToOwned.rawValue != 0 {
                if printedOptionSet {
                    printer << " and "
                }
                printedOptionSet = true
                printer << "Guaranteed To Owned"
            }

            if raw & FunctionSigSpecializationParamKind.SROA.rawValue != 0 {
                if printedOptionSet {
                    printer << " and "
                }
                printer << "Exploded"
                return nil
            }

            if printedOptionSet {
                return nil
            }

            switch FunctionSigSpecializationParamKind(rawValue: raw)! {
            case .BoxToValue:
                printer << "Value Promoted from Box"
                return nil
            case .BoxToStack:
                printer << "Stack Promoted from Box"
                return nil
            case .ConstantPropFunction:
                printer << "Constant Propagated Function"
                return nil
            case .ConstantPropGlobal:
                printer << "Constant Propagated Global"
                return nil
            case .ConstantPropInteger:
                printer << "Constant Propagated Integer"
                return nil
            case .ConstantPropFloat:
                printer << "Constant Propagated Float"
                return nil
            case .ConstantPropString:
                printer << "Constant Propagated String"
                return nil
            case .ClosureProp:
                printer << "Closure Propagated"
                return nil
            case .ExistentialToGeneric: fallthrough
            case .Dead: fallthrough
            case .OwnedToGuaranteed: fallthrough
            case .GuaranteedToOwned: fallthrough
            case .SROA:
                unreachable("option sets should have been handled earlier")
            }
        case .SpecializationPassID:
            printer << node.index
            return nil
        case .BuiltinTypeName:
            printer << node.text
            return nil
        case .Number:
            printer << node.index
            return nil
        case .InfixOperator:
            printer << node.text
            printer << " infix"
            return nil
        case .PrefixOperator:
            printer << node.text
            printer << " prefix"
            return nil
        case .PostfixOperator:
            printer << node.text
            printer << " postfix"
            return nil
        case .LazyProtocolWitnessTableAccessor:
            printer << "lazy protocol witness table accessor for type "
            print(node.children[0])
            printer << " and conformance "
            print(node.children[1])
            return nil
        case .LazyProtocolWitnessTableCacheVariable:
            printer << "lazy protocol witness table cache variable for type "
            print(node.children[0])
            printer << " and conformance "
            print(node.children[1])
            return nil
        case .ProtocolSelfConformanceWitnessTable:
            printer << "protocol self-conformance witness table for "
            print(node.children[0])
            return nil
        case .ProtocolWitnessTableAccessor:
            printer << "protocol witness table accessor for "
            print(node.children[0])
            return nil
        case .ProtocolWitnessTable:
            printer << "protocol witness table for "
            print(node.children[0])
            return nil
        case .ProtocolWitnessTablePattern:
            printer << "protocol witness table pattern for "
            print(node.children[0])
            return nil
        case .GenericProtocolWitnessTable:
            printer << "generic protocol witness table for "
            print(node.children[0])
            return nil
        case .GenericProtocolWitnessTableInstantiationFunction:
            printer << "instantiation function for generic protocol witness table for "
            print(node.children[0])
            return nil
        case .ResilientProtocolWitnessTable:
            printer << "resilient protocol witness table for "
            print(node.children[0])
            return nil
        case .VTableThunk:
            printer << "vtable thunk for "
            print(node.children[1])
            printer << " dispatching to "
            print(node.children[0])
            return nil
        case .ProtocolSelfConformanceWitness:
            printer << "protocol self-conformance witness for "
            print(node.children[0])
            return nil
        case .ProtocolWitness:
            printer << "protocol witness for "
            print(node.children[1])
            printer << " in conformance "
            print(node.children[0])
            return nil
        case .PartialApplyForwarder:
            if options.contains(.ShortenPartialApply) {
                printer << "partial apply"
            } else {
                printer << "partial apply forwarder"
            }

            if node.children.count > 0 {
                printer << " for "
                print(node.children[0])
            }
            return nil
        case .PartialApplyObjCForwarder:
            if options.contains(.ShortenPartialApply) {
                printer << "partial apply"
            } else {
                printer << "partial apply ObjC forwarder"
            }

            if node.children.count > 0 {
                printer << " for "
                print(node.children[0])
            }
            return nil
        case .KeyPathGetterThunkHelper: fallthrough
        case .KeyPathSetterThunkHelper:
            if node.kind == .KeyPathGetterThunkHelper {
                printer << "key path getter for "
            } else {
                printer << "key path setter for "
            }

            print(node.children[0])
            printer << " : "
            for child in node.children.dropFirst() {
                if child.kind == .IsSerialized {
                    printer << ", "
                }
                print(child)
            }
            return nil
        case .KeyPathEqualsThunkHelper: fallthrough
        case .KeyPathHashThunkHelper:
            printer << "key path index "
            printer << (node.kind == .KeyPathEqualsThunkHelper ? "equality" : "hash")
            printer  << " operator for "

            var lastChildIndex = node.children.count
            var lastChild = node.children[lastChildIndex]
            if lastChild.kind == .IsSerialized {
                lastChildIndex -= 1
                lastChild = node.children[lastChildIndex]
            }

            if lastChild.kind == .DependentGenericSignature {
                print(lastChild)
                lastChildIndex -= 1
            }

            printer << "("
            for i in 0..<lastChildIndex {
                if i != 0 {
                    printer << ", "
                }
                print(node.children[i])
            }
            printer << ")"
            return nil
        case .FieldOffset:
            print(node.children[0]) // directness
            printer << "field offset for "
            let entity = node.children[1]
            print(entity, /*asContext*/ asPrefixContext: false)
            return nil
        case .EnumCase:
            printer << "enum case for "
            let entity = node.children[0]
            print(entity, /*asContext*/ asPrefixContext: false)
            return nil
        case .ReabstractionThunk: fallthrough
        case .ReabstractionThunkHelper:
            if options.contains(.ShortenThunk) {
                printer << "thunk for "
                print(node.children[node.children.count - 1])
                return nil
            }
            printer << "reabstraction thunk "
            if node.kind == .ReabstractionThunkHelper {
                printer << "helper "
            }
            var idx = 0
            if node.children.count == 3 {
                let generics = node.children[0]
                idx = 1
                print(generics)
                printer << " "
            }
            printer << "from "
            print(node.children[idx + 1])
            printer << " to "
            print(node.children[idx])
            return nil
        case .ReabstractionThunkHelperWithSelf:
            printer << "reabstraction thunk "
            var idx = 0
            if node.children.count == 4 {
                let generics = node.children[0]
                idx = 1
                print(generics)
                printer << " "
            }
            printer << "from "
            print(node.children[idx + 2])
            printer << " to "
            print(node.children[idx + 1])
            printer << " self "
            print(node.children[idx])
            return nil
        case .MergedFunction:
            if !options.contains(.ShortenThunk) {
                printer << "merged "
            }
            return nil
        case .TypeSymbolicReference:
            printer << "type symbolic reference 0x"
            printer.writeHex(node.index)
            return nil
        case .OpaqueTypeDescriptorSymbolicReference:
            printer << "opaque type symbolic reference 0x"
            printer.writeHex(node.index)
            return nil
        case .DynamicallyReplaceableFunctionKey:
            if !options.contains(.ShortenThunk) {
                printer << "dynamically replaceable key for "
            }
            return nil
        case .DynamicallyReplaceableFunctionImpl:
            if !options.contains(.ShortenThunk) {
                printer << "dynamically replaceable thunk for "
            }
            return nil
        case .DynamicallyReplaceableFunctionVar:
            if !options.contains(.ShortenThunk) {
                printer << "dynamically replaceable variable for "
            }
            return nil
        case .ProtocolSymbolicReference:
            printer << "protocol symbolic reference 0x"
            printer.writeHex(node.index)
            return nil
        case .GenericTypeMetadataPattern:
            printer << "generic type metadata pattern for "
            print(node.children[0])
            return nil
        case .Metaclass:
            printer << "metaclass for "
            print(node.children[0])
            return nil
        case .ProtocolSelfConformanceDescriptor:
            printer << "protocol self-conformance descriptor for "
            print(node.children[0])
            return nil
        case .ProtocolConformanceDescriptor:
            printer << "protocol conformance descriptor for "
            print(node.children[0])
            return nil
        case .ProtocolDescriptor:
            printer << "protocol descriptor for "
            print(node.children[0])
            return nil
        case .ProtocolRequirementsBaseDescriptor:
            printer << "protocol requirements base descriptor for "
            print(node.children[0])
            return nil
        case .FullTypeMetadata:
            printer << "full type metadata for "
            print(node.children[0])
            return nil
        case .TypeMetadata:
            printer << "type metadata for "
            print(node.children[0])
            return nil
        case .TypeMetadataAccessFunction:
            printer << "type metadata accessor for "
            print(node.children[0])
            return nil
        case .TypeMetadataInstantiationCache:
            printer << "type metadata instantiation cache for "
            print(node.children[0])
            return nil
        case .TypeMetadataInstantiationFunction:
            printer << "type metadata instantiation function for "
            print(node.children[0])
            return nil
        case .TypeMetadataSingletonInitializationCache:
            printer << "type metadata singleton initialization cache for "
            print(node.children[0])
            return nil
        case .TypeMetadataCompletionFunction:
            printer << "type metadata completion function for "
            print(node.children[0])
            return nil
        case .TypeMetadataLazyCache:
            printer << "lazy cache variable for type metadata for "
            print(node.children[0])
            return nil
        case .AssociatedConformanceDescriptor:
            printer << "associated conformance descriptor for "
            print(node.children[0])
            printer << "."
            print(node.children[1])
            printer << ": "
            print(node.children[2])
            return nil
        case .DefaultAssociatedConformanceAccessor:
            printer << "default associated conformance accessor for "
            print(node.children[0])
            printer << "."
            print(node.children[1])
            printer << ": "
            print(node.children[2])
            return nil
        case .AssociatedTypeDescriptor:
            printer << "associated type descriptor for "
            print(node.children[0])
            return nil
        case .AssociatedTypeMetadataAccessor:
            printer << "associated type metadata accessor for "
            print(node.children[1])
            printer << " in "
            print(node.children[0])
            return nil
        case .BaseConformanceDescriptor:
            printer << "base conformance descriptor for "
            print(node.children[0])
            printer << ": "
            print(node.children[1])
            return nil
        case .DefaultAssociatedTypeMetadataAccessor:
            printer << "default associated type metadata accessor for "
            print(node.children[0])
            return nil
        case .AssociatedTypeWitnessTableAccessor:
            printer << "associated type witness table accessor for "
            print(node.children[1])
            printer << " : "
            print(node.children[2])
            printer << " in "
            print(node.children[0])
            return nil
        case .BaseWitnessTableAccessor:
            printer << "base witness table accessor for "
            print(node.children[1])
            printer << " in "
            print(node.children[0])
            return nil
        case .ClassMetadataBaseOffset:
            printer << "class metadata base offset for "
            print(node.children[0])
            return nil
        case .PropertyDescriptor:
            printer << "property descriptor for "
            print(node.children[0])
            return nil
        case .NominalTypeDescriptor:
            printer << "nominal type descriptor for "
            print(node.children[0])
            return nil
        case .OpaqueTypeDescriptor:
            printer << "opaque type descriptor for "
            print(node.children[0])
            return nil
        case .OpaqueTypeDescriptorAccessor:
            printer << "opaque type descriptor accessor for "
            print(node.children[0])
            return nil
        case .OpaqueTypeDescriptorAccessorImpl:
            printer << "opaque type descriptor accessor impl for "
            print(node.children[0])
            return nil
        case .OpaqueTypeDescriptorAccessorKey:
            printer << "opaque type descriptor accessor key for "
            print(node.children[0])
            return nil
        case .OpaqueTypeDescriptorAccessorVar:
            printer << "opaque type descriptor accessor var for "
            print(node.children[0])
            return nil
        case .CoroutineContinuationPrototype:
            printer << "coroutine continuation prototype for "
            print(node.children[0])
            return nil
        case .ValueWitness:
            printer << ValueWitnessKind(rawValue: node.children[0].index)!.description
            if options.contains(.ShortenValueWitness) {
                printer << " for "
            } else {
                printer << " value witness for "
            }
            print(node.children[1])
            return nil
        case .ValueWitnessTable:
            printer << "value witness table for "
            print(node.children[0])
            return nil
        case .BoundGenericClass: fallthrough
        case .BoundGenericStructure: fallthrough
        case .BoundGenericEnum: fallthrough
        case .BoundGenericProtocol: fallthrough
        case .BoundGenericOtherNominalType: fallthrough
        case .BoundGenericTypeAlias:
            printBoundGeneric(node: node)
            return nil
        case .DynamicSelf:
            printer << "Self"
            return nil
        case .CFunctionPointer:
            printer << "@convention(c) "
            printFunctionType(labelList: nil, node: node)
            return nil
        case .ObjCBlock:
            printer << "@convention(block) "
            printFunctionType(labelList: nil, node: node)
            return nil
        case .SILBoxType:
            printer << "@box "
            let type = node.children[0]
            print(type)
            return nil
        case .Metatype:
            var idx = 0
            if node.children.count == 2 {
                let repr = node.children[idx]
                print(repr)
                printer << " "
                idx += 1
            }
            let type = node.children[idx].children[0]
            printWithParens(type: type)
            if isExistentialType(node: type) {
                printer << ".Protocol"
            } else {
                printer << ".Type"
            }
            return nil
        case .ExistentialMetatype:
            var idx = 0
            if node.children.count == 2 {
                let repr = node.children[idx]
                print(repr)
                printer << " "
                idx += 1
            }

            let type = node.children[idx]
            print(type)
            printer << ".Type"
            return nil
        case .MetatypeRepresentation:
            printer << node.text
            return nil
        case .AssociatedTypeRef:
            print(node.children[0])
            printer << "."
            printer << node.children[1].text
            return nil
        case .ProtocolList:
            if node.children.isEmpty {
                return nil
            }
            let type_list = node.children[0]
            if type_list.children.count == 0 {
                printer << "Any"
            } else {
                printChildren(of: type_list, separator: " & ")
            }
            return nil
        case .ProtocolListWithClass:
            if node.children.count < 2 {
                return nil
            }
            let protocols = node.children[0]
            let superclass = node.children[1]
            print(superclass)
            printer << " & "
            if protocols.children.count < 1 {
                return nil
            }
            let type_list = protocols.children[0]
            printChildren(of: type_list, separator: " & ")
            return nil
        case .ProtocolListWithAnyObject:
            if node.children.count < 1 {
                return nil
            }
            let protocols = node.children[0]
            if protocols.children.count < 1 {
                return nil
            }
            let type_list = protocols.children[0]
            if type_list.children.count > 0 {
                printChildren(of: type_list, separator: " & ")
                printer << " & "
            }
            if options.contains(.QualifyEntities) {
                printer << "Swift."
            }
            printer << "AnyObject"
            return nil
        case .AssociatedType:
            // Don"t print for now.
            return nil
        case .OwningAddressor:
            return printAbstractStorage(node: node.children[0], asPrefixContent: asPrefixContext, extraName: "owningAddressor")
        case .OwningMutableAddressor:
            return printAbstractStorage(node: node.children[0], asPrefixContent: asPrefixContext, extraName: "owningMutableAddressor")
        case .NativeOwningAddressor:
            return printAbstractStorage(node: node.children[0], asPrefixContent: asPrefixContext, extraName: "nativeOwningAddressor")
        case .NativeOwningMutableAddressor:
            return printAbstractStorage(node: node.children[0], asPrefixContent: asPrefixContext, extraName: "nativeOwningMutableAddressor")
        case .NativePinningAddressor:
            return printAbstractStorage(node: node.children[0], asPrefixContent: asPrefixContext, extraName: "nativePinningAddressor")
        case .NativePinningMutableAddressor:
            return printAbstractStorage(node: node.children[0], asPrefixContent: asPrefixContext, extraName: "nativePinningMutableAddressor")
        case .UnsafeAddressor:
            return printAbstractStorage(node: node.children[0], asPrefixContent: asPrefixContext, extraName: "unsafeAddressor")
        case .UnsafeMutableAddressor:
            return printAbstractStorage(node: node.children[0], asPrefixContent: asPrefixContext, extraName: "unsafeMutableAddressor")
        case .GlobalGetter:
            return printAbstractStorage(node: node.children[0], asPrefixContent: asPrefixContext, extraName: "getter")
        case .Getter:
            return printAbstractStorage(node: node.children[0], asPrefixContent: asPrefixContext, extraName: "getter")
        case .Setter:
            return printAbstractStorage(node: node.children[0], asPrefixContent: asPrefixContext, extraName: "setter")
        case .MaterializeForSet:
            return printAbstractStorage(node: node.children[0], asPrefixContent: asPrefixContext, extraName: "materializeForSet")
        case .WillSet:
            return printAbstractStorage(node: node.children[0], asPrefixContent: asPrefixContext, extraName: "willset")
        case .DidSet:
            return printAbstractStorage(node: node.children[0], asPrefixContent: asPrefixContext, extraName: "didset")
        case .ReadAccessor:
            return printAbstractStorage(node: node.children[0], asPrefixContent: asPrefixContext, extraName: "read")
        case .ModifyAccessor:
            return printAbstractStorage(node: node.children[0], asPrefixContent: asPrefixContext, extraName: "modify")
        case .Allocator:
            return printEntity(node, asPrefixContext: asPrefixContext, typePr: .FunctionStyle, /*hasName*/hasName: false, extraName: isClassType(node: node.children[0]) ? "__allocating_init" : "init")
        case .Constructor:
            return printEntity(node, asPrefixContext: asPrefixContext, typePr: .FunctionStyle, /*hasName*/hasName: node.children.count > 2, extraName: "init")
        case .Destructor:
            return printEntity(node, asPrefixContext: asPrefixContext, typePr: .NoType, /*hasName*/hasName: false, extraName: "deinit")
        case .Deallocator:
            return printEntity(node, asPrefixContext: asPrefixContext, typePr: .NoType, /*hasName*/hasName: false, extraName: isClassType(node: node.children[0]) ? "__deallocating_deinit" : "deinit")
        case .IVarInitializer:
            return printEntity(node, asPrefixContext: asPrefixContext, typePr: .NoType, /*hasName*/hasName: false, extraName: "__ivar_initializer")
        case .IVarDestroyer:
            return printEntity(node, asPrefixContext: asPrefixContext, typePr: .NoType, /*hasName*/hasName: false, extraName: "__ivar_destroyer")
        case .ProtocolConformance:
            let child0 = node.children[0]
            let child1 = node.children[1]
            let child2 = node.children[2]
            if node.children.count == 4 {
                // TO_apple_DO: check if this is correct
                printer << "property behavior storage of "
                print(child2)
                printer << " in "
                print(child0)
                printer << " : "
                print(child1)
            } else {
                print(child0)
                if options.contains(.DisplayProtocolConformances) {
                    printer << " : "
                    print(child1)
                    printer << " in "
                    print(child2)
                }
            }
            return nil
        case .TypeList:
            printChildren(of: node)
            return nil
        case .LabelList:
            return nil
        case .ImplEscaping:
            printer << "@escaping"
            return nil
        case .ImplConvention:
            printer << node.text
            return nil
        case .ImplFunctionAttribute:
            printer << node.text
            return nil
        case .ImplErrorResult:
            printer << "@error "
            fallthrough
        case .ImplParameter: fallthrough
        case .ImplResult:
            printChildren(of: node, separator: " ")
            return nil
        case .ImplFunctionType:
            printImplFunctionType(node)
            return nil
        case .ErrorType:
            printer << "<ERROR TYPE>"
            return nil

        case .DependentPseudogenericSignature: fallthrough
        case .DependentGenericSignature:
            printer << "<"

            var depth = 0
            let numChildren = node.children.count
            while depth < numChildren && node.children[depth].kind == .DependentGenericParamCount {
                if depth != 0 {
                    printer << "><"
                }

                let count = node.children[depth].index
                for index in 0..<count {
                    if index != 0 {
                        printer << ", "
                    }
                    // Limit the number of printed generic parameters. In practice this
                    // it will never be exceeded. The limit is only imporant for malformed
                    // symbols where count can be really huge.
                    if index >= 128 {
                        printer << "..."
                        break
                    }
                    // FIX_apple_ME: Depth won"t match when a generic signature applies to a
                    // method in generic type context.
                    printer << genericParameterName(depth: UInt64(depth), index: index) // XXX: must be customisable
                }

                depth += 1
            }

            if depth != numChildren {
                if options.contains(.DisplayWhereClauses) {
                    printer << " where "
                    for i in depth..<numChildren {
                        if i > depth {
                            printer << ", "
                        }
                        print(node.children[i])
                    }
                }
            }
            printer << ">"
            return nil
        case .DependentGenericParamCount:
            unreachable("should be printed as a child of a DependentGenericSignature")
        case .DependentGenericConformanceRequirement:
            let type = node.children[0]
            let reqt = node.children[1]
            print(type)
            printer << ": "
            print(reqt)
            return nil

        case .DependentGenericLayoutRequirement:
            let type = node.children[0]
            let layout = node.children[1]
            print(type)
            printer << ": "
            precondition(layout.kind == .Identifier)
            precondition(layout.text.count == 1)
            let c = layout.text.unicodeScalars.first!
            var name = ""
            if c == "U" {
                name = "_UnknownLayout"
            } else if c == "R" {
                name = "_RefCountedObject"
            } else if c == "N" {
                name = "_NativeRefCountedObject"
            } else if c == "C" {
                name = "AnyObject"
            } else if c == "D" {
                name = "_NativeClass"
            } else if c == "T" {
                name = "_Trivial"
            } else if c == "E" || c == "e" {
                name = "_Trivial"
            } else if c == "M" || c == "m" {
                name = "_TrivialAtMost"
            }
            printer << name
            if node.children.count > 2 {
                printer << "("
                print(node.children[2])
                if node.children.count > 3 {
                    printer << ", "
                    print(node.children[3])
                }
                printer << ")"
            }
            return nil
        case .DependentGenericSameTypeRequirement:
            let fst = node.children[0]
            let snd = node.children[1]

            print(fst)
            printer << " == "
            print(snd)
            return nil
        case .DependentGenericParamType:
            let index = node.children[1].index
            let depth = node.children[0].index
            printer << genericParameterName(depth: depth, index: index) // XXX: should be customisable
            return nil
        case .DependentGenericType:
            let sig = node.children[0]
            let depTy = node.children[1]
            print(sig)
            if needSpaceBeforeType(depTy) {
                printer << " "
            }
            print(depTy)
            return nil
        case .DependentMemberType:
            let base = node.children[0]
            print(base)
            printer << "."
            let assocTy = node.children[1]
            print(assocTy)
            return nil
        case .DependentAssociatedTypeRef:
            printer << node.children[0].text
            return nil
        case .ReflectionMetadataBuiltinDescriptor:
            printer << "reflection metadata builtin descriptor "
            print(node.children[0])
            return nil
        case .ReflectionMetadataFieldDescriptor:
            printer << "reflection metadata field descriptor "
            print(node.children[0])
            return nil
        case .ReflectionMetadataAssocTypeDescriptor:
            printer << "reflection metadata associated type descriptor "
            print(node.children[0])
            return nil
        case .ReflectionMetadataSuperclassDescriptor:
            printer << "reflection metadata superclass descriptor "
            print(node.children[0])
            return nil

        case .ThrowsAnnotation:
            printer << " throws "
            return nil
        case .EmptyList:
            printer << " empty-list "
            return nil
        case .FirstElementMarker:
            printer << " first-element-marker "
            return nil
        case .VariadicMarker:
            printer << " variadic-marker "
            return nil
        case .SILBoxTypeWithLayout:
            precondition(node.children.count == 1 || node.children.count == 3)
            let layout = node.children[0]
            precondition(layout.kind == .SILBoxLayout)
            var genericArgs: Node?
            if node.children.count == 3 {
                let signature = node.children[1]
                precondition(signature.kind == .DependentGenericSignature)
                genericArgs = node.children[2]
                precondition(genericArgs?.kind == .TypeList)

                print(signature)
                printer << " "
            }
            print(layout)
            if let genericArgs = genericArgs {
                printer << " <"
                for i in 0..<genericArgs.children.count {
                    if i > 0 {
                        printer << ", "
                    }
                    print(genericArgs.children[i])
                }
                printer << ">"
            }
            return nil
        case .SILBoxLayout:
            printer << "{"
            for i in 0..<node.children.count {
                if i > 0 {
                    printer << ","
                }
                printer << " "
                print(node.children[i])
            }
            printer << " }"
            return nil
        case .SILBoxImmutableField: fallthrough
        case .SILBoxMutableField:
            printer << (node.kind == .SILBoxImmutableField ? "let " : "var ")
            precondition(node.children.count == 1 && node.children[0].kind == .Type)
            print(node.children[0])
            return nil
        case .AssocTypePath:
            printChildren(of: node, separator: ".")
            return nil
        case .ModuleDescriptor:
            printer << "module descriptor "
            print(node.children[0])
            return nil
        case .AnonymousDescriptor:
            printer << "anonymous descriptor "
            print(node.children[0])
            return nil
        case .ExtensionDescriptor:
            printer << "extension descriptor "
            print(node.children[0])
            return nil
        case .AssociatedTypeGenericParamRef:
            printer << "generic parameter reference for associated type "
            printChildren(of: node)
            return nil
        case .AnyProtocolConformanceList:
            printChildren(of: node)
            return nil
        case .ConcreteProtocolConformance:
            printer << "concrete protocol conformance "
            if node.hasIndex {
                printer << "#"
                printer << node.index
                printer << " "
            }
            printChildren(of: node)
            return nil
        case .DependentAssociatedConformance:
            printer << "dependent associated conformance "
            printChildren(of: node)
            return nil
        case .DependentProtocolConformanceAssociated:
            printer << "dependent associated protocol conformance "
            printOptionalIndex(node: node.children[2])
            print(node.children[0])
            print(node.children[1])
            return nil
        case .DependentProtocolConformanceInherited:
            printer << "dependent inherited protocol conformance "
            printOptionalIndex(node: node.children[2])
            print(node.children[0])
            print(node.children[1])
            return nil
        case .DependentProtocolConformanceRoot:
            printer << "dependent root protocol conformance "
            printOptionalIndex(node: node.children[2])
            print(node.children[0])
            print(node.children[1])
            return nil
        case .ProtocolConformanceRefInTypeModule:
            printer << "protocol conformance ref (type's module) "
            printChildren(of: node)
            return nil
        case .ProtocolConformanceRefInProtocolModule:
            printer << "protocol conformance ref (protocol's module) "
            printChildren(of: node)
            return nil
        case .ProtocolConformanceRefInOtherModule:
            printer << "protocol conformance ref (retroactive) "
            printChildren(of: node)
            return nil
        case .SugaredOptional:
            printWithParens(type: node.children[0])
            printer << "?"
            return nil
        case .SugaredArray:
            printer << "["
            print(node.children[0])
            printer << "]"
            return nil
        case .SugaredDictionary:
            printer << "["
            print(node.children[0])
            printer << " : "
            print(node.children[1])
            printer << "]"
            return nil
        case .SugaredParen:
            printer << "("
            print(node.children[0])
            printer << ")"
            return nil
        case .OpaqueReturnType:
            printer << "some"
            return nil
        case .OpaqueReturnTypeOf:
            printer << "<<opaque return type of "
            printChildren(of: node)
            printer << ">>"
            return nil
        case .OpaqueType:
            print(node.children[0])
            printer << "."
            print(node.children[1])
            return nil
        case .AccessorFunctionReference:
            printer << "accessor function at "
            printer << node.index
            return nil
        }
    }

    private mutating func printAbstractStorage(node: Node, asPrefixContent: Bool, extraName: String) -> Node? {
        switch node.kind {
        case .Variable:
            return printEntity(node, asPrefixContext: asPrefixContent, typePr: .WithColon, /*hasName*/hasName: true, extraName: extraName)
        case .Subscript:
            return printEntity(node, asPrefixContext: asPrefixContent, typePr: .WithColon, /*hasName*/hasName: false, extraName: extraName, overwriteName: "subscript")
        default:
            unreachable("Not an abstract storage node");
        }
    }

    /// Utility function to print entities.
    ///
    /// \param Entity The entity node to print
    /// \param asPrefixContext Should the entity printed as a context which as a
    ///        prefix to another entity, e.g. the Abc in Abc.def()
    /// \param TypePr How should the type of the entity be printed, if at all.
    ///        E.g. with a colon for properties or as a function type.
    /// \param hasName Does the entity has a name, e.g. a function in contrast to
    ///        an initializer.
    /// \param ExtraName An extra name added to the entity name (if any).
    /// \param ExtraIndex An extra index added to the entity name (if any),
    ///        e.g. closure #1
    /// \param OverwriteName If non-empty, print this name instead of the one
    ///        provided by the node. Gets printed even if hasName is false.
    /// \return If a non-null node is returned it"s a context which must be
    ///         printed in postfix-form after the entity: "<entity> in <context>".
    private mutating func printEntity(_ entity: Node, asPrefixContext: Bool, typePr: TypePrinting, hasName: Bool, extraName: String = "", extraIndex: UInt64? = nil, overwriteName: String = "") -> Node? {
        var entity = entity
        var extraName = extraName
        var typePr = typePr

        var genericFunctionTypeList: Node?
        if entity.kind == .BoundGenericFunction {
            genericFunctionTypeList = entity.children[1]
            entity = entity.children[0]
        }

        // Either we print the context in prefix form "<context>.<name>" or in
        // suffix form "<name> in <context>".
        var multiWordName = extraName.contains(" ")
        // Also a local name (e.g. Mystruct #1) does not look good if its context is
        // printed in prefix form.
        if (hasName && entity.children[1].kind == .LocalDeclName) {
            multiWordName = true
        }

        if (asPrefixContext && (typePr != .NoType || multiWordName)) {
            // If the context has a type to be printed, we can't use the prefix form.
            return entity
        }

        var postfixContext: Node?
        let context = entity.children[0]
        if printContext(context) {
            if (multiWordName) {
                // If the name contains some spaces we don't print the context now but
                // later in suffix form.
                postfixContext = context
            } else {
                let currentPos = printer.count
                postfixContext = print(context, /*asPrefixContext*/asPrefixContext: true)

                // Was the context printed as prefix?
                if printer.count != currentPos {
                    printer << "."
                }
            }
        }

        if hasName || !overwriteName.isEmpty {
            precondition(extraIndex == nil, "Can't have a name and extra index")
            if !extraName.isEmpty && multiWordName {
                printer << extraName
                printer << " of "
                extraName = ""
            }
            let currentPos = printer.count
            if !overwriteName.isEmpty {
                printer << overwriteName
            } else {
                let name = entity.children[1]
                if name.kind != .PrivateDeclName {
                    print(name)
                }

                if let privateName = getChildIf(node: entity, kind: .PrivateDeclName) {
                    print(privateName)
                }
            }
            if printer.count != currentPos && !extraName.isEmpty {
                printer << "."
            }
        }
        if !extraName.isEmpty {
            printer << extraName
            if let extraIndex = extraIndex {
                printer << extraIndex
            }
        }
        if typePr != .NoType {
            guard let child = getChildIf(node: entity, kind: .Type) else {
                precondition(false, "malformed entity")
                setInvalid()
                return nil
            }
            let type = child.children[0]
            if typePr == .FunctionStyle {
                // We expect to see a function type here, but if we don't, use the colon.
                var t = type
                while t.kind == .DependentGenericType {
                    t = t.children[1].children[0]
                }
                if (t.kind != .FunctionType &&
                    t.kind != .NoEscapeFunctionType &&
                    t.kind != .UncurriedFunctionType &&
                    t.kind != .CFunctionPointer &&
                    t.kind != .ThinFunctionType) {
                    typePr = .WithColon
                }
            }

            if typePr == .WithColon {
                if options.contains(.DisplayEntityTypes) {
                    printer << " : "
                    printEntityType(entity: entity, type: type, genericFunctionTypeList: genericFunctionTypeList)
                }
            } else {
                precondition(typePr == .FunctionStyle)
                if multiWordName || needSpaceBeforeType(type) {
                    printer << " "
                }
                printEntityType(entity: entity, type: type, genericFunctionTypeList: genericFunctionTypeList)
            }
        }
        if let pc = postfixContext, !asPrefixContext {
            // Print any left over context which couldn't be printed in prefix form.
            if (entity.kind == .DefaultArgumentInitializer ||
                entity.kind == .Initializer) {
                printer << " of ";
            } else {
                printer << " in ";
            }
            print(pc)
            postfixContext = nil
        }
        return postfixContext
    }

    /// Print the type of an entity.
    ///
    /// \param Entity The entity.
    /// \param type The type of the entity.
    /// \param genericFunctionTypeList If not null, the generic argument types
    ///           which is printed in the generic signature.
    private mutating func printEntityType(entity: Node, type: Node, genericFunctionTypeList: Node?) {
        var type = type
        let labelList = getChildIf(node: entity, kind: .LabelList)
        if labelList != nil || genericFunctionTypeList != nil {
            if let genericFunctionTypeList = genericFunctionTypeList {
                printer << "<"
                printChildren(of: genericFunctionTypeList, separator: ", ")
                printer << ">"
            }
            if type.kind == .DependentGenericType {
                if genericFunctionTypeList == nil {
                    print(type.children[0]) // generic signature
                }

                let dependentType = type.children[1]
                if needSpaceBeforeType(dependentType) {
                    printer << " "
                }
                type = dependentType.children[0]
            }
            printFunctionType(labelList: labelList, node: type)
        } else {
            print(type)
        }
    }

    private func isExistentialType(node: Node) -> Bool {
        return (node.kind == .ExistentialMetatype ||
            node.kind == .ProtocolList ||
            node.kind == .ProtocolListWithClass ||
            node.kind == .ProtocolListWithAnyObject)
    }


    private func isClassType(node: Node) -> Bool {
        return node.kind == .Class
    }

    private func needSpaceBeforeType(_ type: Node) -> Bool {
        switch (type.kind) {
        case .Type:
            return needSpaceBeforeType(type.children[0])
        case .FunctionType: fallthrough
        case .NoEscapeFunctionType: fallthrough
        case .UncurriedFunctionType: fallthrough
        case .DependentGenericType:
            return false
        default:
            return true
        }
    }
}

extension NodePrinter {
    private var failure: Error {
        enum NodePrinterError: Error { case error }
        return NodePrinterError.error
    }

    func require<T>(_ optional: Optional<T>) throws -> T {
        if let v = optional {
            return v
        } else {
            throw failure
        }
    }

    func require(_ value: Bool) throws {
        if !value {
            throw failure
        }
    }
}

fileprivate extension String {
    struct Quoted {
        let value: String
        init(_ value: String) {
            self.value = value
        }
    }

    static func << (lhs: inout String, rhs: Quoted) {
        lhs << "\""
        for c in rhs.value.unicodeScalars {
            switch c {
            case "\\": lhs << "\\\\"
            case "\t": lhs << "\\t"
            case "\n": lhs << "\\n"
            case "\r": lhs << "\\r"
            case "\"": lhs << "\\\""
            case "'": lhs << "'" // no need to escape these
            case "\0": lhs << "\\0"
            default:
                // Other ASCII control characters should get escaped.
                if c.value < 0x20 || c.value == 0x7F {
                    let hexdigits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
                    lhs << "\\x"
                    lhs << hexdigits[Int(c.value >> 4)]
                    lhs << hexdigits[Int(c.value & 0xF)]
                } else {
                    lhs << "\(c)"
                }
            }
        }
        lhs << "\""
    }
}

extension String {
    static func << (lhs: inout String, rhs: String) {
        lhs += rhs
    }
    static func << <T: BinaryInteger>(lhs: inout String, rhs: T) {
        lhs += "\(rhs)"
    }
    static func << (lhs: inout String, rhs: UnicodeScalar) {
        lhs += "\(rhs)"
    }
    mutating func writeHex(_ n: UInt64) {
        self += String(format: "%llX", n)
    }
}

extension NodePrinter {
    @_transparent // this makes debugger stop at the callsite, not here
    private func unreachable(_ message: String, file: StaticString = #file, line: UInt = #line) -> Never {
        fatalError(message, file: file, line: line)
    }
}
