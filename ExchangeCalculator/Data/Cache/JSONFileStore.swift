//
//  JSONFileStore.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

import Foundation

nonisolated struct JSONFileStore<Value: Codable> {
    private let fileURL: URL
    private let fileManager: FileManager

    init(
        filename: String,
        directory: URL = FileManager.default.exchangeCalculatorCacheDirectory,
        fileManager: FileManager = .default
    ) {
        self.fileURL = directory.appendingPathComponent(filename)
        self.fileManager = fileManager
    }

    func load() throws -> Value? {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(Value.self, from: data)
    }

    func save(_ value: Value) throws {
        let directory = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let data = try JSONEncoder().encode(value)
        try data.write(to: fileURL, options: [.atomic])
    }
}

private extension FileManager {
    nonisolated var exchangeCalculatorCacheDirectory: URL {
        urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ExchangeCalculator", isDirectory: true)
    }
}

