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

enum ParameterConvention {
    /// This argument is passed indirectly, i.e. by directly passing the address of an object in memory.  The callee is responsible for destroying the object.  The callee may assume that the address does not alias any valid object.
    case indirectIn

    /// This argument is passed indirectly, i.e. by directly passing the address of an object in memory.  The callee must treat the object as read-only. The callee may assume that the address does not alias any valid object.
    case indirectInConstant

    /// This argument is passed indirectly, i.e. by directly passing the address of an object in memory.  The callee may not modify and does not destroy the object.
    case indirectInGuaranteed

    /// This argument is passed indirectly, i.e. by directly passing the address of an object in memory.  The object is always valid, but the callee may assume that the address does not alias any valid object and reorder loads stores to the parameter as long as the whole object remains valid. Invalid single-threaded aliasing may produce inconsistent results, but should remain memory safe.
    case indirectInout

    /// This argument is passed indirectly, i.e. by directly passing the address of an object in memory. The object is allowed to be aliased by other well-typed references, but is not allowed to be escaped. This is the convention used by mutable captures in @noescape closures.
    case indirectInoutAliasable

    /// This argument is passed directly.  Its type is non-trivial, and the callee is responsible for destroying it.
    case directOwned

    /// This argument is passed directly.  Its type may be trivial, or it may simply be that the callee is not responsible for destroying it.  Its validity is guaranteed only at the instant the call begins.
    case directUnowned

    /// This argument is passed directly.  Its type is non-trivial, and the caller guarantees its validity for the entirety of the call.
    case directGuaranteed

    // Does this parameter convention require indirect storage? This reflects a SILFunctionType's formal (immutable) conventions, as opposed to the transient SIL conventions that dictate SILValue types.
    var isIndirectFormalParameter: Bool {
        switch self {
        case .indirectIn,
             .indirectInConstant,
             .indirectInout,
             .indirectInoutAliasable,
             .indirectInGuaranteed:
            return true

        case .directUnowned, .directGuaranteed, .directOwned:
            return false
        }
    }

    var isConsumedParameter: Bool {
        switch self {
        case .indirectIn,
             .indirectInConstant,
             .directOwned:
            return true

        case .indirectInout,
             .indirectInoutAliasable,
             .directUnowned,
             .directGuaranteed,
             .indirectInGuaranteed:
            return false
        }
    }

    /// Returns true if conv is a guaranteed parameter. This may look unnecessary but this will allow code to generalize to handle Indirect_Guaranteed parameters when they are added.
    var isGuaranteedParameter: Bool {
        switch self {
        case .directGuaranteed,
             .indirectInGuaranteed:
            return true

        case .indirectInout,
             .indirectInoutAliasable,
             .indirectIn,
             .indirectInConstant,
             .directUnowned,
             .directOwned:
            return false
        }
    }
}

/// A parameter type and the rules for passing it.
struct SILParameterInfo: Hashable {
    let type: CanType
    let convention: ParameterConvention

    init(type: CanType, convention: ParameterConvention) {
        self.type = type
        self.convention = convention
    }

    init(type: AType, convention: ParameterConvention) {
        self.type = CanType(type: type)
        self.convention = convention
    }

    // Does this parameter convention require indirect storage? This reflects a SILFunctionType's formal (immutable) conventions, as opposed to the transient SIL conventions that dictate SILValue types.
    var isFormalIndirect: Bool {
        convention.isIndirectFormalParameter
    }

    var isDirectGuaranteed: Bool {
        convention == .directGuaranteed
    }

    var isIndirectInGuaranteed: Bool {
        convention == .indirectInGuaranteed
    }

    var isIndirectInOut: Bool {
        convention == .indirectInout
    }

    var isIndirectMutating: Bool {
        convention == .indirectInout || convention == .indirectInoutAliasable
    }

    /// True if this parameter is consumed by the callee, either indirectly or directly.
    var isConsumed: Bool {
        convention.isConsumedParameter
    }

    /// Returns true if this parameter is guaranteed, either indirectly or directly.
    var isGuaranteed: Bool {
        convention.isGuaranteedParameter
    }

    /// The SIL storage type determines the ABI for arguments based purely on the formal parameter conventions. The actual SIL type for the argument values may differ in canonical SIL. In particular, opaque values require indirect storage. Therefore they will be passed using an indirect formal convention, and this method will return an address type. However, in canonical SIL the opaque arguments might not have an address type.
    var silStorageType: SILType {
        SILModuleConventions.getSILParamType(self, true)
    }

    /// Return a version of this parameter info with the type replaced.
    func getWithType(type: CanType) ->  SILParameterInfo {
        SILParameterInfo(type: type, convention: convention)
    }
}
