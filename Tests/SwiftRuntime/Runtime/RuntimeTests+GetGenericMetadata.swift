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

import XCTest
import Nimble
@testable import SwiftMocks

class RuntimeTests_GetGenericMetadata: XCTestCase {
    func testOptional() {
        verifyRoundtrip(type: Int?.self, genericParams: Int.self)
    }

    func testArray() {
        verifyRoundtrip(type: [Int].self, genericParams: Int.self)
    }

    func testDictionary() {
        struct HashableProtocolDescriptorExtractionHelper<T: Hashable> {}
        let proto = ProtocolDescriptorExtractor.extract(type: HashableProtocolDescriptorExtractionHelper<Int>.self)
        verifyRoundtrip(type: [Int: Double].self, genericParams: Int.self, Double.self, conformances: [(Int.self, proto)])
        verifyRoundtrip(type: [String: [Double]].self, genericParams: String.self, [Double].self, conformances: [(String.self, proto)])
        verifyRoundtrip(type: [AnyHashable: [Double]].self, genericParams: AnyHashable.self, [Double].self, conformances: [(AnyHashable.self, proto)])
    }

    /// Verify that `Runtime.getGenericMetadata`, when invoked with the type descriptor and generic arguments of the passed type, returns the same metadata
    private func verifyRoundtrip(type: Any.Type, genericParams: Any.Type..., conformances: [(conformingType: Any.Type, proto: ProtocolDescriptor)] = [], file: FileString = #file, line: UInt = #line) {
        let originalMetadata = Metadata.of(type)
        let descriptor = originalMetadata.typeContextDescriptor!
        let genericArguments = genericParams.map { Metadata.of($0) }
        let conformanceWitnessTables = conformances.compactMap { (conformingType, proto) -> WitnessTable? in
            let conformingType = Metadata.of(conformingType)
            let witnessTable = Runtime.conformsToProtocol(metadata: conformingType, proto: proto)
            return witnessTable
        }
        let metadata = Runtime.getGenericMetadata(descriptor: descriptor, genericParams: genericArguments, conformanceWitnessTables: conformanceWitnessTables)
        expect(metadata, file: file, line: line).to(equal(originalMetadata)) //.to(equal(original))
    }
}
