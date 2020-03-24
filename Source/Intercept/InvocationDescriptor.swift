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

/// Descriptor containing all the bits necessary to decode and work with an intercepted function invocation
struct InvocationDescriptor {
    private let constant: SILDeclRef
    let mangledName: String

    let loweredInterfaceType: AnyFunctionType
    let silFunctionType: SILFunctionType
    let irSignature: IRSignature
    let formalParameterRanges: [SILParameterRange]

    init(mangledName: String, genericTypeParamReplacement: AType? = nil) throws {
        let silModule = SILModule.theModule

        var mangledName = mangledName
        if mangledName.hasPrefix("_") {
            mangledName.removeFirst()
        }
        if !mangledName.hasPrefix("$") {
            mangledName = "$" + mangledName
        }
        constant = try SILDeclRef.from(mangledName: mangledName)

        let constantInfo = try silModule.types.getConstantInfo(constant: constant)
        formalParameterRanges = constantInfo.silParameterRanges
        loweredInterfaceType = constantInfo.loweredType

        var silFunctionType = constantInfo.silFnType
        if let sig = silFunctionType.genericSig, silFunctionType.selfInstanceType.type == GenericTypeParamType.tau00 {
            let type = sig.requirements[0].second! // FIXME: why force unwrap? // FIXME: we do the same in InvocationHandler - maybe do it once?
            let metadata = TypeFactory.convert(type)

            let subst = genericTypeParamReplacement ?? TypeFactory.from(metadata: metadata) // FIXME: isn't it a round trip?
            silFunctionType = silFunctionType.replacingTau00(with: subst, generic: genericTypeParamReplacement == nil)
        }
        self.silFunctionType = silFunctionType

        irSignature = silModule.igm.getSignature(fn: silFunctionType)

        self.mangledName = mangledName
    }
}

extension InvocationDescriptor: CustomStringConvertible {
    var description: String {
        "InvocationDescriptor(name: \(mangledName), silFnType: \(silFunctionType), irSignature: \(irSignature)"
    }
}
