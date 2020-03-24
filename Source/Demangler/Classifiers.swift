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

extension Node.Kind {
    var isDeclName: Bool {
        self == .Identifier ||
            self == .LocalDeclName ||
            self == .PrivateDeclName ||
            self == .RelatedEntityDeclName ||
            self == .PrefixOperator ||
            self == .PostfixOperator ||
            self == .InfixOperator ||
            self == .TypeSymbolicReference ||
            self == .ProtocolSymbolicReference
    }

    var isAnyGeneric: Bool {
        return
            self == .Structure ||
                self == .Class ||
                self == .Enum ||
                self == .Protocol ||
                self == .ProtocolSymbolicReference ||
                self == .OtherNominalType ||
                self == .TypeAlias ||
                self == .TypeSymbolicReference
    }

    var isEntity: Bool{
        // Also accepts some kind which are not entities.
        if self == .Type {
            return true
        }
        return isContext
    }

    var isRequirement: Bool {
        return
            self == .DependentGenericSameTypeRequirement ||
                self == .DependentGenericLayoutRequirement ||
                self == .DependentGenericConformanceRequirement
    }

    /// Returns true if the node \p kind refers to a context node, e.g. a nominal
    /// type or a function.
    var isContext: Bool {
        // see generators
        self == .Allocator ||
            self == .AnonymousContext ||
            self == .Class ||
            self == .Constructor ||
            self == .Deallocator ||
            self == .DefaultArgumentInitializer ||
            self == .Destructor ||
            self == .DidSet ||
            self == .Enum ||
            self == .ExplicitClosure ||
            self == .Extension ||
            self == .Function ||
            self == .Getter ||
            self == .GlobalGetter ||
            self == .IVarInitializer ||
            self == .IVarDestroyer ||
            self == .ImplicitClosure ||
            self == .Initializer ||
            self == .MaterializeForSet ||
            self == .ModifyAccessor ||
            self == .Module ||
            self == .NativeOwningAddressor ||
            self == .NativeOwningMutableAddressor ||
            self == .NativePinningAddressor ||
            self == .NativePinningMutableAddressor ||
            self == .OtherNominalType ||
            self == .OwningAddressor ||
            self == .OwningMutableAddressor ||
            self == .Protocol ||
            self == .ProtocolSymbolicReference ||
            self == .ReadAccessor ||
            self == .Setter ||
            self == .Static ||
            self == .Structure ||
            self == .Subscript ||
            self == .TypeSymbolicReference ||
            self == .TypeAlias ||
            self == .UnsafeAddressor ||
            self == .UnsafeMutableAddressor ||
            self == .Variable ||
            self == .WillSet ||
            self == .OpaqueReturnTypeOf ||
        false
    }

    /// Returns true if the node \p kind refers to a node which is placed before a
    /// function node, e.g. a specialization attribute.
    var isFunctionAttr: Bool {
        self == .FunctionSignatureSpecialization ||
            self == .GenericSpecialization ||
            self == .InlinedGenericFunction ||
            self == .GenericSpecializationNotReAbstracted ||
            self == .GenericPartialSpecialization ||
            self == .GenericPartialSpecializationNotReAbstracted ||
            self == .ObjCAttribute ||
            self == .NonObjCAttribute ||
            self == .DynamicAttribute ||
            self == .DirectMethodReferenceAttribute ||
            self == .VTableAttribute ||
            self == .PartialApplyForwarder ||
            self == .PartialApplyObjCForwarder ||
            self == .OutlinedVariable ||
            self == .OutlinedBridgedMethod ||
            self == .MergedFunction ||
            self == .DynamicallyReplaceableFunctionImpl ||
            self == .DynamicallyReplaceableFunctionKey ||
            self == .DynamicallyReplaceableFunctionVar
    }
}

extension Node {
    var isClassNode: Bool {
        switch kind {
        case .Type: return children[0].isClassNode
        case .Class,
             .BoundGenericClass: return true
        default: return false
        }
    }

    var isAliasNode: Bool {
        switch kind {
        case .Type: return children[0].isAliasNode
        case .TypeAlias: return true
        default: return false
        }
    }

    var isEnumNode: Bool {
        switch kind {
        case .Type: return children[0].isEnumNode
        case .Enum: return true
        case .BoundGenericEnum: return true
        default: return false
        }
    }

    var isProtocolNode: Bool {
        switch kind {
        case .Type: return children[0].isProtocolNode
        case .Protocol: return true
        case .ProtocolSymbolicReference: return true
        default: return false
        }
    }

    var isStructNode: Bool {
        switch kind {
        case .Type: return children[0].isStructNode
        case .Structure: return true
        case .BoundGenericStructure: return true
        default: return false
        }
    }

    var isSpecialized: Bool {
        switch kind {
        case .BoundGenericStructure,
             .BoundGenericEnum,
             .BoundGenericClass,
             .BoundGenericOtherNominalType,
             .BoundGenericTypeAlias,
             .BoundGenericProtocol,
             .BoundGenericFunction:
            return true

        case .Structure,
             .Enum,
             .Class,
             .TypeAlias,
             .OtherNominalType,
             .Protocol,
             .Function,
             .Allocator,
             .Constructor,
             .Destructor,
             .Variable,
             .Subscript,
             .ExplicitClosure,
             .ImplicitClosure,
             .Initializer,
             .DefaultArgumentInitializer,
             .Getter,
             .Setter,
             .WillSet,
             .DidSet,
             .ReadAccessor,
             .ModifyAccessor,
             .UnsafeAddressor,
             .UnsafeMutableAddressor:
            return children[0].isSpecialized

        case .Extension:
            return children[1].isSpecialized

        default:
            return false
        }
    }

    func getUnspecialized() -> Node {
        var numberOfNodesToCopy = 2
        switch kind {
        case .Function,
             .Getter,
             .Setter,
             .WillSet,
             .DidSet,
             .ReadAccessor,
             .ModifyAccessor,
             .UnsafeAddressor,
             .UnsafeMutableAddressor,
             .Allocator,
             .Constructor,
             .Destructor,
             .Variable,
             .Subscript,
             .ExplicitClosure,
             .ImplicitClosure,
             .Initializer,
             .DefaultArgumentInitializer:
            numberOfNodesToCopy = children.count
            fallthrough
        case .Structure,
             .Enum,
             .Class,
             .TypeAlias,
             .OtherNominalType:
            var children: [Node] = []
            var parentOrModule = self.children[0]
            if (parentOrModule.isSpecialized) {
                parentOrModule = parentOrModule.getUnspecialized()
            }
            children.append(parentOrModule)
            for idx in 1..<numberOfNodesToCopy {
                children.append(self.children[idx])
            }
            let result = Node(kind: kind, children: children)
            return result

        case .BoundGenericStructure,
             .BoundGenericEnum,
             .BoundGenericClass,
             .BoundGenericProtocol,
             .BoundGenericOtherNominalType,
             .BoundGenericTypeAlias:
            let unboundType = children[0]
            precondition(unboundType.kind == .Type)
            let nominalType = unboundType.children[0]
            if nominalType.isSpecialized {
                return nominalType.getUnspecialized()
            }
            return nominalType

        case .BoundGenericFunction:
            let unboundFunction = children[0]
            precondition(unboundFunction.kind == .Function || unboundFunction.kind == .Constructor)
            if (unboundFunction.isSpecialized) {
                return unboundFunction.getUnspecialized()
            }
            return unboundFunction

        case .Extension:
            let parent = children[1]
            if !parent.isSpecialized {
                return self
            }
            var result = Node(kind: .Extension, children: [children[0], parent.getUnspecialized()])
            if children.count == 3 {
                // Add the generic signature of the extension.
                result.children.append(children[2])
            }
            return result

        default:
            fatalError("bad nominal type kind")
        }
    }

}

extension Mangle {
    public static func isMangledName(mangledName: String) -> Bool {
        return manglingPrefixLength(mangledName: mangledName) != 0
    }

    public static func isAlias(_ mangledName: String) -> Bool {
        var demangler = Demangler(mangledName: mangledName)
        return (try? demangler.demangleType().isAliasNode) ?? false
    }

    public static func isClass(_ mangledName: String) -> Bool {
        var demangler = Demangler(mangledName: mangledName)
        return (try? demangler.demangleType().isClassNode) ?? false
    }

    public static func isEnum(mangledName: String) -> Bool {
        var demangler = Demangler(mangledName: mangledName)
        return (try? demangler.demangleType().isEnumNode) ?? false
    }

    public static func isProtocol(mangledName: String) -> Bool {
        var demangler = Demangler(mangledName: mangledName)
        return (try? demangler.demangleType().isProtocolNode) ?? false
    }

    public static func isStruct(mangledName: String) -> Bool {
        var demangler = Demangler(mangledName: mangledName)
        return (try? demangler.demangleType().isStructNode) ?? false
    }

    public static func isObjCSymbol(mangledName: String) -> Bool {
        let nameWithoutPrefix = String(mangledName.dropFirst(manglingPrefixLength(mangledName: mangledName)))
        return nameWithoutPrefix.starts(with: "So") || nameWithoutPrefix.starts(with: "SC")
    }

    public static func isThunkSymbol(mangledName: String) -> Bool {
        if (isMangledName(mangledName: mangledName)) {
            // First do a quick check
            if (mangledName.hasSuffix("TA") ||  // partial application forwarder
                mangledName.hasSuffix("Ta") ||  // ObjC partial application forwarder
                mangledName.hasSuffix("To") ||  // swift-as-ObjC thunk
                mangledName.hasSuffix("TO") ||  // ObjC-as-swift thunk
                mangledName.hasSuffix("TR") ||  // reabstraction thunk helper function
                mangledName.hasSuffix("Tr") ||  // reabstraction thunk
                mangledName.hasSuffix("TW") ||  // protocol witness thunk
                mangledName.hasSuffix("fC")) {  // allocating constructor

                // To avoid false positives, we need to fully demangle the symbol.
                var d = Demangler(mangledName: mangledName)
                guard let node = try? d.demangleSymbol() else { return false }
                if (node.kind != .Global || node.children.count == 0) { return false }

                switch node.children[0].kind {
                case .ObjCAttribute: return true
                case .NonObjCAttribute: return true
                case .PartialApplyObjCForwarder: return true
                case .PartialApplyForwarder: return true
                case .ReabstractionThunkHelper: return true
                case .ReabstractionThunk: return true
                case .ProtocolWitness: return true
                case .Allocator: return true
                default: break
                }
            }
            return false
        }

        if (mangledName.starts(with: "_T")) {
            // Old mangling.
            let remaining = mangledName.dropFirst(2)
            if (remaining.starts(with: "To") ||   // swift-as-ObjC thunk
                remaining.starts(with: "TO") ||   // ObjC-as-swift thunk
                remaining.starts(with: "PA_") ||  // partial application forwarder
                remaining.starts(with: "PAo_")) { // ObjC partial application forwarder
                return true
            }
        }
        return false
    }

    public static func thunkTarget(for mangledName: String) -> String? {
        if (!isThunkSymbol(mangledName: mangledName)) {
            return nil
        }

        if (isMangledName(mangledName: mangledName)) {
            // The targets of those thunks not derivable from the mangling.
            if mangledName.hasSuffix("TR") ||
                mangledName.hasSuffix("Tr") ||
                mangledName.hasSuffix("TW") {
                return nil
            }

            if mangledName.hasSuffix("fC") {
                let target = String(mangledName.prefix(mangledName.count - 1)) + "c"
                return target
            }

            return String(mangledName.suffix(mangledName.count - 2))
        }

        // old mangling
        return nil
    }

    public static func hasSwiftCallingConvention(mangledName: String) -> Bool {
        guard let global = try? demangleSymbol(mangledName: mangledName) else { return false }
        if global.kind != .Global || global.children.count == 0 { return false }

        let TopLevel = global.children[0]
        switch TopLevel.kind {
        // Functions, which don't have the swift calling conventions:
        case .TypeMetadataAccessFunction: fallthrough
        case .ValueWitness: fallthrough
        case .ProtocolWitnessTableAccessor: fallthrough
        case .GenericProtocolWitnessTableInstantiationFunction: fallthrough
        case .LazyProtocolWitnessTableAccessor: fallthrough
        case .AssociatedTypeMetadataAccessor: fallthrough
        case .AssociatedTypeWitnessTableAccessor: fallthrough
        case .BaseWitnessTableAccessor: fallthrough
        case .ObjCAttribute:
            return false
        default: break
        }
        return true
    }

    public static func moduleName(mangledName: String) -> String {
        guard var node = try? demangleSymbol(mangledName: mangledName) else { return "" }
        while true {
            switch node.kind {
            case .Module:
                return node.text
            case .TypeMangling,
                 .Type:
                node = node.children[0]
                break
            case .Global:
                guard let newNode = node.children.first(where: { !$0.kind.isFunctionAttr }) else { return "" }
                node = newNode
                break
            default:
                if node.isSpecialized {
                    node = node.getUnspecialized()
                    break
                }
                if node.kind.isContext {
                    node = node.children[0]
                    break
                }
                return ""
            }
        }
    }
}
