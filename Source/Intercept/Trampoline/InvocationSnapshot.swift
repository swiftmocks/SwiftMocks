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

// https://github.com/llvm-mirror/llvm/blob/master/lib/Target/X86/X86CallingConv.td#L492

/// A snapshot of an in-flight function invocation when intercepted by the trampoline function. In short, the contents of the registers and rbp used to obtain the stack arguments.
struct InvocationSnapshot {
    /// `rsp` once all registers have been saved onto the stack
    private let rsp: Pointer<UInt>

    /// Base address of stack arguments. I.e., the first argument on the stack will be at `stackBase + 0`, the second at `stackBase + 1` etc
    var stackBase: Pointer<UInt> {
        rsp + (numberOfSavedQuads + 1 /* saved rbp */ + 1 /* return ip */)
    }

    /// Base address of saved values of the general purpose registers used for argument passing. They are saved contiguously in the order they are used by the ABI — `rdi`, `rsi`, `rdx` etc, — so that the `Nth` register argument is located at `gprBase + N`
    var gprBase: Pointer<UInt> {
        rsp + 1 /* rax is before anything else */
    }

    /// Base address of saved values of floating-point registers. They are saved contiguously in the order they are used by the ABI — `xmm0`...`xmm7`, — so that the `Nth` register argument is located at `xmmBase + N`
    var xmmBase: Pointer<UInt> {
        (rsp + 10 /* GPRs */).reinterpret(UInt.self)
    }

    init(rsp: RawPointer) {
        self.rsp = rsp.reinterpret(UInt.self)
    }

    func resultGPR(index: Int) -> RawPointer {
        switch index {
        case 0:
            return rsp.raw // rax
        case 1:
            return (rsp + 3).raw // rdx
        case 2:
            return (rsp + 4).raw // rcx
        case 3:
            return (rsp + 5).raw // r8
        default:
            fatalError("there are only 4 registers for result")
        }
    }

    /// Creates an invocation snapshot that does not actually capture any actual invocation arguments. Used to calculate iterator distances.
    static func makeEmpty() -> InvocationSnapshot {
        .init(rsp: RawPointer(bitPattern: 0xdeadbeef)!)
    }
}

/// Accessors for individual registers
extension InvocationSnapshot {
    var rax: UInt {
        get {
            (rsp + 0).pointee
        }
        nonmutating set {
            (rsp + 0).pointee = newValue
        }
    }

    var r10: UInt {
        get {
            (rsp + 7).pointee
        }
        nonmutating set {
            (rsp + 7).pointee = newValue
        }
    }

    var r12: UInt {
        get {
            (rsp + 8).pointee
        }
        nonmutating set {
            (rsp + 8).pointee = newValue
        }
    }

    var r13: UInt {
        get {
            (rsp + 9).pointee
        }
        nonmutating set {
            (rsp + 9).pointee = newValue
        }
    }

    /// Pointer to `r13`
    var pr13: RawPointer {
        (rsp + 9).raw
    }

    var rdi: UInt { (rsp + 1).pointee }
    var rsi: UInt { (rsp + 2).pointee }
    var rdx: UInt { (rsp + 3).pointee }
    var rcx: UInt { (rsp + 4).pointee }
    var r8: UInt { (rsp + 5).pointee }
    var r9: UInt { (rsp + 6).pointee }

    var xmm0: Double { Double(bitPattern: UInt64((xmmBase + 0).pointee)) }
    var xmm1: Double { Double(bitPattern: UInt64((xmmBase + 1).pointee)) }
    var xmm2: Double { Double(bitPattern: UInt64((xmmBase + 2).pointee)) }
    var xmm3: Double { Double(bitPattern: UInt64((xmmBase + 3).pointee)) }
    var xmm4: Double { Double(bitPattern: UInt64((xmmBase + 4).pointee)) }
    var xmm5: Double { Double(bitPattern: UInt64((xmmBase + 5).pointee)) }
    var xmm6: Double { Double(bitPattern: UInt64((xmmBase + 6).pointee)) }
    var xmm7: Double { Double(bitPattern: UInt64((xmmBase + 7).pointee)) }

    var xmm0AsFloat: Float { Float(bitPattern: UInt32(truncatingIfNeeded: (xmmBase + 0).pointee)) }
    var xmm1AsFloat: Float { Float(bitPattern: UInt32(truncatingIfNeeded: (xmmBase + 1).pointee)) }
    var xmm2AsFloat: Float { Float(bitPattern: UInt32(truncatingIfNeeded: (xmmBase + 2).pointee)) }
    var xmm3AsFloat: Float { Float(bitPattern: UInt32(truncatingIfNeeded: (xmmBase + 3).pointee)) }
    var xmm4AsFloat: Float { Float(bitPattern: UInt32(truncatingIfNeeded: (xmmBase + 4).pointee)) }
    var xmm5AsFloat: Float { Float(bitPattern: UInt32(truncatingIfNeeded: (xmmBase + 5).pointee)) }
    var xmm6AsFloat: Float { Float(bitPattern: UInt32(truncatingIfNeeded: (xmmBase + 6).pointee)) }
    var xmm7AsFloat: Float { Float(bitPattern: UInt32(truncatingIfNeeded: (xmmBase + 7).pointee)) }
}

extension InvocationSnapshot {
    /// `body` should return true to continue walking
    func walkCallStack(_ body: (RawPointer, RawPointer) -> Bool) {
        let frameRBP = (rsp + numberOfSavedQuads)/*(rsp - 2)*/.reinterpret(RawPointer.self)
        var rip = (frameRBP + 1).reinterpret(RawPointer.self).pointee
        var rbp = frameRBP.pointee.reinterpret(RawPointer.self)
        while body(rip, rbp) && (rbp.pointee as RawPointer?) != nil {
            rip = (rbp + 1).pointee
            rbp = rbp.pointee.reinterpret(RawPointer.self)
        }
    }
}

extension InvocationSnapshot: CustomDebugStringConvertible {
    var debugDescription: String {
        "InvocationSnapshot"
            .appending("rsp", rsp)
            .appending("rdi", rdi.hex)
            .appending("rsi", rsi.hex)
            .appending("rdx", rdx.hex)
            .appending("rcx", rcx.hex)
            .appending("r8 ", r8.hex)
            .appending("r9 ", r9.hex)
            .appending("rax", rax.hex)
            .appending("r10", r10.hex)
            .appending("r12", r12.hex)
            .appending("r13", r13.hex)
            .appending("xmm0", "\(xmm0) (\(xmm0AsFloat))")
            .appending("xmm1", "\(xmm1) (\(xmm1AsFloat))")
            .appending("xmm2", "\(xmm2) (\(xmm2AsFloat))")
            .appending("xmm3", "\(xmm3) (\(xmm3AsFloat))")
            .appending("xmm4", "\(xmm4) (\(xmm4AsFloat))")
            .appending("xmm5", "\(xmm5) (\(xmm5AsFloat))")
            .appending("xmm6", "\(xmm6) (\(xmm6AsFloat))")
            .appending("xmm7", "\(xmm7) (\(xmm7AsFloat))")
    }
}

private extension UInt {
    var hex: String { String(format: "0x%016llx", self) }
}

private extension Int {
    var hex: String { String(format: "0x%016llx", self) }
}

private let numberOfSavedQuads: Int = 10 /* GPRs */ + 8 /* xmms */
