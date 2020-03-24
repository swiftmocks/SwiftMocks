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

extension FieldRecord: CustomDebugStringConvertible {
    public var debugDescription: String {
        "FieldRecord"
            .appending("isIndirectEnumCase", isIndirectEnumCase)
            .appending("isVar", isVar)
            .appending("fieldName", name)
            .appending("type", try? Mangle.demangleType(mangledName: mangledTypeName!).description, onlyIf: mangledTypeName != nil)
    }
}

extension FieldDescriptor: CustomDebugStringConvertible {
    public var debugDescription: String {
        "FieldDescriptor"
            .appending("type", try? Mangle.demangleType(mangledName: mangledTypeName!).description, onlyIf: mangledTypeName != nil)
            .appending("superclass", try? Mangle.demangleType(mangledName: superclassMangledTypeName!).description, onlyIf: superclassMangledTypeName != nil)
            .appending("kind", kind)
            .appending("fieldRecordSize", fieldRecordSize)
            .appending("numberOfFields", numberOfFields)
    }
}
