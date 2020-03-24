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

class ReferenceStorageType: AType, ATypeEquatable {
    let referentType: AType

    var ownership: ReferenceOwnership {
        switch kind {
        case .weakStorage:
            return .weak
        case .unownedStorage:
            return .unowned
        case .unmanagedStorage:
            return .unmanaged
        default:
            LoweringError.unreachable("bad kind of \(ReferenceStorageType.self): \(kind)")
        }
    }

    fileprivate init(kind: TypeKind, referentType: AType) {
        self.referentType = referentType
        super.init(kind: kind)
    }

    func isEqual(to other: AType) -> Bool {
        guard let other = other as? ReferenceStorageType else {
            return false
        }
        return other.kind == kind && other.referentType == referentType
    }

    /// To be called only by `TypeFactory`
    static func _get(referentType: AType, referenceOwnership: ReferenceOwnership) -> ReferenceStorageType {
        switch referenceOwnership {
        case .strong:
            LoweringError.unreachable("\(#function) called for .strong ownership")
        case .weak:
            return WeakStorageType(referentType: referentType)
        case .unowned:
            return UnownedStorageType(referentType: referentType)
        case .unmanaged:
            return UnmanagedStorageType(referentType: referentType)
        }
    }
}

class WeakStorageType: ReferenceStorageType {
    init(referentType: AType) {
        super.init(kind: .weakStorage, referentType: referentType)
    }
}

class UnownedStorageType: ReferenceStorageType {
    fileprivate init(referentType: AType) {
        super.init(kind: .unownedStorage, referentType: referentType)
    }

    func isLoadable(expansion: ResilienceExpansion) -> Bool {
        var ty = referentType
        if let underlyingTy = ty.optionalObjectType {
            ty = underlyingTy
        }

        return ty.referenceCounting == .native
    }
}

class UnmanagedStorageType: ReferenceStorageType {
    fileprivate init(referentType: AType) {
        super.init(kind: .unmanagedStorage, referentType: referentType)
    }
}
