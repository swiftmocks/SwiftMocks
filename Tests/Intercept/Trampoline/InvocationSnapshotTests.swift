//
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

import XCTest
import Nimble
@testable import IR
@testable import SwiftMocks

class InvocationSnapshotTests: XCTestCase {
    func testRegisters() {
        var wasCalled = false
        preview(___35(reg8: 1, reg16: 2, reg32: 3, reg64: 4, reg: 5, reg: 6, stackInt32: 7, xmm: 1.5, xmm: 2.5, xmm: 3.5, xmm: 4.5, xmm: 5.5, xmm: 6.5, xmm: 7.5, xmm: 8.5, stackFloat: 9.5)) { snapshot in
            wasCalled = true

            expect(snapshot.rdi & 0xFF) == 1
            expect(snapshot.rsi & 0xFFFF) == 2
            expect(snapshot.rdx & 0xFFFFFFFF) == 3
            expect(snapshot.rcx) == 4
            expect(snapshot.r8) == 5
            expect(snapshot.r9) == 6

            expect(snapshot.xmm0) == 1.5
            expect(snapshot.xmm1AsFloat) == 2.5
            expect(snapshot.xmm2) == 3.5
            expect(snapshot.xmm3AsFloat) == 4.5
            expect(snapshot.xmm4) == 5.5
            expect(snapshot.xmm5AsFloat) == 6.5
            expect(snapshot.xmm6) == 7.5
            expect(snapshot.xmm7AsFloat) == 8.5

            expect((snapshot.stackBase + 0).pointee & 0xFFFFFFFF) == 7
            expect(Float(bitPattern: UInt32((snapshot.stackBase + 1).pointee & 0xFFFFFFFF))) == 9.5
        }
        expect(wasCalled) == true
    }

    func testWalkCallStack() {
        var stack = [RawPointer]()
        _ = walkStack(___3(0)) { rip, _ -> Bool in
            stack.append(rip)
            return true
        }
        expect(stack).toNot(beEmpty())
        let stackTrace: [String] = stack.map { simpleDladdr($0) ?? "\($0)" }.map { Runtime.demangle($0) ?? $0 }
        expect(stackTrace.first { $0.contains("testWalkCallStack() -> ()") }).toNot(beNil())
        // print(stackTrace.map { "- \($0)" }.joined(separator: "\n"))
    }
}

private func walkStack<T>(_ fn: @autoclosure () -> T, _ stackWalker: ((RawPointer, RawPointer) -> Bool)) {
    _ = theCore.interceptor.intercept(execute: fn, onIntercept: { (_, handler) -> Interceptor.Result in
        handler.snapshot.walkCallStack(stackWalker)
        return .proceed
    })
}

private func preview<T>(_ fn: @autoclosure () -> T, _ execute: (InvocationSnapshot) -> Void) {
    _ = theCore.interceptor.intercept(execute: fn, onIntercept: { (_, handler) -> Interceptor.Result in
        execute(handler.snapshot)
        return .proceed
    })
}
