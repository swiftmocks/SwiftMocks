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

class TypeDecl: ValueDecl {
    /// The type of this declaration's values. For the type of the declaration itself, use getInterfaceType(), which returns a metatype.
    var declaredInterfaceType: AType {
        LoweringError.abstract()
    }
}

class GenericTypeDecl: TypeDecl {}

class NominalTypeDecl: GenericTypeDecl {
    let declaredInterfaceTy: AType

    override var declaredInterfaceType: AType {
        declaredInterfaceTy
    }

    init(type: AType) {
        self.declaredInterfaceTy = type
        super.init(context: .topLevel /* not necessarily, but we can't work with private or local types, so will do for now */)
    }
}

/// This represents a type extension containing methods associated with the type. This is not a `ValueDecl` and has no `Type` because there are no runtime values of the Extension's type.
class ExtensionTypeDecl: Decl {
    let extendedNominal: AType

    init(extendedNominal: AType) {
        self.extendedNominal = extendedNominal
        super.init(context: .topLevel)
    }
}

class StructDecl: NominalTypeDecl {}

class ClassDecl: NominalTypeDecl {}

class EnumDecl: NominalTypeDecl {}

class ProtocolDecl: NominalTypeDecl {
    let isObjC = false

    var proto: ProtocolType {
        super.declaredInterfaceType as! ProtocolType
    }

    init(proto: ProtocolType) {
        super.init(type: proto)
    }
}
