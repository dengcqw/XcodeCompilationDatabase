//
//  CommandStorage.swift
//  XcodeCompilationDatabase
//
//  Created by Deng Jinlong on 2019/4/27.
//

import Foundation

private func archivePath() -> String {
    return getWorkingDir() + "/archivedCommands"
}

func storeCommands(_ commands: [[Command]]) {
    NSKeyedArchiver.archiveRootObject(commands, toFile: archivePath())
}

func restoreCommands() -> [[Command]] {
    assert(FileManager.default.fileExists(atPath: archivePath()))
    let str1 = try? NSString.init(contentsOfFile: archivePath(), encoding: 0)
    let data = try! Data.init(contentsOf: URL(fileURLWithPath: archivePath()), options: [])
    let commands = NSKeyedUnarchiver.unarchiveObject(withFile: archivePath())
    let cmds = NSKeyedUnarchiver.unarchiveObject(with: data)
//    guard let commands = commands as? [[Command]] else { return [] }
    return []
}
