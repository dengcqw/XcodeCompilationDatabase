import Foundation

let outPath = FileManager.default.currentDirectoryPath 
    + "/compile_commands.json"

// TODO:
// - read from log file: done
// - read from xcodebuild script: done
// - read from shell pipe, as read from stdin: done
// - store command with JSON: done
// - command line standard support


// run command
runCommand()
exit(0)

// check exist commands
//if let saveCommands = restoreCommands() {
//    saveCommands.forEach { (key, commands) in
//        print(key)
//        commands.forEach { print("    \($0.name)")}
//        print("    ")
//    }
//    exit(0)
//}


// TODO: how to clean only one target
// NOTE: open xcode and clean project, then xcodebuild fail
/*
 Build system information
 error: unable to attach DB: error: accessing build database "/Users/dengjinlong/Library/Developer/Xcode/DerivedData/TVGuor-fomvyhexvtnxgiapyrtldmbgjnod/Build/Intermediates.noindex/XCBuildData/build.db": database is locked Possibly there are two concurrent builds running in the same filesystem location.
 */
/*
  whole module building cause symbol mixed
 */
let cleancmd = "xcodebuild clean -workspace TVGuor.xcworkspace -scheme TVGuor -configuration Debug -arch arm64"
let cdcmd = "cd /Users/dengjinlong/Documents/8-tvguo/2-TVGuoiOSApp"
// use pipe
let buildcmd = "xcodebuild build -workspace TVGuor.xcworkspace -scheme TVGuor -configuration Debug SWIFT_COMPILATION_MODE=singlefile SWIFT_WHOLE_MODULE_OPTIMIZATION=NO -arch arm64"
let scriptCmd = [cdcmd, cleancmd, buildcmd].joined(separator: ";")

#if false
let logSource = ScriptSource.init(shellCommand: scriptCmd)
#elseif true

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

