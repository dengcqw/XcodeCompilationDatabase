//
//  CommandDesc.swift
//  XcodeCompilationDatabase
//
//  Created by Deng Jinlong on 2019/4/20.
//

import Foundation

let ClangPath = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
let SwiftPath = ""

protocol CommandDescription {
    /// project target
    var target: String { get set }
    /// command name
    var name: String { get set }
    /// command content
    var content: [String] { get set }
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

func createCommand(commandLines: [String]) -> Command? {
    guard commandLines.count > 1 else { return nil }
    guard let desc = commandLines.first, let commandIndex = desc.firstIndex(of: " ") else { return nil }
    let content = Array(commandLines.dropFirst())
    let command = desc.prefix(upTo: commandIndex)
    let prefix = "    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain"
    print(command)
    switch command {
    case "CompileSwiftSources":
        return CommandCompileSwiftSources(desc: desc, content: content.filterCmd(prefix))
    case "CompileSwift":
        return CommandCompileSwift(desc: desc, content: content.filterCmd(prefix))
    case "MergeSwiftModule":
        return CommandMergeSwiftModule(desc: desc, content: content.filterCmd(prefix))
    case "CompileC":
        return CommandCompileC(desc: desc, content: content.filterCmd(prefix))
    case "Ld":
        return CommandLd(desc: desc, content: content.filterCmd(prefix))
    case "CopyPNGFile":
        return CommandCopyPNGFile(desc: desc, content: content)
    case "CompileXIB":
        return CommandCompileXIB(desc: desc, content: content)
    case "CodeSign":
        let prefix = "    /usr/bin/codesign"
        return CommandCodeSign(desc: desc, content: content.filterCmd(prefix))
    default:
        return nil
    }
}

/// entity to store command description
class Command: CommandDescription {
    var target: String
    var name: String
    var content: [String] = []
    var prepared: Bool = false

    init(target: String, name: String, content: [String]) {
        self.target = target
        self.name = name
        self.content = content
    }

    func execute(params: [String], done: (String?)->Void) {
        if !prepared {
            self.content = prepare(content)
        }
        let bash: CommandExecuting = Bash()
        let output = bash.execute(script: (params + content).joined(separator: ";"))
        if output == "" {
            done(nil)
        } else {
            done(output)
        }
    }

    func prepare(_ content: [String]) -> [String] {
        prepared = true
        return content
    }

    func equal(to: Command) -> Bool {
        return
            target == to.target &&
            name   == to.name
    }
}

class CommandCompileC: Command {
    var outputPath: String
    var inputPath: String
    var arch: String
    var lang: String

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
        guard let filePath = params.first, let fileName = filePath.getFileNameWithoutType() else { return }
        let defines = ["FILEPATH=\(filePath)", "FILENAME=\(fileName)"]
        super.execute(params: defines, done: done)
    }

    override func prepare(_ content: [String]) -> [String] {
        guard let lastLine = content.last else { return [] }
        guard let fileName = inputPath.getFileNameWithoutType() else { return [] }
        let newLine = lastLine.replacingOccurrences(of: inputPath, with: "$FILEPATH")
            .replacingOccurrences(of: fileName, with: "$FILENAME")
        return super.prepare(content.dropLast() + [newLine])
    }

    override func equal(to: Command) -> Bool {
        if let to = to as? CommandCompileC {
            return arch == to.arch &&
                lang == to.lang &&
                super.equal(to: to)
        }
        return false
    }
}

// 生成一个filelist，和output file list
class CommandCompileSwiftSources: Command {
    var arch: String

    required init?(desc: String, content: [String]) {
        let arr = desc.split(separator: " ")
        guard arr.count == 7 else { return nil }
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

class CommandCompileSwift: Command {

    var arch: String
    var inputPath: String?

    required init?(desc: String, content: [String]) {
        let arr = desc.split(separator: " ")
        if arr.count == 7 {
            self.arch = String(arr[2])
            self.inputPath = String(arr[3])
            let _target = arr.last!.replacingOccurrences(of: ")", with: "")

            super.init(target: _target, name: String(arr[0]), content: content)
        } else if arr.count == 6 {
            self.arch = String(arr[2])
            self.inputPath = nil
            let _target = arr.last!.replacingOccurrences(of: ")", with: "")
            super.init(target: _target, name: String(arr[0]), content: content)
        } else { return nil }

    }

    override func execute(params: [String], done: (String?) -> Void) {
        guard params.count == 3 else { return }
        guard let filePath = params.first, let fileName = filePath.getFileNameWithoutType() else { return }
        let defines = ["FILEPATH=\(filePath)", "FILENAME=\(fileName)", "SourceFileList=\(params[1])", "ObjectsPATH=\(params[3])"]
        super.execute(params: defines, done: done)
    }

    override func prepare(_ content: [String]) -> [String] {
        guard let lastLine = content.last else { return [] }
        if let inputPath = inputPath {
            guard let fileName = inputPath.getFileNameWithoutType() else { return [] }
            var newLine = lastLine.replacingOccurrences(of: inputPath, with: "$FILEPATH")
                .replacingOccurrences(of: fileName, with: "$FILENAME")
            newLine.replaceCommandLineParam(withPrefix: "-filelist", replaceString: "-filelist $SourceFileList")
            return super.prepare(content.dropLast() + [newLine])
        } else {
            // $ObjectsPATH
            let replaceText = "-primary-file $FILEPATH " +
                "-emit-module-path $ObjectsPATH/$FILENAME~partial.swiftmodule " +
                "-emit-module-doc-path $ObjectsPATH/$FILENAME~partial.swiftdoc " +
                "-serialize-diagnostics-path $ObjectsPATH/$FILENAME.dia " +
                "-emit-dependencies-path $ObjectsPATH/$FILENAME.d " +
                "-emit-reference-dependencies-path $ObjectsPATH/$FILENAME.swiftdeps "

            var newLine = lastLine
            newLine.replaceCommandLineParam(withPrefix: "-filelist", replaceString: "-filelist $SourceFileList")
            newLine.replaceCommandLineParam(withPrefix: "-supplementary-output-file-map", replaceString: replaceText)
            newLine.replaceCommandLineParam(withPrefix: "-output-filelist", replaceString: "-o $ObjectsPATH/$FILENAME.d")

            return super.prepare(content.dropLast() + [newLine])
        }
    }

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

    init?(desc: String, content: [String]) {
        let arr = desc.split(separator: " ")
        guard arr.count == 6 else { return nil }
        self.arch = String(arr[2])
        let _target = arr.last!.replacingOccurrences(of: ")", with: "")
        super.init(target: _target, name: String(arr[0]), content: content)
    }

    override func execute(params: [String], done: (String?) -> Void) {
        guard let objfileList = params.first else { return }
        let defines = ["ObjFileList=\(objfileList)"]
        super.execute(params: defines, done: done)
    }

    override func prepare(_ content: [String]) -> [String] {
        guard let lastLine: String = content.last else { return []}
        var newLine = lastLine
        newLine.replaceCommandLineParam(withPrefix: "-filelist", replaceString: "-filelist $ObjFileList")
        return super.prepare(content.dropLast() + [newLine])
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
    var inputPath: String

    required init?(desc: String, content: [String]) {
        let arr = desc.split(separator: " ")
        guard arr.count == 5 else { return nil }
        self.inputPath = String(arr[1])
        let _target = arr.last!.replacingOccurrences(of: ")", with: "")
        super.init(target: _target, name: String(arr[0]), content: content)
    }

    override func execute(params: [String], done: (String?) -> Void) {
        guard let filePath = params.first, let fileName = filePath.getFileNameWithoutType() else { return }
        let defines = ["FILEPATH=\(filePath)", "FILENAME=\(fileName)"]
        super.execute(params: defines, done: done)
    }

    override func prepare(_ content: [String]) -> [String] {
        guard let lastLine = content.last else { return [] }
        guard let fileName = inputPath.getFileNameWithoutType() else { return [] }
        let newLine = lastLine.replacingOccurrences(of: inputPath, with: "$FILEPATH")
            .replacingOccurrences(of: fileName, with: "$FILENAME")
        return super.prepare(content.dropLast() + [newLine])
    }
}

class CommandCopyPNGFile: Command {
    var outputPath: String
    var inputPath: String

    required init?(desc: String, content: [String]) {
        let arr = desc.split(separator: " ")
        guard arr.count == 6 else { return nil }
        self.outputPath = String(arr[1])
        self.inputPath = String(arr[2])
        let _target = arr.last!.replacingOccurrences(of: ")", with: "")
        super.init(target: _target, name: String(arr[0]), content: content)
    }

    override func execute(params: [String], done: (String?) -> Void) {
        guard params.count == 2 else { return }
        let defines = ["INPUT=\(params[0])", "OUTPUT=\(params[1])"]
        super.execute(params: defines, done: done)
    }

    override func prepare(_ content: [String]) -> [String] {
        guard let lastLine = content.last else { return [] }
        let newLine = lastLine.replacingOccurrences(of: inputPath, with: "$INPUT")
            .replacingOccurrences(of: outputPath, with: "$OUTPUT")
        return super.prepare(content.dropLast() + [newLine])
    }
}

class CommandCodeSign: Command {
    var outputPath: String

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
}
