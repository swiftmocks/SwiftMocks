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

extension IRTypeConverter {
    func convertBoxType(_ type: SILBoxType) -> TypeInfo {
        LoweringError.notImplemented("SILBoxType")
    }

    func convertBuiltinNativeObject() -> LoadableTypeInfo {
        BuiltinNativeObjectTypeInfo(storage: igm.refCountedPtrTy, size: igm.pointerSize, alignment: igm.pointerAlignment)
    }

    func convertWeakStorageType(_ type: WeakStorageType) -> TypeInfo {
        createWeakStorageType()
    }

    func convertUnownedStorageType(_ type: UnownedStorageType) -> TypeInfo {
        createUnownedStorageType()
    }

    func convertUnmanagedStorageType(_ type: UnmanagedStorageType) -> TypeInfo {
        createUnmanagedStorageType()
    }

    func createWeakStorageType() -> TypeInfo {
        WeakReferenceTypeInfo(storage: .pointer, size: igm.pointerSize, alignment: igm.pointerAlignment)
    }

    func createUnownedStorageType() -> TypeInfo {
        UnownedReferenceTypeInfo(storage: .pointer, size: igm.pointerSize, alignment: igm.pointerAlignment)
    }

    func createUnmanagedStorageType() -> TypeInfo {
        UnmanagedReferenceTypeInfo(storage: .pointer, size: igm.pointerSize, alignment: igm.pointerAlignment)
    }
}

private class UnmanagedReferenceTypeInfo: PODSingleScalarTypeInfo {}
private class UnownedReferenceTypeInfo: PODSingleScalarTypeInfo {}
private class WeakReferenceTypeInfo: PODSingleScalarTypeInfo {}

private class BuiltinNativeObjectTypeInfo: HeapTypeInfo {}
