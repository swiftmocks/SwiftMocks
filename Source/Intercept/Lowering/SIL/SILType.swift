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

/// How an existential type container is represented.
enum SILExistentialRepresentation: Hashable {
    /// The type is not existential.
    case none
    /// The container uses an opaque existential container, with a fixed-sized
    /// buffer. The type is address-only and is manipulated using the
    /// {init,open,deinit}_existential_addr family of instructions.
    case opaque
    /// The container uses a class existential container, which holds a reference
    /// to the class instance that conforms to the protocol. The type is
    /// reference-counted and is manipulated using the
    /// {init,open}_existential_ref family of instructions.
    case `class`
    /// The container uses a metatype existential container, which holds a reference to the type metadata for a type that conforms to the protocol.
    /// The type is trivial, and is manipulated using the {init,open}_existential_metatype family of instructions.
    case metatype
    /// The container uses a boxed existential container, which is a reference-counted buffer that indirectly contains the conforming value. The type is manipulated using the {alloc,open,dealloc}_existential_box family of instructions.
    /// The container may be able to directly adopt a class reference using init_existential_ref for some class types.
    case boxed
}

/// The value category.
enum SILValueCategory: Hashable {
    /// An object is a value of the type.
    case object
    /// An address is a pointer to an allocated variable of the type (possibly uninitialized).
    case address
}

/// SILType - A Swift type that has been lowered to a SIL representation type.
/// In addition to the Swift type system, SIL adds "address" types that can reference any Swift type (but cannot take the address of an address). *T is the type of an address pointing at T.
struct SILType: Hashable {
    let type: AType
    let category: SILValueCategory

    init(canType: CanType, category: SILValueCategory) {
        type = canType.type
        self.category = category
    }

    /// Returns the canonical AST type referenced by this SIL type.
    func getASTType() -> CanType {
        CanType(type: type)
    }

    /// True if the type is an object type.
    var isObject: Bool {
        category == .object
    }

    /// Returns true if the referenced type is an existential type.
    var isExistentialType: Bool {
        getASTType().isExistentialType
    }

    /// Returns the representation used by an existential type. If the concrete type is provided, this may return a specialized representation kind that can be used for that type. Otherwise, returns the most general representation kind for the type. Returns None if the type is not an existential type.
    func getPreferredExistentialRepresentation(module: SILModule, containedType: AType? = nil) -> SILExistentialRepresentation {
        // Existential metatypes always use metatype representation.
        if getASTType().type is ExistentialMetatypeType {
            return .metatype
        }

        // If the type isn't existential, then there is no representation.
        if !isExistentialType {
            return .none
        }

        let layout = getASTType().existentialLayout

        if layout.isErrorExistential {
            // NSError or CFError references can be adopted directly as Error existentials.
            if (isBridgedErrorClass(module: module, typet: containedType)) {
                return .class
            } else {
                return .boxed
            }
        }

        // A class-constrained protocol composition can adopt the conforming class reference directly.
        if layout.requiresClass {
            return .class
        }

        // Otherwise, we need to use a fixed-sized buffer.
        return .opaque
    }

    /// Form the type of an r-value, given a Swift type that either does not require any special handling or has already been appropriately lowered.
    static func getPrimitiveObjectType(_ type: CanType) -> SILType {
        SILType(canType: type, category: .object)
    }

    /// Form the type for the address of an object, given a Swift type that either does not require any special handling or has already been appropriately lowered.
    static func getPrimitiveAddressType(_ type: CanType) -> SILType {
        SILType(canType: type, category: .address)
    }

    /// Get the standard exception type.
    static func getExceptionType() -> SILType {
        SILType.getPrimitiveObjectType(TypeFactory.from(anyType: Swift.Error.self).canonicalType)
    }
}

private func isBridgedErrorClass(module: SILModule, typet : AType?) -> Bool {
    false // TODO: this should be properly implemented for objc interop
}
