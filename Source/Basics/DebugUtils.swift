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

// a small collection of utility methods useful for debugging

import Foundation

internal func simpleDladdr(_ pointer: RawPointer?) -> String? {
    var dlinfo = Dl_info()
    dladdr(pointer, &dlinfo)
    guard let cString = dlinfo.dli_sname else { return nil }
    return String(cString: cString)
}

internal func simpleDladdr(_ int: Int) -> String? {
    simpleDladdr(RawPointer(bitPattern: int))
}

internal func simpleDlsym(_ name: String) -> RawPointer? {
    dlsym(dlopen(nil, 0), name)
}

internal func pokeAround(_ pointer: RawPointer) {
    let pp = pointer.reinterpret(RawPointer.self, aligned: false)
    for i in (-3..<20) {
        let prefix: String = i == 0 ? "->" : "  "
        let p = (pp + i).pointee
        let name = simpleDladdr(p) ?? "n/a"
        print("\(prefix)\(p) -> \(name)")
    }
}

internal func pokeAround(_ i: Int) {
    pokeAround(RawPointer(bitPattern: i)!)
}

internal func pokeAround(_ object: AnyObject) {
    pokeAround(Unmanaged.passUnretained(object).toOpaque())
}
