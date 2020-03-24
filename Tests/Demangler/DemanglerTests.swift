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

class DemanglerTests: XCTestCase {
    func testDemangleSymbol() {
        let mangledName = "$s1b1CC16funcWithCallback3fooyyyXE_tF"
        let demangledName = "b.C.funcWithCallback(foo: () -> ()) -> ()"
        let result = try? Mangle.demangleSymbol(mangledName: mangledName).description
        expect(result) == demangledName
    }

    func testManglings() {
        for m in assortedManglings {
            expect(try? Mangle.demangleSymbol(mangledName: m)).toNot(beNil())
        }
    }

    func `test_$sSo16MKCoordinateSpana6MapKitE34_conditionallyBridgeFromObjectiveC_6resultSbSo7NSValueC_ABSgztFZ`() {
        expect(try? Mangle.demangleSymbol(mangledName: "$sSo16MKCoordinateSpana6MapKitE34_conditionallyBridgeFromObjectiveC_6resultSbSo7NSValueC_ABSgztFZ")).toNot(beNil())
    }

    func `test_$sSo8PHChangeC6PhotosE13changeDetails3forSo014PHObjectChangeD0CyxGSgx_tSo0F0CRbzlF`() {
        let result = try? Mangle.demangleSymbol(mangledName: "$sSo8PHChangeC6PhotosE13changeDetails3forSo014PHObjectChangeD0CyxGSgx_tSo0F0CRbzlF")
        expect(result).toNot(beNil())
    }

    func `test_$sSo10SCNVector3V8SceneKitEyAB12CoreGraphics7CGFloatV_A2FtcfC`() {
        expect(try? Mangle.demangleSymbol(mangledName: "$sSo10SCNVector3V8SceneKitEyAB12CoreGraphics7CGFloatV_A2FtcfC")).toNot(beNil())
    }

    func `test_$sBf128_N`() {
        expect(try? Mangle.demangleSymbol(mangledName: "_$sBf128_N")).toNot(beNil())
    }

    func `test_$sSB18exponentBitPattern11RawExponentQzvgTj`() {
        expect(try? Mangle.demangleSymbol(mangledName: "_$sSB18exponentBitPattern11RawExponentQzvgTj")).toNot(beNil())
    }

    func `test_$sSD10startIndexSD0B0Vyxq__Gvg`() {
        expect(try? Mangle.demangleSymbol(mangledName: "_$sSD10startIndexSD0B0Vyxq__Gvg")).toNot(beNil())
    }

    func `test_$S3nix8MystructV1xACyxGx_tcfc7MyaliasL_ayx__GD`() {
        expect(try? Mangle.demangleSymbol(mangledName: "$S3nix8MystructV1xACyxGx_tcfc7MyaliasL_ayx__GD")).toNot(beNil())
    }

    func `test_$s1c1CCAA17__FirstProtocol__A2aDP7__foo__8intParam06stringE0ySi_SStFTW`() {
        expect(try? Mangle.demangleSymbol(mangledName: "$s1c1CCAA17__FirstProtocol__A2aDP7__foo__8intParam06stringE0ySi_SStFTW")).toNot(beNil())
    }

    func `test_$sSo8NSObjectCSgIeyBa_ACIego_TR`() {
        let node: Node? = try? Mangle.demangleSymbol(mangledName: "$sSo8NSObjectCSgIeyBa_ACIego_TR")
        expect(node).toNot(beNil())
        _ = node?.description // problem with node printer
    }

    func `test_$s14SwiftInternals11TypeFactoryO014getSILFunctionC010genericSig7extInfo13coroutineKind16calleeConvention6params6yields13normalResults11errorResult24witnessMethodConformanceAA0fC0CAA16GenericSignatureVSg_AO03ExtJ0VAA012SILCoroutineL0OAA09ParameterN0OSayAA012SILParameterJ0VGA_SayAA09SILResultJ0VGA1_SgAA08ProtocolW3RefVSgtFZ`() {
        let name = "$s14SwiftInternals11TypeFactoryO014getSILFunctionC010genericSig7extInfo13coroutineKind16calleeConvention6params6yields13normalResults11errorResult24witnessMethodConformanceAA0fC0CAA16GenericSignatureVSg_AO03ExtJ0VAA012SILCoroutineL0OAA09ParameterN0OSayAA012SILParameterJ0VGA_SayAA09SILResultJ0VGA1_SgAA08ProtocolW3RefVSgtFZ"
        let node = try? Mangle.demangleSymbol(mangledName: name)
        let description = node!.description
        let expectedDescription = Runtime.demangle(name)
        expect(description) == expectedDescription
    }

    func `test_$sSS8withUTF8yxxSRys5UInt8VGKXEKlFyt_Tg5088$ss17_assertionFailure__4file4line5flagss5NeverOs12StaticStringV_SSAHSus6UInt32VtFySRys5C15VGXEfU_yAMXEfU_s0jK0VADSus0M0VTf1ncn_n`() {
        let name = "$sSS8withUTF8yxxSRys5UInt8VGKXEKlFyt_Tg5088$ss17_assertionFailure__4file4line5flagss5NeverOs12StaticStringV_SSAHSus6UInt32VtFySRys5C15VGXEfU_yAMXEfU_s0jK0VADSus0M0VTf1ncn_n"
        let node = try? Mangle.demangleSymbol(mangledName: name)
        let description = node!.description
        let expectedDescription = Runtime.demangle(name)
        expect(description) == expectedDescription
    }

    /// this is a bug in original remangler, which can be observed by running `xcrun swift-demangle -test-remangle s10Foundation4DataV15replaceSubrange_4withySnySiG_xtSlRzs5UInt8V7ElementRtzlFySpySo28_ConditionalAllocationBufferaGXEfU_s15EmptyCollectionVyAHG_Tgq5TA.414`
    func `todo_test_$s10Foundation4DataV15replaceSubrange_4withySnySiG_xtSlRzs5UInt8V7ElementRtzlFySpySo28_ConditionalAllocationBufferaGXEfU_s15EmptyCollectionVyAHG_Tgq5TA_dot_414`() {
        let name = "$s10Foundation4DataV15replaceSubrange_4withySnySiG_xtSlRzs5UInt8V7ElementRtzlFySpySo28_ConditionalAllocationBufferaGXEfU_s15EmptyCollectionVyAHG_Tgq5TA.414"
        let node = try! Mangle.demangleSymbol(mangledName: name)
        let description = node.description
        let expectedDescription = Runtime.demangle(name)
        expect(description) == expectedDescription

        let remangled = Mangle.mangleNode(node: node)
        expect(remangled) == name
    }

    // PRAGMA MARK: - Invalid manglings

    // XXX: this is a curious case. It is not being demangled by the swift-demangle tools bundled with Xcode 11, yet in manglings.txt it is demangled as "associated conformance descriptor for resilient_protocol.ResilientDerivedProtocol.A: resilient_protocol.ResilientBaseProtocol". This line was added on 2018-12-03 - perhaps it used to work back then?
    func `test_$s18resilient_protocol24ResilientDerivedProtocolPxAA0c4BaseE0Tn`() {
        expect(try? Mangle.demangleSymbol(mangledName: "$s18resilient_protocol24ResilientDerivedProtocolPxAA0c4BaseE0Tn")).to(beNil())
    }

    func `test_$sSD5IndexVy__GD`() {
        expect(try? Mangle.demangleSymbol(mangledName: "$sSD5IndexVy__GD")).to(beNil())
    }
}
