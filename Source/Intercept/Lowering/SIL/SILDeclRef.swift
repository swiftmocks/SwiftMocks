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

import Foundation

/// A key for referencing a Swift declaration in SIL.
///
/// This can currently be either a reference to a ValueDecl for functions, methods, constructors, and other named entities, or a reference to a AbstractClosureExpr for an anonymous function.  In addition to the AST reference, there are discriminators for referencing different implementation-level entities associated with a single language-level declaration, such as uncurry levels of a function, the allocating and initializing entry points of a constructor, etc.
struct SILDeclRef {
    /// A.k.a. `DeclRefKind`
    enum Kind {
        case `func`
        case allocator
        case initializer
        case enumElement
        case destroyer
        case deallocator
        case globalAccessor
        case defaultArgGenerator
        case storedPropertyInitializer
        case ivarInitializer
        case ivarDestroyer
    }

    let kind: Kind

    let isCurried: Bool
    let isForeign: Bool = false
    let isDirectReference: Bool = false
    let defaultArgIndex: Int = 0
    let decl: ValueDecl

    var isSetter: Bool {
        (decl as? AccessorDecl)?.isSetter ?? false
    }

    var parameterListCount: Int {
        if isCurried || kind == .defaultArgGenerator {
            return 1
        }

        if let fnc = decl as? AbstractFunctionDecl {
            return fnc.hasImplicitSelfDecl ? 2 : 1
        } else {
          LoweringError.unreachable("Unhandled ValueDecl for SILDeclRef")
        }
    }

    private init(params: [AType], resultOrStorageType: AType /* passing storage type here for accessors */, throws: Bool, selfType: AType?, isStatic: Bool, isExtension: Bool, proto: ProtocolType? = nil, accessorKind: AccessorKind? = nil, indices: [AType]? = nil) {
        self.kind = .func
        let genericSignature: GenericSignature?
        if let proto = proto {
            genericSignature = GenericSignature.genericTypeParamType(conformsTo: proto)
        } else {
            genericSignature = nil
        }

        let declContext: DeclContext
        if let selfType = selfType {
            let decl: NominalTypeDecl
            if let proto = proto {
                decl = ProtocolDecl(proto: proto)
            } else {
                decl = NominalTypeDecl(type: selfType)
            }
            if isExtension {
                declContext = .extension(decl)
            } else {
                declContext = .genericTypeContext(decl)
            }
        } else {
            declContext = .topLevel
        }

        if let accessorKind = accessorKind {
            decl = AccessorDecl(parent: declContext, kind: accessorKind, storageType: resultOrStorageType, indices: indices ?? [], isStatic: isStatic, genericSig: genericSignature)
        } else {
            decl = FuncDecl(parent: declContext, throws: `throws`, hasImplicitSelfDecl: selfType != nil, params: params, resultTy: resultOrStorageType, isStatic: isStatic, genericSig: genericSignature)
        }

        isCurried = false
    }
}

extension SILDeclRef {
    static func from(mangledName: String) throws -> Self {
        let root: Node
        do {
            root = try Mangle.demangleSymbol(mangledName: mangledName)
        } catch {
            throw InterceptorError.couldNotDemangle(mangledName, error)
        }

        if let (function, isStatic, conformance) = root.asFunctionBits {
            guard let functionType = function.child(path: [.Type, .FunctionType]) else {
                preconditionFailure("malformed global or method node: \(Mangle.mangleNode(node: root))")
            }

            let proto: ProtocolType? = try conformance?.asProtocolConformanceRef().proto.proto

            let (selfType, fakeProto, isExtension) = try computeSelfType(variableOrFunctionNode: function, isWitnessMethod: conformance != nil, root: root)

            let (argumentTupleNode, returnNode, doesThrow) = functionType.explodeFunctionChildren()
            let parameters = try argumentTupleNode.explodeArgumentTupleToTypes()
            let resultType = try returnNode.asType()

            return self.init(params: parameters, resultOrStorageType: resultType, throws: doesThrow, selfType: selfType, isStatic: isStatic, isExtension: isExtension, proto: proto ?? fakeProto)
        }

        if let (accessorKind, variable, isStatic, isSubscript, conformance) = root.asAccessorBits {
            let proto: ProtocolType? = try conformance?.asProtocolConformanceRef().proto.proto

            let (selfType, fakeProto, isExtension) = try computeSelfType(variableOrFunctionNode: variable, isWitnessMethod: proto != nil, root: root)

            if isSubscript {
                let (argumentTupleNode, returnNode, doesThrow) = variable.children[2].children[0].explodeFunctionChildren()
                let indices = try argumentTupleNode.explodeArgumentTupleToTypes()
                let storageType = try returnNode.asType()
                return self.init(params: [], resultOrStorageType: storageType, throws: doesThrow, selfType: selfType, isStatic: isStatic, isExtension: isExtension, proto: proto ?? fakeProto, accessorKind: accessorKind, indices: indices)
            } else {
                let storageType = try variable.children[2].asType()
                return self.init(params: [], resultOrStorageType: storageType, throws: false, selfType: selfType, isStatic: isStatic, isExtension: isExtension, proto: proto ?? fakeProto, accessorKind: accessorKind)
            }
        }

        throw InterceptorError.unsupportedFunctionType(mangledName)
    }

    private static func computeSelfType(variableOrFunctionNode: Node, isWitnessMethod: Bool, root: Node) throws -> (selfType: AType?, fakeProto: ProtocolType?, isExtension: Bool) {
        let selfType: AType?
        var proto: ProtocolType? = nil
        var isExtension = false
        if isWitnessMethod {
            // witness method
            selfType = GenericTypeParamType.tau00
        } else if let selfNode = variableOrFunctionNode.child(oneOfKind: [.Structure, .Class, .Enum]) {
            // a property
            selfType = try Node(kind: .Type, child: selfNode).asType()
        } else if variableOrFunctionNode.child(ofKind: .Module) != nil {
            // a global
            selfType = nil
        } else if let extnNode = variableOrFunctionNode.child(ofKind: .Extension), let protoNode = extnNode.child(ofKind: .Protocol) { // protocol non-requiremtn method, for example: s10playground3FooPAAE17nonRequirementVarSivg
            selfType = GenericTypeParamType.tau00
            guard let protoType = try Node(kind: .Type, child: protoNode).asType() as? ProtocolType else {
                throw InterceptorError.unsupportedFunctionType(Mangle.mangleNode(node: root))
            }
            proto = protoType
            isExtension = true
        } else {
            throw InterceptorError.unsupportedFunctionType(Mangle.mangleNode(node: root))
        }
        return (selfType, proto, isExtension)
    }
}

extension SILDeclRef: CustomStringConvertible {
    var description: String {
        "SILDeclRef(kind: \(kind))"
    }
}
