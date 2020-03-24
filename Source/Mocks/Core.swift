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

let theCore = Core()

protocol Filter {
    func matches(invocationHandler: InvocationHandler) throws -> Bool
}

internal class Core: InterceptorDelegate {
    enum Action {
        case `return`(Any)
        case `throw`(Error)

        fileprivate func execute(handler: InvocationHandler) throws {
            switch self {
            case .return(let value):
                try handler.inject(result: value)
            case .throw(let error):
                handler.inject(error: error)
            }
        }
    }

    private let images: [MachImage]
    private var stubs = [Interceptor.FunctionIndex: [(filter: Filter, action: Action)]]()
    private var catchAllActions = [Interceptor.FunctionIndex: Action]()

    let interceptor: Interceptor
    let dummyFactory: DummyFactory

    init() {
        let images = MachImage.allExcludingKnownSystemPaths
        self.images = images
        do {
            self.interceptor = try Interceptor(images: images)
        } catch {
            // no way to recover
            fatalError("Failed to create the Core: \(error)")
        }
        self.dummyFactory = DummyFactory(interceptor: interceptor, images: images)
        interceptor.delegate = self

        // interceptor.verbose = true
    }

    func dummyInstance<T>(of type: T.Type) -> T {
        do {
            return try dummyFactory.dummyInstance(of: type)
        } catch {
            gracefullyAbort(error: error)
        }
    }

    func resetAllMocks() {
        stubs.removeAll()
        catchAllActions.removeAll()
        dummyFactory.gcDummies()
    }

    func prependStub(filter: Filter, action: Action, for index: Interceptor.FunctionIndex) {
        var stubs = self.stubs[index] ?? []
        stubs.insert((filter: filter, action: action), at: 0)
        self.stubs[index] = stubs

        // XXX: remove an old filter if the new filter covers the same or a superset of conditions
    }

    func setCatchAllAction(_ action: Action, for index: Interceptor.FunctionIndex) {
        catchAllActions[index] = action
    }

    func replacementFunctionDidInvoke(fnIndex: Interceptor.FunctionIndex, handler: InvocationHandler) -> Interceptor.Result {
        do {
            if let stubs = self.stubs[fnIndex] {
                if let stub = try stubs.first(where: { try $0.filter.matches(invocationHandler: handler) }) {
                    try stub.action.execute(handler: handler)
                    return .return
                }
            }

            if let catchAll = catchAllActions[fnIndex] {
                try catchAll.execute(handler: handler)
                return .return
            }
        } catch {
            gracefullyAbort(error: error)
        }

        return .proceed
    }

    /// Executes `execute` and returns the internal index of the interceptable function that was invoked. If no invocation was detected (because the invoked function is not repleceable), gracefully abort. Graceful abo by throwing an Obj-C exception.
    func detect<R>(execute: () throws -> R, returning result: R) rethrows -> (index: Interceptor.FunctionIndex, instance: Any?) {
        switch try interceptor.detect(execute: execute, returning: result) {
        case .none:
            gracefullyAbort(message: "Could not detect function invocation")
        case .failure(let error):
            gracefullyAbort(error: error)
        case .success(let (idx, instance)):
            return (idx, instance)
        }
    }

    func gracefullyAbort(error: Error) -> Never {
        // XCTFail does not always prevent the rest of the test method to run, and it seems to be version- and environment-specific, so we are using a more surefire way to abort the current test method, by throwing an Obj-C exception
        let reason = (error as? LocalizedError)?.errorDescription ?? "\(error)"
        let ex = NSException(name: .init(rawValue: "\(type(of: error))"), reason: reason, userInfo: ["originalError": error])
        objc_exception_throw(ex)
        fatalError(reason)
    }

    func gracefullyAbort(message: String) -> Never {
        let ex = NSException(name: .init(rawValue: message), reason: nil, userInfo: nil)
        objc_exception_throw(ex)
        fatalError(message)
    }
}

class InstanceFilter: Filter {
    let instance: AnyObject

    init(instance: AnyObject) {
        self.instance = instance
    }

    func matches(invocationHandler: InvocationHandler) throws -> Bool {
        guard let selfParam = try invocationHandler.extractSelfParameter() else {
            // XXX: report an error?
            return false
        }

        return selfParam as AnyObject === instance
    }
}

class AnyTypeFilter: Filter {
    let theType: Any.Type
    let impl: (InvocationHandler) -> Bool

    init(type: Any.Type) {
        self.theType = type
        impl = { handler in
            false
        }
    }

    func matches(invocationHandler: InvocationHandler) throws -> Bool {
        try theType == invocationHandler.extractSelfParameter() as? Any.Type
    }
}

class TypeFilter: Filter {
    let theType: Any.Type
    let impl: (InvocationHandler) throws -> Bool

    init<T>(type: T.Type) {
        self.theType = type
        impl = { handler in
            guard let selfParam = try handler.extractSelfParameter() else {
                // XXX: report an error?
                return false
            }
            return selfParam is T.Type
        }
    }

    init(anyType: Any.Type) {
        self.theType = anyType
        let anyTypeMetadata = Metadata.of(anyType)
        let anyClassMetadata = anyTypeMetadata as? AnyClassMetadata
        impl = { handler in
            guard let selfParamAsAnyType = try handler.extractSelfParameter() as? Any.Type else {
                // XXX: report an error?
                return false
            }

            /// If `self` of the invoked method is not `AnyClassMetadata`, then a simple equality will do. FIXME: what about protocol extensions which get Protocol as self? ⬅️ here we'd have `selfParamAsAnyType` as Protocol
            guard let selfParamMetadata = Metadata.of(selfParamAsAnyType) as? AnyClassMetadata else {
                return selfParamAsAnyType == anyType
            }

            /// if `self` of the invoked method is `AnyClassMetadata`, and the stored type is not, then they can't be equal. FIXME: what about protocol extensions which get Protocol as self? ⬅️ here we'd have `anyType` as Protocol
            guard let anyClassMetadata = anyClassMetadata else {
                return false
            }

            let relationship = anyClassMetadata.isRelated(to: selfParamMetadata)
            return relationship == .parent || relationship == .same
        }
    }

    func matches(invocationHandler: InvocationHandler) throws -> Bool {
        try impl(invocationHandler)
    }
}

class EquatableFilter: Filter {
    let impl: (InvocationHandler) throws -> Bool

    init<T: Equatable>(equatable: T) {
        impl = { handler in
            guard let selfParam = try handler.extractSelfParameter() else {
                fatalError("no self in an instance method?")
            }
            guard let selfT = selfParam as? T else {
                fatalError("self parameter is not of self type \(T.self)")
            }
            return selfT == equatable
        }
    }

    init(anyEquatable: Any) {
        precondition(Equatables.conformsToEquatable(anyEquatable))
        impl = { handler in
            guard let selfParam = try handler.extractSelfParameter() else {
                fatalError("no self in an instance method?")
            }
            guard let areEqual = Equatables.areEqual(lhs: anyEquatable, rhs: selfParam) else {
                fatalError("self parameter is equatable with \(type(of: anyEquatable))")
            }
            return areEqual
        }
    }

    func matches(invocationHandler: InvocationHandler) throws -> Bool {
        try impl(invocationHandler)
    }
}
