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

// FIXME: LLVM license

import Foundation

struct SwiftAggLowering {
    private struct StorageEntry {
        var begin: Int
        var end: Int
        var type: LLVMType?
        var width: Int {
            end - begin
        }
    }

    private var entries = [StorageEntry]()
    private var finished = false

    var isEmpty: Bool {
        precondition(finished)
        return entries.isEmpty
    }

    func shouldPassIndirectly(asReturnValue: Bool) -> Bool {
        precondition(finished)

        guard !entries.isEmpty else {
            return false
        }

        if entries.count == 1 {
            return LLVMSwiftABIInfo.shouldPassIndirectlyForSwift([entries[0].type! /* never nil once finished */], asReturnValue: asReturnValue)
        }
        return LLVMSwiftABIInfo.shouldPassIndirectlyForSwift(entries.map { $0.type! /* never nil once finished */ }, asReturnValue: asReturnValue)
    }

    mutating func addOpaqueData(begin: Int, end: Int) {
        entries.append(StorageEntry(begin: begin, end: end, type: nil))
    }

    mutating func addTypedData(_ type: LLVMType, begin: Int) {
        addTypedData(type, begin: begin, end: begin + getTypeStoreSize(type))
    }

    mutating func addTypedData(_ type: LLVMType, begin: Int, end: Int) {
        precondition(getTypeStoreSize(type) == end - begin)

        // SwiftMocks: we don't have vectors, and we only have legal ints, so the original code that was here is not needed

        return addLegalTypedData(type, begin: begin, end: end);
    }

    func enumerateComponents(_ body: (Int, Int, LLVMType) -> Void) {
        precondition(finished)

        entries.forEach { entry in
            body(entry.begin, entry.end, entry.type! /* never nil if finished */)
        }
    }

    private mutating func addLegalTypedData(_ type: LLVMType, begin: Int, end: Int) {
        // Require the type to be naturally aligned.
        if begin != 0 && begin % type.alignment != 0 {
            // sd: no vectors, so skipping some code here
            return addOpaqueData(begin: begin, end: end)
        }

        addEntry(type, begin: begin, end: end);
    }

    private mutating func addEntry(_ type: LLVMType?, begin: Int, end: Int) {
        switch type {
        case .struct, .array:
            preconditionFailure("cannot add aggregate-typed data")
        default: break
        }
        precondition(type == nil || begin % type!.alignment == 0)

        // Fast path: we can just add entries to the end.
        if entries.isEmpty || entries.last!.end <= begin {
            entries.append(StorageEntry(begin: begin, end: end, type: type))
            return
        }

        // Find the first existing entry that ends after the start of the new data.
        let index = entries.reversed().firstIndex { $0.end <= begin }! + 1

        // The entry ends after the start of the new data. If the entry starts after the end of the new data, there's no conflict.
        if entries[index].begin >= end {
            // This insertion is potentially O(n), but the way we generally build these layouts makes that unlikely to matter: we'd need a union of several very large types.
            entries.insert(StorageEntry(begin: begin, end: end, type: type), at: index)
            return
        }

        // sd: The rest of the original code deals with conflicts/overlaps. We never have that.
        LoweringError.unreachable("overlaps should never happen")
    }

    mutating func finish() {
        if entries.isEmpty {
            finished = true
            return
        }

        // We logically split the layout down into a series of chunks of this size, which is generally the size of a pointer.
        let chunkSize = getMaximumVoluntaryIntegerSize()

        // First pass: if two entries should be merged, make them both opaque and stretch one to meet the next.
        // Also, remember if there are any opaque entries.
        var hasOpaqueEntries = entries[0].type == nil
        for i in 1..<entries.count {
            if shouldMergeEntries(entries[i - 1], entries[i], chunkSize: chunkSize) {
                entries[i - 1].type = nil
                entries[i].type = nil
                entries[i - 1].end = entries[i].begin
                hasOpaqueEntries = true
            } else if entries[i].type == nil {
                hasOpaqueEntries = true
            }
        }

        // The rest of the algorithm leaves non-opaque entries alone, so if we have no opaque entries, we're done.
        if !hasOpaqueEntries {
            finished = true
            return
        }

        // Okay, move the entries to a temporary and rebuild Entries.
        let orig = entries
        entries.removeAll()

        let e = orig.count
        var i = 0
        while i < e {
            // Just copy over non-opaque entries.
            if orig[i].type != nil {
                entries.append(orig[i])
                i += 1
                continue
            }

            // Scan forward to determine the full extent of the next opaque range.
            // We know from the first pass that only contiguous ranges will overlap the same aligned chunk.
            var begin = orig[i].begin
            var end = orig[i].end
            while (i + 1 != e && orig[i + 1].type == nil && end == orig[i + 1].begin) {
                end = orig[i + 1].end;
                i += 1
            }

            // Add an entry per intersected chunk.
            repeat {
                // Find the smallest aligned storage unit in the maximal aligned storage unit containing 'begin' that contains all the bytes in the intersection between the range and this chunk.
                let localBegin = begin
                let chunkBegin = getOffsetAtStartOfUnit(offset: localBegin, unitSize: chunkSize)
                let chunkEnd = chunkBegin + chunkSize
                let localEnd = min(end, chunkEnd)

                // Just do a simple loop over ever-increasing unit sizes.
                var unitSize = 1
                var unitBegin = 0
                var unitEnd = 0
                while true {
                    assert(unitSize <= chunkSize)
                    unitBegin = getOffsetAtStartOfUnit(offset: localBegin, unitSize: unitSize)
                    unitEnd = unitBegin + unitSize
                    if unitEnd >= localEnd {
                        break
                    }
                    unitSize *= 2
                }

                // Add an entry for this unit.
                let entryTy = LLVMType.getInteger(bitWidth: unitSize * 8)
                entries.append(StorageEntry(begin: unitBegin, end: unitEnd, type: entryTy))

                // The next chunk starts where this chunk left off.
                begin = localEnd
            } while (begin != end)

            i += 1
        }

        // Okay, finally finished.
        finished = true
    }

    private func shouldMergeEntries(_ first: StorageEntry, _ second: StorageEntry, chunkSize: Int) -> Bool {
        // Only merge entries that overlap the same chunk.  We test this first despite being a bit more expensive because this is the condition that tends to prevent merging.
        if !areBytesInSameUnit(first.end - 1, second.begin, chunkSize: chunkSize) {
            return false
        }

        return isMergeableEntryType(first.type) && isMergeableEntryType(second.type)
    }

    // MARK: -

    private func getMaximumVoluntaryIntegerSize() -> Int { 8 } // for x86_64

    private func areBytesInSameUnit(_ first: Int, _ second: Int, chunkSize: Int) -> Bool {
        getOffsetAtStartOfUnit(offset: first, unitSize: chunkSize) == getOffsetAtStartOfUnit(offset: second, unitSize: chunkSize)
    }

    /// Given a power-of-two unit size, return the offset of the aligned unit of that size which contains the given offset.
    /// In other words, round down to the nearest multiple of the unit size.
    private func getOffsetAtStartOfUnit(offset: Int, unitSize: Int) -> Int {
        precondition(unitSize.isPowerOf2)
        let unitMask = ~(unitSize - 1)
        return offset & unitMask
    }

    private func isMergeableEntryType(_ type: LLVMType?) -> Bool {
        // Opaquely-typed memory is always mergeable.
        guard let type = type else {
            return true
        }

        // Pointers and integers are always mergeable.  In theory we should not
        // merge pointers, but (1) it doesn't currently matter in practice because
        // the chunk size is never greater than the size of a pointer and (2)
        // Swift IRGen uses integer types for a lot of things that are "really"
        // just storing pointers (like Optional<SomePointer>).  If we ever have a
        // target that would otherwise combine pointers, we should put some effort
        // into fixing those cases in Swift IRGen and then call out pointer types
        // here.

        // Floating-point and vector types should never be merged.
        // Most such types are too large and highly-aligned to ever trigger merging
        // in practice, but it's important for the rule to cover at least 'half'
        // and 'float', as well as things like small vectors of 'i1' or 'i8'.
        return !type.isFloatingPoint && !type.isVector
    }

    private func getTypeStoreSize(_ type: LLVMType) -> Int {
        type.size
    }
}

