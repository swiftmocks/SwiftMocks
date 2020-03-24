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
//
// This source file contains code developed by Swift open source project,
// licensed under Apache License v2.0 with Runtime Library Exception. For
// licensing information, see https://swift.org/LICENSE.txt

import Foundation

/// Transient wrapper for SIL-level argument conventions. This abstraction helps handle the transition from canonical SIL conventions to lowered SIL conventions.
///
/// In Interceptor, we only use it during lowered address stage, so all code dealing with `useLoweredAddresses == false` has been removed.
struct SILFunctionConventions {
    let silConv: SILModuleConventions = SILModuleConventions()
    let funcTy: SILFunctionType

    init(_ funcTy: SILFunctionType) {
        self.funcTy = funcTy
    }

    var useLoweredAddresses: Bool {
        true
    }

    var silResultType: SILType {
        funcTy.directFormalResultsType
    }

    var numberOfIndirectSILResults: Int {
        funcTy.numberOfIndirectFormalResults
    }

    var indirectSILResults: [SILResultInfo] {
        funcTy.indirectFormalResults
    }

    var indirectSILResultTypes: [SILType] {
        indirectSILResults.map { getSILType($0) }
    }

    func getSILType(_ param: SILParameterInfo) -> SILType {
        silConv.getSILType(param)
    }

    func getSILType(_ result: SILResultInfo) -> SILType {
        silConv.getSILType(result)
    }
}

/// Transient wrapper for SILParameterInfo and SILResultInfo conventions. This abstraction helps handle the transition from canonical SIL conventions to lowered SIL conventions.
struct SILModuleConventions {
    let loweredAddresses: Bool = true

    func getSILType(_ param: SILParameterInfo) -> SILType {
        Self.getSILParamType(param, loweredAddresses)
    }

    func getSILType(_ param: SILResultInfo) -> SILType {
        Self.getSILResultType(param, loweredAddresses)
    }

    static func getSILParamType(_ param: SILParameterInfo, _ loweredAddresses: Bool) -> SILType {
        isIndirectSILParam(param, loweredAddresses) ? SILType.getPrimitiveAddressType(param.type) : SILType.getPrimitiveObjectType(param.type)
    }

    static func getSILResultType(_ result: SILResultInfo, _ loweredAddresses: Bool) -> SILType {
        isIndirectSILResult(result, loweredAddresses) ? SILType.getPrimitiveAddressType(result.type) : SILType.getPrimitiveObjectType(result.type)
    }

    private static func isIndirectSILResult(_ result: SILResultInfo, _ loweredAddresses: Bool) -> Bool {
        switch result.convention {
        case .indirect:
            return loweredAddresses || result.type~>.isOpenedExistentialWithError
        case .owned, .unowned, .unownedInnerPointer, .autoreleased:
            return false
        }
    }

    private static func isIndirectSILParam(_ param: SILParameterInfo, _ loweredAddresses: Bool) -> Bool {
        switch param.convention {
        case .directUnowned, .directGuaranteed, .directOwned:
            return false

        case .indirectIn, .indirectInConstant, .indirectInGuaranteed:
            return loweredAddresses || param.type~>.isOpenedExistentialWithError

        case .indirectInout, .indirectInoutAliasable:
            return true
        }
    }
}
