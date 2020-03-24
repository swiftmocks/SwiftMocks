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

extension IRTypeConverter {
    func convertEnumType(_ typeInfoHelper: CompositeTypeInfoHelper) -> TypeInfo {
        guard var strategy = getEnumImplStrategy(typeConverter: self, typeInfoHelper: typeInfoHelper) else {
            return emptyTypeInfo
        }
        let ret = strategy.completeEnumTypeLayout()
        return ret
    }
}

private protocol EnumImplStrategy {
    mutating func completeEnumTypeLayout() -> TypeInfo

    func addToAggLowering(igm: IRGenModule, lowering: inout SwiftAggLowering, offset: Int)
}

private struct Element {
    let ti: TypeInfo?
}

private struct SingletonEnumImplStrategy: EnumImplStrategy {
    let element: Element

    func addToAggLowering(igm: IRGenModule, lowering: inout SwiftAggLowering, offset: Int) {
        guard let loadableSingleton = loadableSingleton else {
            return // empty
        }
        loadableSingleton.addToAggLowering(igm: igm, lowering: &lowering, offset: offset)
    }

    mutating func completeEnumTypeLayout() -> TypeInfo {
        if let loadableSingleton = loadableSingleton {
            let storageType = LLVMType.struct([loadableSingleton.storageType])
            return LoadableEnumTypeInfo(strategy: self, storage: storageType, size: loadableSingleton.size, alignment: loadableSingleton.alignment)
        } else {
            let storageType = LLVMType.struct([])
            return LoadableEnumTypeInfo(strategy: self, storage: storageType, size: 0, alignment: 1)
        }
    }

    private var loadableSingleton: LoadableTypeInfo? {
        guard let elementTI = element.ti else {
            return nil
        }
        guard let lti = elementTI as? LoadableTypeInfo else {
            LoweringError.unreachable("a loadable enum with unloadable elements?")
        }
        return lti
    }
}

private struct NoPayloadEnumImplStrategy: EnumImplStrategy {
    let numberOfNoPayloadCases: Int
    private var fixedSize: Int!

    init(numberOfNoPayloadCases: Int) {
        self.numberOfNoPayloadCases = numberOfNoPayloadCases
    }

    mutating func completeEnumTypeLayout() -> TypeInfo {
        let usedBits = (numberOfNoPayloadCases - 1).log2 + 1
        let (numberOfBytes, tagTy) = getIntegerTypeForTag(tagBits: usedBits)
        fixedSize = numberOfBytes
        let storageType = LLVMType.struct([tagTy])
        return LoadableEnumTypeInfo(strategy: self, storage: storageType, size: fixedSize, alignment: fixedSize)
    }

    func addToAggLowering(igm: IRGenModule, lowering: inout SwiftAggLowering, offset: Int) {
        lowering.addOpaqueData(begin: offset, end: offset + fixedSize)
    }
}

private protocol PayloadEnumImplStrategyBase {
    var payloadBits: Int { get }
    var extraTagBits: Int { get }

    func taggedEnumBody(payloadBits: Int, extraTagBits: Int) -> [LLVMType]
    func addToAggLowering(igm: IRGenModule, lowering: inout SwiftAggLowering, offset: Int)
}

extension PayloadEnumImplStrategyBase {
    func taggedEnumBody(payloadBits: Int, extraTagBits: Int) -> [LLVMType] {
        // Represent the payload area as a byte array in the LLVM storage type, so that we have full control of its alignment and load/store size. Integer types in LLVM tend to have unexpected alignments or store sizes.
        var body = [LLVMType]()
        if payloadBits > 0 {
            let payloadArrayTy = LLVMType.array(.i8, (payloadBits + 7) / 8)
            body.append(payloadArrayTy)
        }

        if extraTagBits > 0 {
            let (extraTagSize, _) = getIntegerTypeForTag(tagBits: extraTagBits)
            let extraTagArrayTy = LLVMType.array(.i8, extraTagSize)
            body.append(extraTagArrayTy)
        }

        return body
    }

    func addToAggLowering(igm: IRGenModule, lowering: inout SwiftAggLowering, offset: Int) {
        var byteSize = (payloadBits + 7) / 8
        var runningOffset = offset
        if payloadBits > 0 {
            let pointerSize = igm.pointerSize
            while byteSize >= pointerSize {
                lowering.addTypedData(igm.sizeTy, begin: runningOffset, end: runningOffset + pointerSize)
                runningOffset += pointerSize
                byteSize -= pointerSize
            }
            if byteSize > 0 {
                if byteSize.isPowerOf2 {
                    lowering.addTypedData(LLVMType.getInteger(bitWidth: byteSize * 8), begin: runningOffset, end: runningOffset + byteSize)
                } else {
                    lowering.addOpaqueData(begin: runningOffset, end: runningOffset + byteSize)
                }
                runningOffset += byteSize
            }
        }
        if extraTagBits > 0 {
            let extraTagBytes = (extraTagBits + 7) / 8
            lowering.addOpaqueData(begin: runningOffset, end: runningOffset + extraTagBytes)
        }
    }
}

private struct SinglePayloadEnumImplStrategy: EnumImplStrategy, PayloadEnumImplStrategyBase {
    let bytesBeyondPayload: Int
    let alignment: Int
    let payloadBits: Int
    let extraTagBits: Int

    init(payloadElement: Element, payloadSize: Int, payloadAlignment: Int, bytesBeyondPayload: Int) {
        self.bytesBeyondPayload = bytesBeyondPayload
        self.alignment = payloadAlignment
        self.payloadBits = payloadSize * 8
        self.extraTagBits = bytesBeyondPayload * 8 // we can't tell more precisely whether we are using 1 bit or all 8, but it doesn't matter here
    }

    mutating func completeEnumTypeLayout() -> TypeInfo {
        let storageBody = taggedEnumBody(payloadBits: payloadBits, extraTagBits: extraTagBits)
        let ret = LoadableEnumTypeInfo(strategy: self, storage: .struct(storageBody) /* packed */, size: payloadBits + extraTagBits /* we know they are in fact % 8 == 0 */, alignment: alignment)
        return ret
    }
}

private struct MultiPayloadEnumImplStrategy: EnumImplStrategy, PayloadEnumImplStrategyBase {
    let payloadBits: Int
    let extraTagBits: Int
    let alignment: Int

    init(payloadElements: [Element], payloadSize: Int, payloadAlignment: Int, bytesBeyondPayload: Int) {
        self.payloadBits = payloadSize * 8
        self.alignment = payloadAlignment
        self.extraTagBits = bytesBeyondPayload * 8 // we can't tell more precisely whether we are using 1 bit or all 8, but it doesn't matter here
    }

    func completeEnumTypeLayout() -> TypeInfo {
        let storageBody = taggedEnumBody(payloadBits: payloadBits, extraTagBits: extraTagBits)
        let ret = LoadableEnumTypeInfo(strategy: self, storage: .struct(storageBody) /* packed */, size: payloadBits + extraTagBits /* we know they are in fact % 8 == 0 */, alignment: alignment)
        return ret
    }
}

// a.k.a. EnumImplStrategy::get()
private func getEnumImplStrategy(typeConverter: IRTypeConverter, typeInfoHelper: CompositeTypeInfoHelper) -> EnumImplStrategy? {
    var payloadCases = [Element]()
    var numberOfNoPayloadCases = 0
    for (type, isIndirect, _) in typeInfoHelper.fields {
        if isIndirect {
            payloadCases.append(Element(ti: typeConverter.nativeObjectTypeInfo))
            continue
        }
        if let type = type {
            let lowered = typeConverter.igm.silModule.types.getTypeLowering(type, expansion: .maximal).loweredType.getASTType().type
            payloadCases.append(Element(ti: typeConverter.convertType(lowered)))
        } else {
            numberOfNoPayloadCases += 1
        }
    }
    let numberOfCases = numberOfNoPayloadCases + payloadCases.count
    if numberOfCases == 0 {
        return nil
    }
    if numberOfCases == 1 {
        return SingletonEnumImplStrategy(element: payloadCases.first ?? Element(ti: nil))
    }
    if payloadCases.isEmpty {
        return NoPayloadEnumImplStrategy(numberOfNoPayloadCases: numberOfNoPayloadCases)
    }
    if payloadCases.count == 1 {
        let bytesBeyondPayload = typeInfoHelper.size - typeInfoHelper.payloadSize
        return SinglePayloadEnumImplStrategy(payloadElement: payloadCases[0], payloadSize: typeInfoHelper.payloadSize, payloadAlignment: typeInfoHelper.payloadAlignment, bytesBeyondPayload: bytesBeyondPayload)
    }
    if payloadCases.count > 1 {
        let bytesBeyondPayload = typeInfoHelper.size - typeInfoHelper.payloadSize
        return MultiPayloadEnumImplStrategy(payloadElements: payloadCases, payloadSize: typeInfoHelper.payloadSize, payloadAlignment: typeInfoHelper.payloadAlignment, bytesBeyondPayload: bytesBeyondPayload)
    }
    return nil
}

private class LoadableEnumTypeInfo: LoadableTypeInfo {
    let strategy: EnumImplStrategy

    init(strategy: EnumImplStrategy, storage: LLVMType, size: Int, alignment: Int) {
        self.strategy = strategy
        super.init(storage: storage, size: size, alignment: alignment)
    }

    override func addToAggLowering(igm: IRGenModule, lowering: inout SwiftAggLowering, offset: Int) {
        strategy.addToAggLowering(igm: igm, lowering: &lowering, offset: offset)
    }
}

private func getIntegerTypeForTag(tagBits: Int) -> (numberOfBytes: Int, type: LLVMType) {
    let typeBits = IRGenModule.getIntegerBitSizeForTag(tagBits: tagBits)
    return ((typeBits + 7) / 8, LLVMType.getInteger(bitWidth: typeBits))
}
