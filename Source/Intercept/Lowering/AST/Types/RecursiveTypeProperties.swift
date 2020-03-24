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

/// Various properties of types that are primarily defined recursively on structural types.
struct RecursiveTypeProperties {
    enum Property: UInt {
        /// This type expression contains a TypeVariableType.
        case hasTypeVariable

        /// This type expression contains a context-dependent archetype, either a PrimaryArchetypeType or OpenedArchetypeType.
        case hasArchetype

        /// This type expression contains a GenericTypeParamType.
        case hasTypeParameter

        /// This type expression contains an UnresolvedType.
        case hasUnresolvedType

        /// Whether this type expression contains an unbound generic type.
        case hasUnboundGeneric

        /// This type expression contains an LValueType other than as a function input, and can be loaded to convert to an rvalue.
        case isLValue

        /// This type expression contains an opened existential ArchetypeType.
        case hasOpenedExistential

        /// This type expression contains a DynamicSelf type.
        case hasDynamicSelf

        /// This type contains an Error type.
        case hasError

        /// This type contains a DependentMemberType.
        case hasDependentMember

        /// This type contains an OpaqueTypeArchetype.
        case hasOpaqueArchetype

        static func |(lhs: Property, rhs: Property) -> RecursiveTypeProperties {
            RecursiveTypeProperties(bits: lhs.rawValue | rhs.rawValue)
        }
    }

    private let bits: UInt

    init(bits: UInt = 0) {
        self.bits = bits
    }

    init(property: Property) {
        self.bits = property.rawValue
    }

    /// Does a type with these properties structurally contain a type variable?
    var hasTypeVariable: Bool {
        bits & Property.hasTypeVariable.rawValue != 0
    }

    /// Does a type with these properties structurally contain a context-dependent archetype (that is, a Primary- or OpenedArchetype)?
    var hasArchetype: Bool {
        bits & Property.hasArchetype.rawValue != 0
    }

    /// Does a type with these properties structurally contain an archetype from an opaque type declaration?
    var hasOpaqueArchetype: Bool {
        bits & Property.hasOpaqueArchetype.rawValue != 0
    }

    /// Does a type with these properties have a type parameter somewhere in it?
    var hasTypeParameter: Bool {
        bits & Property.hasTypeParameter.rawValue != 0
    }

    /// Does a type with these properties have an unresolved type somewhere in it?
    var hasUnresolvedType: Bool {
        bits & Property.hasUnresolvedType.rawValue != 0
    }

    /// Is a type with these properties an lvalue?
    var isLValue: Bool {
        bits & Property.isLValue.rawValue != 0
    }

    /// Does this type contain an error?
    var hasError: Bool {
        bits & Property.hasError.rawValue != 0
    }

    /// Does this type contain a dependent member type, possibly with a non-type parameter base, such as a type variable or concrete type?
    var hasDependentMember: Bool {
        bits & Property.hasDependentMember.rawValue != 0
    }

    /// Does a type with these properties structurally contain an archetype?
    var hasOpenedExistential: Bool {
        bits & Property.hasOpenedExistential.rawValue != 0
    }

    /// Does a type with these properties structurally contain a reference to DynamicSelf?
    var hasDynamicSelf: Bool {
        bits & Property.hasDynamicSelf.rawValue != 0
    }

    /// Does a type with these properties structurally contain an unbound generic type?
    var hasUnboundGeneric: Bool {
        bits & Property.hasUnboundGeneric.rawValue != 0
    }

    var removingHasTypeParameter: RecursiveTypeProperties {
        RecursiveTypeProperties(bits: bits & ~Property.hasTypeParameter.rawValue)
    }

    var removingHasDependentMember: RecursiveTypeProperties {
        RecursiveTypeProperties(bits: bits & ~Property.hasDependentMember.rawValue)
    }

    static func |(lhs: RecursiveTypeProperties, rhs: RecursiveTypeProperties) -> RecursiveTypeProperties {
        RecursiveTypeProperties(bits: lhs.bits | rhs.bits)
    }

    static func |=(lhs: inout RecursiveTypeProperties, rhs: RecursiveTypeProperties) {
        lhs = RecursiveTypeProperties(bits: lhs.bits | rhs.bits)
    }

    static func &(lhs: RecursiveTypeProperties, rhs: RecursiveTypeProperties) -> RecursiveTypeProperties {
        RecursiveTypeProperties(bits: lhs.bits & rhs.bits)
    }

    static func &=(lhs: inout RecursiveTypeProperties, rhs: RecursiveTypeProperties) {
        lhs = RecursiveTypeProperties(bits: lhs.bits & rhs.bits)
    }
}

/// The result of a type trait check.
enum TypeTraitResult {
    /// The type cannot have the trait.
    case isNot
    /// The generic type can be bound to a type that has the trait.
    case canBe
    /// The type has the trait irrespective of generic substitutions.
    case `is`
}

/// Specifies which normally-unsafe type mismatches should be accepted when
/// checking overrides.
enum TypeMatchFlags: UInt {
    /// Allow properly-covariant overrides.
    case allowOverride = 1
    /// Allow a parameter with IUO type to be overridden by a parameter with non- optional type.
    case allowNonOptionalForIUOParam = 2
    /// Allow any mismatches of Optional or ImplicitlyUnwrappedOptional at the top level of a type.
    /// This includes function parameters and result types as well as tuple elements, but excludes generic parameters.
    case allowTopLevelOptionalMismatch = 4
    /// Allow any ABI-compatible types to be considered matching.
    case allowABICompatible = 8
    /// Allow escaping function parameters to override optional non-escaping ones.
    /// This is necessary because Objective-C allows optional function paramaters to be non-escaping, but Swift currently does not.
    case ignoreNonEscapingForOptionalFunctionParam = 16
    /// Allow compatible opaque archetypes.
    case allowCompatibleOpaqueTypeArchetypes = 32
}
