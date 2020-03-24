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

// contains all types with internal and public visibility, needed for tests

import Foundation

func voidFunction() {}
func simpleFunction(_ param: Double) -> Int { 0 }

func voidThrowingFunction() throws {}
func simpleThrowingFunction(_ param: Double) throws -> Int { 0 }

func functionWithUnsupportedReturnType() -> Float80 { 0.0 }

func functionWithInOutParameters(_ param1: inout String, _ param2: inout SomeClass, _ param3: inout SomeStruct) -> (String, SomeClass, SomeStruct) {
    (param1, param2, param3)
}

var someGlobalVar: Int = 0 {
    didSet {}
}

struct EmptyStruct {}
class EmptyClass {}

class SomeClass {
    var computedVar: String {
        ""
    }

    var varWithDidSet = [String]() {
        didSet {}
    }

    static var someStaticVar: String {
        ""
    }

    func method(string: String) -> Int {
        0
    }

    func throwingMethod(string: String) throws -> Int {
        0
    }

    class func classMethod(_ param1: Double, _ param2: String) -> Int {
        0
    }

    class func throwingClassMethod(_ param1: Double, _ param2: String) throws -> Int {
        0
    }
}

struct SomeStruct: Equatable {
    init(varWithDidSet: [String] = []) {
        self.varWithDidSet = varWithDidSet
    }

    var computedVar: String {
        ""
    }

    var varWithDidSet = [String]() {
        didSet {}
    }

    static var someStaticVar: String {
        ""
    }

    func method(_ param1: Double, _ param2: String) -> String {
        ""
    }

    func throwingMethod(_ param1: Double, _ param2: String) throws -> String {
        ""
    }

    static func staticMethod(_ param1: Double, _ param2: String) -> [String: Int] {
        [:]
    }

    static func throwingStaticMethod(_ param1: Double, _ param2: String) throws -> [String: Int] {
        [:]
    }
}

struct NonEquatableStructWithAMethod {
    func method() -> Int { 0 }
}

class SomeChildClass: SomeClass {}

protocol EmptyProtocol {}
protocol AnotherEmptyProtocol {}
protocol EmptyProtocolWithClassConstraint: class {}
protocol EmptyChildProtocol: EmptyProtocol {}
protocol EmptyErrorProtocol: Error { }
@objc protocol EmptyObjCProtocol {}

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

protocol ProtocolWithDefaultImplementation: AnyObject {
    func method(_ param: Int) -> Double
}
extension ProtocolWithDefaultImplementation {
    func method(_ param: Int) -> Double { 0.0 }

    func nonRequirementMethod(_ param: String) -> Int { 0 }

    var nonRequirementVar: Int { 0 }
}

protocol ProtocolWithAssociatedTypes {
    associatedtype T
    func foo() -> Self
}

protocol RealisticallyLookingProtocol {
    var someVar: String { get set }
    func method(param: Double) -> [String: [Int]]
    static func staticMethod(_ param: Int) -> [String]
}

struct ModifiableStruct {
    var prop: String
}
protocol ProtocolWithModify {
    var modifiableStructProp: ModifiableStruct { get set }
    var modifiableTupleProp: (String, [Int]) { get set }
}
protocol ProtocolWithSubscript {
    subscript(index: Int) -> ModifiableStruct { get set }
    subscript(_ index1: Int, _ index2: String) -> ModifiableStruct { get set }
}

protocol BaseProtocolForRealisticallyLookingProtocol {
    var someVar: String { get set }
    func method(param: Double) -> Character
    static func staticMethod(_ param: Int) -> [String]
    static var staticVar: BaseProtocolForRealisticallyLookingProtocol { get set }

    var someVarToOverride: Double { get set }
    func methodToOverride(_ param: Int) -> EmptyClass
    static func staticMethodToOverride(_ param: inout EmptyClass) -> Int
    static var staticVarToOverride: BaseProtocolForRealisticallyLookingProtocol { get set }
}

protocol RealisticallyLookingProtocolWithABaseProtocol: BaseProtocolForRealisticallyLookingProtocol {
    var someVarToOverride: Double { get set }
    func methodToOverride(_ param: Int) -> EmptyClass
    static func staticMethodToOverride(_ param: inout EmptyClass) -> Int
    static var staticVarToOverride: BaseProtocolForRealisticallyLookingProtocol { get set }
}

protocol ProtocolWithTwoBaseProtocols: RealisticallyLookingProtocolWithABaseProtocol, ProtocolWithAMethod {
    func method(_ param: String) -> [String]
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

protocol ProtocolWithGenericMethod {
    func method<T>(param: T)
}

protocol ProtocolWithSelfConformance {
    func method() -> Self
}
