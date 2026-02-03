import Foundation

/// Represents a mapping between a numpad key and an action
struct KeyBinding: Identifiable, Codable, Equatable {
    
    enum Action: Codable, Equatable {
        case snippet(id: UUID)
        case folder(id: UUID)
        case switchProfile(id: UUID)
        case cycleProfile(direction: CycleDirection)
        case appFunction(AppFunction)
        
        var displayName: String {
            switch self {
            case .snippet:
                return "Snippet"
            case .folder:
                return "Folder"
            case .switchProfile:
                return "Switch Profile"
            case .cycleProfile(let direction):
                return "Cycle Profiles (\(direction.rawValue.capitalized))"
            case .appFunction(let function):
                return function.displayName
            }
        }
    }

    enum CycleDirection: String, Codable {
        case next
        case previous
    }
    
    enum AppFunction: String, Codable, CaseIterable {
        case peakSnippets
        
        var displayName: String {
            switch self {
            case .peakSnippets: return "Peak Snippets"
            }
        }
        
        var icon: String {
            switch self {
            case .peakSnippets: return "eye.fill"
            }
        }
    }
    
    // MARK: - Properties
    
    let id: UUID
    var key: NumpadKey
    var action: Action
    var isEnabled: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Initialisation
    
    init(
        id: UUID = UUID(),
        key: NumpadKey,
        action: Action,
        isEnabled: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.key = key
        self.action = action
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Backward Compatibility
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.key = try container.decode(NumpadKey.self, forKey: .key)
        self.isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        // Handle migration from snippet to action
        if let action = try? container.decode(Action.self, forKey: .action) {
            self.action = action
        } else if let snippet = try? container.decode(Snippet.self, forKey: .snippet) {
            self.action = .snippet(id: snippet.id)
        } else {
            // Default to empty if somehow both missing (should not happen normally)
            throw DecodingError.dataCorruptedError(forKey: .action, in: container, debugDescription: "Missing action or snippet data")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(key, forKey: .key)
        try container.encode(action, forKey: .action)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, key, action, snippet, isEnabled, createdAt, updatedAt
    }
}

// MARK: - Helper for legacy constructors
extension KeyBinding {
    init(key: NumpadKey, snippet: Snippet) {
        self.init(key: key, action: .snippet(id: snippet.id))
    }
}
