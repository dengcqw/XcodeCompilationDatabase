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

/// entity to store command description
class Command: CommandDescription {
    var target: String
    var name: String
    var content: [String] = []
    var prepared: Bool = false

    init(target: String, name: String, content: [String]) {
        self.target = target
        self.name = name
        self.content = prepare(content)
    }

    func execute(params: [String], done: (String?)->Void) {
        if !prepared {
            self.content = prepare(content)
        }
        let bash: CommandExecuting = Bash()
        guard let fileHandle = bash.execute(script: (params + content).joined(separator: ";")) else {
            done(nil)
            return
        }
        let output = readStringSync(fileHandle: fileHandle)
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
    var wholeModuleOptimization: Bool = false

    required init?(desc: String, content: [String]) {
        let arr = desc.split(separator: " ")
        guard arr.count == 7 else { return nil }
        self.arch = String(arr[2])
        let _target = arr.last!.replacingOccurrences(of: ")", with: "")

        super.init(target: _target, name: String(arr[0]), content: content)
        if var lastLine = content.last, let range = lastLine.range(of: "-whole-module-optimization") {
            lastLine.replaceSubrange(range, with: "")
            self.wholeModuleOptimization = true
        }
        if let lastLine = content.last {
            cacheFileList(lastLine)
        }
    }

    override func equal(to: Command) -> Bool {
        if let to = to as? CommandCompileSwiftSources {
            return arch == to.arch &&
                super.equal(to: to)
        }
        return false
    }
    
    func getFileName() -> String {
        return "\(target)-swiftfiles"
    }
    
    func cacheFileList(_ compileCommand: String) {
        let splited = compileCommand.split(separator: " ")
        var fileList = ""
        for str in splited {
            if str.hasSuffix(".swift") {
                fileList.append(String(str))
                fileList.append("\n")
            }
        }
        guard let workingDir = getWorkingDir() else {
            assert(false, "working dir create err")
            return
        }
        do {
            try fileList.write(toFile: workingDir + "/\(getFileName())", atomically: true, encoding: .utf8)
        } catch _ {
            print("cache swift files error")
        }
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
        } else if arr.count == 6 { // this situation may be removed
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
        if let to = to as? CommandCompileSwift {
            return arch == to.arch &&
                super.equal(to: to)
        }
        return false
    }
}

class CommandMergeSwiftModule: Command {
    var arch: String
    var swiftmodulePath: String?  //-o  .../TVGuor.build/Objects-normal/x86_64/TVGuor.swiftmodule

    init?(desc: String, content: [String]) {
        let arr = desc.split(separator: " ")
        guard arr.count == 6 else { return nil }
        self.arch = String(arr[2])
        let _target = arr.last!.replacingOccurrences(of: ")", with: "")
        super.init(target: _target, name: String(arr[0]), content: content)
    }

    override func execute(params: [String], done: (String?) -> Void) {
        guard let moduleList = params.first else { return }
        let defines = ["ModuleList=\(moduleList)"]
        super.execute(params: defines, done: done)
    }

    override func prepare(_ content: [String]) -> [String] {
        guard let lastLine: String = content.last else { return [] }
        var newLine = lastLine
        newLine.replaceCommandLineParam(withPrefix: "-filelist", replaceString: "-filelist $ModuleList")
        
        if let range = lastLine.rangeOfOptionContent(option: "-o", reverse: true) {
            let modulePath = String(lastLine[range])
            swiftmodulePath = modulePath
            
            if let idx = modulePath.lastIndex(of: "/") {
                let dirPath = String(modulePath.prefix(upTo: idx))
                let mergedModule = String(modulePath.suffix(from: modulePath.index(after: idx)))
                assert(FileManager.default.fileExists(atPath: dirPath), "object folder not exist: \(dirPath)")
                
                var moduleList = ""
                let enumerator = FileManager.default.enumerator(atPath: dirPath)
                while let element = enumerator?.nextObject() as? String {
                    // mergedModule in the same folder, cannot include in file list
                    if element.hasSuffix(".swiftmodule") && !element.hasSuffix(mergedModule) {
                        moduleList.append(element)
                        moduleList.append("\n")
                    }
                }
                if let file = tempFilePath() {
                    print(file)
                    do {
                        try moduleList.write(toFile: file, atomically: true, encoding: .utf8)
                    } catch _ {
                        print("cache swift module list err:")
                    }
                }
            }
        }
        return super.prepare(content.dropLast() + [newLine])
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
