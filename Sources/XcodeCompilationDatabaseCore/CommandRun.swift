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

func getFileTarget(_ file: String) -> String {
    // read xcode project
    // or read filelist
    return ""
}

func getFileCommandName(_ file: String) -> String {
    guard let index = file.lastIndex(of: ".") else { return "" }
    let type = file.suffix(from: index)
    switch type {
    case ".swift":
        return "CompileSwift"
    case ".c", ".m", ".mm":
        return "CompileC"
    case ".png":
        return "CopyPNGFile"
    case ".xib":
        return "CompileXIB"
    default:
        return ""
    }
}

func getCommand(commands: [Command], commandName: String) -> Command? {
    for command in commands {
        if command.name == commandName {
            return command
        }
    }
    return nil
}

func runCommand() {
    let commands = restoreCommands()
    guard let tvguoCommands = commands?["TVGuor"] else { return }
    
    var objPath: String = ""
    for cmd in tvguoCommands {
        if cmd is CommandMergeSwiftModule {
            objPath = (cmd as! CommandMergeSwiftModule).swiftmodulePath ?? ""
        }
    }
    
    // process file
    for file in getModifiedFiles() {
        print("\(file)")
         if let command = getCommand(commands: tvguoCommands, commandName: getFileCommandName(file)) {
            print("\(command.name)")
            command.execute(params: [FileManager.default.currentDirectoryPath + "/" + file, objPath]) { (output) in
                print("output \(command.name): \(output ?? "")")
            }
        }
    }
    
    // run other command in order
    tvguoCommands
        .filter { $0.name == "MergeSwiftModule" }
        .forEach {
            $0.execute(params: [], done: { (output) in
                print(output ?? "")
            })
        }
    tvguoCommands
        .filter { $0.name == "Ld" }
        .forEach {
            $0.execute(params: [], done: { (output) in
                print(output ?? "")
            })
        }
    // code sign in same target coubld be more then one
    tvguoCommands
        .filter { $0.name == "CodeSign" }
        .forEach {
            $0.execute(params: [], done: { (output) in
                print(output ?? "")
            })
        }
}
