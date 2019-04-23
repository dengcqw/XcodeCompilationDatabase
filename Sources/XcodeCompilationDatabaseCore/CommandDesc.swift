//
//  CommandDesc.swift
//  XcodeCompilationDatabase
//
//  Created by Deng Jinlong on 2019/4/20.
//

import Foundation

protocol CommandDescription {
    /// project target
    var target: String { get set }
    /// command name
    var name: String { get set }
    /// command content
    var content: [String] { get set }
}


func createCommand(commandLines: [String]) -> Command? {
    guard commandLines.count > 1 else { return nil }
    guard let desc = commandLines.first, let commandIndex = desc.firstIndex(of: " ") else { return nil }
    let content = Array(commandLines.dropFirst())
    let command = desc.prefix(upTo: commandIndex)
    print(command)
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
class Command: CommandDescription {
    var target: String
    var name: String
    var content: [String]

    init(target: String, name: String, content: [String]) {
        self.target = target
        self.name = name
        self.content = content
    }

    func execute(params: [String], done: (String?)->Void) {
        let bash: CommandExecuting = Bash()
        let output = bash.execute(script: content.joined(separator: ";"))
        if output == "" {
            done(nil)
        } else {
            done(output)
        }
    }

    func equal(to: Command) -> Bool {
        return
            target == to.target &&
            name   == to.name
    }
}

class CommandCompileC: Command {
    required init?(desc: String, content: [String]) {
        let arr = desc.split(separator: " ") // TODO: filepath may contain blank char
        guard arr.count == 10 else { return nil }
        self.outputPath = String(arr[1])
        self.inputPath = String(arr[2])
        self.arch = String(arr[4])
        self.lang = String(arr[5])
        let _target = arr.last!.replacingOccurrences(of: ")", with: "")
        super.init(target: _target, name: String(arr[0]), content: content)
    }
 
    override func execute(params: [String], done: (String?) -> Void) {
        super.execute(params: params, done: done)
    }

    var outputPath: String
    var inputPath: String
    var arch: String
    var lang: String

    override func equal(to: Command) -> Bool {
        if let to = to as? CommandCompileC {
            return arch == to.arch &&
                lang == to.lang &&
                super.equal(to: to)
        }
        return false
    }
}

class CommandCompileSwiftSources: Command {
    required init?(desc: String, content: [String]) {
        let arr = desc.split(separator: " ")
        guard arr.count == 7 else { return nil }
        self.arch = String(arr[2])
        let _target = arr.last!.replacingOccurrences(of: ")", with: "")
        super.init(target: _target, name: String(arr[0]), content: content)
    }

    override func execute(params: [String], done: (String?) -> Void) {
        super.execute(params: params, done: done)
    }

    var arch: String

    override func equal(to: Command) -> Bool {
        if let to = to as? CommandCompileC {
            return arch == to.arch &&
                super.equal(to: to)
        }
        return false
    }
}

class CommandCompileSwift: Command {
    required init?(desc: String, content: [String]) {
        let arr = desc.split(separator: " ")
        guard arr.count == 7 else { return nil }
        self.arch = String(arr[2])
        self.inputPath = String(arr[3])
        let _target = arr.last!.replacingOccurrences(of: ")", with: "")
        super.init(target: _target, name: String(arr[0]), content: content)
    }

    override func execute(params: [String], done: (String?) -> Void) {
        super.execute(params: params, done: done)
    }

    var arch: String
    var inputPath: String

    override func equal(to: Command) -> Bool {
        if let to = to as? CommandCompileC {
            return arch == to.arch &&
                super.equal(to: to)
        }
        return false
    }
}

class CommandMergeSwiftModule: Command {
    var arch: String

    override func execute(params: [String], done: (String?) -> Void) {
    }

    init?(desc: String, content: [String]) {
        let arr = desc.split(separator: " ")
        guard arr.count == 6 else { return nil }
        self.arch = String(arr[2])
        let _target = arr.last!.replacingOccurrences(of: ")", with: "")
        super.init(target: _target, name: String(arr[0]), content: content)
    }

    override func equal(to: Command) -> Bool {
        if let to = to as? CommandCompileC {
            return arch == to.arch &&
                super.equal(to: to)
        }
        return false
    }
}

class CommandLd: Command {
    init?(desc: String, content: [String]) {
        let arr = desc.split(separator: " ")
        guard arr.count == 7 else { return nil }
        self.outputPath = String(arr[1])
        self.arch = String(arr[3])
        let _target = arr.last!.replacingOccurrences(of: ")", with: "")
        super.init(target: _target, name: String(arr[0]), content: content)
    }

    override func execute(params: [String], done: (String?) -> Void) {
        super.execute(params: params, done: done)
    }
    var outputPath: String
    var arch: String

    override func equal(to: Command) -> Bool {
        if let to = to as? CommandCompileC {
            return arch == to.arch &&
                super.equal(to: to)
        }
        return false
    }
}

class CommandCompileXIB: Command {
    required init?(desc: String, content: [String]) {
        let arr = desc.split(separator: " ")
        guard arr.count == 5 else { return nil }
        self.xibFilePath = String(arr[1])
        let _target = arr.last!.replacingOccurrences(of: ")", with: "")
        super.init(target: _target, name: String(arr[0]), content: content)
    }

    override func execute(params: [String], done: (String?) -> Void) {
        super.execute(params: params, done: done)
    }

    var xibFilePath: String
}

class CommandCopyPNGFile: Command {
    required init?(desc: String, content: [String]) {
        let arr = desc.split(separator: " ")
        guard arr.count == 10 else { return nil }
        self.outputPath = String(arr[1])
        self.inputPath = String(arr[2])
        let _target = arr.last!.replacingOccurrences(of: ")", with: "")
        super.init(target: _target, name: String(arr[0]), content: content)
    }

    override func execute(params: [String], done: (String?) -> Void) {
        super.execute(params: params, done: done)
    }

    var outputPath: String
    var inputPath: String
}

class CommandCodeSign: Command {
    required init?(desc: String, content: [String]) {
        let arr = desc.split(separator: " ")
        guard arr.count == 5 else { return nil }
        self.outputPath = String(arr[1])
        let _target = arr.last!.replacingOccurrences(of: ")", with: "")
        super.init(target: _target, name: String(arr[0]), content: content)
    }

    override func execute(params: [String], done: (String?) -> Void) {
        super.execute(params: params, done: done)
    }
    var outputPath: String
}
