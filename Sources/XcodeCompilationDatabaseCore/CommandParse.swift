//
//  CommandParse.swift
//  XcodeCompilationDatabase
//
//  Created by Deng Jinlong on 2019/4/19.
//

import Foundation

protocol LogSource {
    func getStreamReader() -> StreamReader?
}

struct FileSource: LogSource {
    var filePath: String
    func getStreamReader() -> StreamReader? {
        let pathURL = URL(fileURLWithPath: filePath)
        return StreamReader(url: pathURL, chunkSize: 40960)
    }
}

struct ScriptSource: LogSource {
    var shellCommand: String
    func getStreamReader() -> StreamReader? {
        if let fileHandle = Bash().execute(script: shellCommand) {
            return StreamReader(fileHandle: fileHandle, chunkSize: 40960)
        } else {
            return nil
        }
    }
}

struct StdinSource: LogSource {
    func getStreamReader() -> StreamReader? {
        return StreamReader(fileHandle: FileHandle.standardInput)
    }
}

// MARK: - main

func parse(_ logSource: LogSource) {
    let reader = logSource.getStreamReader()
    var commands: [String: [Command]] = [:]
    
    var tmpStack: [String] = []
    
    while let line = reader?.nextLine() {
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
    if commands.count > 0 {
        storeCommands(commands)
    }
}

let targets = getProjectTargets()

func addCommand(_ commands: inout [String: [Command]], _ command: Command) {
    guard targets.contains(command.target) else {
        return
    }
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

func tempFilePath() -> String? {
    let temporaryDirectoryURL = URL(string: NSTemporaryDirectory())
    let temporaryFileURL = temporaryDirectoryURL?.appendingPathComponent(UUID().uuidString)
    return temporaryFileURL?.absoluteString
}


func getSouceFilePath(target: String) -> String {
    return "\(getWorkingDir())/\(target)-swiftfiles"
}

func getModuleFilePath(target: String) -> String {
    return "\(getWorkingDir())/\(target)-swiftmodules"
}

func archivePath() -> String {
    return getWorkingDir() + "/archivedCommands.json"
}

func getWorkingDir() -> String {
//    let workingDir = FileManager.default.currentDirectoryPath + "/.FastCompile"
    let workingDir = "/Users/dengjinlong/Documents/8-tvguo/2-TVGuoiOSApp" + "/.FastCompile"
    if !FileManager.default.fileExists(atPath:  workingDir) {
        do {
            try FileManager.default.createDirectory(atPath: workingDir, withIntermediateDirectories: false, attributes: nil)
            return workingDir
        } catch _ {
            assert(false, "create working dir fail")
        }
    } else {
        return workingDir
    }
}

func createCommand(commandLines: [String]) -> Command? {
    guard commandLines.count > 1 else { return nil }
    guard let desc = commandLines.first, let commandIndex = desc.firstIndex(of: " ") else { return nil }
    let content = Array(commandLines.dropFirst())
    let command = desc.prefix(upTo: commandIndex)
    let prefix = "    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain"
    print(command)
    switch command {
    case "CompileSwift":
        return CommandCompileSwift(desc: desc, content: content.filterCmd(prefix))
    case "CompileC":
        return CommandCompileC(desc: desc, content: content.filterCmd(prefix))
    case "CopyPNGFile":
        return CommandCopyPNGFile(desc: desc, content: content)
    case "CompileXIB":
        return CommandCompileXIB(desc: desc, content: content)
    case "CompileSwiftSources":
        return CommandCompileSwiftSources(desc: desc, content: content.filterCmd(prefix))
    case "MergeSwiftModule":
        return CommandMergeSwiftModule(desc: desc, content: content.filterCmd(prefix))
    case "Ld":
        return CommandLd(desc: desc, content: content.filterCmd(prefix))
    case "CodeSign":
        let prefix = "    /usr/bin/codesign"
        return CommandCodeSign(desc: desc, content: content.filterCmd(prefix))
    case "GenerateDSYMFile":
        let target = desc.split(separator: " ").last!.replacingOccurrences(of: ")", with: "")
        return Command(target: target, name: "GenerateDSYMFile", content: content)
    default:
        return nil
    }
}

extension Array where Element == String {
    func filterCmd(_ prefix: String) -> [String] {
        for (index, value) in self.enumerated() {
            if value.hasPrefix(prefix) {
                return self.dropLast(self.count - 1 - index)
            }
        }
        return self
    }
}

public extension String {
    func getFileNameWithoutType() -> String? {
        guard let slashIndex = lastIndex(of: "/") else { return nil }
        let fileName = suffix(from: self.index(after: slashIndex))
        if let ret = fileName.split(separator: ".").first {
            return String(ret)
        } else {
            return nil
        }
    }
    
    // replace option and content
    mutating func replaceCommandLineParam(withPrefix prefix: String, replaceString: String) {
        guard let range = self.range(of: prefix) else { return }
        var preChar: Character = Character.init("-")
        var distance: Int = 0
        for (index, char) in self.suffix(from: range.upperBound).enumerated() {
            if char == "-" && preChar == " " { // end to next option
                distance = index - 1
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
    
    /// find content range of option
    ///
    /// - parameters
    ///    option   an command option which has content
    ///    reverse    if enumrate chars from endIndex
    func rangeOfOptionContent(option: String, reverse: Bool) -> Range<String.Index>? {
        if reverse {
            var idx = endIndex
            while(idx != startIndex) {
                var blankIdx = idx
                repeat {
                    if blankIdx == startIndex { break }
                    blankIdx = index(blankIdx, offsetBy: -1)
                } while(self[blankIdx] != " ")
                if index(blankIdx, offsetBy: -option.count) >= startIndex &&
                    option == self[index(blankIdx, offsetBy: -option.count)..<blankIdx] {
                    return index(blankIdx, offsetBy: 1) ..< idx
                } else {
                    idx = blankIdx // not need -1, is open upper bound
                }
            }
        } else {
            var idx = startIndex
            while(idx != endIndex) {
                var blankIdx = idx
                repeat { // find blank
                    blankIdx = index(blankIdx, offsetBy: 1)
                    if blankIdx == endIndex { break }
                } while(self[blankIdx] != " ")
                
                if distance(from: idx, to: blankIdx) == option.count && self[idx..<blankIdx] == option {
                    idx = index(blankIdx, offsetBy: 1) // content start index
                    repeat {  // find next blank
                        blankIdx = index(blankIdx, offsetBy: 1)
                        if blankIdx == endIndex { break }
                    } while(self[blankIdx] != " ")
                    return idx..<blankIdx
                } else {
                    idx = index(blankIdx, offsetBy: 1)
                }
            }
        }
        return nil
    }
}
