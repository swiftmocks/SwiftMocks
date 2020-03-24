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
import Nimble
@testable import SwiftMocks
@testable import IR

var verbose = true // FIXME: convert to a test superclass

// Verifies that the SIL and IR signatures produced for a mangled name matches the ones produced by the compiler
@discardableResult
func verifySignature(_ partialName: String, isWitness: Bool = false, kind: FunctionKind = .func, file: FileString = #file, line: UInt = #line) -> (mangledName: String, silSignature: SILFunctionType, irSignature: IRSignature)? {
    do {
        let (mangledName, expectedSILSignatureDescription, expectedIRSignatureDescription) = silAndIRSignatures(for: partialName, isWitness: isWitness, kind: kind)
        let expectedIRSignature = try IRTest.parseIRFunctionType(expectedIRSignatureDescription)

        let conformingTypeForWitness: AType?
        if let functionBits = try Mangle.demangleSymbol(mangledName: "$" + mangledName).asFunctionBits {
            conformingTypeForWitness = try functionBits.conformance?.children[0].asType()
        } else if let accessorBits = try Mangle.demangleSymbol(mangledName: "$" + mangledName).asAccessorBits {
            conformingTypeForWitness = try accessorBits.conformance?.children[0].asType()
        } else {
            conformingTypeForWitness = nil
        }

        let descriptor = try InvocationDescriptor(mangledName: mangledName, genericTypeParamReplacement: conformingTypeForWitness)

        if verbose {
            print("\(mangledName) ~> \(descriptor.silFunctionType.description) ~> \(descriptor.irSignature.strippingNonEssentialAttributesAndMappings.description)")
        }

        expect(descriptor.silFunctionType.description, file: file, line: line) == expectedSILSignatureDescription
        expect(descriptor.irSignature, file: file, line: line) == expectedIRSignature // note we are using a custom matcher that strips some stuff before comparison

        return (mangledName, descriptor.silFunctionType, descriptor.irSignature)
    } catch {
        fail("\(error.localizedDescription)", file: file, line: line)
    }
    return nil
}

private let definedSymbols = MachImage.all.filter { $0.filename.contains("IR") }.first!.definedExternalSymbols
private let image = MachImage.allExcludingKnownSystemPaths.first { $0.filename.hasSuffix("IR") }!
