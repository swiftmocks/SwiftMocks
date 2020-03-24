// This source file is part of SwiftInternals open source project.
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

open class ResilientOutsideParent {
    open var property: String = "ResilientOutsideParent.property"
    public final var finalProperty: String = "ResilientOutsideParent.finalProperty"

    open class var classProperty: String {
        return "ResilientOutsideParent.classProperty"
    }

    public init() {
        print("ResilientOutsideParent.init()")
    }

    open func method() {
        print("ResilientOutsideParent.method()")
    }

    open class func classMethod() {
        print("ResilientOutsideParent.classMethod()")
    }

    open func getValue() -> Int {
        return 0
    }
}

open class ResilientOutsideChild : ResilientOutsideParent {
    open override func method() {
        print("ResilientOutsideChild.method()")
        super.method()
    }
    
    open override class func classMethod() {
        print("ResilientOutsideChild.classMethod()")
        super.classMethod()
    }
}

// Resilient generic base class
open class ResilientGenericOutsideParent<A> {
  open var property: A
  public init(property: A) {
    self.property = property
    print("ResilientGenericOutsideParent.init()")
  }

  open func method() {
    print("ResilientGenericOutsideParent.method()")
  }

  open class func classMethod() {
    print("ResilientGenericOutsideParent.classMethod()")
  }
}

// Resilient generic subclass

open class ResilientGenericOutsideChild<A> : ResilientGenericOutsideParent<A> {
    public override init(property: A) {
        print("ResilientGenericOutsideGenericChild.init(a: A)")
        super.init(property: property)
    }

    open override func method() {
        print("ResilientGenericOutsideChild.method()")
        super.method()
    }

    open override class func classMethod() {
        print("ResilientGenericOutsideChild.classMethod()")
        super.classMethod()
    }
}


// Resilient subclass of generic class
open class ResilientConcreteOutsideChild : ResilientGenericOutsideParent<String> {
    public override init(property: String) {
        print("ResilientConcreteOutsideChild.init(property: String)")
        super.init(property: property)
    }

    open override func method() {
        print("ResilientConcreteOutsideChild.method()")
        super.method()
    }

    open override class func classMethod() {
        print("ResilientConcreteOutsideChild.classMethod()")
        super.classMethod()
    }
}

public protocol ResilientEmptyProtocol {}

public protocol ResilientRealisticallyLookingProtocol {
    var prop: ResilientOutsideParent { get set }
    func someFunc()
    static func someStaticFunc()
}

public class ResilientClassConformingToEmptyProtocol: ResilientEmptyProtocol {
    public init() {}
}
