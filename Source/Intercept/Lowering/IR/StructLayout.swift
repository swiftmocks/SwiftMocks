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

/// An algorithm for laying out a structure.
enum LayoutStrategy {
  /// Compute an optimal layout;  there are no constraints at all.
  case optimal

  /// The 'universal' strategy: all modules must agree on the layout.
  case universal
}

/// The kind of object being laid out.
enum LayoutKind {
  /// A non-heap object does not require a heap header.
  case nonHeapObject

  /// A heap object is destined to be allocated on the heap and must be emitted with the standard heap header.
  case heapObject
}

/// An element layout is the layout for a single element of some sort of aggregate structure.
struct ElementLayout {
    enum Kind {
        /// The element is known to require no storage in the aggregate. Its offset in the aggregate is always statically zero.
        case empty

        /// The element can be positioned at a fixed offset within the aggregate.
        case fixed

        /// The element cannot be positioned at a fixed offset within the aggregate.
        case nonFixed

        /// The element is an object lacking a fixed size but located at offset zero.  This is necessary because LLVM forbids even a 'gep 0' on an unsized type.
        case initialNonFixedSize
    }

    /// The swift type information for this element's layout.
    private(set) var type: TypeInfo

    /// The offset in bytes from the start of the struct.
    private(set) var byteOffset: UInt?

    /// The index of this element, either in the LLVM struct (if fixed) or in the non-fixed elements array (if non-fixed).
    private(set) var index: UInt

    /// Whether this element is known to be POD in the local resilience domain.
    private(set) var isPOD: Bool

    /// The kind of layout performed for this element.
    private(set) var theKind: Kind?

    private init(_ type: TypeInfo) {
        self.type = type
        self.byteOffset = nil
        self.index = 0
        self.isPOD = false
        self.theKind = nil
    }

    var isCompleted: Bool {
        theKind != nil
    }

    static func getIncomplete(_ type: TypeInfo) -> ElementLayout {
        ElementLayout(type)
    }

    mutating func completeFrom(other: ElementLayout) {
        precondition(!isCompleted)
        theKind = other.theKind
        isPOD = other.isPOD
        byteOffset = other.byteOffset
        index = other.index
    }

    mutating func completeEmpty(isPOD: Bool) {
        theKind = .empty
        self.isPOD = isPOD
        byteOffset = 0
        index = 0
    }

    mutating func completeInitialNonFixedSize(isPOD: Bool) {
        theKind = .initialNonFixedSize
        self.isPOD = isPOD
        byteOffset = 0
        index = 0
    }

    mutating func completeFixed(isPOD: Bool, byteOffset: Int, index: UInt) {
        theKind = .fixed
        self.isPOD = isPOD
        self.byteOffset = UInt(byteOffset)
        self.index = index
  }

  /// Complete this element layout with a non-fixed offset.
  /// - parameter nonFixedElementIndex: the index into the elements array
    mutating func completeNonFixed(isPOD: Bool, nonFixedElementIndex: UInt) {
        theKind = .nonFixed
        self.isPOD = isPOD
        self.index = nonFixedElementIndex
    }

    var isEmpty: Bool {
        theKind == .empty
    }

    var hasByteOffset: Bool {
        switch theKind {
        case .empty, .fixed:
            return true
        case .initialNonFixedSize, .nonFixed:
            return false
        case .none:
            return false
        }
    }
}

struct StructLayout {
    /// The statically-known minimum bound on the alignment.
    let minimumAlign: Int

  /// The statically-known minimum bound on the size.
    let minimumSize: Int

    // TODO: remove these once TypeInfo doesn't have all the unused bits
  /// Whether this layout is fixed in size.  If so, the size and alignment are exact.
    let isFixedLayout: Bool = true

    let isPOD: Bool = false
    let isBitwiseTakable: Bool = true // all loadable types are bitwise takable I think?
    let isAlwaysFixedSize: Bool = true

    let ty: LLVMType
    let elements: [ElementLayout]

    init(igm: IRGenModule, fields: [TypeInfo]) {
        var offset = 0
        var align: UInt8 = 1
        elements = fields.enumerated().map { indexAndType -> ElementLayout in
            let index = indexAndType.offset
            guard let type = indexAndType.element as? LoadableTypeInfo else {
                LoweringError.unreachable("only works for loadable types")
            }
            offset = offset.aligned(type.alignment)
            var ret = ElementLayout.getIncomplete(type)
            ret.completeFixed(isPOD: true, byteOffset: offset, index: UInt(index))
            offset += type.size
            align = max(align, UInt8(type.alignment))
            return ret
        }
        minimumSize = offset
        minimumAlign = Int(align)
        let fieldTypes = elements.map { $0.type.storageType }
        ty = .struct(fieldTypes)
    }

    init(fields: [TypeInfo], fieldOffsets: [Int], alignment: Int, size: Int) {
        precondition(fields.count == fieldOffsets.count)
        elements = zip(fieldOffsets, fields).enumerated().map { elt -> ElementLayout in
            let (index, (offset, type)) = elt
            var ret = ElementLayout.getIncomplete(type)
            ret.completeFixed(isPOD: true, byteOffset: offset, index: UInt(index))
            return ret
        }
        minimumAlign = alignment
        minimumSize = size
        ty = .struct(fields.map { $0.storageType })
    }
}
