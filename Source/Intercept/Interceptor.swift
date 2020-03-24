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

protocol InterceptorDelegate: AnyObject {
    func replacementFunctionDidInvoke(fnIndex: Interceptor.FunctionIndex, handler: InvocationHandler) -> Interceptor.Result
}

/// The main entry point into the world of invocation interception.
///
/// While it looks like a class and mostly behaves like a class, since the underlying trampoline implementation is currently based on statically compiled trampoline code with a fixed number of slots, it makes no sense to have two `Interceptor` instances at any given time, as they would be unsuccessfully trying to use the same trampoline. Going forward, when trampolines become dynamically generated (for most platforms, anyway), it might be possible to have several instances of interceptors, even though it's not clear why we'd want to. TL;DR: do not create more than one instance of this.
final class Interceptor {
    enum FunctionIndex: Hashable {
        case regular(Int)
        case synthesizedWitness(Int)

        var isWitness: Bool {
            if case .synthesizedWitness = self {
                return true
            }
            return false
        }
    }

    enum Result: Equatable {
        case proceed
        case `return`
    }

    private enum ReplacementDescriptor {
        case notComputed
        case unsupported(Error)
        case computed(InvocationDescriptor)
    }

    private enum DispatchMode {
        case delegate
        case callback((FunctionIndex, InvocationHandler) -> Result)
    }

    private static var _theManager: Interceptor?

    private let replacementVars: [ReplacementVar]
    private var replacementDescriptors: [ReplacementDescriptor]
    private var mode: DispatchMode = .delegate
    private var detectError: Error? // used by detect. XXX: explain more, why

    var verbose: Bool = false
    weak var delegate: InterceptorDelegate?

    init(images: [MachImage]) throws {
        // when a new instance is created, make sure that we first uninstall old replacements. otherwise the new replacement vars' `original` will point to trampoline
        Self._theManager?.uninstallDynamicReplacement()

        self.replacementVars = images.flatMap { $0.replacementVars }
        self.replacementDescriptors = Array(repeating: .notComputed, count: replacementVars.count)

        let (first, stride) = try Trampoline.reserveSlots(count: replacementVars.count)
        installDynamicReplacement(first: first, stride: stride)

        Self._theManager = self
    }

    func name(at index: Int) -> String {
        String(replacementVars[index].key.name.dropLast(2))
    }

    func detect<R>(execute: () throws -> R, returning result: R) rethrows -> Swift.Result<(index: FunctionIndex, instance: Any?), Error>? {
        detectError = nil

        var interceptedIndex: FunctionIndex?
        var instance: Any?
        _ = try intercept(execute: execute, onIntercept: { index, handler in
            interceptedIndex = index
            do {
                instance = try handler.extractSelfParameter()
                try handler.inject(result: result)
            } catch {
                // for now, just abort. we could potentially properly recover from this error, but this involves making onIntercept throwing, which will introduce a lot of hairiness elsewhere.
                fatalError("\(error)")
            }
            return .return
        })

        if let detectError = self.detectError {
            self.detectError = nil
            return .failure(detectError)
        }

        guard let idx = interceptedIndex else {
            return nil
        }

        return .success((idx, instance))
    }

    /// This should be a private method, as it's just an implementation of `detect()` and is not directly called by client code. However, it needs to be internal, because without it testing a lot of low-level things would be difficult or impossible.
    func intercept<R>(execute: () throws -> R, onIntercept: (FunctionIndex, InvocationHandler) -> Result) rethrows -> R {
        try withoutActuallyEscaping(onIntercept) { onIntercept -> R in
            mode = .callback(onIntercept)
            defer {
                mode = .delegate
            }

            return try execute()
        }
    }

    private func dispatch(index: Trampoline.FunctionIndex, snapshot: InvocationSnapshot) -> RawPointer? {
        detectError = nil

        switch index {
        case let .reserved(index):
            let maybeDescriptor: InvocationDescriptor?
            // could be InvocationDescriptor, nil (if we had already determined that we can't handle this function), or error (if this is the first time we are realising that)
            switch computeOrGetInvocationDescriptor(index: index) {
            case .success(let desc):
                maybeDescriptor = desc
            case .failure(let error):
                detectError = error
                maybeDescriptor = nil
            }

            guard let descriptor = maybeDescriptor else {
                replacementVars[index].prepareToInvokeOriginal()
                return replacementVars[index].original
            }
            if verbose {
                print(descriptor)
            }

            let handler = InvocationHandler(descriptor: descriptor, snapshot: snapshot)

            let result: Result
            switch mode {
            case .delegate:
                result = delegate?.replacementFunctionDidInvoke(fnIndex: .regular(index), handler: handler) ?? .proceed
            case let .callback(callback):
                result = callback(.regular(index), handler)
            }
            if result == .proceed {
                replacementVars[index].prepareToInvokeOriginal()
                return replacementVars[index].original
            }
            return nil
        case let .permanent(index):
            let descriptor = Trampoline.permanentSlots[index]
            if verbose {
                print(descriptor)
            }

            let handler = InvocationHandler(descriptor: descriptor, snapshot: snapshot)

            let result: Result
            switch mode {
            case .delegate:
                result = delegate?.replacementFunctionDidInvoke(fnIndex: .synthesizedWitness(index), handler: handler) ?? .proceed
            case let .callback(callback):
                result = callback(.synthesizedWitness(index), handler)
            }

            if result == .proceed {
                let original = RawPointer(bitPattern: 0xdeaddeadbeef)! // the exact value is ignored by trampoline, as long as it's not nil, it will invoke the default implementation
                return original
            }
            return nil
        }
    }

    private func computeOrGetInvocationDescriptor(index: Int) -> Swift.Result<InvocationDescriptor, Error> {
        precondition(index < replacementDescriptors.count)
        switch replacementDescriptors[index] {
        case let .computed(invocationDescriptor):
            return .success(invocationDescriptor)
        case .unsupported(let error):
            return .failure(error)
        case .notComputed:
            do {
                let invocationDescriptorOrError = try tryLowering {
                    try InvocationDescriptor(mangledName: self.name(at: index))
                }
                switch invocationDescriptorOrError {
                case .failure(let error):
                    throw error
                case .success(let invocationDescriptor):
                    replacementDescriptors[index] = .computed(invocationDescriptor)
                    return .success(invocationDescriptor)
                }
            } catch {
                replacementDescriptors[index] = .unsupported(error)
                return .failure(error)
            }
        }
    }

    private func installDynamicReplacement(first: RawPointer, stride: Int) {
        var current = first
        for i in 0..<replacementVars.count {
            replacementVars[i].variable.reinterpret(RawPointer.self).pointee = current
            current += stride
        }

        Trampoline.dispatch = { [weak self] index, snapshot in
            guard let self = self else {
                fatalError("dispatching to a dead interceptor")
            }

            return self.dispatch(index: index, snapshot: snapshot)
        }
    }

    private func uninstallDynamicReplacement() {
        for i in 0..<replacementVars.count {
            replacementVars[i].variable.reinterpret(RawPointer.self).pointee = replacementVars[i].original
        }
    }
}
