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

protocol PointeeFacade: Equatable {
    associatedtype Pointee
    var pointer: RawPointer { get }
}

extension PointeeFacade {
    var typedPointer: Pointer<Pointee> { pointer.reinterpret(Pointee.self) }
    var pointee: Pointee {
        get { typedPointer.pointee }
        nonmutating set { typedPointer.pointee = newValue }
    }
}

extension PointeeFacade {
    init(_ pointer: RawPointer) {
        self = unsafeBitCast(pointer, to: Self.self)
    }

    init?(_ pointer: RawPointer?) {
        guard let pointer = pointer else { return nil }
        self.init(pointer)
    }
}
