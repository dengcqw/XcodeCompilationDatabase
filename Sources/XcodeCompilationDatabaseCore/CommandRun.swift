//
//  CommandRun.swift
//  XcodeCompilationDatabase
//
//  Created by Deng Jinlong on 2019/4/28.
//

import Foundation

// TODO
// - find changed file
// - find target
// - run command in order

func supportFile(_ line: String) -> Bool {
    return line.hasSuffix(".swift")
        || line.hasSuffix(".m")
        || line.hasSuffix(".mm")
        || line.hasSuffix(".c")
        || line.hasSuffix(".png")
}

let statusPrefixLength = 3

func supportStatus(_ line: String) -> Bool {
    assert(line.count != 0)
    let containD = line.prefix(upTo: line.index(line.startIndex, offsetBy: statusPrefixLength)).contains("D")
    return !containD
}

// not support file path containing whitespace
func getModifiedFiles() -> [String] {
    if let output = readStringSync(fileHandle: Bash().execute(script: "git status -s")) {
        return output.components(separatedBy: .newlines)
            .filter { $0.count > statusPrefixLength } // filter invalid lines
            .filter { supportStatus($0) && supportFile($0) } // filter support lines
            .map { String($0.suffix(from: $0.index($0.startIndex, offsetBy: statusPrefixLength))) } // get file name
    } else {
        return []
    }
}

func runCommand() {
    print(getModifiedFiles())
}
