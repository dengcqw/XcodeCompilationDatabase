import Foundation

protocol CommandExecuting {
    func execute(commandName: String) -> String?
    func execute(commandName: String, arguments: [String]) -> String?
}

final class Bash: CommandExecuting {

    // MARK: - CommandExecuting

    func execute(commandName: String) -> String? {
        return execute(commandName: commandName, arguments: [])
    }

    func execute(commandName: String, arguments: [String]) -> String? {
        guard var bashCommand = execute(command: "/bin/bash" , arguments: ["-l", "-c", "which \(commandName)"]) else { return "\(commandName) not found" }
        bashCommand = bashCommand.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        return execute(command: bashCommand, arguments: arguments)
    }

    // MARK: Private

    private func execute(command: String, arguments: [String] = []) -> String? {
        let process = Process()
        process.launchPath = command
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: String.Encoding.utf8)
        return output
    }
}

/*let bash: CommandExecuting = Bash()*/
/*if let lsOutput = bash.execute(commandName: "ls") { print(lsOutput) }*/
/*if let lsWithArgumentsOutput = bash.execute(commandName: "ls", arguments: ["-la"]) { print(lsWithArgumentsOutput) }*/

