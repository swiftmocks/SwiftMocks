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

class IRTypeConverter {
    private var cache = [AType: TypeInfo]()

    unowned var igm: IRGenModule!

    var currentGenericContext: GenericSignature? {
        genericContexts.popLast()
    }
    private var genericContexts = [GenericSignature]()

    lazy var nativeObjectTypeInfo: LoadableTypeInfo = {
        convertBuiltinNativeObject()
    }()

    lazy var rawPointerTypeInfo: LoadableTypeInfo = {
        getRawPointerTypeInfo()
    }()

    lazy var integerLiteralTypeInfo: LoadableTypeInfo = {
        getIntegerLiteralTypeInfo()
    }()

    func getCompleteTypeInfo(_ type: CanType) -> TypeInfo {
        getTypeEntry(type.type)
    }

    func getTypeEntry(_ canonicalTy: AType) -> TypeInfo {
        if let cached = cache[canonicalTy] {
            return cached
        }
        var contextTy = canonicalTy
        if contextTy.hasTypeParameter {
            // The type we got should be lowered, so lower it like a SILType.
            contextTy = { LoweringError.notImplemented("Generics") }()
        }

        let exemplarTy = getExemplarType(contextTy)
        assert(!exemplarTy.hasTypeParameter)

        if exemplarTy != canonicalTy {
            LoweringError.notImplemented("Generics")
        }

        let convertedTy = convertType(exemplarTy)

        cache[canonicalTy] = convertedTy

        return convertedTy
    }

    func pushGenericContext(_ sig: GenericSignature?) {
        guard let sig = sig else {
            return
        }
        genericContexts.append(sig)
    }

    func popGenericContext(_ sig: GenericSignature?) {
        guard sig != nil else {
            return
        }
        _ = genericContexts.popLast()
    }
}
