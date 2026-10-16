import Foundation
import OSLog

/// Atomic JSON persistence. Unreadable files are moved aside as `.corrupt` and the fallback is used.
enum Persistence {
    private static let logger = Logger(category: "Persistence")

    static let dir: URL = {
        let url = URL.applicationSupportDirectory.appending(path: "Sidepiece", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()

    static func load<T: Decodable>(from url: URL, fallback: T) -> T {
        guard let data = try? Data(contentsOf: url) else { return fallback }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            logger.error("Archiving corrupt \(url.lastPathComponent): \(error)")
            let backup = url.appendingPathExtension("corrupt")
            try? FileManager.default.removeItem(at: backup)
            try? FileManager.default.moveItem(at: url, to: backup)
            return fallback
        }
    }

    static func save<T: Encodable>(_ value: T, to url: URL) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            try encoder.encode(value).write(to: url, options: .atomic)
        } catch {
            logger.error("Failed to save \(url.lastPathComponent): \(error)")
        }
    }
}
