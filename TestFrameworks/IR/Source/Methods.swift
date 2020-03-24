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

var lastCalledMethod = ""

class AnotherEmptyClass: Equatable {
    public static func == (lhs: AnotherEmptyClass, rhs: AnotherEmptyClass) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}

// MARK: - Classes

class ___C2000 {
    func ___2000() { lastCalledMethod = #function }
    var emptyClass: AnotherEmptyClass
    init() {
        emptyClass = AnotherEmptyClass()
    }
}

class ___C2001 {
    func ___2001(param: Int) -> Int { lastCalledMethod = #function; return 0 }
    var emptyClass: AnotherEmptyClass
    init() {
        emptyClass = AnotherEmptyClass()
    }
}

class ___C2002 {
    func ___2002(param: Int) -> Self { lastCalledMethod = #function; return self }
}

class ___C2003 {
    func ___2003(param: Int) throws -> Self { lastCalledMethod = #function; return self }
}

class ___C2004 {
    class func ___2004(param: Int) -> Int { lastCalledMethod = #function; return 0 }
}

class ___C2005 {}
extension ___C2005 {
    func ___2005(param: Int) -> Float { 0.0 }
}

class ___C2006 {}
extension ___C2006 {
    var ___2006: [String] { [] }
}

// MARK: - Structs

struct ___S2010: Equatable {
    func ___2010() { lastCalledMethod = #function }
    let property: Int
}

struct ___S2011: Equatable {
    func ___2011(param: Int) -> Int { lastCalledMethod = #function; return 0 }
    let property: Int
}

struct ___S2012: Equatable {
    func ___2012(param: Int) -> Self { lastCalledMethod = #function; return self }
    let property: Int
}

struct ___S2013: Equatable {
    func ___2013(param: Int) throws -> Self { lastCalledMethod = #function; return self }
    let property: Int
}

struct ___S2014: Equatable {
    static func ___2014(param: Int) -> Int { lastCalledMethod = #function; return 0 }
}

struct ___S2015: Equatable {
    func ___2015(_ param: Int) -> Int { lastCalledMethod = #function; return 0 }
}

struct ___S2016 {}
extension ___S2016 {
    func ___2016() -> String { "" }
}

struct ___S2017 {}
extension ___S2017 {
    var ___2017: Int { 0 }
}

// MARK: - Enums

enum ___E2020: Equatable {
    func ___2020() { lastCalledMethod = #function }
    case foo(___S2020)
    case bar
}
struct ___S2020: Equatable {
    let property: Int
}

enum ___E2021: Equatable {
    func ___2021(param: Int) -> Int { lastCalledMethod = #function; return 0 }
    case foo(___S2021)
    case bar
}
struct ___S2021: Equatable {
    let property: Int
}

enum ___E2022: Equatable {
    func ___2022(param: Int) -> Self { lastCalledMethod = #function; return self }
    case foo(___S2022)
    case bar
}
struct ___S2022: Equatable {
    let property: Int
}

enum ___E2023: Equatable {
    func ___2023(param: Int) throws -> Self { lastCalledMethod = #function; return self }
    case foo(___S2023)
    case bar
}
struct ___S2023: Equatable {
    let property: Int
}

enum ___E2024: Equatable {
    static func ___2024(param: Int) -> Int { lastCalledMethod = #function; return 0 }
    case foo(___S2024)
    case bar
}
struct ___S2024: Equatable {
    let property: Int
}

enum ___E2025 { case foo}
extension ___E2025 {
    func ___2025() -> CChar { 0 }
}

enum ___E2026 { case foo}
extension ___E2026 {
    var ___2026: UnsafeMutableRawPointer? { nil }
}

// MARK: - Subscripts

class ___2100 {
    subscript(_ index: String) -> Character { " " }
}

class ___2101 {
    var yieldedValue = ""

    subscript(_ index: Double) -> String {
        get { "" }
        set {}
        _modify {
            yield &yieldedValue
        }
    }
}

struct ___2102: Equatable {
    var yieldedValue = ""

    subscript(_ index: Double, _ anotherIndex: Int) -> String {
        get { "" }
        set {}
        _modify {
            yield &yieldedValue
        }
    }
}

enum ___2103 {
    static subscript(_ index: String, _ anotherIndex: Int) -> UnicodeScalar { "a" }
}

struct ___2104 {
    static subscript(_ index: String, _ anotherIndex: Int) -> (UnicodeScalar, Double) {
        get { ("a", 11.25) }
        set { }
    }
}
