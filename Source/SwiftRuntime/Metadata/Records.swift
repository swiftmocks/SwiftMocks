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

public enum FieldDescriptorKind : UInt16 {
    // Swift nominal types.
    case `struct` = 0
    case `class`
    case `enum`

    // Fixed-size multi-payload enums have a special descriptor format that encodes spare bits. FIX_apple_ME: Actually implement this. For now, a descriptor with this kind just means we also have a builtin descriptor from which we get the size and alignment.
    case multiPayloadEnum

    // A Swift opaque protocol. There are no fields, just a record for the type itself.
    case `protocol`

    // A Swift class-bound protocol.
    case classProtocol

    // An Objective-C protocol, which may be imported or defined in Swift.
    case objCProtocol

    // An Objective-C class, which may be imported or defined in Swift. In the former case, field type metadata is not emitted, and must be obtained from the Objective-C runtime.
    case objCClass
}

// Field records describe the type of a single stored property or case member of a class, struct or enum.
public struct FieldRecord: PointeeFacade {
    public struct Pointee {
        var flags: UInt32
        var mangledTypeName: TargetRelativeDirectPointer
        var fieldName: TargetRelativeDirectPointer
    }
    public var pointer: RawPointer

    // Is this an indirect enum case?
    private let IsIndirectCase: UInt32 = 0x1

    // Is this a mutable `var` property?
    private let IsVar: UInt32 = 0x2

    public var isIndirectEnumCase: Bool {
        pointee.flags & IsIndirectCase == IsIndirectCase
    }

    public var isVar: Bool {
        pointee.flags & IsVar == IsVar
    }

    public var name: String {
        String(relativeDirectPointer: &typedPointer.pointee.fieldName)
    }

    public var mangledTypeName: Pointer<CChar>? { // nil for enums
        Pointer<CChar>(relative: &typedPointer.pointee.mangledTypeName)
    }
}

public extension FieldRecord {
    func resolveType(contextDescriptor: ContextDescriptor?, genericArguments: BufferPointer<RawPointer>?) -> Any.Type? {
        guard let mangledTypeName = mangledTypeName else { return nil }
        return Runtime.getTypeByMangledNameInContext(name: mangledTypeName, contextDescriptor: contextDescriptor, genericArguments: genericArguments)
    }

    func resolveTypeAndReferenceOwnership(contextDescriptor: ContextDescriptor?, genericArguments: BufferPointer<RawPointer>?) -> (type: Any.Type, ownership: ReferenceOwnership)? {
        guard let mangledTypeName = mangledTypeName else { return nil }
        guard let type = Runtime.getTypeByMangledNameInContext(name: mangledTypeName, contextDescriptor: contextDescriptor, genericArguments: genericArguments) else {
            fatalError("getTypeByMangledNameInContext() returned nil for a non-nil mangled type name for a field. Looks like a bug. The field is:\n\(self)")
        }
        let demangled: Node
        do {
            demangled = try Mangle.demangleType(mangledName: mangledTypeName)
        } catch {
            fatalError("Failed to demangle type. Looks like a bug. The error was: \(error). The field is:\n\(self)")
        }
        guard demangled.kind == .Type else {
            fatalError("Demangling a type resulted in a non-type node. Looks like a bug. The field is:\n\(self)")
        }
        let ownership: ReferenceOwnership
        if demangled.child(ofKind: .Weak) != nil {
            ownership = .weak
        } else if demangled.child(ofKind: .Unowned) != nil {
            ownership = .unowned
        } else if demangled.child(ofKind: .Unmanaged) != nil {
            ownership = .unmanaged
        } else {
            ownership = .strong
        }
        return (type, ownership)
    }
}

public struct FieldDescriptor: PointeeFacade {
    public struct Pointee {
        var mangledTypeName: TargetRelativeDirectPointer
        var superclass: TargetRelativeDirectPointer
        var kind: UInt16
        var fieldRecordSize: UInt16
        var numberOfFields: UInt32
    }
    public let pointer: RawPointer

    public var superclassMangledTypeName: Pointer<CChar>? { Pointer(relative: &typedPointer.pointee.superclass) }

    public var kind: FieldDescriptorKind { FieldDescriptorKind(rawValue: pointee.kind)! }

    public var fieldRecordSize: UInt16 { pointee.fieldRecordSize }

    public var numberOfFields: UInt32 { pointee.numberOfFields }

    public var mangledTypeName: Pointer<CChar>? { Pointer(relative: &typedPointer.pointee.mangledTypeName) }
}

extension FieldDescriptor {
    public func resolveSuperclass(contextDescriptor: ContextDescriptor?, genericArguments: BufferPointer<RawPointer>?) -> Any.Type? {
        guard let superclassMangledTypeName = superclassMangledTypeName else { return nil }
        return Runtime.getTypeByMangledNameInContext(name: superclassMangledTypeName, contextDescriptor: contextDescriptor, genericArguments: genericArguments)
    }

    public func resolveType(contextDescriptor: ContextDescriptor?, genericArguments: BufferPointer<RawPointer>?) -> Any.Type? {
        guard let mangledTypeName = mangledTypeName else { return nil }
        return Runtime.getTypeByMangledNameInContext(name: mangledTypeName, contextDescriptor: contextDescriptor, genericArguments: genericArguments)
    }
}
