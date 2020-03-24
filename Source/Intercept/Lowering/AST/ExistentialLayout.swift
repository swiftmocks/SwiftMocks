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

struct ExistentialLayout {
    enum Kind {
        case `class`
        case error
        case opaque
    }

    /// The explicit superclass constraint, if any.
    let explicitSuperclass: AType?
    /// Whether the existential contains an explicit '& AnyObject' constraint.
    let hasExplicitAnyObject: Bool
    /// Whether any protocol members are non-@objc.
    let containsNonObjCProtocol: Bool
    /// Does this existential consist of an Error protocol only with no other constraints?
    let isErrorExistential: Bool

    let requiresClass: Bool

    let numberOfProtocols: Int

    let kind: Kind
    let isAnyObject: Bool

    var superclass: AType? {
        if let explicitSuperclass = explicitSuperclass {
            return explicitSuperclass
        }
        // FIXME protocol superclass code needs to be reviewed and tested (and written, because it's missing here)
        return nil
    }

    var isObjC: Bool {
        (explicitSuperclass != nil || hasExplicitAnyObject || numberOfProtocols > 0) && !containsNonObjCProtocol
    }

    init(proto: ProtocolType) {
        hasExplicitAnyObject = false
        containsNonObjCProtocol = !proto.isObjC
        numberOfProtocols = proto.numberOfProtocols
        explicitSuperclass = nil
        requiresClass = proto.requiresClass
        switch proto.representation {
        case .opaque:
            kind = .opaque
        case .class:
            kind = .class
        case .error:
            kind = .error
        }
        isAnyObject = hasExplicitAnyObject && proto.numberOfProtocols == 0 /* && explicitSuperclass == nil */
        isErrorExistential = proto.representation == .error
    }

    init(protoComp: ProtocolCompositionType) {
        precondition(protoComp.numberOfProtocols > 1)
        hasExplicitAnyObject = protoComp.hasExplicitAnyObject
        containsNonObjCProtocol = !protoComp.isObjC
        numberOfProtocols = protoComp.numberOfProtocols
        explicitSuperclass = protoComp.explicitSuperclass
        requiresClass = protoComp.requiresClass
        switch protoComp.existentialMetadata.representation {
        case .opaque:
            kind = .opaque
        case .class:
            kind = .class
        case .error:
            kind = .error
        }
        isAnyObject = hasExplicitAnyObject && protoComp.existentialMetadata.numberOfProtocols == 0 && protoComp.explicitSuperclass == nil
        isErrorExistential = protoComp.existentialMetadata.representation == .error
    }

    func protocolRequiresWitnessTable(index: Int) -> Bool {
        true // ObjC would return false
    }
}
