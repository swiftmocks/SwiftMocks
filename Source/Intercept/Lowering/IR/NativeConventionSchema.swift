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

struct NativeConventionSchema {
    let lowering: SwiftAggLowering
    let requiresIndirect: Bool
    let asArray: [LLVMType]

    var isEmpty: Bool { lowering.isEmpty }

    init(igm: IRGenModule, ti: TypeInfo, isResult: Bool) {
        var lowering = SwiftAggLowering()
        let requiresIndirect: Bool
        if let loadable = ti as? LoadableTypeInfo {
            loadable.addToAggLowering(igm: igm, lowering: &lowering, offset: 0)
            lowering.finish()
             // Should we pass indirectly according to the ABI?
            requiresIndirect = lowering.shouldPassIndirectly(asReturnValue: isResult)
        } else {
            lowering.finish()
            requiresIndirect = true
        }

        self.init(lowering: lowering, requiresIndirect: requiresIndirect)
    }

    private init(lowering: SwiftAggLowering, requiresIndirect: Bool) {
        self.lowering = lowering
        self.requiresIndirect = requiresIndirect

        var elts = [LLVMType]()
        lowering.enumerateComponents { _, _, type in
            elts.append(type)
        }
        self.asArray = elts
    }

    func getExpandedType(_ igm: IRGenModule) -> LLVMType {
        if isEmpty {
            return .void
        }

        var elts = [LLVMType]()
        lowering.enumerateComponents { _, _, type in
            elts.append(type)
        }
        if elts.count == 1 {
            return elts[0]
        }

        return .struct(elts.map { $0 })
    }

    static func forIndirectSILParameter() -> NativeConventionSchema {
        var lowering = SwiftAggLowering()
        lowering.addTypedData(.pointer, begin: 0)
        return NativeConventionSchema(lowering: lowering, requiresIndirect: false) // so it's a pointer, but passed (as far as native parameters are concerned) directly
    }
}
