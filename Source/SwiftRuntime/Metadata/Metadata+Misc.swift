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

/// The header before a metadata object which appears on all type metadata.
///
/// Note that heap metadata are not necessarily type metadata, even for objects of a heap type: for example, objects of Objective-C type possess a form of heap metadata (an Objective-C Class pointer), but this metadata lacks the type metadata header. This case can be distinguished using the isTypeMetadata() flag on ClassMetadata.
public struct TypeMetadataHeader: PointeeFacade {
    public let pointer: RawPointer

    public struct Pointee {
        var valueWitnesses: TargetPointer /* <Runtime, const ValueWitnessTable> */
    }
}

