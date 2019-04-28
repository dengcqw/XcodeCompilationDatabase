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

func storeCommands(_ commands: [String: [Command]]) {
    do {
        let data = try JSONEncoder().encode(commands)
        try? data.write(to: URL(fileURLWithPath: archivePath()))
    } catch let err {
        print(err)
    }
}

func restoreCommands() -> [String: [Command]]? {
    let data = try! Data.init(contentsOf: URL(fileURLWithPath: archivePath()), options: [])
    let commands = try? JSONDecoder().decode([String: [Command]].self, from: data)
    return commands
}
