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

public struct ReplacementVar {
    public let key: (name: String, address: RawPointer)
    public let variable: RawPointer
    public let original: RawPointer

    public init(key: (name: String, address: RawPointer), variable: RawPointer, original: RawPointer) {
        self.key = key
        self.variable = variable
        self.original = original
    }

    /// Just a `Runtime.getOrigOfReplaceable(origFnPtr:)` with a better name. See comment for `Runtime.getOrigOfReplaceable(origFnPtr:)` for more details.
    public func prepareToInvokeOriginal() {
        var mutableOriginal = original
        _ = Runtime.getOrigOfReplaceable(origFnPtr: &mutableOriginal)
    }
}

public extension MachImage {
    /// Return the list of Swift replacement variables removing the "_" prefix from the name. At the moment, the only check we do is that the name ends with "Tx"; it is enough for now, but as new manglings are introduced, we may need to actually demangle the name to confirm that it's a replacement var
    var replacementVars: [ReplacementVar] {
        definedSymbols(in: MachSection.textConstSection)
            .filter { $0.isExternal && !$0.isPrivateExternal && $0.name.hasSuffix("Tx") }
            .map {
                let name = $0.name.hasPrefix("_") ? String($0.name.dropFirst()) : $0.name
                let pointer = $0.pointer
                let variable = RawPointer(relative: pointer.reinterpret(TargetRelativeDirectPointer.self))!
                let original = variable.reinterpret(RawPointer.self).pointee
                return ReplacementVar(key: (name, $0.pointer), variable: variable, original: original)
        }
    }

    var types: [ContextDescriptor] {
        guard let data = sectionData(name: "__swift5_types", segmentName: "__TEXT") else {
            return []
        }

        let start = data.start.assumingMemoryBound(to: TypeMetadataRecord.Pointee.self)
        return (start..<start+data.size/MemoryLayout<TypeMetadataRecord.Pointee>.size).map {
            TypeMetadataRecord(pointer: $0).contextDescriptor
        }
    }

    var protocols: [ProtocolDescriptor] {
        guard let data = sectionData(name: "__swift5_protos", segmentName: "__TEXT") else {
            return []
        }

        let start = data.start.assumingMemoryBound(to: ProtocolRecord.self)
        return (start..<start+data.size/MemoryLayout<ProtocolRecord>.size).map {
            var reserved: UInt8 = 0
            let resolved = RawPointer(relative: &$0.pointee, int: &reserved)! // can't be nil
            let ret = ProtocolDescriptor(resolved)
            return ret
        }
    }

    var protocolConformances: [ProtocolConformanceDescriptor] {
        guard let data = sectionData(name: "__swift5_proto", segmentName: "__TEXT") else {
            return []
        }

        let start = data.start.assumingMemoryBound(to: ProtocolConformanceRecord.self)
        return (start..<start+data.size/MemoryLayout<ProtocolConformanceRecord>.size).map {
            ProtocolConformanceDescriptor($0.raw.advanced(by: $0.pointee.Offset))
        }
    }
}
