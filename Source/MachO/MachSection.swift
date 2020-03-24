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
import MachO

#if (arch(i386) || arch(arm))
public typealias MachSection = section
#else
public typealias MachSection = section_64
#endif

public extension MachSection {
    var id: String { String("\(String(machOName: segname)):\(String(machOName: sectname))") }
    var name: String { String(machOName: sectname) }
    var segmentName: String { String(machOName: segname) }
    var address: RawPointer { RawPointer(bitPattern: UInt(addr))! }

    static let dataSection = "__DATA:__data"
    static let textSection = "__TEXT:__text"
    static let textConstSection = "__TEXT:__const"
}

extension MachSection: CustomDebugStringConvertible {
    public var debugDescription: String {
        "MachSection (\(segmentName):\(name))"
            .appending("addr", addr)
            .appending("size", size)
            .appending("offset", offset)
            .appending("reloff", reloff)
            .appending("nreloc", nreloc)
    }
}
