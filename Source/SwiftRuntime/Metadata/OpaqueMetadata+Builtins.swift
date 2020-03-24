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

// See Scripts/builtins or BuiltinTypes.def for the list. See Scripts/builtins-generate for the generator. Opaque metadata symbols (like $sBoN) point to a `FullMetadata`:
// A "full" metadata pointer is simply an adjusted address point on a metadata object; it points to the beginning of the metadata's allocation, rather than to the canonical address point of the metadata object.
public extension OpaqueMetadata {
    enum Builtin {
        static func kind(of metadata: OpaqueMetadata) -> Kind? {
            cachedOpaqueMetadata[metadata]
        }
    }
}
