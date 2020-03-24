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
@testable import SwiftMocks

// a couple of wrappers around interceptor to make tests look leaner

func testableIntercept<R>(returning injectedResult: R, _ execute: () throws -> R) rethrows -> (arguments: [Any], result: R) {
    var params = [Any]()
    let result: R = try theCore.interceptor.intercept(execute: execute, onIntercept: { _, handler in
        do {
            params = try handler.extractParameters()
            try handler.inject(result: injectedResult)
        } catch {
            fatalError("\(error)")
        }
        return .return
    })
    return (params, result)
}

func testableInterceptVoid(_ execute: () throws -> Void) rethrows -> [Any] {
    try testableIntercept(returning: (), execute).arguments
}

func testableIntercept<R>(throwing error: Error, _ execute: () throws -> R) rethrows {
    // technically it's a Never-returning function if interception actually intercepted something. But in case it didn't, we don't want to trap, instead letting the caller handle it
    _ = try theCore.interceptor.intercept(execute: execute, onIntercept: { _, handler in
        handler.inject(error: error)
        return .return
    })
}
