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

public let void: Void = ()

public func resetAllMocks() { theCore.resetAllMocks() }

public func any<T>() -> T { theCore.dummyInstance(of: T.self) }

public func mock<T>(of: T.Type = T.self, _ config: ((T) -> Void)? = nil) -> T {
    let ret: T = any()
    if let config = config {
        config(ret)
    }
    return ret
}

public func stub<R>(file: StaticString = #file, line: UInt = #line, _ fn: () -> R) -> Stub<R> {
    Factory<R>.globalOrInstanceStub(fn, file: file, line: line)
}

public func stub<R>(file: StaticString = #file, line: UInt = #line, _ fn: () throws -> R) -> ThrowingStub<R> {
    do {
        return try Factory<R>.globalOrInstanceStub(fn, file: file, line: line)
    } catch {
        theCore.gracefullyAbort(message: "\(#function) is not supposed to throw, but it did")
    }
}

public func stub<T, R>(everyInstanceOf type: T.Type, method: (T) -> R) -> Stub<R> {
    Factory<R>.everyInstanceOf(type: type, fn: method)
}

public func stub<T, R>(everyInstanceOf type: T.Type, method: (T) throws -> R) -> ThrowingStub<R> {
    do {
        return try Factory<R>.everyInstanceOf(type: type, fn: method)
    } catch {
        theCore.gracefullyAbort(message: "\(#function) is not supposed to throw, but it did")
    }
}

public class Stub<R> {
    let index: Interceptor.FunctionIndex
    let filter: Filter?

    init(index: Interceptor.FunctionIndex, filter: Filter?) {
        self.index = index
        self.filter = filter
    }

    public func toReturn(_ value: R) {
        if let filter = filter {
            theCore.prependStub(filter: filter, action: .return(value), for: index)
        } else {
            theCore.setCatchAllAction(.return(value), for: index)
        }
    }

    public func with(_ value: R) {
        toReturn(value)
    }
}

extension Stub where R == Void {
    public func toReturn() {
        toReturn(())
    }

    public func justReturn() {
        toReturn(())
    }
}

public class ThrowingStub<R>: Stub<R> {
    public func toThrow(_ error: Error) {
        if let filter = filter {
            theCore.prependStub(filter: filter, action: .throw(error), for: index)
        } else {
            theCore.setCatchAllAction(.throw(error), for: index)
        }
    }
}

public struct InOut<T> {
    public static var any: T {
        _read {
            yield SwiftMocks.any() as T
        }
        _modify {
            var yie = SwiftMocks.any() as T
            yield &yie
        }
    }
}

// MARK: - Implementation

private enum Factory<R> {
    static func globalOrInstanceStub<R>(_ fn: () throws -> R, file: StaticString, line: UInt) rethrows -> ThrowingStub<R> {
        let returnValue: R = theCore.dummyInstance(of: R.self)
        let (index, instance) = try theCore.detect(execute: fn, returning: returnValue)
        if let instance = instance {
            return instanceStub(instance, index: index)
        }
        return ThrowingStub<R>(index: index, filter: nil)
    }

    static func explicitInstanceStub<T, R>(_ instance: T, method: (T) throws -> R) rethrows -> ThrowingStub<R> {
        let returnValue: R = theCore.dummyInstance(of: R.self)
        let (index, _) = try theCore.detect(execute: { try method(instance) }, returning: returnValue)
        return instanceStub(instance, index: index)
    }

    static func explicitEquatableInstanceStub<T: Equatable>(instance: T, fn: (T) throws -> R) rethrows -> ThrowingStub<R> {
        let returnValue = theCore.dummyInstance(of: R.self)
        let (index, _) = try theCore.detect(execute: { try fn(instance) }, returning: returnValue)
        return instanceStub(instance, index: index)
    }

    static func explicitTypeStub<T>(type: T.Type, fn: (T.Type) throws -> R) rethrows -> ThrowingStub<R> {
        let returnValue: R = theCore.dummyInstance(of: R.self)
        let (index, _) = try theCore.detect(execute: { try fn(type) }, returning: returnValue)
        return instanceStub(type, index: index)
    }

    private static func instanceStub<R>(_ instance: Any, index: Interceptor.FunctionIndex) -> ThrowingStub<R> {
        let isExistentialDummy = instance is ExistentialDummy
        if isExistentialDummy {
            return ThrowingStub<R>(index: index, filter: nil) // FIXME: always nil? what about two different mocks with different stubs?
        }

        let filter: Filter
        if let anyType = instance as? Any.Type {
            filter = TypeFilter(anyType: anyType)
        } else if Swift.type(of: instance) is AnyClass {
            filter = InstanceFilter(instance: instance as AnyObject)
        } else if Equatables.conformsToEquatable(instance) {
            filter = EquatableFilter(anyEquatable: instance)
        } else {
            theCore.gracefullyAbort(message: "Cannot stub a method of non-class, non-equatable, non-metatype type")
        }

        return ThrowingStub<R>(index: index, filter: filter)
    }

    static func everyInstanceOf<T>(type: T.Type, fn: (T) throws -> R) rethrows -> ThrowingStub<R> {
        let instance: T = theCore.dummyInstance(of: type)
        let returnValue: R = theCore.dummyInstance(of: R.self)
        let (index, _) = try theCore.detect(execute: { try fn(instance) }, returning: returnValue)
        return ThrowingStub<R>(index: index, filter: nil)
    }
}

// MARK: - More explicit DSL

// Turns out we should be able to get away with just a single "stub { ... }" for all of the stubbing needs, but in case we don't, here is the initial DSL with more explicit spelling. It is internal and so not usable from outside.

internal func stub<T, R>(_ instance: T, method: (T) -> R) -> Stub<R> {
    Factory<R>.explicitInstanceStub(instance, method: method)
}

internal func stub<T, R>(_ instance: T, method: (T) throws -> R) -> ThrowingStub<R> {
    do {
        return try Factory<R>.explicitInstanceStub(instance, method: method)
    } catch {
        theCore.gracefullyAbort(message: "\(#function) is not supposed to throw, but it did")
    }
}

internal func stub<T: Equatable, R>(_ instance: T, method: (T) -> R) -> Stub<R> {
    Factory<R>.explicitEquatableInstanceStub(instance: instance, fn: method)
}

internal func stub<T: Equatable, R>(_ instance: T, method: (T) throws -> R) -> ThrowingStub<R> {
    do {
        return try Factory<R>.explicitEquatableInstanceStub(instance: instance, fn: method)
    } catch {
        theCore.gracefullyAbort(message: "\(#function) is not supposed to throw, but it did")
    }
}

internal func stub<T, R>(_ type: T.Type, method: (T.Type) -> R) -> Stub<R> {
    Factory<R>.explicitTypeStub(type: type, fn: method)
}

internal func stub<T, R>(_ type: T.Type, method: (T.Type) throws -> R) -> ThrowingStub<R> {
    do {
        return try Factory<R>.explicitTypeStub(type: type, fn: method)
    } catch {
        theCore.gracefullyAbort(message: "\(#function) is not supposed to throw, but it did")
    }
}



