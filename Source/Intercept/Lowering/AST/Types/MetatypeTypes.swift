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

/// Describes the representation of a metatype.
///
/// There are several potential representations for metatypes within SIL, which are distinguished by the metatype representation. This enumeration captures the different representations. Some conversions between representations are possible: for example, one can convert a thin representation to a thick one (but not vice-versa), and different representations are required in different places.
enum MetatypeRepresentation {
    /// A thin metatype requires no runtime information, because the
    /// type itself provides no dynamic behavior.
    ///
    /// Struct and enum metatypes are thin, because dispatch to static
    /// struct and enum members is completely static.
    case thin
    /// A thick metatype refers to a complete metatype representation
    /// that allows introspection and dynamic dispatch.
    ///
    /// Thick metatypes are used for class and existential metatypes,
    /// which permit dynamic behavior.
    case thick
    /// An Objective-C metatype refers to an Objective-C class object.
    case objc
}

class AnyMetatypeType: AType, ATypeEquatable {
    let representation: MetatypeRepresentation?
    let instanceType: AType

    fileprivate init(kind: TypeKind, instanceType: AType, representation: MetatypeRepresentation?) {
        self.representation = representation
        self.instanceType = instanceType
        super.init(kind: kind)
    }

    func isEqual(to other: AType) -> Bool {
        guard let other = other as? AnyMetatypeType else {
            return false
        }
        return instanceType == other.instanceType && representation == other.representation
    }
}

class MetatypeType: AnyMetatypeType {
    let metadata: Metadata?

    private init(instanceType: AType, representation: MetatypeRepresentation?, metadata: MetatypeMetadata? = nil) {
        self.metadata = metadata
        super.init(kind: .metatype, instanceType: instanceType, representation: representation)
    }

    /// To be used only by `TypeFactory`
    static func _get(instanceType: AType, representation: MetatypeRepresentation? = nil) -> MetatypeType {
        MetatypeType(instanceType: instanceType, representation: representation)
    }

    /// To be used only by `TypeFactory`
    static func _with(type: MetatypeType, representation: MetatypeRepresentation) -> MetatypeType {
        MetatypeType(instanceType: type.instanceType, representation: representation, metadata: type.metadata as? MetatypeMetadata)
    }
}

class ExistentialMetatypeType: AnyMetatypeType {
    let metadata: Metadata?

    private init(instanceType: AType, representation: MetatypeRepresentation?, metadata: ExistentialMetatypeMetadata? = nil) {
        self.metadata = metadata
        super.init(kind: .existentialMetatype, instanceType: instanceType, representation: representation)
    }

    /// To be used only by `TypeFactory`
    static func _get(instanceType: AType, representation: MetatypeRepresentation? = nil) -> ExistentialMetatypeType {
        ExistentialMetatypeType(instanceType: instanceType, representation: representation)
    }

    /// To be used only by `TypeFactory`
    static func _with(type: ExistentialMetatypeType, representation: MetatypeRepresentation) -> ExistentialMetatypeType {
        ExistentialMetatypeType(instanceType: type.instanceType, representation: representation, metadata: type.metadata as? ExistentialMetatypeMetadata)
    }
}
