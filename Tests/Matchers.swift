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

import Nimble
@testable import SwiftMocks

func ==(lhs: Expectation<Any.Type>, rhs: Any.Type) {
    func _equal(_ expectedValue: Any.Type) -> Predicate<Any.Type> {
        return Predicate.define("equal <\(stringify(expectedValue))>") { actualExpression, msg in
            guard let actualValue = try actualExpression.evaluate() else { return PredicateResult(bool: false, message: msg) }
            return PredicateResult(bool: actualValue == expectedValue, message: msg)
        }
    }
    return lhs.to(_equal(rhs as Any.Type))
}

func ==(lhs: Expectation<IRSignature>, rhs: IRSignature) {
    func _equal(_ expectedValue: IRSignature) -> Predicate<IRSignature> {
            return Predicate.define("equal <\(stringify(expectedValue))>") { actualExpression, msg in
                guard let actualValue = try actualExpression.evaluate() else { return PredicateResult(bool: false, message: msg) }
                return PredicateResult(bool: actualValue.strippingNonEssentialAttributesAndMappings == expectedValue.strippingNonEssentialAttributesAndMappings, message: msg)
            }
        }
        return lhs.to(_equal(rhs as IRSignature))
}

func ~=<T: Equatable>(lhs: Expectation<Any>, rhs: T) {
    func _equal<T: Equatable>(_ expectedValue: T) -> Predicate<Any> {
        return Predicate.define("equal <\(stringify(expectedValue))>") { actualExpression, msg in
            guard let actualValue = try actualExpression.evaluate() else { return PredicateResult(bool: false, message: msg) }
            guard let castValue = actualValue as? T else { return PredicateResult(bool: false, message: .expectedCustomValueTo("be \(T.self)", "\(type(of: actualValue)): \(actualValue)")) }
            return PredicateResult(bool: castValue == expectedValue, message: msg)
        }
    }
    return lhs.to(_equal(rhs))
}

extension IRSignature {
    /// Produces a new signature with only the essential attributes (swiftself, swifterror, sret) and no mappings. Used for comparisons in tests.
    var strippingNonEssentialAttributesAndMappings: IRSignature {
        IRSignature(type: type, attributes: attributes.strippingNonEssential)
    }
}

private extension LLVMAttributeList {
    var strippingNonEssential: LLVMAttributeList {
        let functionAttributes = Set<String>() // we don't have any function attributes that we deem "essential"
        let resultAttributes = self.resultAttributes.intersection(Set(["sret", "swifterror", "swiftself"]))
        let parameterAttributes = self.parameterAttributes.compactMapValues { attrs -> Set<String>? in
            let important = attrs.intersection(Set(["sret", "swifterror", "swiftself"]))
            return important.isEmpty ? nil : important
        }
        return LLVMAttributeList(functionAttributes: functionAttributes, resultAttributes: resultAttributes, parameterAttributes: parameterAttributes)
    }
}
