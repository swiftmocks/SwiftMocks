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

// A simple implementation of LLVM types, without arbitrarily-sized ints, packed structs and everything else that we don't need
enum LLVMType: Hashable {
    case void
    case i1
    case i8
    case i16
    case i32
    case i64
    case float
    case double
    case x86_fp80
    indirect case array(LLVMType, Int)
    indirect case `struct`([LLVMType])
    case pointer

    var isFloatingPoint: Bool {
        switch self {
        case .float, .double, .x86_fp80: return true
        default: return false
        }
    }

    var isVector: Bool { false }

    var pointerTo: LLVMType {
        .pointer
    }

    static func getInteger(bitWidth: Int) -> LLVMType {
        // we don't support arbitrarily-sized ints
        switch bitWidth {
        case 1:
            return .i1
        case 8:
            return .i8
        case 16:
            return .i16
        case 32:
            return .i32
        case 64:
            return .i64
        default:
            LoweringError.notImplemented("LLVM i\(bitWidth)")
        }
    }

    var size: Int {
        switch self {
        case .void:
            return 0
        case .i1:
            return 1
        case .i8:
            return 1
        case .i16:
            return 2
        case .i32:
            return 4
        case .i64:
            return 8
        case .float:
            return 4
        case .double:
            return 8
        case .x86_fp80:
            LoweringError.notImplemented("x86_fp80")
        case let .array(type, size):
            return type.size * size
        case let .struct(types):
            var result = 0
            for type in types {
                result = result.aligned(type.alignment)
                result += type.size
            }
            return result
        case .pointer: return 8
        }
    }

    var alignment: Int {
        switch self {
        case .void: return 1
        case .i1: return 1
        case .i8: return 1
        case .i16: return 2
        case .i32: return 4
        case .i64: return 8
        case .float: return 4
        case .double: return 8
        case .x86_fp80: LoweringError.notImplemented("x86_fp80")
        case let .array(type, _): return type.alignment
        case let .struct(types): return types.max(by: { $0.alignment < $1.alignment })?.alignment ?? 1
        case .pointer: return 8
        }
    }
}

enum LLVMSwiftABIInfo {
    // this method accepts only primitive types; structs and arrays must have been split into chunks already
    static func shouldPassIndirectlyForSwift(_ types: [LLVMType], asReturnValue: Bool) -> Bool {
        var ints = 0
        var floats = 0
        for type in types {
            switch type {
            case .pointer:
                ints += 1
            case .float, .double:
                floats += 1
            case .i1, .i8, .i16, .i32, .i64:
                ints += 1
            case .void:
                break
            case .x86_fp80:
                LoweringError.notImplemented("x86_fp80")
            case .array:
                LoweringError.unreachable("LLVM array in \(#function)?")
            case .struct:
                LoweringError.unreachable("LLVM struct in \(#function)?")
            }
        }
        return ints + floats > 4 // for x86_64
    }

    static var isSwiftErrorInRegister: Bool { true } // only for x86_64
}

struct LLVMFunctionType: Hashable {
    let result: LLVMType
    let params: [LLVMType]
    let isVarArgs: Bool
}

enum LLVMCallingConvID: Hashable {
    case swift
}

struct LLVMAttributeList: Hashable {
    let functionAttributes: Set<String>
    let resultAttributes: Set<String>
    let parameterAttributes: [Int: Set<String>]

    var usesSret: Bool {
        parameterAttributes[0]?.contains("sret") == true
    }

    func attributes(for paramIndex: Int) -> Set<String> {
        parameterAttributes[paramIndex] ?? []
    }
}

