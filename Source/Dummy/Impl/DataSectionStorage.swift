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

internal func reserveDataSectionStorage(byteCount: Int, alignment: Int) -> RawPointer {
    usedDataSectionStorage.align(alignment)

    let ret: RawPointer = dataSectionStorage + usedDataSectionStorage

    usedDataSectionStorage += byteCount
    if usedDataSectionStorage > dataSectionStorageSize {
        fatalError("Data section storage overflow")
    }

    return ret
}

private var usedDataSectionStorage = 0

// MARK: Asm interop

private var dataSectionStorage: RawPointer = {
    guard let p = dlsym(dlopen(nil, 0), "SwiftInternals$dataSectionStorage") else {
        fatalError("SwiftInternals$dataSectionStorage missing")
    }
    return p
}()

private var dataSectionStorageSize: Int = {
    guard let p = dlsym(dlopen(nil, 0), "SwiftInternals$dataSectionStorageSize") else {
        fatalError("SwiftInternals$dataSectionStorageSize missing")
    }
    return p.assumingMemoryBound(to: Int.self).pointee
}()
