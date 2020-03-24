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

/// Enum/namespace responsible for keeping track of trampoline slots, and in the future allocating them. Since current implementation is based on statically compiled trampoline slots, its role is limited to only keeping track of how many slots of each kind are used, and to crash if more slots are requested than there are available. This is also why it is not instantiatable and just a static "namespace".
///
/// There are two kinds of slots, each used for a different purpose:
/// - _reserved slots_ are the ones used by interceptor to replace dynamically replaceable functions. Trampoline allocator does not keep track of them individually, and only needs to be made aware, via `reserveSlots()`, of how many of them are used up so that it can detect an overflow.
/// - _permanent slots_ are used for functions "synthesized" at runtime, for example witnesses. Once allocated, they need to stay around forever, so that any invocation of those synthesized functions can be correctly routed to whatever code that needs to handle them.
enum Trampoline {
    enum FunctionIndex: Hashable {
        case reserved(Int)
        case permanent(Int)
    }

    enum Error: LocalizedError {
        case trampolineOverflow

        public var errorDescription: String? {
            "\(Self.self).\(self)"
        }
    }

    /// Manages synthesized (created at runtime) functions. In the current implementation trampoline slots from the top of the common pool are used for that, and going forward, these functions may be fully synthesized at runtime for OSes that support it (i.e. all except on-device iOS).
    ///
    /// Creation of a synthesized function is a two-phase process due to a possibility of infinite recursion during creation of existential dummies. First, a trampoline slot needs to be reserved via `reserve()`, and then an implementation for that slot needs to be provided via `setImpl(_:index:)`.
    class PermanentSlots {
        typealias Impl = (InvocationSnapshot) -> Void

        private var descriptors = [InvocationDescriptor]()
        private var implementations = [Impl?]()

        var count: Int {
            descriptors.count
        }

        fileprivate init() {}

        func reserve(descriptor: InvocationDescriptor) -> (index: Int, slot: RawPointer) {
            descriptors.append(descriptor)
            implementations.append(nil)
            let index: Int = implementations.count - 1
            let slot: RawPointer = trampolineSlot(at: numberOfTrampolineSlots - index - 1) // take the next available slot from the top
            return (index, slot)
        }

        func setImplementation(_ impl: @escaping Impl, at index: Int) {
            guard index < implementations.count, index >= 0 else {
                fatalError("no fulfilment for slot \(index)")
            }
            implementations[index] = impl
        }

        subscript(_ index: Int) -> InvocationDescriptor {
            descriptors[index]
        }

        fileprivate func handle(index: Int, snapshot: InvocationSnapshot) {
            guard let impl = implementations[index] else {
                fatalError("no implementation for slot \(index)")
            }
            impl(snapshot)
        }
    }

    static let permanentSlots = PermanentSlots()

    // this is only used to detect overflow when the number of reserved slots plus the number of permanent slots becomes greater than what is available
    private static var reservedSlots = 0

    /// Mark `count` trampoline slots at the beginning of the global trampoline table as reserved. If the total amount of reserved and permanently allocated slots is greater than the total number of static slots, throws an error.
    static func reserveSlots(count: Int) throws -> (first: RawPointer, stride: Int) {
        reservedSlots = count
        if permanentSlots.count + reservedSlots >= numberOfTrampolineSlots {
            throw Error.trampolineOverflow
        }
        return (trampolineSlot(at: 0), stride: bytesPerTrampolineSlot)
    }

    /// Trampoline dispatch function
    static var dispatch: ((FunctionIndex, InvocationSnapshot) -> RawPointer?)? {
        didSet {
            guard let dispatch = dispatch else {
                trampolineDispatcherPointer.pointee = nil
                return
            }

            // the code is never intended to run in multi-threaded mode, so storing the dispatch function in a TLS is equivalent to storing it in a global var
            Thread.current.threadDictionary[tlsTrampolineDispatcherKey] = dispatch

            trampolineDispatcherPointer.pointee = { index, rsp -> RawPointer? in
                guard let trampolineDispatcher = Thread.current.threadDictionary[tlsTrampolineDispatcherKey] as? ((FunctionIndex, InvocationSnapshot) -> RawPointer?) else {
                    fatalError("attempting to dispatch replaced function without a trampoline dispatcher in place")
                }

                let snapshot = InvocationSnapshot(rsp: rsp)

                if index < Self.reservedSlots {
                    return trampolineDispatcher(.reserved(index), snapshot)
                }

                let permanentSlotIndex = numberOfTrampolineSlots - index - 1
                if trampolineDispatcher(.permanent(permanentSlotIndex), snapshot) != nil {
                    Self.permanentSlots.handle(index: permanentSlotIndex, snapshot: snapshot)
                }
                return nil // for synthesized functions, we always return, since there is no actual implementation to tailcall
            }
        }
    }
}

private func trampolineSlot(at index: Int) -> RawPointer {
    precondition(index < numberOfTrampolineSlots)
    let offset: Int = index * bytesPerTrampolineSlot
    return trampoline.advanced(by: offset)
}

private var numberOfTrampolineSlots: Int = {
    guard let p = dlsym(dlopen(nil, 0), "SwiftInternals$numberOfTrampolineSlots") else {
        fatalError("SwiftInternals$numberOfTrampolineSlots missing")
    }
    return p.assumingMemoryBound(to: Int.self).pointee
}()

private var bytesPerTrampolineSlot: Int = {
    guard let p = dlsym(dlopen(nil, 0), "SwiftInternals$bytesPerTrampolineSlot") else {
        fatalError("SwiftInternals$bytesPerTrampolineSlot missing")
    }
    return p.assumingMemoryBound(to: Int.self).pointee
}()

private typealias DispatcherFunction = @convention(c) (Int, RawPointer) -> RawPointer?

/// Assembler trampoline code calls the function at this address, passing trampoline slot index and pointer to %rsp (after all registers have been pushed). Upon return of this function, all registers are restored, and if the return value of this function is 0, trampoline code returns to the caller, otherwise a tail call to the returned address is performed.
private var trampolineDispatcherPointer: Pointer<Optional<DispatcherFunction>> = {
    guard let p = dlsym(dlopen(nil, 0), "SwiftInternals$trampolineDispatcher") else {
        fatalError("SwiftInternals$trampolineDispatcher missing")
    }
    return p.assumingMemoryBound(to: Optional<DispatcherFunction>.self)
}()

private var trampoline: RawPointer = {
    guard let p = dlsym(dlopen(nil, 0), "SwiftInternals$trampoline") else {
        fatalError("SwiftInternals$trampoline missing")
    }
    return RawPointer(p)
}()

private let tlsTrampolineDispatcherKey = "trampoline.dispatcher.key"
