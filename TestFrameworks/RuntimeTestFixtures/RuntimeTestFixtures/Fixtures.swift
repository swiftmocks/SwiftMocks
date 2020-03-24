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

struct EmptyStruct {}
class EmptyClass {}

protocol EmptyProtocol {}

protocol AnotherEmptyProtocol {}

@objc protocol EmptyObjCProtocol {}

protocol EmptyChildProtocol: EmptyProtocol {}

protocol EmptyProtocolWithClassConstraint: class {}

protocol EmptyErrorProtocol: Error { }

protocol ProtocolWithAMethod {
    func method() -> Int
}

protocol ProtocolWithFiveMethods {
    func method_0()
    func method_1()
    func method_2()
    func method_3()
    func method_4()
}

protocol ProtocolWithDefaultImplementation {
    func method()
}
extension ProtocolWithDefaultImplementation {
    func method() {}
}

class BaseClassForRealisticallyLookingProtocol {}

protocol RealisticallyLookingProtocolWithABaseClass: BaseClassForRealisticallyLookingProtocol, EmptyChildProtocol {
    var foo: Int { get }
    func method()
    static func classMethod()
}

class RealisticallyLoookingClass: BaseClassForRealisticallyLookingProtocol, RealisticallyLookingProtocolWithABaseClass {
    let foo: Int = 123456
    func method() {}
    static func classMethod() {}
}

class GenericParentClass<T> {}

protocol Fighter {}
struct XWing: Fighter { }

@available(iOS 13.0.0, *)
func launchFighter() -> some Fighter {
    XWing()
}
