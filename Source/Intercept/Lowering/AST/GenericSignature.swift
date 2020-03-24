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

/// Describes the generic signature of a particular declaration, including both the generic type parameters and the requirements placed on those generic parameters.
struct GenericSignature: Hashable {
    let genericParams: [GenericTypeParamType]
    let requirements: [Requirement]

    private init(types: [GenericTypeParamType], requirements: [Requirement]) {
        self.genericParams = types
        self.requirements = requirements
    }

    func isConcreteType(_ type: AType) -> Bool {
        precondition(requirements.count == 1 && requirements[0].first == type && requirements[0].kind == .conformance) // that's all we can handle
        return false // a conformance requirement never results in a concrete type
    }

    func requiresClass(_ type: AType) -> Bool {
        guard type.isTypeParameter else {
            return false
        }

        precondition(requirements.count == 1 && requirements[0].first == type && requirements[0].kind == .conformance) // that's all we can handle
        guard let proto = requirements[0].second as? ProtocolType else {
            LoweringError.unreachable("conforming to non-protocol type?")
        }

        return proto.requiresClass
    }

    func getConcreteType(_ type: AType) -> AType? {
        precondition(requirements.count == 1 && requirements[0].first == type && requirements[0].kind == .conformance) // that's all we can handle
        return nil // a conformance requirement never results in a concrete type
    }

    /// Determine the superclass bound on the given dependent type.
    func getSuperclassBound(_ type: AType) -> AType? {
        if !type.isTypeParameter {
            return nil
        }
        LoweringError.notImplemented("generics")
    }

    /// Determine the set of protocols to which the given dependent type must conform.
    func getConformsTo(type: AType) -> [ProtocolDecl] {
        if !type.isTypeParameter {
            return []
        }

        LoweringError.notImplemented(#function)
    }

    /// Iterate over all generic parameters, passing a flag to the callback indicating if the generic parameter is canonical or not.
    func forEachParam(_ callback: (GenericTypeParamType, Bool) -> Void) {
        // Figure out which generic parameters are concrete or same-typed to another type parameter.
        let genericParamsAreCanonical: [Bool] = Array(repeating: true, count: genericParams.count)

        for req in requirements {
            if req.kind != .sameType {
                continue
            }

            LoweringError.notImplemented("same type in \(#function)")
        }

        // Call the callback with each parameter and the result of the above analysis.
        for index in genericParams.indices {
            callback(genericParams[index], genericParamsAreCanonical[index])
        }
    }

    /// Create a generics signature with a single generic type param type of (invalid) `depth == index == 0` conforming to a single protocol (`<τ_0_0 where τ_0_0 : P>`). This is used for protocol method types.
    static func genericTypeParamType(conformsTo proto: ProtocolType) -> GenericSignature {
        let first: GenericTypeParamType = GenericTypeParamType.tau00
        return .init(types: [first], requirements: [.conformance(of: first, to: proto)])
    }

    static func == (lhs: GenericSignature, rhs: GenericSignature) -> Bool {
        lhs.genericParams == rhs.genericParams && lhs.requirements == rhs.requirements
    }

    func hash(into hasher: inout Hasher) {
        genericParams.hash(into: &hasher)
        requirements.hash(into: &hasher)
    }
}
