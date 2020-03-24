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

// Convenience wrappers around VWT

import Foundation

public extension Metadata {
    func copy(from storage: RawPointer) -> Any {
        var result: Any = 0xbeef // just create _any_ Any with an inline POD type
        let box = AnyExistentialBox(&result)
        box.container.type = self
        let p: RawPointer
        // Metadata::allocateBoxForExistentialIn
        if valueWitnesses.isValueInline {
            p = box.container.buffer.pointer
        } else {
            let boxPair = Runtime.allocBox(metadata: self)
            p = boxPair.buffer
            box.container.buffer.asRawPointers[0] = boxPair.object
        }
        _ = valueWitnesses.initializeWithCopy(dest: p, src: storage)
        return result
    }

    /// Initialises uninitialised memory pointed to by `storage` with a copy of the `value`, casting it to the type described by the receiver.
    func initialize(_ storage: RawPointer, withCopyOf value: Any) {
        var value = value
        let box = AnyExistentialBox(&value)
        guard Runtime.dynamicCast(dest: storage, src: box.projected, srcType: box.container.type, targetType: self) else {
            fatalError("Failed to cast \(box.container.type.silDescription) to \(self.silDescription)")
        }
    }
}
