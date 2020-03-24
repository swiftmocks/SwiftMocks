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

extension Demangler {
    mutating func pop() -> Node? {
        return nodeStack.popLast()
    }

    mutating func pop(kind: Node.Kind) -> Node? {
        return nodeStack.last?.kind == kind ? pop() : nil
    }

    mutating func pop(where cond: (Node.Kind) -> Bool) -> Node? {
        return nodeStack.last.map({ cond($0.kind) }) == true ? pop() : nil
    }

    mutating func popFunctionType(kind: Node.Kind) throws -> Node {
        var name = Node(kind: kind)
        if let ta = pop(kind: .ThrowsAnnotation) {
            name.children.append(ta)
        }
        name.children.append(try popFunctionParams(kind: .ArgumentTuple))
        name.children.append(try popFunctionParams(kind: .ReturnType))
        return Node(kind: .Type, child: name)
    }

    mutating func popFunctionParams(kind: Node.Kind) throws -> Node {
        let paramsType: Node
        if pop(kind: .EmptyList) != nil {
            return Node(kind: kind, child: Node(kind: .Type, child: Node(kind: .Tuple)))
        } else {
            paramsType = try require(pop(kind: .Type))
        }

        if kind == .ArgumentTuple {
            let params = try require(paramsType.children.first)
            let numParams = params.kind == .Tuple ? params.children.count : 1
            return Node(kind: kind, children: [paramsType], payload: .Index(UInt64(numParams)))
        } else {
            return Node(kind: kind, children: [paramsType])
        }
    }

    mutating private func getLabel(params: inout Node, idx: Int) throws -> Node {
        if isOldFunctionTypeMangling {
            let param = try require(params.children.at(idx))
            if let label = param.children.enumerated().first(where: { $0.element.kind == .TupleElementName }) {
                params.children[idx].children.remove(at: label.offset)
                return Node(kind: .Identifier, payload: .Text(label.element.text))
            }
            return Node(kind: .FirstElementMarker)
        }
        return try require(pop())
    }

    mutating func popFunctionParamLabels(type: Node) throws -> Node? {
        if !isOldFunctionTypeMangling && pop(kind: .EmptyList) != nil {
            return Node(kind: .LabelList)
        }

        guard type.kind == .Type else { return nil }

        let topFuncType = try require(type.children.first)
        let funcType: Node
        if topFuncType.kind == .DependentGenericType {
            funcType = try require(topFuncType.children.at(1)?.children.first)
        } else {
            funcType = topFuncType
        }

        guard funcType.kind == .FunctionType || funcType.kind == .NoEscapeFunctionType else { return nil }

        var parameterType = try require(funcType.children.first)
        if parameterType.kind == .ThrowsAnnotation {
            parameterType = try require(funcType.children.at(1))
        }

        try require(parameterType.kind == .ArgumentTuple)
        guard parameterType.hasIndex else { return nil }

        let possibleTuple = parameterType.children.first?.children.first
        guard !isOldFunctionTypeMangling, var tuple = possibleTuple, tuple.kind == .Tuple else {
            return Node(kind: .LabelList)
        }

        var hasLabels = false
        var children = [Node]()
        for i in 0..<parameterType.index {
            let label = try getLabel(params: &tuple, idx: Int(i))
            try require(label.kind == .Identifier || label.kind == .FirstElementMarker)
            children.append(label)
            hasLabels = hasLabels || (label.kind != .FirstElementMarker)
        }

        if !hasLabels {
            return Node(kind: .LabelList)
        }

        return Node(kind: .LabelList, children: isOldFunctionTypeMangling ? children : children.reversed())
    }

    mutating func popTuple() throws -> Node {
        var children: [Node] = []
        if pop(kind: .EmptyList) == nil {
            var firstElem = false
            repeat {
                firstElem = pop(kind: .FirstElementMarker) != nil
                var elemChildren: [Node] = pop(kind: .VariadicMarker).map { [$0] } ?? []
                if let ident = pop(kind: .Identifier), case .Text(let text) = ident.payload {
                    elemChildren.append(Node(kind: .TupleElementName, payload: .Text(text)))
                }
                elemChildren.append(try require(pop(kind: .Type)))
                children.insert(Node(kind: .TupleElement, children: elemChildren), at: 0)
            } while (!firstElem)
        }
        return Node(typeWithChildKind: .Tuple, childChildren: children)
    }

    mutating func popTypeList() throws -> Node {
        var children: [Node] = []
        if pop(kind: .EmptyList) == nil {
            var firstElem = false
            repeat {
                firstElem = pop(kind: .FirstElementMarker) != nil
                children.insert(try require(pop(kind: .Type)), at: 0)
            } while (!firstElem)
        }
        return Node(kind: .TypeList, children: children)
    }

    mutating func popProtocol() throws -> Node {
        if let type = pop(kind: .Type) {
            try require(type.children.at(0)?.kind == .Protocol)
            return type
        }

        let name = try require(pop { $0.isDeclName })
        let context = try popContext()
        return Node(typeWithChildKind: .Protocol, childChildren: [context, name])
    }

    mutating func popModule() -> Node? {
        if let ident = pop(kind: .Identifier) {
            return ident.changingKind(.Module)
        } else {
            return pop(kind: .Module)
        }
    }

    mutating func popContext() throws -> Node {
        if let mod = popModule() {
            return mod
        } else if let type = pop(kind: .Type) {
            let child = try require(type.children.first)
            try require(child.kind.isContext)
            return child
        }
        return try require(pop { $0.isContext })
    }

    mutating func popTypeAndGetChild() throws -> Node {
        return try require(pop(kind: .Type)?.children.first)
    }

    mutating func popTypeAndGetAnyGeneric() throws -> Node {
        let child = try popTypeAndGetChild()
        try require(child.kind.isAnyGeneric)
        return child
    }

    mutating func popAssociatedTypeName() throws -> Node {
        let proto = pop(kind: .Type)
        let id = try require(pop(kind: .Identifier))
        var result = id.changingKind(.DependentAssociatedTypeRef)
        if let p = proto {
            try require(p.children.first?.kind == .Protocol)
            result.children.append(p)
        }
        return result
    }

    mutating func popAssociatedTypePath() throws -> Node {
        var firstElem = false
        var assocTypePath = [Node]()
        repeat {
            firstElem = pop(kind: .FirstElementMarker) != nil
            assocTypePath.append(try require(pop { $0.isDeclName }))
        } while !firstElem
        return Node(kind: .AssocTypePath, children: assocTypePath.reversed())
    }

    mutating func popProtocolConformance() throws -> Node {
        let genSig = pop(kind: .DependentGenericSignature)
        let module = try require(popModule())
        let proto = try popProtocol()
        var type = pop(kind: .Type)
        var ident: Node? = nil
        if type == nil {
            ident = pop(kind: .Identifier)
            type = pop(kind: .Type)
        }
        if let gs = genSig {
            type = Node(typeWithChildKind: .DependentGenericType, childChildren: [gs, try require(type)])
        }
        var children = [try require(type), proto, module]
        if let i = ident {
            children.append(i)
        }
        return Node(kind: .ProtocolConformance, children: children)
    }

    mutating func popAnyProtocolConformanceList() throws -> Node {
        var conformanceList = Node(kind: .AnyProtocolConformanceList);
      if pop(kind: .EmptyList) == nil {
        var firstElem = false
        repeat {
          firstElem = pop(kind: .FirstElementMarker) != nil
          let anyConformance = try popAnyProtocolConformance()
            conformanceList.children.append(anyConformance)
        } while !firstElem

        conformanceList.reverseChildren(startingAt: 0)
      }
      return conformanceList
    }

    mutating func popAnyProtocolConformance() throws -> Node {
        return try require(pop(where: { (it: Node.Kind) -> Bool in
            it == .ConcreteProtocolConformance ||
                it == .DependentProtocolConformanceRoot ||
                it == .DependentProtocolConformanceInherited ||
                it == .DependentProtocolConformanceAssociated
        }))
    }

    mutating func popDependentProtocolConformance() throws -> Node {
        let node: Node? = pop(where: { (kind: Node.Kind) -> Bool in kind == .DependentProtocolConformanceRoot || kind == .DependentProtocolConformanceInherited || kind == .DependentProtocolConformanceAssociated })
        return try require(node)
    }

    mutating func popDependentAssociatedConformance() throws -> Node {
        let `protocol` = try popProtocol()
        let dependentType = try require(pop(kind: .Type))
        return Node(kind: .DependentAssociatedConformance, children: [dependentType, `protocol`])
    }

    mutating func popAssocTypeName() throws -> Node {
        var proto = pop(kind: .Type)

        if let p = proto {
            try require(p.isProtocolNode)
        }

        // If we haven"t seen a protocol, check for a symbolic reference.
        if proto == nil {
            proto = pop(kind: .ProtocolSymbolicReference)
        }

        let id = try require(pop(kind: .Identifier))
        var assocTy = Node(kind: .DependentAssociatedTypeRef, child: id)
        if let p = proto {
            assocTy.children.append(p)
        }
        return assocTy
    }

    mutating func popAssocTypePath() throws -> Node {
        var assocTypePath = Node(kind: .AssocTypePath)
        var firstElem = false
        repeat {
            firstElem = pop(kind: .FirstElementMarker) != nil
            let assocTy = try popAssocTypeName()
            assocTypePath.children.append(assocTy)
        } while !firstElem
        assocTypePath.children.reverse()
        return assocTypePath
    }

}
