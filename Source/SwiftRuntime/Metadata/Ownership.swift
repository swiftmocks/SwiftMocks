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

public enum ReferenceOwnership {
    case strong
    case weak
    case unowned
    case unmanaged
}

/// Different kinds of value ownership supported by Swift.
public enum ValueOwnership : UInt8 {
    /// the context-dependent default ownership (sometimes shared, sometimes owned)
    case `default`
    /// an 'inout' mutating pointer-like value
    case inOut
    /// a '__shared' non-mutating pointer-like value
    case shared
    /// an '__owned' value
    case owned

    public static let lastKind = ValueOwnership.owned
}
