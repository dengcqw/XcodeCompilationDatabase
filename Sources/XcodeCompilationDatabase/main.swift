import XcodeCompilationDatabaseCore
import Foundation

let outPath = FileManager.default.currentDirectoryPath 
    + "/compile_commands.json"

// TODO:
// - read from log file: done
// - read from xcodebuild script: done
// - read from shell pipe, as read from stdin: done


// TODO: how to clean only one target
let cleancmd = "xcodebuild clean -workspace TVGuor.xcworkspace -scheme TVGuor -configuration Debug -arch arm64"
let cdcmd = "cd /Users/dengjinlong/Documents/8-tvguo/2-TVGuoiOSApp"
// use pipe
let buildcmd = "xcodebuild build -workspace TVGuor.xcworkspace -scheme TVGuor -configuration Debug SWIFT_COMPILATION_MODE=singlefile SWIFT_WHOLE_MODULE_OPTIMIZATION=NO -arch arm64"
let scriptCmd = [cdcmd, cleancmd, buildcmd].joined(separator: ";")

#if false
let logSource = ScriptSource.init(shellCommand: scriptCmd)
#elseif true

let command = restoreCommands()
exit(0)
guard CommandLine.arguments.count > 1 else {
    print("""
          usage: /path/to/xcodebuild.log
          """)
    exit(0)
}
let logPath = CommandLine.arguments[1]
let logSource = FileSource.init(filePath: logPath)
#else
let logSource = StdinSource.init()
#endif
splitLog(logSource)
