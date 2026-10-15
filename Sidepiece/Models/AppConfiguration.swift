import Foundation

struct AppConfiguration: Codable, Equatable {
    var launchAtLogin = false
    var showMenuBarIcon = true
    var showHUD = true
    var playSoundOnCopy = true
    var showNotificationOnCopy = false
    var activeProfileId: UUID?
    var requireModifierKey = false
    var modifierKey = ModifierKeyOption.fn
    var theme = AppTheme.system
    var autoPaste = true
    var autoEnterAfterPaste = false
    var autoExitFolderMode = true
    var autoExitFolderAfterSelection = true
    var autoPeakFolderContents = true
    var peakHotkey: NumpadKey?

    static let `default` = AppConfiguration()
}

extension AppConfiguration {
    /// Falls back to defaults for any key missing from older saved configs.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func load<T: Decodable>(_ key: CodingKeys, _ path: WritableKeyPath<Self, T>, into cfg: inout Self) throws {
            if let v = try c.decodeIfPresent(T.self, forKey: key) { cfg[keyPath: path] = v }
        }
        var cfg = Self()
        try load(.launchAtLogin, \.launchAtLogin, into: &cfg)
        try load(.showMenuBarIcon, \.showMenuBarIcon, into: &cfg)
        try load(.showHUD, \.showHUD, into: &cfg)
        try load(.playSoundOnCopy, \.playSoundOnCopy, into: &cfg)
        try load(.showNotificationOnCopy, \.showNotificationOnCopy, into: &cfg)
        try load(.activeProfileId, \.activeProfileId, into: &cfg)
        try load(.requireModifierKey, \.requireModifierKey, into: &cfg)
        try load(.modifierKey, \.modifierKey, into: &cfg)
        try load(.theme, \.theme, into: &cfg)
        try load(.autoPaste, \.autoPaste, into: &cfg)
        try load(.autoEnterAfterPaste, \.autoEnterAfterPaste, into: &cfg)
        try load(.autoExitFolderMode, \.autoExitFolderMode, into: &cfg)
        try load(.autoExitFolderAfterSelection, \.autoExitFolderAfterSelection, into: &cfg)
        try load(.autoPeakFolderContents, \.autoPeakFolderContents, into: &cfg)
        try load(.peakHotkey, \.peakHotkey, into: &cfg)
        self = cfg
    }
}

enum ModifierKeyOption: String, Codable, CaseIterable {
    case fn, control, option, command

    var displayName: String {
        switch self {
        case .fn: "Fn"
        case .control: "Control (⌃)"
        case .option: "Option (⌥)"
        case .command: "Command (⌘)"
        }
    }

    var symbol: String {
        switch self {
        case .fn: "fn"
        case .control: "⌃"
        case .option: "⌥"
        case .command: "⌘"
        }
    }
}

enum AppTheme: String, Codable, CaseIterable {
    case system, light, dark

    var displayName: String { rawValue.capitalized }
}
