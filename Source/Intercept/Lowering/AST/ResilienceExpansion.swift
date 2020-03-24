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

/// A specification for how much to expand resilient types.
///
/// Right now, this is just a placeholder; a proper expansion specification will probably need to be able to express things like 'expand any type that was fragile in at least such-and-such version'.
enum ResilienceExpansion: Int {
    /// A minimal expansion does not expand types that do not have a
    /// universally fragile representation.  This provides a baseline
    /// for what all components can possibly support.
    ///   - All exported functions must be compiled to at least provide
    ///     a minimally-expanded entrypoint, or else it will be
    ///     impossible for components that do not have that type
    ///     to call the function.
    ///   - Similarly, any sort of abstracted function call must go through
    ///     a minimally-expanded entrypoint.
    ///
    /// Minimal expansion will generally pass all resilient types indirectly.
    case minimal

    /// A maximal expansion expands all types with fragile representation, even when they're not universally fragile.  This is better when internally manipulating values or when working with specialized entry points for a function.
    case maximal

    static let lastResilienceExpansion = ResilienceExpansion.maximal.rawValue
}
