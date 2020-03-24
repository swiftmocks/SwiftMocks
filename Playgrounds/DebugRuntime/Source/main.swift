// This source file is part of SwiftInternals open source project.
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

class Foo<T> {
    let bar: T

    init(bar: T) {
        self.bar = bar
    }
}

let foo = Foo(bar: 0xbeef)

print(foo)

// Uncomment the following line to inspect the value of DYLD_LIBRARY_PATH if the application does not seem to pick up the debug version of runtime and stdlib.
// print(ProcessInfo.processInfo.environment["DYLD_LIBRARY_PATH"]?.components(separatedBy: ":").first ?? "not set")

protocol AnyTypeRuntimeExtensions {}
extension AnyTypeRuntimeExtensions {
    static func initialize(_ storage: UnsafeMutableRawPointer, with value: Any) {
        storage.assumingMemoryBound(to: self).initialize(to: value as! Self)
    }
}

enum Bar: Error, AnyTypeRuntimeExtensions {
    case a
}

let p = UnsafeMutableRawPointer.allocate(byteCount: 100, alignment: 16)
Bar.initialize(p, with: Bar.a)
