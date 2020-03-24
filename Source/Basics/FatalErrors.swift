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

@_transparent // this causes the debugger to halt at the call site, instead of inside of this function
internal func notImplemented(_ what: String? = nil, file: StaticString = #file, line: UInt = #line) -> Never {
    if let what = what {
        fatalError("Not implemented: " + what, file: file, line: line)
    } else {
        fatalError("Not implemented. That's all we know.", file: file, line: line)
    }
}

@_transparent // this causes the debugger to halt at the call site, instead of inside of this function
internal func unreachable(_ message: String? = nil, file: StaticString = #file, line: UInt = #line) -> Never {
    if let message = message {
        fatalError("Unreachable: \(message)", file: file, line: line)
    }

    fatalError("Unreachable", file: file, line: line)
}

@_transparent // this causes the debugger to halt at the call site, instead of inside of this function
internal func abstract(file: StaticString = #file, line: UInt = #line, function: StaticString = #function) -> Never {
    fatalError("\(function) must be implemented in a subclass", file: file, line: line)
}
