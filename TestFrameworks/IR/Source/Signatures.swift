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

import Foundation

enum FunctionKind {
    case `func`
    case getter
    case setter
    case modify
    case subscriptGet
    case subscriptSet
    case subscriptModify
}

func silAndIRSignatures(for partialName: String, isWitness: Bool = false, kind: FunctionKind = .func) -> (fullName: String, silSignature: String, irSignature: String) {
    let key = findKey(partialName, isWitness: isWitness, kind: kind, in: silSignatures)
    return (key, silSignatures[key]!, irSignatures[key]!)
}

private let irSignatures: [String: String] = {
    dictionaryFromTabSeparated(filename: "Resources/ll")
}()

private let silSignatures: [String: String] = {
    dictionaryFromTabSeparated(filename: "Resources/sil")
}()

private func findKey(_ partialName: String, isWitness: Bool, kind: FunctionKind, in dictionary: [String: String]) -> String {
    // the set of known prefixes needs to match the greps used in the Build-Phases/generate-sil-ll script to filter unnecessary stuff
    let filter: (String) -> Bool
    switch kind {
    case .func:
        if isWitness {
            filter = { $0.hasSuffix("FTW") || $0.hasSuffix("FZTW") }
        } else {
            filter = { $0.hasSuffix("F") || $0.hasSuffix("FZ") }
        }
    case .getter:
        if isWitness {
            filter = { $0.hasSuffix("vgTW") || $0.hasSuffix("vgZTW") }
        } else {
            filter = { $0.hasSuffix("vg") || $0.hasSuffix("vgZ") }
        }
    case .setter:
        if isWitness {
            filter = { $0.hasSuffix("vsTW") || $0.hasSuffix("vsZTW") }
        } else {
            filter = { $0.hasSuffix("vs") || $0.hasSuffix("vsZ") }
        }
    case .modify:
        if isWitness {
            filter = { $0.hasSuffix("vMTW") || $0.hasSuffix("vMZTW") }
        } else {
            filter = { $0.hasSuffix("vM") || $0.hasSuffix("vMZ") }
        }
    case .subscriptGet:
        if isWitness {
            filter = { $0.hasSuffix("cigTW") || $0.hasSuffix("cigZTW") }
        } else {
            filter = { $0.hasSuffix("cig") || $0.hasSuffix("cigZ") }
        }
    case .subscriptSet:
        if isWitness {
            filter = { $0.hasSuffix("cisTW") || $0.hasSuffix("cisZTW") }
        } else {
            filter = { $0.hasSuffix("cis") || $0.hasSuffix("cisZ") }
        }
    case .subscriptModify:
        if isWitness {
            filter = { $0.hasSuffix("ciMTW") || $0.hasSuffix("ciMZTW") }
        } else {
            filter = { $0.hasSuffix("ciM") || $0.hasSuffix("ciMZ") }
        }
    }

    let keys = dictionary.keys.filter { filter($0) && $0.contains("\(partialName.count)\(partialName)") }

    guard !keys.isEmpty else { fatalError("Function whose name contains \(partialName) not found") }
    guard keys.count == 1 else { fatalError("More than one function whose name contains \(partialName) found") }

    return keys[0]
}

private func dictionaryFromTabSeparated(filename: String) -> [String: String] {
    guard let path = Bundle(for: AClass.self).path(forResource: filename, ofType: "txt") else { fatalError() }
    var result = [String: String]()
    do {
        let lines = try String(contentsOfFile: path).components(separatedBy: "\n")
        for line in lines {
            let components = line.components(separatedBy: "\t")
            guard components.count == 2 else { continue }
            result[components[0]] = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
        }
    } catch {
        fatalError()
    }
    guard !result.isEmpty else { fatalError() }
    return result
}

// just for getting the correct bundle
private class AClass {}
