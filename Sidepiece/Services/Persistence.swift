import Foundation

/// Internal utility for atomic JSON persistence with automatic backup of corrupted files
enum Persistence {
    
    static func load<T: Decodable>(from url: URL, fallback: T? = nil, silent: Bool = true) -> T {
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                let data = try Data(contentsOf: url)
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                if !silent {
                    print("Sidepiece Error: Corruption detected in \(url.lastPathComponent). Archiving as .corrupt")
                }
                
                // Backup corrupted file
                let backupUrl = url.appendingPathExtension("corrupt")
                try? FileManager.default.removeItem(at: backupUrl)
                try? FileManager.default.moveItem(at: url, to: backupUrl)
            }
        }
        
        if let fallback = fallback { return fallback }
        if let defaultable = T.self as? Defaultable.Type, let defaultValue = defaultable.defaultValue as? T {
            return defaultValue
        }
        
        fatalError("Sidepiece: Failed to load \(url.lastPathComponent) and no fallback for \(T.self)")
    }
    
    static func save<T: Encodable>(_ value: T, to url: URL, pretty: Bool = false) {
        do {
            let encoder = JSONEncoder()
            if pretty {
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            }
            let data = try encoder.encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            print("Sidepiece Error: Failed to save \(url.lastPathComponent): \(error)")
        }
    }
}

/// Helper protocol to avoid fatalErrors in load
protocol Defaultable {
    static var defaultValue: Self { get }
}

extension AppConfiguration: Defaultable {
    static var defaultValue: AppConfiguration { .default }
}
