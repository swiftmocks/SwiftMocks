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

/// Conventions for returning values.
enum ResultConvention {
    /// This result is returned indirectly, i.e. by passing the address of an uninitialized object in memory.  The callee is responsible for leaving an initialized object at this address.  The callee may assume that the address does not alias any valid object.
    case indirect

    /// The caller is responsible for destroying this return value. Its type is non-trivial.
    case owned

    /// The caller is not responsible for destroying this return value. Its type may be trivial, or it may simply be offered unsafely. It is valid at the instant of the return, but further operations may invalidate it.
    case unowned

    /// The caller is not responsible for destroying this return value. The validity of the return value is dependent on the 'self' parameter, so it may be invalidated if that parameter is released.
    case unownedInnerPointer

    /// This value has been (or may have been) returned autoreleased. The caller should make an effort to reclaim the autorelease. The type must be a class or class existential type, and this must be the only return value.
    case autoreleased

    var isIndirectFormalResult: Bool {
        self == .indirect
    }
}


struct SILResultInfo: Hashable {
    let type: CanType
    let convention: ResultConvention

    init(type: CanType, convention: ResultConvention) {
        self.type = type
        self.convention = convention
    }

    init(type: AType, convention: ResultConvention) {
        self.type = CanType(type: type)
        self.convention = convention
    }

    // Does this result convention require indirect storage? This reflects a SILFunctionType's formal (immutable) conventions, as opposed to the transient SIL conventions that dictate SILValue types.
    var isFormalIndirect: Bool {
        convention.isIndirectFormalResult
    }

    var isFormalDirect: Bool {
        !convention.isIndirectFormalResult
    }
}
