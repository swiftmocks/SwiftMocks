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

struct IRSignature: Equatable {
    typealias Range = Swift.Range<Array<LLVMType>.Index>
    typealias Mapping = (requiresIndirect: Bool, range: Range)
    typealias ResultMapping = (requiresIndirect: Bool, ranges: [Range])

    let type: LLVMFunctionType
    let attributes: LLVMAttributeList
    let callingConv: LLVMCallingConvID = .swift
    /// Mapping of original SIL parameters to IR parameters
    private let mappings: [Mapping]
    /// Mappings of direct formal results into IR result aggregate
    private let resultMapping: ResultMapping

    var usesSret: Bool {
        attributes.usesSret
    }

    init(type: LLVMFunctionType,
         attributes: LLVMAttributeList,
         // parameters below are not present in parsed IR signatures, so they are optional
         mappings: [Mapping] = [],
         resultMapping: ResultMapping = (false, [])) {
        self.type = type
        self.attributes = attributes
        self.mappings = mappings
        self.resultMapping = resultMapping
    }

    /// Returns a range of IR parameters corresponding to a SIL formal parameter with the given index.
    func rangeOfIRParameters(for silParameterIndex: Int) -> Range {
        mappings[silParameterIndex].range
    }

    /// Returns `true` if Swift calling convention requires that the SIL parameter with the given index should be passed indirectly (because it's deemed too large to be passed in registers).
    func requiresIndirect(for silParameterIndex: Int) -> Bool {
        mappings[silParameterIndex].requiresIndirect
    }

    var requiresIndirectResult: Bool {
        resultMapping.requiresIndirect
    }

    static func getUncached(module: IRGenModule, formalType: SILFunctionType) -> IRSignature {
        let expansion = SignatureExpansion(igm: module, fnType: formalType)
        return expansion.signature
    }

    static func == (lhs: IRSignature, rhs: IRSignature) -> Bool {
        lhs.type == rhs.type &&
            lhs.attributes == rhs.attributes &&
            lhs.mappings.count == rhs.mappings.count && !zip(lhs.mappings, rhs.mappings).contains { !isEqual(lhs: $0.0, rhs: $0.1) } && // poor man's `operator ==` for arrays of tuples
            lhs.callingConv == rhs.callingConv
    }
}

private func isEqual(lhs: IRSignature.Mapping, rhs: IRSignature.Mapping) -> Bool {
    lhs.requiresIndirect == rhs.requiresIndirect && lhs.range == rhs.range
}
