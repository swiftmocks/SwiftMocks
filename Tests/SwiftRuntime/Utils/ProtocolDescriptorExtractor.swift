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
import SwiftMocks

enum ProtocolDescriptorExtractor {
    /// Extracts protocol descriptor from a generic class. I.e. `type: Foo<T: Hashable` -> `Hashable`
    static func extract(type: Any.Type) -> ProtocolDescriptor {
        let req = Metadata.of(type).typeContextDescriptor!.genericRequirements![0]
        guard case let .protocol(maybeSwiftProto) = req.kind, let proto = maybeSwiftProto else {
            fatalError()
        }
        return proto
    }
}
