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

protocol ___P3000 {
    func ___3000()
}
class ___C3000: ___P3000 {
    func ___3000() {}
}

protocol ___P3001: AnyObject {
    func ___3001()
}
class ___C3001: ___P3001 {
    func ___3001() {}
}

protocol ___P3002_Base: AnyObject {}
protocol ___P3002: ___P3002_Base {
    func ___3002()
}
class ___C3002: ___P3002 {
    func ___3002() {}
}

class ___P3003_Base {}
protocol ___P3003: ___P3003_Base {
    func ___3003()
}
class ___C3003: ___P3003_Base, ___P3003 {
    func ___3003() {}
}

protocol ___P3010 {
    static func ___3010()
}
class ___C3010: ___P3010 {
    static func ___3010() {}
}

protocol ___P3011 {
    static func ___3011()
}
struct ___S3011: ___P3011 {
    static func ___3011() {}
}

protocol ___P3012 {
    static func ___3012(param: String) -> String
}
enum ___E3012: ___P3012 {
    static func ___3012(param: String) -> String { param }
}

protocol ___P3013 {
    var ___3013: String { get set }
}
struct ___S3013: ___P3013 {
    var ___3013: String {
        didSet {}
    }
}

protocol ___P3014 {
    static var ___3014: String { get set }
}
class ___C3014: ___P3014 {
    static var ___3014: String = "" {
        didSet {}
    }
}

protocol ___P3015_Base {
    func ___3015(_ param: Double) -> String
}
protocol ___P3015: ___P3015_Base {}
class ___C3015: ___P3015 {
    func ___3015(_ param: Double) -> String { "" }
}

protocol ___P3016_Base {
    var ___3016: String { get set }
}
protocol ___P3016: ___P3016_Base {}
class ___C3016: ___P3016 {
    var ___3016: String = "" { didSet {} }
}

protocol ___P3017_Base {
    static var ___3017: String { get set }
}
protocol ___P3017: ___P3017_Base {}
class ___C3017: ___P3017 {
    static var ___3017: String = "" { didSet {} }
}

protocol ___P3019 {
    var ___3019: String { get set }
}
class ___C3019: ___P3019 {
    var ___3019: String = "" { didSet {} }
}

// MARK: - Default implementations

protocol ___P3100 {
    func ___3100() -> Float
}
extension ___P3100 {
    func ___3100() -> Float { 0.0 }
}
class ___C3100: ___P3100 {}

protocol ___P3101 {}
extension ___P3101 {
    func ___3101() -> Double { 0.0 }
}
class ___C3101: ___P3101 {}

protocol ___P3102 {}
extension ___P3102 {
    func ___3102(_ p1: Double, _ slf: Self) -> Double { 0.0 }
}
class ___C3102: ___P3102 {}

