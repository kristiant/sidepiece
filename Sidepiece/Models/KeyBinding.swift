import Foundation

struct KeyBinding: Identifiable, Codable, Equatable {
    
    enum Action: Codable, Equatable {
        case snippet(id: UUID)
        case folder(id: UUID)
        case switchProfile(id: UUID)
        case cycleProfile(direction: CycleDirection)
        case appFunction(AppFunction)
        case launchApp(bundleId: String)
        case runCommand(command: String)

        var displayName: String {
            switch self {
            case .snippet:               "Snippet"
            case .folder:                "Folder"
            case .switchProfile:         "Switch Profile"
            case .cycleProfile(let d):   "Cycle Profiles (\(d.rawValue.capitalized))"
            case .appFunction(let f):    f.displayName
            case .launchApp(let id):     "Launch: \(id)"
            case .runCommand(let cmd):   cmd.split(separator: " ").prefix(3).joined(separator: " ")
            }
        }
    }

    enum CycleDirection: String, Codable {
        case next
        case previous
    }
    
    enum AppFunction: String, Codable, CaseIterable {
        case peakSnippets
        case cycleWindows
        case appExpose
        case missionControl

        var displayName: String {
            switch self {
            case .peakSnippets:   "Peak Snippets"
            case .cycleWindows:   "Cycle Windows"
            case .appExpose:      "App Exposé"
            case .missionControl: "Mission Control"
            }
        }

        var icon: String {
            switch self {
            case .peakSnippets:   "eye.fill"
            case .cycleWindows:   "rectangle.2.swap"
            case .appExpose:      "rectangle.3.group.fill"
            case .missionControl: "square.3.layers.3d.top.filled"
            }
        }
    }
    
    let id: UUID
    var key: NumpadKey
    var action: Action
    var isEnabled: Bool
    var createdAt: Date
    var updatedAt: Date
    
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.key = try container.decode(NumpadKey.self, forKey: .key)
        self.isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        if let action = try? container.decode(Action.self, forKey: .action) {
            self.action = action
        } else if let snippet = try? container.decode(Snippet.self, forKey: .snippet) {
            self.action = .snippet(id: snippet.id)
        } else {
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

