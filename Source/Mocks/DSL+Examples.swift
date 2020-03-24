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

struct Struct {
    func func0() {}
    func func0Ret() -> Int { 0 }
}

class Class {
    func func0() {}
    func func0Ret() -> Int { 0 }

    func similar(int: Int) {}
    func similar(float: Float) {}

    class func classFunc() {}
}

protocol Protocol {
    func func0()
    func func0Ret() -> Int
    func func1(p: Int, p: Int)
    func func2(p: Int, p: Int)
    func func3(p: Int, p: Int, p: Int)
}

func globalFunc() {}
func globalFunc(int: Int) -> Int { 0 }

func example0() {
    let person = Class()
    let _ = Struct()
    let classProto = mock(of: Protocol.self)

    stub { globalFunc() }.toReturn(void)
    stub { globalFunc(int: 0) } .toReturn(0)

    stub(person) { $0.func0() } .toReturn(void)
    stub(classProto) { $0.func0Ret() } .toReturn(1)
    stub(person) { $0.func0Ret() } .toReturn(1)

    stub(everyInstanceOf: Class.self) { $0.func0() } .toReturn(void)
    stub(everyInstanceOf: Struct.self) { $0.func0() } .toReturn(void)
    stub(everyInstanceOf: Protocol.self) { $0.func0() } .toReturn(void)

    stub(Class.self) { $0.classFunc() }.toReturn(void)

    /*
    _ = check(person) { $0.func0Ret() }.wasCalled()
    _ = check(classProto) { $0.func0Ret() }.wasCalled()
    _ = check(someInstanceOf: Class.self) { $0.func0Ret() }.wasCalled()
    */
}
