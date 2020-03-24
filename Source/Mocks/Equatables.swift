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

enum Equatables {
    private static let equatableProto: ProtocolDescriptor = {
        struct S<T: Equatable> {}
        let req = Metadata.of(S<Int>.self).typeContextDescriptor!.genericRequirements![0]
        guard case let .protocol(maybeSwiftProto) = req.kind, let proto = maybeSwiftProto else {
            fatalError()
        }
        return proto
    }()

    /// Return whether the **runtime type** of the given `instance` conforms to `Equatable` protocol.
    static func conformsToEquatable(_ instance: Any) -> Bool {
        Runtime.conformsToProtocol(metadata: Metadata.of(type(of: instance)), proto: equatableProto) != nil
    }

    /// Returns whether two given instances are equal.
    ///
    /// - Returns:
    ///     - `true` if both instances are of the same runtime type conforming to `Equatable`, and they are equal
    ///     - `false` if both instances are of the same runtime type conforming to `Equatable`, and they are not equal
    ///     - `nil` if the instances are of different runtime types, **or** their runtime type does not conform to `Equatable`, **or** they are class instances (SwiftMocks doesn't need to test class instances for equality, so we don't bother to support it here)
    static func areEqual(lhs: Any, rhs: Any) -> Bool? {
        let lhsMetadata = Metadata.of(type(of: lhs))
        let rhsMetadata = Metadata.of(type(of: rhs))
        if lhsMetadata != rhsMetadata {
            return nil
        }

        if lhsMetadata is AnyClassMetadata {
            return nil
        }

        guard let witnessTable = Runtime.conformsToProtocol(metadata: lhsMetadata, proto: equatableProto) else {
            return nil
        }

        let equatableImpl = witnessTable.pointer.reinterpret(RawPointer.self).advanced(by: 1).pointee

        var lhs = lhs
        var rhs = rhs

        let lhsBox = AnyExistentialBox(&lhs)
        let rhsBox = AnyExistentialBox(&rhs)

        let fn = unsafeBitCast(equatableImpl, to: (@convention(c) (RawPointer /* @in_guaranteed T */, RawPointer /* @in_guaranteed T */, RawPointer /* @thick T.Type */) -> Bool).self)

        let ret = fn(lhsBox.projected, rhsBox.projected, lhsMetadata.pointer)
        return ret
    }
}
