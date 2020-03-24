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

extension Int {
    /// Return the floor log base 2 of the specified value, -1 if the value is zero. For example: 32.log2 == 5, 1.log2 == 0, 0.log2 == -1, 6.log2 == 2
    @_transparent
    var log2: Int {
        Int(Foundation.log2(Double(self)))
    }

    /// Return `true` if the argument is a power of two > 0. For example, 0b00100000.isPowerOf2 == true
    @_transparent
    var isPowerOf2: Bool {
        return self != 0 && (self & (self - 1)) == 0
    }

    /// Returns the next power of two that is strictly greater than A. Returns zero on overflow.
    @_transparent
    var nextPowerOf2: Int {
        var value = self
        value |= (value >> 1)
        value |= (value >> 2)
        value |= (value >> 4)
        value |= (value >> 8)
        value |= (value >> 16)
        value |= (value >> 32)
        return value + 1
    }

    // Returns the receiver if it is a power of 2, or else the next power of 2.
    @_transparent
    var aligningToPowerOf2: Int {
        if isPowerOf2 {
            return self
        }
        return nextPowerOf2
    }
}
