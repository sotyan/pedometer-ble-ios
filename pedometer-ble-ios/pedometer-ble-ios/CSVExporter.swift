//
//  CSVExporter.swift
//  pedometer-ble-ios
//
//  Created by k24098kk on 2026/06/27.
//

import Foundation
import Combine

final class CSVExporter: ObservableObject {
    @Published private(set) var isLogging = false
    private(set) var currentFileURL: URL?

    private var fileHandle: FileHandle?
    private let timestampFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    func startLogging() {
        guard !isLogging else { return }

        let nameFormatter = DateFormatter()
        nameFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let filename = "acceleration_\(nameFormatter.string(from: Date())).csv"
        let url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)

        FileManager.default.createFile(atPath: url.path, contents: nil)
        guard let handle = try? FileHandle(forWritingTo: url) else { return }
        handle.write(Data("timestamp,x,y,z\n".utf8))

        fileHandle = handle
        currentFileURL = url
        isLogging = true
    }

    func append(_ data: AccelerationData) {
        guard isLogging, let handle = fileHandle else { return }
        let line = "\(timestampFormatter.string(from: Date())),\(data.x),\(data.y),\(data.z)\n"
        handle.write(Data(line.utf8))
    }

    func stopLogging() -> URL? {
        guard isLogging else { return nil }
        fileHandle?.closeFile()
        fileHandle = nil
        isLogging = false
        return currentFileURL
    }
}
