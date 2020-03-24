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

private let trace = false
var lastCalledGlobal = ""

class AnEmptyClass {}
struct AnAddressOnlyStruct {
    weak var weakVar: AnEmptyClass?
}

// Simple parameters (1-200) — builtins, loadable structs, classes, tuples, functions, metadatas
func ___1()
{ lastCalledGlobal = #function }

func ___2() -> Int
{ lastCalledGlobal = #function; return 0 }

func ___3(_ int: Int) -> Int
{ lastCalledGlobal = #function; return 0 }

func ___4(_ int: Int, _ pointer: UnsafeMutableRawPointer) -> Int
{ lastCalledGlobal = #function; return 0 }

func ___5(reg a: Int8,
          reg b: Int16,
          reg c: Int32,
          reg d: Int64,
          reg e: UnsafeMutableRawPointer,
          reg f: UnsafeRawPointer,
          stack g: Int8,
          stack h: Int16,
          stack i: Int32,
          stack j: Int64,
          stack k: UnsafeMutablePointer<Int>)
{ lastCalledGlobal = #function }

func ___6(xmm a: Float,
          xmm b: Float,
          xmm c: Double,
          xmm d: Double,
          xmm e: Float,
          reg weirdo: Int8,
          xmm f: Double,
          xmm g: Float,
          xmm h: Double,
          stack i: Float,
          stack j: Double,
          reg anotherWeirdo: Int16)
{ lastCalledGlobal = #function }

func ___7(_ param: ___S7) -> ___S7
{ lastCalledGlobal = #function; return param }
struct ___S7: Equatable {
    let a: Int
}

func ___8(_ param: ___S8) -> ___S8
{ lastCalledGlobal = #function; return param }
struct ___S8: Equatable {
    let a: Int
    let b: String
    let c: [AnyHashable: [Double]]
    let d: Int?
    let e: String?
    let f: (Int, Double, String)
    let g: Set<UnsafeRawPointer?>
    let h: Int

    static func == (lhs: ___S8, rhs: ___S8) -> Bool {
        lhs.a == rhs.a && lhs.b == rhs.b && lhs.c == rhs.c && lhs.d == rhs.d && lhs.e == rhs.e && lhs.f.0 == rhs.f.0 && lhs.f.1 == rhs.f.1 && lhs.f.2 == rhs.f.2 && lhs.g == rhs.g && lhs.h == rhs.h
    }
}

func ___9(_ param: ___C9) -> ___C9
{ lastCalledGlobal = #function; return param }
class ___C9 {
    var foo: Float
    init(foo: Float) {
        self.foo = foo
    }
}

func ___10(_ param: ___E10) -> ___E10
{ lastCalledGlobal = #function; return param }
enum ___E10: Equatable { case a, b }

func ___12(_ param: (a: Int16, b: Double)) -> (Double, Float)
{ lastCalledGlobal = #function; return (10.0, 11.0) }

func ___13(_ param: Void)
{ lastCalledGlobal = #function }

func ___14(_ param1: (UnicodeScalar, Void, (Void), (Void, Void), (Double, Int16, Void, (Float, Float))), _ param2: (CChar, Int)) -> (Float, Double, Void)
{ lastCalledGlobal = #function; return (10.0, 11.0, ()) }

func ___15() -> (a: Int, b: (Double, Float))
{ lastCalledGlobal = #function; return (10, (11.0, 12.0)) }

func ___16(_ param: ___C16) -> ___C16
{ lastCalledGlobal = #function; return param }
class ___C16 { var c: ___C16? }

func ___17(_ param: ___S17) -> ___S17
{ lastCalledGlobal = #function; return param }
struct ___S17: Equatable { var c: ___E17<___S17?> }
indirect enum ___E17<T: Equatable>: Equatable {
    case a(T)
}

func ___18(_ param: @escaping (Double) throws -> ((Int, Float), String)) -> ((Double) throws -> ((Int, Float), String))
{ lastCalledGlobal = #function; return param }

func ___19(_ param: ((Double) throws -> (Int)))
{ lastCalledGlobal = #function }

func ___20(_ param: @autoclosure () -> ___S20) -> ___S20
{ lastCalledGlobal = #function; return param() }
class ___C20 {}
struct ___S20 { weak var c: ___C20? }

func ___21(_ param: Any) -> Any
{ lastCalledGlobal = #function; return param }

func ___22(_ param: AnyObject) -> AnyObject
{ lastCalledGlobal = #function; return param }

func ___23(_ param: ___P23) -> ___P23
{ lastCalledGlobal = #function; return param }
protocol ___P23 {}

func ___24(_ param: ___P24_1 & ___P24_2) -> ___P24_1 & ___P24_2
{ lastCalledGlobal = #function; return param }
protocol ___P24_1 {}
protocol ___P24_2 {}

func ___25(_ param: ___P25) -> ___P25
{ lastCalledGlobal = #function; return param }
protocol ___P25: AnyObject {}

func ___26(_ param: ___P26) -> ___P26
{ lastCalledGlobal = #function; return param }
protocol ___P26_Base {}
protocol ___P26: ___P26_Base {}

func ___27(`class`: ___C27.Type,
           `struct`: ___S27.Type,
           `enum`: ___E27.Type,
           `protocol`: ___P27.Protocol,
           protocolComp: (___P27_Another & ___P27).Protocol
) -> (___C27.Type, ___S27.Type, ___E27.Type, ___P27.Protocol, (___P27_Another & ___P27).Protocol)
{ lastCalledGlobal = #function; return (`class`, `struct`, `enum`, `protocol`, protocolComp) }
class ___C27 {}
struct ___S27 {}
enum ___E27 {}
protocol ___P27 {}
protocol ___P27_Another {}

func ___28(`class`: ___C28<Int>.Type, `struct`: ___S28<Int>.Type, `enum`: ___E28<Int>.Type) -> (___C28<Int>.Type, ___S28<Int>.Type, ___E28<Int>.Type)
{ lastCalledGlobal = #function; return (`class`, `struct`, `enum`) }
class ___C28<T> {}
struct ___S28<T> {}
enum ___E28<T> {}

func ___29(a: Int = 10, b: Float, c: Double = 11.0)
{ lastCalledGlobal = #function }

func ___30() throws -> Void
{ lastCalledGlobal = #function }

func ___31(_ error: Error) -> Error
{ lastCalledGlobal = #function; return error }

func ___32(_ param: Int) throws -> Int
{ lastCalledGlobal = #function; return param }

func ___35(reg8 rdi: Int8,
          reg16 rsi: Int16,
          reg32 rdx: Int32,
          reg64 rcx: Int64,
          reg r8: UInt,
          reg f9: UInt,
          stackInt32: UInt32,
          xmm xmm0: Double,
          xmm xmm1: Float,
          xmm xmm2: Double,
          xmm xmm3: Float,
          xmm xmm4: Double,
          xmm xmm5: Float,
          xmm xmm6: Double,
          xmm xmm7: Float,
          stackFloat: Float)
{ lastCalledGlobal = #function }

func ___42(_ param: ___S32_Outer) -> ___S32_Outer
{ lastCalledGlobal = #function; return param }
class ___C42 {}
struct ___S42 {}
enum ___E42 {}
protocol ___P42 {}
protocol ___P42_Another {}
struct ___S32_Outer {
    var `class`: ___C42.Type
    var `struct`: ___S42.Type
    var `enum`: ___E42.Type
    var proto: ___P42.Type
    var protocolComp: (___P42_Another & ___P42).Type
}

func ___43(_ param: ___E43) -> ___E43?
{ lastCalledGlobal = #function; return param }
enum ___E43 { case a(___P43), b(___P43_Another) }
protocol ___P43 {}
protocol ___P43_Another: AnyObject {}

func ___44(_ param: ___S44) -> ___S44?
{ lastCalledGlobal = #function; return param }
struct ___S44 { var a: ___P44; var b: ___P44_Another }
protocol ___P44 {}
protocol ___P44_Another: AnyObject {}

func ___45(_ param: ___P45) -> ___P45 { param }
protocol ___P45 {}

// MARK: - Getters

var ___100: String { "" }

var ___101: String = "" { didSet {} }

class ___C102 {
    var ___102: AnEmptyClass { AnEmptyClass() }
}

class ___C103 {
    var ___103: AnEmptyClass = AnEmptyClass() { didSet {} }
}

struct ___S104 {
    var ___104: AnEmptyClass { AnEmptyClass() }
}

struct ___S105 {
    var ___105: AnEmptyClass = AnEmptyClass() { didSet {} }
}

class ___C106 {
    static var ___106: String { "" }
}

class ___C107 {
    static var ___107 = "" { didSet {} }
}

struct ___S108 {
    static var ___108: String { "" }
}

struct ___S109 {
    static var ___109 = "" { didSet {} }
}

// MARK: - Modify

// this does not produce a _modify coroutine
var ___150: String = "" { didSet {} }

var ___151: String {
    get { "" }
    _modify {
        var fakeResult = ""
        yield &fakeResult
    }
}

class ___C155 {
    struct Content {
        var a: Int
        var b: String
    }
    var ___155: Content = Content(a: 0, b: "") { didSet {} }
}

class ___C156 {
    struct Content {
        var a: Int
        var b: String
    }
    static var ___156: Content = Content(a: 0, b: "") { didSet {} }
}

struct ___C160 {
    struct Content {
        var a: [Int]
        var b: [String]
    }
    var ___160: Content = Content(a: [0], b: [""]) { didSet {} }
}

struct ___C161 {
    struct Content {
        var a: [Int]
        var b: [String]
    }
    var ___161: Content = Content(a: [0], b: [""]) { didSet {} }
}

// MARK: - Optionals (200-250)

func ___200(_ param: Double?) -> Double?
{ lastCalledGlobal = #function; return nil }

func ___201(_ param: ___S201?) -> ___S201?
{ lastCalledGlobal = #function; return param }
struct ___S201: Equatable { var a: String?; var b: Double }

func ___202(_ param: (Int, Double?)?) -> (Int, Double?)?
{ lastCalledGlobal = #function; return param }
class ___C202 {}

func ___203(_ param: (Int, Double, String?, ___C202?)?) -> (Int, Double, String?, ___C202?)?
{ lastCalledGlobal = #function; return param }
class ___C203 {}

// MARK: - Tuples (250-300)

func ___250(a: (Double, (Void, Void)), b: Int) -> Void
{ lastCalledGlobal = #function; }

func ___251(a: (Double, (Int16, (Int8, (Int32, Void), (Int64))))) -> Void
{ lastCalledGlobal = #function; }

// MARK: - Address-only params and returns (300-500)

func ___300(_ param: ___S300) -> ___S300
{ lastCalledGlobal = #function; return param }
class ___C300 {}
struct ___S300 { weak var c: ___C300? }

func ___301(_ param: ___S301) -> ___S301
{ lastCalledGlobal = #function; return param }
class ___C301 {}
struct ___S301 { unowned(unsafe) var c: ___C301? }

func ___302(_ param: ___S302) -> ___S302
{ lastCalledGlobal = #function; return param }
class ___C302 {}
struct ___S302 { unowned var c: ___C302? }

func ___303(_ param: ___S303) -> ___S303
{ lastCalledGlobal = #function; return param }
class ___C303 { weak var c: ___C303? }
struct ___S303 { unowned var c: ___C303? }

func ___310(_ param: String) -> String
{ lastCalledGlobal = #function; return param }

// MARK: - Functions as parameters and properties 400-500

func ___400(_ param: () -> ()) -> () ->()
{ lastCalledGlobal = #function; return {} }

func ___401(_ param: @escaping () -> ()) -> () ->()
{ lastCalledGlobal = #function; return param }

func ___402(_ param: @convention(c) () -> ()) -> @convention(c) () ->()
{ lastCalledGlobal = #function; return {} }

func ___403(_ param: (() -> ())?) -> (() ->())?
{ lastCalledGlobal = #function; return nil }

func ___404(_ param: (@convention(c) () -> ())?) -> (@convention(c) () ->())?
{ lastCalledGlobal = #function; return param }

func ___420(_ param: ___S420) -> ___S420
{ lastCalledGlobal = #function; return param }
struct ___S420_Inner { var a: (Int) -> Double; var b: ((String) -> Int)? }
struct ___S420 { var a: ___S420_Inner }

func ___431(_ param: ___E431) -> ___E431 // single-payload enum with a function
{ lastCalledGlobal = #function; return param }
enum ___E431 { case a(() -> ()) }

func ___432(_ param: ___E432) -> ___E432 // single-payload enum with an optional function
{ lastCalledGlobal = #function; return param }
enum ___E432 { case a((() -> ()?)) }

func ___433(_ param: ___E433) -> ___E433 // multi-payload enum with an optional function
{ lastCalledGlobal = #function; return param }
enum ___E433 { case a((() -> ()?)), b((Int) -> (Double)) }

func ___434(_ param: ___E434) -> ___E434 // enum with functions returning functions
{ lastCalledGlobal = #function; return param }
enum ___E434 { case a(((String) -> () -> (Double))); case b((String) -> () -> (___E434)); case c(() -> (() -> Double?)?) }

func ___435(_ param: ___E435) -> ___E435 // enum with functions returning that enum
{ lastCalledGlobal = #function; return param }
enum ___E435 { case a((String) -> ___E434); case b((String) -> () -> ___E434); case c(() -> (() -> ___E434)?) }


// MARK: - Inout params 500-700

func ___500(_ param: inout Int) -> Int
{ lastCalledGlobal = #function; return param }

func ___501(_ intParam: inout Int, _ stringParam: inout String, _ genericParam: inout [String: AnyObject], _ objectParam: inout ___C501, _ unloadableParam: inout ___S501)
{ lastCalledGlobal = #function }
class ___C501 {}
struct ___S501 { weak var c: ___C501? }

// MARK: - Enums 750

enum ___E750 { case a }
func ___750(_ param: ___E750) -> ___E750 // singleton enum
{ lastCalledGlobal = #function; return param }

enum ___E751 { case a(String) }
func ___751(_ param: ___E751) -> ___E751 // singleton payload enum
{ lastCalledGlobal = #function; return param }

enum ___E752: Int8 { case a = 20 }
func ___752(_ param: ___E752) -> ___E752 // singleton C-style enum
{ lastCalledGlobal = #function; return param }

indirect enum ___E753: Int16 { case a = 30 }
func ___753(_ param: ___E753) -> ___E753 // indirect singleton C-style enum
{ lastCalledGlobal = #function; return param }

enum ___E754 { case a, b }
func ___754(_ param: ___E754) -> ___E754 // enum without payload cases
{ lastCalledGlobal = #function; return param }

enum ___E755: Int32 { case a = 20, b = 50 }
func ___755(_ param: ___E755) -> ___E755 // C-style enum without payload cases
{ lastCalledGlobal = #function; return param }

indirect enum ___E756 { case a, b }
func ___756(_ param: ___E756) -> ___E756 // indirect enum without payload cases
{ lastCalledGlobal = #function; return param }

indirect enum ___E757: Int8 { case a = 30, b = 60 }
func ___757(_ param: ___E757) -> ___E757 // indirect C-style enum
{ lastCalledGlobal = #function; return param }

enum ___E758 { case a, b(UnsafeRawPointer) }
func ___758(_ param: ___E758) -> ___E758 // single payload enum
{ lastCalledGlobal = #function; return param }

enum ___E759 { case a; indirect case b(Float); case c }
func ___759(_ param: ___E759) -> ___E759 // single payload enum with indirect cases
{ lastCalledGlobal = #function; return param }

indirect enum ___E760 { case a, b(UnicodeScalar), c }
func ___760(_ param: ___E760) -> ___E760 // single payload indirect enum
{ lastCalledGlobal = #function; return param }

enum ___E761 { case a, b(UnsafeRawPointer), c(Int8, Double, Int16) }
func ___761(_ param: ___E761) -> ___E761 // multi-payload enum
{ lastCalledGlobal = #function; return param }

enum ___E762 { case a; indirect case b(Character); indirect case c(Float, String, Double); case d }
func ___762(_ param: ___E762) -> ___E762 // multi-payload enum with indirect cases
{ lastCalledGlobal = #function; return param }

indirect enum ___E763 { case a, b(Int16, Int16), c(Int16, Int32, Int64) }
func ___763(_ param: ___E763) -> ___E763 // multi-payload indirect enum
{ lastCalledGlobal = #function; return param }

enum ___E764 { case a, b(Void) }
func ___764(_ param: ___E764) -> ___E764 // single-payload enum with a void payload case
{ lastCalledGlobal = #function; return param }

enum ___E765 { case a, b(Void), c(Int16, Int64, Int32) }
func ___765(_ param: ___E765) -> ___E765 // multi-payload enum with a void payload case
{ lastCalledGlobal = #function; return param }

enum ___E766 { indirect case b(Int32); indirect case c(Int16, Int32, Int64) }
func ___766(_ param: ___E766) -> ___E766 // multi-payload enum with all indirect cases
{ lastCalledGlobal = #function; return param }

indirect enum ___E767 { case b(Int); case c(Int16, Int32, Int64) }
func ___767(_ param: ___E767) -> ___E767 // indirect multi-payload enum (same as above, but indirect as a whole)
{ lastCalledGlobal = #function; return param }

struct ___S768 {}
func ___768(_ param: ___S768?) -> ___S768? // single-payload enum with empty payload
{ lastCalledGlobal = #function; return param }

struct ___S769 {}
enum ___E769 { case a, b(___S769), c(Int16, Int32, Int64) }
func ___769(_ param: ___E769) -> ___E769 // multi-payload enum with an empty payload case
{ lastCalledGlobal = #function; return param }

struct ___S770 {}
enum ___E770 { case a, b(___S770), c(Int16, Int32, Int64) }
func ___770(_ param: ___E770) -> ___E770 // multi-payload enum with only empty payload cases
{ lastCalledGlobal = #function; return param }

enum ___E771 { case a(Int8, Int); case b }
func ___771(_ param: ___E771) -> ___E771 // single-payload enum with spare bits (but no xi, and so it allocates a discriminator byte!) ...
{ lastCalledGlobal = #function; return param }

enum ___E772 { case a(Int8, Int16); case b }
func ___772(_ param: ___E772) -> ___E772 // ... and the same enum but fitting into a quad together with the discriminator
{ lastCalledGlobal = #function; return param }

enum ___E773 { case a(Int32, Int8), b }
func ___773(_ param: ___E773) -> ___E773 // enum with a payload that's not a power of 2 size
{ return param }

enum ___E774 { case a(Int8, Double) }
func ___774(_ param: ___E774) -> ___E774 // single-payload enum without no-payload cases
{ return param }

struct ___C775 {
  let a: Int8
  struct Inner {
    let b: Int8
    let c: Int64
  }
  let b: Inner
}
enum ___E775 {
    case a(___C775)
    case b
}
func ___775(_ param: ___E775) -> ___E775 // single-payload enum with nested struct as a payload
{ return param }

struct ___C776 {
  let a: Int8
  struct Inner {
    let b: Int8
    let c: Int64
  }
  let b: Inner
}
enum ___E776 {
    case a(___C776)
}
func ___776(_ param: ___E776) -> ___E776 // same as above, but without a no-payload case
{ return param }


// MARK: - Returns

func ___850() -> (Int8, (Int8, Int8))
{ lastCalledGlobal = #function; return (0, (0, 0)) }

func ___851() -> (Int8, (), (Int8, Int8))
{ lastCalledGlobal = #function; return (0, (), (0, 0)) }

func ___852() -> (Int, (Int16), (Int, Int))
{ lastCalledGlobal = #function; return (0, (0), (0, 0)) }

func ___853() -> (Int, (Int16), (Int, Int), Int8)
{ lastCalledGlobal = #function; return (0, (0), (0, 0), 0) }

func ___854() -> (Int, (Float), (Int, Int))
{ lastCalledGlobal = #function; return (0, (0), (0, 0)) }

func ___855() -> (Double, (Float), (Float, Double))
{ lastCalledGlobal = #function; return (0, (0), (0, 0)) }

func ___856() -> (Int, (Float), (Double, Int), Int8)
{ lastCalledGlobal = #function; return (0, (0), (0, 0), 0) }

func ___857() -> AnAddressOnlyStruct
{ lastCalledGlobal = #function; return AnAddressOnlyStruct(weakVar: nil) }

func ___858() -> (AnAddressOnlyStruct, AnAddressOnlyStruct)
{ lastCalledGlobal = #function; return (AnAddressOnlyStruct(weakVar: nil), AnAddressOnlyStruct(weakVar: nil)) }

func ___859() -> (AnAddressOnlyStruct, AnAddressOnlyStruct, AnAddressOnlyStruct, AnAddressOnlyStruct, AnAddressOnlyStruct)
{ lastCalledGlobal = #function; return (AnAddressOnlyStruct(weakVar: nil), AnAddressOnlyStruct(weakVar: nil), AnAddressOnlyStruct(weakVar: nil), AnAddressOnlyStruct(weakVar: nil), AnAddressOnlyStruct(weakVar: nil)) }

func ___860() -> (AnAddressOnlyStruct, (Int, AnAddressOnlyStruct), Float)
{ lastCalledGlobal = #function; return (AnAddressOnlyStruct(weakVar: nil), (0, AnAddressOnlyStruct(weakVar: nil)), 0) }

func ___861() -> (AnAddressOnlyStruct, Int, Double, Float, Int, Int) // sret for direct, because one formally indirect
{ lastCalledGlobal = #function; return (AnAddressOnlyStruct(weakVar: nil), 0, 0, 0, 0, 0) }

func ___862() -> (AnAddressOnlyStruct, (Int, AnAddressOnlyStruct), (Double, Float, Int, Int)) // no sret, because two indirect
{ lastCalledGlobal = #function; return (AnAddressOnlyStruct(weakVar: nil), (0, AnAddressOnlyStruct(weakVar: nil)), (0, 0, 0, 0)) }

// TODO: Generic enums,

// MARK: - Bound generic params (1000-2000)

func ___1000(_ param: [String: Float]) -> [[Int8: Float]]
{ lastCalledGlobal = #function; return [[:]] }

struct ___S1001<T> { let a: Int }
func ___1001(_ param: ___S1001<Double>) -> ___S1001<Double>
{ lastCalledGlobal = #function; return param }

struct ___S1002<T> { let a: T }
func ___1002(_ param: ___S1002<Double>) -> ___S1002<Double>
{ lastCalledGlobal = #function; return param }

