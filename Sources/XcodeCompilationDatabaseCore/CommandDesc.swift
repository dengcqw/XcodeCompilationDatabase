//
//  CommandDesc.swift
//  XcodeCompilationDatabase
//
//  Created by Deng Jinlong on 2019/4/20.
//

import Foundation

protocol CommandExecution {
    /// run the command with output closure
    func execute(done: (String?)->Void)
}

protocol CommandDescription: CommandExecution {
    /// project target
    var target: String { get set }
    /// command name
    var name: String { get set }
    /// command content
    var content: String { get set }
}

extension CommandDescription {
    func execute(done: (String?)->Void) {
        let bash: CommandExecuting = Bash()
        let output = bash.execute(commandName: content)
        done(output)
    }
}

extension CommandDescription {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return
            lhs.target == rhs.target &&
            lhs.name   == rhs.name
    }
}

/// expose command description as a variable
protocol CommandReference: CommandExecution {
    var command: Command { get }
    init?(desc: String, content: String)
}

func createCommand(commandLines: [String]) -> CommandReference? {
    guard commandLines.count > 1 else { return nil }
    guard let desc = commandLines.first, let commandIndex = desc.firstIndex(of: " ") else { return nil }
    let content = commandLines.dropFirst().joined(separator: ";")
    let command = desc.prefix(upTo: commandIndex)
    switch command {
    case "CompileSwiftSources":
        return CommandCompileSwiftSources(desc: desc, content: content)
    case "CompileSwift":
        return CommandCompileSwift(desc: desc, content: content)
    case "MergeSwiftModule":
        return CommandMergeSwiftModule(desc: desc, content: content)
    case "CompileC":
        return CommandCompileC(desc: desc, content: content)
    case "Ld":
        return CommandLd(desc: desc, content: content)
    case "CopyPNGFile":
        return CommandCopyPNGFile(desc: desc, content: content)
    case "CompileXIB":
        return CommandCompileXIB(desc: desc, content: content)
    case "CodeSign":
        return CommandCodeSign(desc: desc, content: content)
    default:
        return nil
    }
}

/// entity to store command description
struct Command: CommandDescription {
    var target: String
    var name: String
    var content: String
}

struct CommandCompileC: CommandReference {
    init?(desc: String, content: String) {
        let arr = desc.split(separator: " ")
        guard arr.count == 10 else { return nil }
        self.command = Command.init(target: arr.last!.replacingOccurrences(of: ")", with: ""), name: String(arr[0]), content: content)
        self.lang = String(arr[5])
        self.arch = String(arr[4])
        self.compileFilePath = String(arr[2])
    }

    var command: Command

    func execute(done: (String?) -> Void) {
        command.execute(done: done)
    }

    /// program language name
    var lang: String
    /// cpu arch
    var arch: String
    /// file's full path
    var compileFilePath: String

    static func == (lhs: CommandCompileC, rhs: CommandCompileC) -> Bool {
        return
            lhs.command == rhs.command &&
            lhs.lang == rhs.lang
    }
}

struct CommandCompileSwiftSources: CommandReference {
    init?(desc: String, content: String) {
        let arr = desc.split(separator: " ")
        guard arr.count == 7 else { return nil }
        self.command = Command.init(target: arr.last!.replacingOccurrences(of: ")", with: ""), name: String(arr[0]), content: content)
    }

    func execute(done: (String?) -> Void) {
        command.execute(done: done)
    }

    var command: Command
}

struct CommandCompileSwift: CommandReference {
    init?(desc: String, content: String) {
        let arr = desc.split(separator: " ")
        guard arr.count == 7 else { return nil }
        self.command = Command.init(target: arr.last!.replacingOccurrences(of: ")", with: ""), name: String(arr[0]), content: content)
    }

    func execute(done: (String?) -> Void) {
        command.execute(done: done)
    }

    var command: Command
}

struct CommandMergeSwiftModule: CommandReference {
    init(desc: String, content: String) {
        let arr = desc.split(separator: " ")
        guard arr.count > 2 else { return nil }
        self.command = Command.init(target: arr[10].replacingOccurrences(of: ")", with: ""), name: String(arr[0]), content: content)
    }
}

struct CommandLd: CommandReference {
    init(desc: String, content: String) {
        let arr = desc.split(separator: " ")
        guard arr.count == 10 else { return nil }
        self.command = Command.init(target: arr[10].replacingOccurrences(of: ")", with: ""), name: String(arr[0]), content: content)
    }

    func execute(done: (String?) -> Void) {
        command.execute(done: done)
    }

    var command: Command
}

struct CommandCompileXIB: CommandReference {
    init(desc: String, content: String) {
        let arr = desc.split(separator: " ")
        guard arr.count == 10 else { return nil }
        self.command = Command.init(target: arr[10].replacingOccurrences(of: ")", with: ""), name: String(arr[0]), content: content)
    }

    func execute(done: (String?) -> Void) {
        command.execute(done: done)
    }

    var command: Command

    var xibFilePath: String
}

struct CommandCopyPNGFile: CommandReference {
    init(desc: String, content: String) {
        let arr = desc.split(separator: " ")
        guard arr.count == 10 else { return nil }
        self.command = Command.init(target: arr[10].replacingOccurrences(of: ")", with: ""), name: String(arr[0]), content: content)
    }

    func execute(done: (String?) -> Void) {
        command.execute(done: done)
    }

    var command: Command

    var copyFilePath: String
}

struct CommandCodeSign: CommandReference {
    init(desc: String, content: String) {
        let arr = desc.split(separator: " ")
        guard arr.count == 10 else { return nil }
        self.command = Command.init(target: arr[10].replacingOccurrences(of: ")", with: ""), name: String(arr[0]), content: content)
    }

    func execute(done: (String?) -> Void) {
        command.execute(done: done)
    }

    var command: Command
}
