//
//  FileLogger.swift
//  BT-Tracking
//
//  Created by Tomas Svoboda on 16/03/2020.
//  Copyright © 2020 Covid19CZ. All rights reserved.
//

import Foundation

final class FileLogger {
    
    static let shared = FileLogger()!

    private(set) var fileURL: URL
    private var fileHandle: FileHandle

    init?() {
        guard let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else { return nil }
        self.fileURL = URL(fileURLWithPath: documents).appendingPathComponent("application.log")

        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
        }
        guard let fileHandle = try? FileHandle(forWritingTo: fileURL) else { return nil }
        fileHandle.seekToEndOfFile()

        self.fileHandle = fileHandle
    }
    
    func writeLog(_ text: String) {
        let newText = "\n" + formatter.string(from: Date()) + " " + text
        guard let data = newText.data(using: .utf8) else {
            print("Unexpected error writing to log")
            return
        }
        fileHandle.write(data)
    }
    
    func getLog() -> String {
        do {
            return try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            print("Unexpected error reading from log: \(error)")
            return ""
        }
    }
    
    func purgeLogs() {
        do {
            fileHandle.closeFile()
            try FileManager.default.removeItem(at: fileURL)

            FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
            guard let fileHandle = try? FileHandle(forWritingTo: fileURL) else { return }
            self.fileHandle = fileHandle
        } catch {
            print("Unexpected error writing to log: \(error)")
        }
    }
}

private var formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .medium
    return formatter
}()
