//
//  SplitLogFile.swift
//  XcodeCompilationDatabase
//
//  Created by Deng Jinlong on 2019/4/19.
//

import Foundation

func splitLog(_ log: String) {
    var commands: [String: [CommandReference]] = [:]
    let lines = log.split { (char) -> Bool in
        return char == "\n" || char == "\r"
    }
    print("total lines \(lines.count)")
    var tmpStack: [String] = []
    for line in lines {
        let text = String(line)
        let results = matches(for: "in target: (\\w+)", in: text)
        assert(results.count < 2)
        if results.count == 1 {
            if tmpStack.count != 0 { // save old command
                if let command = createCommand(commandLines: tmpStack) {
                    addCommand(&commands, command)
                }
            }
            tmpStack = [] // start new command
            tmpStack.append(text)
        } else if text.hasPrefix("  ") {
            tmpStack.append(text)
        }
    }
    if tmpStack.count > 1 {
        if let command = createCommand(commandLines: tmpStack) {
            addCommand(&commands, command)
        }
    }
    print(NSTemporaryDirectory())
//    commands.forEach { (ref) in
//        ref.execute(done: { (err) in
//            if let err = err {
//                print("run cmd [\(ref.command.name)] err: \(err)")
//            }
//        })
//    }
}

func addCommand(_ commands: inout [String: [CommandReference]], _ ref: CommandReference) {
    if commands[ref.command.target] == nil {
        commands[ref.command.target] = []
    }
    commands[ref.command.target]!.append(ref)
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
