import Foundation

protocol CommandExecuting {
    func execute(script: String) -> FileHandle?
    func execute(commandName: String) -> String?
    func execute(commandName: String, arguments: [String]) -> String?
}


func readStringSync(fileHandle: FileHandle) -> String? {
    let data = fileHandle.readDataToEndOfFile()
    let output = String(data: data, encoding: String.Encoding.utf8)
    return output
}

final class Bash: CommandExecuting {

    // MARK: - CommandExecuting
    
    func execute(script: String) -> FileHandle? {
        guard let scriptFilePath = tempFilePath() else { return nil }
        let data = script.data(using: .utf8)
        if FileManager.default.createFile(atPath: scriptFilePath, contents: data, attributes: nil) {
            return execute(command: "/bin/bash", arguments: [scriptFilePath])
        } else {
            return nil
        }
    }

    func execute(commandName: String) -> String? {
        return execute(commandName: commandName, arguments: [])
    }

    func execute(commandName: String, arguments: [String]) -> String? {
        let handleWhich = execute(command: "/bin/bash" , arguments: ["-l", "-c", "which \(commandName)"])
        guard var bashCommand = readStringSync(fileHandle: handleWhich) else { return "\(commandName) not found" }
        bashCommand = bashCommand.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        let handle = execute(command: bashCommand, arguments: arguments)
        return readStringSync(fileHandle: handle)
    }

    // MARK: Private

    private func execute(command: String, arguments: [String] = []) -> FileHandle {
        let process = Process()
        process.launchPath = command
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()
        return pipe.fileHandleForReading
    }
}

/*let bash: CommandExecuting = Bash()*/
/*if let lsOutput = bash.execute(commandName: "ls") { print(lsOutput) }*/
/*if let lsWithArgumentsOutput = bash.execute(commandName: "ls", arguments: ["-la"]) { print(lsWithArgumentsOutput) }*/

