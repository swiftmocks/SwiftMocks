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

extension InvocationSnapshot {
    /// Iterator over the invocation snapshot if viewed as a sequence of LLVM-typed arguments. Since different types of arguments go into different types of registers, any single argument's exact location depends on the prior arguments; therefore snapshot iterators are not random-access iterators.
    typealias Iterator = LLVMIterator

    /// An index of an argument in the invocation snapshot. Since different types of arguments go into different types of registers, any single argument's exact location depends on the prior arguments; `Index` encodes that information.
    typealias Index = Iterator.Distance

    /// Iterator pointing to the beginning of the snapshot.
    func begin() -> Iterator {
        Iterator(invocationSnapshot: self)
    }

    /// Return an iterator pointing to `index`th LLVM argument in the snapshot.
    subscript(_ index: Index) -> Iterator {
        begin() + index
    }

    /// Iterator over the invocation snapshot if viewed as a sequence of LLVM-typed arguments. Since different types of arguments go into different types of registers, any single argument's exact location depends on the prior arguments; therefore snapshot iterators are not random-access iterators.
    struct LLVMIterator {
        /// Distance between two `LLVMIterator`s.
        struct Distance {
            fileprivate let gprs: Int8
            fileprivate let xmms: Int8
            fileprivate let stack: Int16
        }

        enum What {
            case gpr
            case xmm
        }

        private let invocationSnapshot: InvocationSnapshot
        private let gprCount: UInt8
        private let xmmCount: UInt8

        private var gprs: Pointer<UInt>
        private var xmms: Pointer<UInt>
        // using typed pointer because stack arguments are 8-bytes aligned. if this ever becomes not the case, switch to RawPointer
        private var stackArgs: Pointer<UInt>

        private var remainingRegsCount: UInt8
        private var remainingXmmsCount: UInt8

        /// The number of general purpose registers used before the location of this iterator.
        var usedGPRs: UInt8 {
            precondition(gprs >= invocationSnapshot.gprBase)
            return UInt8(gprs - invocationSnapshot.gprBase)
        }

        /// The number of xmm registers used before the location of this iterator.
        var usedXMMs: UInt8 {
            precondition(xmms >= invocationSnapshot.xmmBase)
            return UInt8(xmms - invocationSnapshot.xmmBase)
        }

        /// The number of words (8 bytes on 64-bit) used on the stack before the location of this iterator.
        var usedStack: UInt16 {
            precondition(stackArgs >= invocationSnapshot.stackBase)
            return UInt16(stackArgs - invocationSnapshot.stackBase)
        }

        init(invocationSnapshot: InvocationSnapshot, gprCount: UInt8 = 6, xmmCount: UInt8 = 8) {
            self.invocationSnapshot = invocationSnapshot
            self.gprCount = gprCount
            self.xmmCount = xmmCount
            stackArgs = invocationSnapshot.stackBase
            gprs = invocationSnapshot.gprBase
            xmms = invocationSnapshot.xmmBase
            remainingRegsCount = gprCount
            remainingXmmsCount = xmmCount
        }

        fileprivate init(invocationSnapshot: InvocationSnapshot, gprCount: UInt8, xmmCount: UInt8, usedGPRs: UInt8, usedXMMs: UInt8, usedStack: UInt16) {
            self.invocationSnapshot = invocationSnapshot
            self.gprCount = gprCount
            self.xmmCount = xmmCount
            self.stackArgs = invocationSnapshot.stackBase.advanced(by: usedStack)
            self.gprs = invocationSnapshot.gprBase.advanced(by: usedGPRs)
            self.xmms = invocationSnapshot.xmmBase.advanced(by: usedXMMs)
            remainingRegsCount = gprCount - usedGPRs
            remainingXmmsCount = xmmCount - usedXMMs
        }

        /// Return a pointer to the argument of type `type` pointed to by the receiver, and advance the receiver past that argument.
        mutating func consume(_ type: LLVMType) -> RawPointer {
            switch type {
            case .void:
                return /* doesn't matter at all */ remainingRegsCount == 0 ? stackArgs.raw : gprs.raw
            case .float, .double:
                    return consume(.xmm)
            case .x86_fp80:
                LoweringError.notImplemented("x86_fp80")
            default:
                return consume(.gpr, byteSize: type.size)
            }
        }

        /// Advance the iterator past the argument of type `type` pointed to by the receiver.
        mutating func skip(_ type: LLVMType) {
            _ = consume(type)
        }

        /// Return a pointer to the argument of either a word type or floating point type pointed to by the receiver, and advance the receiver past that argument.
        mutating func consume(_ what: What, byteSize: Int = 8) -> RawPointer {
            precondition(byteSize <= 8)
            switch what {
            case .gpr:
                return remainingRegsCount == 0 ? consumeStack(byteSize: byteSize) : consumeGPR()
            case .xmm:
                return remainingXmmsCount == 0 ? consumeStack(byteSize: byteSize) : consumeXMM()
            }
        }

        private mutating func consumeGPR() -> RawPointer {
            defer {
                remainingRegsCount -= 1
                gprs += 1
            }
            return gprs.raw
        }

        private mutating func consumeXMM() -> RawPointer {
            defer {
                remainingXmmsCount -= 1
                xmms += 1
            }
            return xmms.raw
        }

        private mutating func consumeStack(byteSize: Int) -> RawPointer {
            defer {
                stackArgs += 1
            }
            return stackArgs.raw
        }

        /// Return the distance between two iterators
        static func -(lhs: Iterator, rhs: Iterator) -> Distance {
            precondition(lhs.gprs >= rhs.gprs && rhs.xmms >= rhs.xmms && lhs.stackArgs >= rhs.stackArgs)
            return Distance(gprs: Int8(rhs.remainingRegsCount - lhs.remainingRegsCount), // it's the other way around because we are subtracting remaining values, rather than used
                            xmms: Int8(rhs.remainingXmmsCount - lhs.remainingXmmsCount),
                            stack: Int16(lhs.usedStack - rhs.usedStack))
        }

        /// Return `lhs` advanced by `rhs`
        static func +(lhs: LLVMIterator, rhs: Distance) -> Iterator {
            precondition(rhs.gprs >= 0 && rhs.xmms >= 0 && rhs.stack >= 0)
            return Iterator(invocationSnapshot: lhs.invocationSnapshot,
                            gprCount: lhs.gprCount,
                            xmmCount: lhs.xmmCount,
                            usedGPRs: UInt8(Int8(lhs.usedGPRs) + rhs.gprs),
                            usedXMMs: UInt8(Int8(lhs.usedXMMs) + rhs.xmms),
                            usedStack: UInt16(Int16(lhs.usedStack) + rhs.stack))
        }
    }
}

extension InvocationSnapshot {
    /// Inject invocation results into result registers
    func injectResults(_ types: [LLVMType], storage: RawPointer) {
        var offset = 0
        var gprsUsed = 0
        var xmmsUsed = 0
        for type in types {
            offset = offset.aligned(type.alignment)
            switch type {
            case .void:
                continue
            case .float, .double:
                (xmmBase + xmmsUsed).raw.copyMemory(from: storage + offset, byteCount: type.size)
                xmmsUsed += 1
            case .x86_fp80:
                LoweringError.notImplemented("x86_fp80")
            default:
                resultGPR(index: gprsUsed).copyMemory(from: storage + offset, byteCount: type.size)
                gprsUsed += 1
            }

            offset += type.size

            assert(gprsUsed + xmmsUsed <= 4, "an aggregate larger than 4 registers. should've been indirect?")
        }
    }
}
