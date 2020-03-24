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
public typealias MachSegmentCommand = segment_command
public typealias MachNlist = nlist
public typealias MachHeader = mach_header
private let LoadCommandSegment = LC_SEGMENT
#else
public typealias MachSegmentCommand = segment_command_64
public typealias MachNlist = nlist_64
public typealias MachHeader = mach_header_64
private let LoadCommandSegment = LC_SEGMENT_64
#endif

public struct MachSymbol {
    public let name: String
    public let pointer: RawPointer
    public let rawType: UInt8

    public var isExternal: Bool { rawType & UInt8(N_EXT) != 0 }
    public var isPrivateExternal: Bool { rawType & UInt8(N_PEXT) != 0 }
}

public extension MachSegmentCommand {
    var segmentName: String { String(machOName: segname) }
}

public class MachImage: Equatable {
    public let address: RawPointer
    public let vmaddrSlide: RawPointer.Distance
    public let filename: String

    internal let loadCommands: [Pointer<load_command>]
    internal let segments: [MachSegmentCommand]
    internal let sections: [MachSection]
    internal let stringTable: Pointer<CChar>?
    internal let symbolTable: UnsafeBufferPointer<MachNlist>?

    internal init(address: RawPointer, vmaddrSlide: RawPointer.Distance, filename: String) {
        self.address = address
        self.vmaddrSlide = vmaddrSlide
        self.filename = filename

        var loadCommands = [Pointer<load_command>]()
        var p = address + MemoryLayout<MachHeader>.size
        let header = address.assumingMemoryBound(to: MachHeader.self).pointee
        for _ in 0..<header.ncmds {
            let pcmd: Pointer<load_command> = p.assumingMemoryBound(to: load_command.self)
            loadCommands.append(pcmd)
            p += Int(pcmd.pointee.cmdsize)
        }
        self.loadCommands = loadCommands
        self.segments = loadCommands
            .filter { $0.pointee.cmd == LoadCommandSegment }
            .map { $0.reinterpret(MachSegmentCommand.self).pointee }
        self.sections = loadCommands
            .filter { $0.pointee.cmd == LoadCommandSegment }
            .flatMap { (pcmd: Pointer<load_command>) -> [MachSection] in
                let count = pcmd.reinterpret(MachSegmentCommand.self).pointee.nsects
                let first = RawPointer(pcmd).advanced(by: MemoryLayout<MachSegmentCommand>.size).assumingMemoryBound(to: MachSection.self)
                return Array(UnsafeBufferPointer<MachSection>(start: first, count: Int(count)))
            }

        if let linkedit = segments.first(where: { $0.segmentName == "__LINKEDIT"}), let symtab = loadCommands.first(where: { $0.pointee.cmd == LC_SYMTAB })?.withMemoryRebound(to: symtab_command.self, capacity: 1, { $0.pointee }) {
            self.stringTable = RawPointer(bitPattern: vmaddrSlide + Int(linkedit.vmaddr) - Int(linkedit.fileoff) + Int(symtab.stroff))!.assumingMemoryBound(to: CChar.self)
            self.symbolTable = UnsafeBufferPointer(start: RawPointer(bitPattern: vmaddrSlide + Int(linkedit.vmaddr) - Int(linkedit.fileoff) + Int(symtab.symoff))!.assumingMemoryBound(to: MachNlist.self), count: Int(symtab.nsyms))
        } else {
            self.stringTable = nil
            self.symbolTable = nil
        }
    }

    public func definedSymbols(in sectionId: String) -> [MachSymbol] {
        guard let stringTable = stringTable, let symbolTable = symbolTable, let sectionIndex = sections.firstIndex(where: { $0.id == sectionId }) else {
            return []
        }

        let result = symbolTable
            .filter { $0.n_sect == sectionIndex + 1 && $0.n_type & UInt8(N_STAB) == 0 && $0.n_type & UInt8(N_TYPE) == UInt8(N_SECT) }
            .compactMap { nlist -> MachSymbol? in
                let name = String(cString: stringTable.advanced(by: Int(nlist.n_un.n_strx)))
                guard !name.isEmpty else { return nil }
                return MachSymbol(name: name, pointer: RawPointer(bitPattern: UInt(nlist.n_value) + UInt(bitPattern: vmaddrSlide))!, rawType: nlist.n_type)
        }
        return result
    }

    public func definedSymbols(in sectionIds: String...) -> [MachSymbol] {
        guard let stringTable = stringTable, let symbolTable = symbolTable else {
            return []
        }

        var result = [MachSymbol]()

        for sectionId in sectionIds {
            guard let sectionIndex = sections.firstIndex(where: { $0.id == sectionId }) else {
                return []
            }

            result += symbolTable
                .filter { $0.n_sect == sectionIndex + 1 && $0.n_type & UInt8(N_STAB) == 0 && $0.n_type & UInt8(N_TYPE) == UInt8(N_SECT) }
                .compactMap { nlist -> MachSymbol? in
                    let name = String(cString: stringTable.advanced(by: Int(nlist.n_un.n_strx)))
                    guard !name.isEmpty else { return nil }
                    return MachSymbol(name: name, pointer: RawPointer(bitPattern: UInt(nlist.n_value) + UInt(bitPattern: vmaddrSlide))!, rawType: nlist.n_type)
            }
        }
        return result
    }

    public func sectionData(name: String, segmentName: String) -> (start: RawPointer, size: Int)? {
        var size: UInt = 0
        guard let p = getsectiondata(address.assumingMemoryBound(to: MachHeader.self), segmentName, name, &size) else {
            return nil
        }
        return (p.raw, Int(size))
    }

    public static var all: [MachImage] {
        all(excluding: [])
    }

    public static func all(excluding prefixes: [String]) -> [MachImage] {
        let ret = (0..<_dyld_image_count()).compactMap { index -> MachImage? in
            let address = RawPointer(mutating: _dyld_get_image_header(index))!
            var dlinfo = dl_info()
            let filename: String
            if dladdr(address, &dlinfo) != 0 && dlinfo.dli_fname != nil, let name = String(utf8String: dlinfo.dli_fname) {
                filename = name
            } else {
                filename = unknownFilename
            }
            if prefixes.contains(where: { filename.hasPrefix($0) }) {
                return nil
            }
            let vmaddrSlide = _dyld_get_image_vmaddr_slide(index)
            return MachImage(address: address, vmaddrSlide: vmaddrSlide, filename: filename)
        }
        return ret
    }

    public static var allExcludingKnownSystemPaths: [MachImage] {
        all(excluding: knownSystemPathPrefixes)
    }

    public static var knownSystemPathPrefixes: [String] = ["/usr/lib/", "/System/Library/", "/System/iOSSupport/", "/Applications/Xcode.app/"]

    public static func == (lhs: MachImage, rhs: MachImage) -> Bool { lhs.address == rhs.address && lhs.vmaddrSlide == rhs.vmaddrSlide }
}

internal extension MachImage {
    var definedExternalSymbols: [String] {
        guard let stringTable = stringTable, let symbolTable = symbolTable else {
            return []
        }

        return symbolTable
            .filter { $0.n_type == 0xf }
            .compactMap { String(cString: stringTable.advanced(by: Int($0.n_un.n_strx))) }
    }

    var allSymbols: [String] {
        guard let stringTable = stringTable, let symbolTable = symbolTable else {
            return []
        }

        return symbolTable
            .compactMap { String(cString: stringTable.advanced(by: Int($0.n_un.n_strx))) }
    }
}

public extension MachImage {
    func dumpAllSymbols() {
        guard let stringTable = stringTable, let symbolTable = symbolTable else {
            return
        }

        symbolTable.forEach { nlist in
            let name = String(cString: stringTable + Int(nlist.n_un.n_strx))
            print(String(format: "\(name): 0x%x", Int(nlist.n_type)))
        }
    }
}

extension String {
    init(machOName name: (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8)) {
        var safeName = (name.0, name.1, name.2, name.3, name.4, name.5, name.6, name.7, name.8, name.9, name.10, name.11, name.12, name.13, name.14, name.15, Int8(clamping: 0))
        self.init(cString: &safeName.0)
    }
}

private let unknownFilename = "<unknown>"
