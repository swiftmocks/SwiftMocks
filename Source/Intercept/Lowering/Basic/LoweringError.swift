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

internal enum LoweringError: LocalizedError {
    case notImplemented(String, StaticString, UInt)
    case unreachable(String, StaticString, UInt)
    case abstract(String, StaticString, UInt)
    case unknown

    var errorDescription: String? {
        let (message, file, line) = unwrap()
        let filename = URL(fileURLWithPath: "\(file)", isDirectory: false).lastPathComponent
        return "\(message) (\(filename):\(line))"
    }

    fileprivate func unwrap() -> (message: String, file: StaticString, line: UInt) {
        switch self {
        case let .notImplemented(what, file, line):
            return ("\(what) not implemented", file, line)
        case let .unreachable(what, file, line):
            return ("Internal inconsistency: \(what)", file, line)
        case let .abstract(what, file, line):
            return ("An internal error occured: \(what) must have been implemented in a subclass. It wasn't.", file, line)
        case .unknown:
            return ("An unknown error occured", "<unknown>", 0)
        }
    }

    @_transparent
    static func notImplemented(_ what: String, file: StaticString = #file, line: UInt = #line) -> Never {
        handle(error: .notImplemented(what, file, line))
    }

    @_transparent
    static func unreachable(_ message: String, file: StaticString = #file, line: UInt = #line) -> Never {
        handle(error: .unreachable(message, file, line))
    }

    @_transparent
    static func abstract(file: StaticString = #file, line: UInt = #line, function: StaticString = #function) -> Never {
        handle(error: .abstract("\(function)", file, line))
    }

    @_transparent
    private static func handle(error: LoweringError) -> Never {
        guard let jmpBuf = Thread.current.threadDictionary[setjmpKey] as? Pointer<Int32> else {
            let (what, file, line) = error.unwrap()
            fatalError(what, file: file, line: line)
        }
        tlsLoweringError = error

        longjmp(jmpBuf, -1)
    }
}

/// `setjmp()`-based error handling mechanism for lowering code.
///
/// There's quite a lot of code in `Lowering`, none of which uses Swift errors for error reporting. Introducing proper error handling there is a lot of effort, which atm doesn't seem worth it.
///
/// At the same time, we do want to handle those errors in a structured way. For example, if we throw from deep within SIL lowering, we still want to handle that error somewhere in the interceptor, to be able to output any additional information that we have at that point.
///
/// We use a home-baked `setjmp()`-based approach where a fatal error would be `longjmp()`'ed to a point somewhere close to entry points into `Intercept` module, namely `Interceptor` and `InvocationHandler`. All objects allocated between that safe point and the point where the error occrus will be leaked, but it is an acceptable price in this case. An alternative approach could be to use Obj-C exceptions, however it also does not correctly interoperate with Swift stacks (https://forums.swift.org/t/is-it-safe-to-throw-objc-exceptions-across-swift-stack-frames/17449/7), and so `longjmp()`, which simply discards the entire stack, is a slightly "safer" approach than Obj-C exceptions.
///
/// At call site, this function essentially provides two error reporting mechanisms:
/// - normal Swift `throw`n errors are delivered as is and need to be caught with `do`/`try`/`catch`
/// - additionally, errors may be reported via the `Result`
internal func tryLowering<R>(_ exec: () throws -> R) rethrows -> Result<R, LoweringError> {
    if tlsJmpBuf != nil {
        fatalError("\(#function) seems to have been re-entered. this is not supported")
    }

    tlsJmpBuf = RawPointer.allocate(byteCount: 512 /* _JBLEN + a lot */, alignment: 16).reinterpret(Int32.self)
    defer {
        tlsJmpBuf = nil
    }

    // of course Swift wouldn't let us just use setjmp.
    if let setjmpPtr = simpleDlsym("setjmp") { // not that it can ever return nil
        let setjmp = unsafeBitCast(setjmpPtr, to: (@convention(c) (Pointer<Int32>) -> Int32).self)
        let ret = setjmp(tlsJmpBuf!)
        if ret != 0 {
            if let error = tlsLoweringError {
                return .failure(error)
            }
            return .failure(LoweringError.unknown)
        }
    }

    return .success(try exec())
}

/// See `tryLowering(_:)`. This is a simpler-to-use wrapper that throws instead of returning a result.
internal func tryLoweringThrowing<R>(_ exec: () -> R) throws -> R {
    let result = try tryLowering(exec)
    switch result {
    case .success(let ret):
        return ret
    case .failure(let error):
        throw error
    }
}

private var tlsLoweringError: LoweringError? {
    get {
        Thread.current.threadDictionary[currentErrorKey] as? LoweringError
    }
    set {
        Thread.current.threadDictionary[currentErrorKey] = newValue
    }
}

private var tlsJmpBuf: Pointer<Int32>? {
    get {
        Thread.current.threadDictionary[setjmpKey] as? Pointer<Int32>
    }
    set {
        if let existingValue = Thread.current.threadDictionary[setjmpKey] as? Pointer<Int32> {
            existingValue.deallocate()
        }
        Thread.current.threadDictionary[setjmpKey] = newValue
    }
}

private let setjmpKey = "intercept.setjmp.key"
private let currentErrorKey = "intercept.currentError.key"
