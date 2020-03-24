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

extension ParameterConvention: CustomStringConvertible {
    var description: String {
        switch self {
        case .indirectIn:
            return "@in"
        case .indirectInConstant:
            return "@in_constant"
        case .indirectInGuaranteed:
            return "@in_guaranteed"
        case .indirectInout:
            return "@inout"
        case .indirectInoutAliasable:
            return "@inout_aliasable"
        case .directOwned:
            return "@owned"
        case .directUnowned:
            return "" // default, unmarked
        case .directGuaranteed:
            return "@guaranteed"
        }
    }
}

extension SILParameterInfo: CustomStringConvertible {
    var description: String {
        let convention = self.convention.description
        return convention.isEmpty ? type.description : "\(convention) \(type)"
    }
}

extension ResultConvention: CustomStringConvertible {
    var description: String {
        switch self {
        case .indirect:
            return "@out"
        case .owned:
            return "@owned"
        case .unowned:
            return ""
        case .unownedInnerPointer:
            return "@unowned_inner_pointer"
        case .autoreleased:
            return "@autoreleased"
        }
    }
}

extension SILResultInfo: CustomStringConvertible {
    var description: String {
        let convention = self.convention.description
        return convention.isEmpty ? type.description : "\(convention) \(type)"
    }
}

extension SILFunctionTypeRepresentation: CustomStringConvertible {
    var description: String {
        switch self {
        case .thick:
            return ""
        case .thin:
            return "thin"
        case .method:
            return "method"
        case .witnessMethod:
            return "witness_method"
        case .closure:
            return "closure"
        }
    }
}

extension SILCoroutineKind: CustomStringConvertible {
    var description: String {
        switch self {
        case .none:
            return ""
        case .yieldOnce:
            return "@yield_once "
        case .yieldMany:
            return "@yield_many "
        }
    }
}

extension SILFunctionType: CustomStringConvertible {
    var description: String {
        var ret = ""
        if isCoroutine {
            ret += coroutineKind.description
        }
        if representation != .thick {
            if representation == .witnessMethod, let witnessMethodConformance = witnessMethodConformance {
                ret += "@convention(\(representation): \(witnessMethodConformance.proto.proto.description)) "
            } else {
                ret += "@convention(\(representation)) "
            }
        }
        if extInfo.isPseudogeneric {
            ret += "@pseudogeneric "
        }
        if extInfo.isNoEscape {
            ret += "@noescape "
        }

        switch calleeConvention {
        case .directUnowned:
            break
        case .directOwned:
          ret += "@callee_owned "
        case .directGuaranteed:
          ret += "@callee_guaranteed "
        default:
            LoweringError.unreachable("callee convention cannot be indirect")
        }

        if let sig = genericSig {
            ret += "\(sig) "
        }

        ret += "(" + parameters.map { $0.description }.joined(separator: ", ") + ")"

        var resultsDescriptions = [String]()
        if coroutineKind == .none {
            resultsDescriptions = results.map { $0.description }
            if let errorResult = errorResult {
                resultsDescriptions.append("@error \(errorResult.type)") // error is implicitly @owned, so no need to print that
            }
        } else {
            resultsDescriptions = yields.map { "@yields \($0.description)" }
        }
        if resultsDescriptions.count == 1 {
            ret += " -> " + resultsDescriptions[0]
        } else {
            ret += " -> (" + resultsDescriptions.joined(separator: ", ") + ")"
        }
        return ret
    }
}

extension SILFunctionType: CustomDebugStringConvertible {
    var debugDescription: String {
        "SILFunctionType"
            .appending("genericSig", genericSig)
            .appending("extInfo", extInfo)
            .appending("calleeConvention", calleeConvention)
            .appending("coroutineKind", coroutineKind)
            .appending("parameters", parameters)
            .appending("yields", yields)
            .appending("anyResults", anyResults)
            .appending("errorResult", errorResult)
            .appending("witnessMethodConformance", witnessMethodConformance)
    }
}
