//
//  SplitLogFile.swift
//  XcodeCompilationDatabase
//
//  Created by Deng Jinlong on 2019/4/19.
//

import Foundation

func splitLog(_ log: String) {
    var commands: [String: [Command]] = [:]
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
        } else if text.hasBlankPrefix(count: 4) {
            tmpStack.append(text)
        }
    }
    if tmpStack.count > 1 {
        if let command = createCommand(commandLines: tmpStack) {
            addCommand(&commands, command)
        }
    }
    print(NSTemporaryDirectory())
}

func addCommand(_ commands: inout [String: [Command]], _ command: Command) {
    var sameTargetCommands = commands[command.target] ?? []
    
    for exist in sameTargetCommands {
        if exist.equal(to: command) {
            return
        }
    }
    sameTargetCommands.append(command)
    commands[command.target] = sameTargetCommands
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

extension String {
    func getFileNameWithoutType() -> String? {
        guard let slashIndex = lastIndex(of: "/") else { return nil }
        let fileName = suffix(from: self.index(after: slashIndex))
        if let ret = fileName.split(separator: ".").first {
            return String(ret)
        } else {
            return nil
        }
    }
    
    mutating func replaceCommandLineParam(withPrefix prefix: String, replaceString: String) {
        guard let range = self.range(of: prefix) else { return }
        var preChar: Character = Character.init("")
        var distance: Int = 0
        for (index, char) in self.suffix(from: range.upperBound).enumerated() {
            if char == "-" && preChar == " " {
                distance = index
                break
            } else {
                preChar = char
            }
        }
        guard distance != 0 else { return }
        let upperBound = self.index(range.upperBound, offsetBy: distance)
        self.replaceSubrange(range.lowerBound..<upperBound, with: replaceString)
    }
    
    func hasBlankPrefix(count: Int) -> Bool {
        var _count = 0
        for char in self {
            if char != " " {
                break
            }
            _count = _count + 1
        }
        return count == _count
    }

}
