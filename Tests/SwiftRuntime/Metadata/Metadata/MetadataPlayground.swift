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
import SwiftMocks

class MetadataPlayground: XCTestCase {
    func playground_testConstructorIsBeforeVTable() {
        class Parent { func base() {} }
        class Child: Parent { var a = 1; var b = 2; func myfunc() {}; class func myclassfunc() {}; }

//        let metadata = Metadata.of(Child.self) as! ClassMetadata
//
//        let vtableOffset = Int(metadata.description.vtableOffset) * MemoryLayout<StoredPointer>.size
//        let sizeofself = MemoryLayout<__ClassMetadata>.offset(of: \__ClassMetadata.IVarDestroyer)! + 8 /* __ClassMetadata.IVarDestroyer */
//        expect(vtableOffset) == sizeofself
//
//        // metadata.printFullVTable()
//
//        // print(sizeofself, metadata.fieldOffsets, vtableOffset)
//
//        let basePlusVtable: UInt32 = metadata.classAddressPoint + UInt32(vtableOffset) + metadata.description.vtableSize * UInt32(8)
//        expect(basePlusVtable) == metadata.classSize
//        let _ = String(describing: metadata)
    }
}
