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

enum StaticSpellingKind {
    case none
    case `static`
    case `class`
}

class FuncDecl: AbstractFunctionDecl {
    let staticSpelling: StaticSpellingKind = .static // the difference is not preserved in mangled names

    override init(parent: DeclContext, throws: Bool, hasImplicitSelfDecl: Bool, params: [AType], resultTy: AType, isStatic: Bool, genericSig: GenericSignature?, selfAccessKind: SelfAccessKind = .nonMutating) {
        super.init(parent: parent, throws: `throws`, hasImplicitSelfDecl: hasImplicitSelfDecl, params: params, resultTy: resultTy, isStatic: isStatic, genericSig: genericSig, selfAccessKind: selfAccessKind)
    }
}

enum AccessorKind: Equatable {
    case get
    case set
    case read
    case modify
    case didSet
    case willSet
}

class AccessorDecl: FuncDecl {
    let kind: AccessorKind
    let storageType: AType

    var isCoroutine: Bool {
        kind == .modify || kind == .read // FIXME: test _read coroutine
    }

    var isGetter: Bool {
        kind == .get
    }

    var isSetter: Bool {
        kind == .set
    }

    init(parent: DeclContext, kind: AccessorKind, storageType: AType, indices: [AType], isStatic: Bool, genericSig: GenericSignature?) {
        // see createAccessorFunc()

        // FIXME: for indices, missing param specifiers (inout etc)
        // FIXME: for indices, missing variadic, autoclosure; implicit [?]

        self.kind = kind
        self.storageType = storageType

        let hasImplicitSelfDecl = parent.isTypeContext

        // First, set up the value argument list.  This is the "newValue" name (for setters) followed by the index list (for subscripts).  For non-subscript getters, this degenerates down to "()". We put the 'newValue' argument before the subscript index list as a micro-optimization for Objective-C thunk generation.
        var params = indices
        let resultTy: AType
        switch kind {
        case .get:
            resultTy = storageType
        case .set:
            params.insert(storageType, at: 0)
            resultTy = TypeFactory.void
        case .modify:
            resultTy = TypeFactory.void
        case .didSet:
            LoweringError.notImplemented("didSet")
        case .willSet:
            LoweringError.notImplemented("willSet")
        case .read:
            LoweringError.notImplemented("_read coroutine")
        }

        let selfAccessKind: SelfAccessKind

        // Non-static set/willSet/didSet/mutableAddress default to mutating. get/address default to non-mutating.
        switch kind {
        case /* .address, */ .get, .read:
            selfAccessKind = .nonMutating
        case /* .mutableAddress, */ .set, .willSet, .didSet, .modify:
            selfAccessKind = !isStatic ? .mutating : .nonMutating
        }

        super.init(parent: parent, throws: false, hasImplicitSelfDecl: hasImplicitSelfDecl, params: params, resultTy: resultTy, isStatic: isStatic, genericSig: genericSig, selfAccessKind: selfAccessKind)
    }
}

class AbstractFunctionDecl: ValueDecl {
    let name: String
    let `throws`: Bool
    let hasImplicitSelfDecl: Bool
    let genericParams: Void

    let params: [AType]
    let resultTy: AType

    let interfaceType: AnyFunctionType

    fileprivate init(parent: DeclContext, throws: Bool, hasImplicitSelfDecl: Bool, params: [AType], resultTy: AType, isStatic: Bool, genericSig: GenericSignature?, selfAccessKind selfAccess: SelfAccessKind = .nonMutating) {
        self.name = "TODO"
        self.throws = `throws`
        self.hasImplicitSelfDecl = hasImplicitSelfDecl
        self.params = params
        self.resultTy = resultTy

        let hasDynamicSelf = false

        func computeSelfParam(isInitializingCtor: Bool = false, wantDynamicSelf: Bool = false) -> AnyFunctionType.Param {
            let declContext = parent
            let containerTy: AType
            switch declContext {
            case .topLevel:
                LoweringError.unreachable("trying to compute self for a top-level definition")
            case let .genericTypeContext(genericTypeDecl):
                containerTy = genericTypeDecl.declaredInterfaceType
            case let .extension(nominalTypeDecl):
                containerTy = nominalTypeDecl.declaredInterfaceType
            }

            guard var selfTy = declContext.selfInterfaceType else {
                LoweringError.unreachable("computing self param for a context that doesn't declare an interface type: \(declContext)")
            }

            let isDynamicSelf: Bool
            if type(of: Self.self) == type(of: FuncDecl.self) || type(of: Self.self) == type(of: AccessorDecl.self) {
                isDynamicSelf = wantDynamicSelf && hasDynamicSelf
            } else {
                LoweringError.notImplemented("constructor and destructor")
            }
            if isDynamicSelf {
                selfTy = TypeFactory.createDynamicSelfType(selfType: selfTy)
            }
            if isStatic {
                return AnyFunctionType.Param(type: TypeFactory.createMetatype(instanceType: selfTy))
            }

            if containerTy.hasReferenceSemantics {
                return AnyFunctionType.Param(type: selfTy)
            }

            let flags: ParameterTypeFlags
            switch selfAccess {
            case .nonMutating:
                flags = ParameterTypeFlags()
            case .mutating:
                flags = ParameterTypeFlags(valueOwnership: .inOut)
            case .__consuming:
                flags = ParameterTypeFlags(valueOwnership: .owned)
            }
            return AnyFunctionType.Param(type: selfTy, flags: flags)
        }

        /// Compute the interface type of this function declaration from the parameter types.
        func computeType(info: AnyFunctionType.ExtInfo = AnyFunctionType.ExtInfo()) -> AnyFunctionType {
            let result: AType
            let hasSelf = hasImplicitSelfDecl
            if type(of: Self.self) == type(of: FuncDecl.self) || type(of: Self.self) == type(of: AccessorDecl.self) {
                result = resultTy
            } else {
                LoweringError.notImplemented("constructor and destructor")
            }

            let info = info.setting(throws: `throws`) // we don't care about noescape

            // (Args...) -> Result
            var funcTy: AnyFunctionType
            let params: [AnyFunctionType.Param] = params.map { type -> AnyFunctionType.Param in
                // FIXME: no ownership or variadicness, or autoclosure
                let variadic = false
                let autoclosure = false

                // FIXME: should be done elsewhere
                if let inoutType = type as? InOutType {
                    return .init(type: inoutType.objectType, flags: .init(isVariadic: variadic, isAutoclosure: autoclosure, valueOwnership: .inOut))
                }
                return .init(type: type, flags: .init(isVariadic: variadic, isAutoclosure: autoclosure, valueOwnership: .default))
            }

            if let genericSig = genericSig, !hasSelf {
                funcTy = TypeFactory.createAnyFunctionType(params: params, result: result, extInfo: info, genericSignature: genericSig)
            } else {
                funcTy = TypeFactory.createAnyFunctionType(params: params, result: result, extInfo: info)
            }

            // (Self) -> (Args...) -> Result
            if hasSelf {
                let selfParam = computeSelfParam()
                if let genericSig = genericSig {
                    funcTy = TypeFactory.createAnyFunctionType(params: [selfParam], result: funcTy, extInfo: AnyFunctionType.ExtInfo(), genericSignature: genericSig)
                } else {
                    funcTy = TypeFactory.createAnyFunctionType(params: [selfParam], result: funcTy)
                }
            }

            return funcTy
        }

        interfaceType = computeType()

        super.init(context: parent)
    }
}
