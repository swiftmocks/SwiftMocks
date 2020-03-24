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

extension Node {
    func explodeFunctionChildren() -> (argumentTupleNode: Node, returnNode: Node, doesThrow: Bool) {
        guard kind == .FunctionType, let argumentTuple = child(ofKind: .ArgumentTuple), let returnType = child(ofKind: .ReturnType) else {
            preconditionFailure("malformed node of kind .functionType")
        }
        let doesThrow = child(ofKind: .ThrowsAnnotation) != nil
        let returnNode = returnType.children[0]
        return (argumentTuple, returnNode, doesThrow)
    }

    func child(path: [Kind]) -> Node? {
        var current = self
        for segment in path {
            guard let found = current.child(ofKind: segment) else {
                return nil
            }
            current = found
        }
        return current
    }

    func child(oneOfKind kinds: [Kind]) -> Node? {
        for child in children {
            if kinds.contains(child.kind) {
                return child
            }
        }
        return nil
    }

    // return .type nodes, discarding labels
    private func explodeTuple() throws -> [Node] {
        guard kind == .Type, let tupleChild = child(ofKind: .Tuple) else {
            preconditionFailure("malformed tuple node: \(Mangle.mangleNode(node: self))")
        }
        return tupleChild
            .children
            .map {
                guard let type = $0.child(ofKind: .Type) else {
                    preconditionFailure("malformed tuple node: \(Mangle.mangleNode(node: $0))")
                }
                return type
            }
    }

    // assuming the receiver is an .argumentTuple, convert it to an array of types
    func explodeArgumentTupleToTypes() throws -> [AType] {
        precondition(kind == .ArgumentTuple)


        if !hasIndex {
            return []
        }

        let parameters = children[0]

        // if there is only a single parameter, it may be encoded verbatim if it is unnamed. otherwise parameters are wrapped into a tuple
        if index == 1 && parameters.children[0].kind != .Tuple {
            return try [children[0].asType()]
        }

        let parameterNodes = try parameters.explodeTuple()
        let ret = try parameterNodes.map { try $0.asType() }
        return ret
    }

    func asType() throws -> AType {
        precondition(kind == .Type || kind == .Metatype)

        var typeNode: Node
        let isInout: Bool
        if let inoutNode = child(ofKind: .InOut) {
            isInout = true
            typeNode = Node(kind: .Type, child: inoutNode.children[0])
        } else {
            isInout = false
            typeNode = self
        }
        let isDynamicSelf: Bool
        if let actualSelf = child(path: [.DynamicSelf, .Type]) {
            typeNode = actualSelf
            isDynamicSelf = true
        } else {
            isDynamicSelf = false
        }

        let mangledName = "s" + Mangle.mangleNode(node: typeNode)
        guard let type = Runtime.getNonGenericTypeByMangledName(name: mangledName) else {
            throw InterceptorError.couldNotGetType(mangledName)
        }

        if isDynamicSelf {
            return TypeFactory.createDynamicSelfType(metadata: Metadata.of(type))
        } else if isInout {
            return TypeFactory.createInOutType(metadata: Metadata.of(type))
        }

        return TypeFactory.from(metadata: Metadata.of(type))
    }

    /// Assuming the receiver is a protocol conformance node, decode it into a `ProtocolConformanceRef`
    func asProtocolConformanceRef() throws -> ProtocolConformanceRef {
        precondition(kind == .ProtocolConformance)
        let (conformingTypeNode, protocolNode) = try explodeProtocolConformance()
        let proto = try protocolNode.asType() as! ProtocolType
        let conformingType = try conformingTypeNode.asType()
        let conformance = ProtocolConformance(kind: .normal, conformingType: conformingType)
        return ProtocolConformanceRef(proto: proto, conformance: conformance)
    }

    /// Assuming the receiver is a protocol conformance, return the conforming type and protocol nodes as a tuple
    private func explodeProtocolConformance() throws -> (conformingType: Node, `protocol`: Node) {
        precondition(kind == .ProtocolConformance)
        if children.count == 3 {
            return (children[0], children[1])
        }
        throw InterceptorError.unrecognisedProtocolConformance
    }

    /// If the receiver is a demangled name of a witness table entry pointing to base protocol conformance, return that base protocol, else return nil.
    func asProtocolInWitnessTableBaseProtocolRequirement() throws -> ProtocolDescriptor? {
        // See bottom of the file for examples
        guard kind == .Global, let witnessTable = child(ofKind: .ProtocolWitnessTable), let conformance = witnessTable.child(ofKind: .ProtocolConformance) else {
            return nil
        }

        let (_, proto) = try conformance.explodeProtocolConformance()
        guard let type = try proto.asType() as? ProtocolType else {
            throw InterceptorError.unrecognisedWitnessTableEntry
        }
        let metadata = type.metadata as! ExistentialTypeMetadata
        assert(metadata.numberOfProtocols == 1)
        return metadata.protocols[0]
    }
}

extension Node {
    /// If the receiver is a node of a known function kind, return its bits and pieces. Otherwise return `nil`
    var asFunctionBits: (function: Node, isStatic: Bool, conformance: Node?)? {
        guard kind == .Global, let (actualNode, isStatic, conformance) = children.first?.extractActualNode() else {
            return nil
        }

        guard actualNode.kind == .Function else {
            return nil
        }

        return (actualNode, isStatic, conformance)
    }

    /// If the receiver is an accessor, return its bits and pieces. Otherwise return `nil`
    var asAccessorBits: (kind: AccessorKind, variableOrSubscriptNode: Node, isStatic: Bool, isSubscript: Bool, conformance: Node?)? {
        guard kind == .Global, let (actualNode, isStatic, conformance) = children.first?.extractActualNode() else {
            return nil
        }

        let kind: AccessorKind
        switch actualNode.kind {
        case .Getter:
            kind = .get
        case .Setter:
            kind = .set
        case .ModifyAccessor:
            kind = .modify
        case .DidSet:
            kind = .didSet
        case .WillSet:
            kind = .willSet
        default:
            return nil
        }

        if let variable = actualNode.children.first, variable.kind == .Variable, variable.children.at(1)?.kind == .Identifier, variable.children.at(2)?.kind == .Type {
            return (kind, variable, isStatic, false, conformance)
        }

        if let subscr = actualNode.children.first, subscr.kind == .Subscript, subscr.children.at(1)?.kind == .LabelList, subscr.children.at(2)?.kind == .Type {
            return (kind, subscr, isStatic, true, conformance)
        }

        return nil
    }

    /// If it is a witness, extract the actual node. Then, if it's a static node, extract the actual actual node.
    private func extractActualNode() -> (actualNode: Node, isStatic: Bool, conformance: Node?) {
        var actualNode = self
        var conformance: Node? = nil

        if kind == .ProtocolWitness, let conf = child(ofKind: .ProtocolConformance), let newActualNode = children.at(1) {
            conformance = conf
            actualNode = newActualNode
        }

        let isStatic = actualNode.kind == .Static
        if isStatic {
            actualNode = actualNode.children.first ?? actualNode
        }

        return (actualNode, isStatic, conformance)
    }
}

/// Setter
/// ```
/// kind=Global
///   kind=Setter
///     kind=Variable
///       kind=Class
///         kind=Module, text="IR"
///         kind=Identifier, text="___C103"
///       kind=Identifier, text="___103"
///       kind=Type
///         kind=Class
///           kind=Module, text="IR"
///           kind=Identifier, text="AnEmptyClass"
/// ```

// Subscript
/// ``` ds -tree-only s2IR7___C110CyS2Scig
/// Demangling for $s2IR7___C110CyS2Scig
/// kind=Global
///   kind=Getter
///     kind=Subscript
///       kind=Class
///         kind=Module, text="IR"
///         kind=Identifier, text="___C110"
///       kind=LabelList
///       kind=Type
///         kind=FunctionType
///           kind=ArgumentTuple
///             kind=Type
///               kind=Structure
///                 kind=Module, text="Swift"
///                 kind=Identifier, text="String"
///           kind=ReturnType
///             kind=Type
///               kind=Structure
///                 kind=Module, text="Swift"
///                 kind=Identifier, text="String"
/// ```

/// Base protocol conformance
/// ```$ ds -tree-only s19SwiftInternalsTests037RealisticallyLookingProtocolWithABaseF4FakeCAA04Basef3FordeF0AAWP
/// Demangling for $s19SwiftInternalsTests037RealisticallyLookingProtocolWithABaseF4FakeCAA04Basef3FordeF0AAWP
/// kind=Global
///   kind=ProtocolWitnessTable
///     kind=ProtocolConformance
///       kind=Type
///         kind=Class
///           kind=Module, text="SwiftInternalsTests"
///           kind=Identifier, text="RealisticallyLookingProtocolWithABaseProtocolFake"
///       kind=Type
///         kind=Protocol
///           kind=Module, text="SwiftInternalsTests"
///           kind=Identifier, text="BaseProtocolForRealisticallyLookingProtocol"
///       kind=Module, text="SwiftInternalsTests"
/// ```
