//
//  SplitLogFile.swift
//  XcodeCompilationDatabase
//
//  Created by Deng Jinlong on 2019/4/19.
//

import Foundation

func splitLog(_ log: String) {
    var targets: [String: [String]] = [:]
    let lines = log.split(separator: "\r")
    print("total lines \(lines.count)")
    var tmpStack: [String] = []
    var target: String = ""
    for line in lines {
        let text = String(line)
        let results = matches(for: "in target: (\\w+)", in: text)
        assert(results.count < 2)
        if results.count == 1 {
            if tmpStack.count != 0 { // save old command
                target = results.first!.replacingOccurrences(of: "in target: ", with: "")
                if targets[target] == nil {
                    targets[target] = []
                }
                if supportCommand(text: tmpStack.first) {
                    targets[target]?.append(tmpStack.joined(separator: ";"))
                }
            }
            target = ""
            tmpStack = [] // start new command
            tmpStack.append(text)
        } else if text.hasPrefix(" ") {
            tmpStack.append(text)
        }
    }
    if target != "" && tmpStack.count > 1 {
        if supportCommand(text: tmpStack.first) {
            targets[target] = tmpStack
        }
    }
    for (key, value) in targets {
        DispatchQueue.global().async {
            processTarget(target: key, commands: value)
        }
    }
}

func supportCommand(text: String?) -> Bool {
    let supports = [
        "CompileSwiftSources",
        "CompileSwift",
        "CompileC",
        "Ld",
        "CopyPNGFile",
        "CompileXIB",
        "CodeSign",
    ]
    if let text = text {
        for prefix in supports {
            if text.hasPrefix(prefix) {
                return true
            }
        }
    }
    return false
}

func processTarget(target: String, commands: [String]) {
    for command in commands {
        if command.hasPrefix("CompileC") {
            print(command)
        } else if command.hasPrefix("CompileSwift") {
        }
    }
}



func matches(for regex: String, in text: String) -> [String] {
    do {
        let regex = try NSRegularExpression(pattern: regex)
        let results = regex.matches(in: text,
                                    range: NSRange(text.startIndex..., in: text))
        return results.map {
            String(text[Range($0.range, in: text)!])
        }
    } catch let error {
        print("invalid regex: \(error.localizedDescription)")
        return []
    }
}
