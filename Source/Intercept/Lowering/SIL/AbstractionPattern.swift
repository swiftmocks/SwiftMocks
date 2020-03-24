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

struct AbstractionPattern: Hashable {
    // implementation note: this is the minimal reimplementation of the code that does not contain any objc or clang related stuff
    enum Kind: Hashable {
        /// A type reference.  OrigType is valid.
        case type
        /// A completely opaque abstraction pattern.
        case opaque
        /// A discarded value. OrigType is valid.
        case discard
    }

    let kind: Kind
    private let _origType: CanType?
    let genericSignature: GenericSignature?

    /// Return the Swift type which provides structure for this abstraction pattern. This is always valid unless the pattern is opaque or an open-coded tuple.  However, it does not always fully describe the abstraction pattern.
    var originalType: CanType {
        switch kind {
        case .opaque:
            LoweringError.unreachable("opaque pattern has no type")
        case .type, .discard:
            return _origType!
        }
    }

    init(origType: CanType, signature: GenericSignature? = nil) {
        self = AbstractionPattern(signature: signature, origType: origType, kind: .type)
    }

    private init(signature: GenericSignature?, origType: CanType, kind: Kind) {
        precondition(signature != nil || !origType~>.hasTypeParameter)
        self.kind = kind
        self._origType = origType
        self.genericSignature = signature
    }

    private init(kind: Kind) {
        self.kind = kind
        self._origType = .none
        self.genericSignature = nil
    }

    static func opaque() -> AbstractionPattern {
        AbstractionPattern(kind: .opaque)
    }

    /// Return an abstraction pattern for a value that is discarded after being evaluated.
    static func discard(signature: GenericSignature?, origType: CanType) -> AbstractionPattern {
        AbstractionPattern(signature: signature, origType: origType, kind: .discard)
    }

    var isTypeParameter: Bool {
        switch kind {
        case .opaque:
            return true
        case .type, .discard:
            if originalType.type is DependentMemberType || originalType.type is GenericTypeParamType {
                return true
            }
            if let archetype = originalType.type as? ArchetypeType {
                return !(archetype.root is OpaqueTypeArchetypeType)
            }
            return false
        }
    }

    var isConcreteType: Bool {
        precondition(isTypeParameter)
        return kind != .opaque && genericSignature != nil && genericSignature!.isConcreteType(originalType.type)
    }

    var requiresClass: Bool {
        switch kind {
        case .opaque:
            return false
        case .type, .discard:
            if let archetype: ArchetypeType = getAs() {
                return archetype.requiresClass
            } else if originalType.type is DependentMemberType || originalType.type is GenericTypeParamType {
                assert(genericSignature != nil, "Dependent type in pattern without generic signature?")
                return genericSignature!.requiresClass(originalType.type)
            }
            return false
        }
    }

    var isForeign: Bool { false }

    var isTuple: Bool {
        switch kind {
        case .type, .discard:
            return originalType.type is TupleType
        default:
            return false
        }
    }

    var numberOfTupleElements: Int {
        switch kind {
        case .type, .discard:
            return (originalType.type as! TupleType).elements.count
        default:
            LoweringError.unreachable("asking for the number of tuple elements for kind \(kind)")
        }
    }

    /// Given that the value being abstracted is a function, return the abstraction pattern for its result type.
    var functionResultType: AbstractionPattern {
        switch kind {
        case .opaque:
            return self
        case .type:
            if isTypeParameter {
                return AbstractionPattern.opaque()
            }
            return AbstractionPattern(origType: (originalType.type as! AnyFunctionType).resultType.canonicalType, signature: genericSignatureForFunctionComponent)
        case .discard:
            LoweringError.unreachable("don't need to discard function abstractions yet")
        }
    }

    var genericSignatureForFunctionComponent: GenericSignature? {
        if let genericFn = originalType.type as? GenericFunctionType {
            return genericFn.genericSignature
        }
        return nil
    }

    var optionalObjectType: AbstractionPattern {
        switch kind {
        case .opaque:
            return self
        case .type:
            if isTypeParameter {
                return AbstractionPattern.opaque()
            }
            guard let optionalObjectType = originalType.optionalObjectType else {
                LoweringError.unreachable("not an optional")
            }
            return AbstractionPattern(origType: optionalObjectType, signature: genericSignature)

        case .discard:
            guard let optionalObjectType = originalType.optionalObjectType else {
                LoweringError.unreachable("not an optional")
            }
            return AbstractionPattern.discard(signature: genericSignature, origType: optionalObjectType)
        }
    }

    var referenceStorageReferentType: AbstractionPattern {
        switch kind {
        case .type:
            return AbstractionPattern(origType: originalType.referenceStorageReferent, signature: genericSignature)
        case .opaque:
            return self
        case .discard:
            return AbstractionPattern.discard(signature: genericSignature, origType: originalType.referenceStorageReferent)
        }
    }

    func tupleElementType(at index: Int) -> AbstractionPattern {
        switch kind {
        case .opaque:
            return self
        case .discard:
            LoweringError.unreachable("operation not needed on discarded abstractions yet")
        case .type:
            if isTypeParameter {
                return AbstractionPattern.opaque()
            }
            return AbstractionPattern(origType: originalType.tupleElementType(index: index), signature: genericSignature)
        }
    }

    /// Given that the value being abstracted is a function type, return the abstraction pattern for one of its parameter types.
    func functionParamType(_ index: Int) -> AbstractionPattern {
        switch kind {
        case .opaque:
            return self
        case .type:
            if isTypeParameter {
                return AbstractionPattern.opaque()
            }
            let params = (originalType.type as! AnyFunctionType).params
            return AbstractionPattern(origType: CanType(type: params[index].getParameterType()), signature: genericSignatureForFunctionComponent)
        case .discard:
            LoweringError.unreachable("\(#function) called for \(kind)")
        }
    }

    func getAs<T: AType>(type: T.Type = T.self) -> T? {
        originalType.type as? T
    }
}
