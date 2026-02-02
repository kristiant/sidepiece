import Foundation

/// Global application settings
struct AppConfiguration: Codable, Equatable {
    
    // MARK: - Properties
    
    var launchAtLogin: Bool
    var showMenuBarIcon: Bool
    var playSoundOnCopy: Bool
    var showNotificationOnCopy: Bool
    var activeProfileId: UUID?
    var requireModifierKey: Bool
    var modifierKey: ModifierKeyOption
    var theme: AppTheme
    var autoPaste: Bool
    var autoEnterAfterPaste: Bool
    var autoExitFolderMode: Bool
    var autoPeakFolderContents: Bool
    
    // MARK: - Initialisation
    
    init(
        launchAtLogin: Bool = false,
        showMenuBarIcon: Bool = true,
        playSoundOnCopy: Bool = true,
        showNotificationOnCopy: Bool = false,
        activeProfileId: UUID? = nil,
        requireModifierKey: Bool = false,
        modifierKey: ModifierKeyOption = .fn,
        theme: AppTheme = .system,
        autoPaste: Bool = true,
        autoEnterAfterPaste: Bool = false,
        autoExitFolderMode: Bool = true,
        autoPeakFolderContents: Bool = true
    ) {
        self.launchAtLogin = launchAtLogin
        self.showMenuBarIcon = showMenuBarIcon
        self.playSoundOnCopy = playSoundOnCopy
        self.showNotificationOnCopy = showNotificationOnCopy
        self.activeProfileId = activeProfileId
        self.requireModifierKey = requireModifierKey
        self.modifierKey = modifierKey
        self.theme = theme
        self.autoPaste = autoPaste
        self.autoEnterAfterPaste = autoEnterAfterPaste
        self.autoExitFolderMode = autoExitFolderMode
        self.autoPeakFolderContents = autoPeakFolderContents
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        self.showMenuBarIcon = try container.decodeIfPresent(Bool.self, forKey: .showMenuBarIcon) ?? true
        self.playSoundOnCopy = try container.decodeIfPresent(Bool.self, forKey: .playSoundOnCopy) ?? true
        self.showNotificationOnCopy = try container.decodeIfPresent(Bool.self, forKey: .showNotificationOnCopy) ?? false
        self.activeProfileId = try container.decodeIfPresent(UUID.self, forKey: .activeProfileId)
        self.requireModifierKey = try container.decodeIfPresent(Bool.self, forKey: .requireModifierKey) ?? false
        self.modifierKey = try container.decodeIfPresent(ModifierKeyOption.self, forKey: .modifierKey) ?? .fn
        self.theme = try container.decodeIfPresent(AppTheme.self, forKey: .theme) ?? .system
        self.autoPaste = try container.decodeIfPresent(Bool.self, forKey: .autoPaste) ?? true
        self.autoEnterAfterPaste = try container.decodeIfPresent(Bool.self, forKey: .autoEnterAfterPaste) ?? false
        self.autoExitFolderMode = try container.decodeIfPresent(Bool.self, forKey: .autoExitFolderMode) ?? true
        self.autoPeakFolderContents = try container.decodeIfPresent(Bool.self, forKey: .autoPeakFolderContents) ?? true
    }
    
    // MARK: - Default
    
    static let `default` = AppConfiguration()
}

// MARK: - Modifier Key Options

enum ModifierKeyOption: String, Codable, CaseIterable {
    case fn = "fn"
    case control = "control"
    case option = "option"
    case command = "command"
    
    var displayName: String {
        switch self {
        case .fn: return "Fn"
        case .control: return "Control (⌃)"
        case .option: return "Option (⌥)"
        case .command: return "Command (⌘)"
        }
    }
    
    var symbol: String {
        switch self {
        case .fn: return "fn"
        case .control: return "⌃"
        case .option: return "⌥"
        case .command: return "⌘"
        }
    }
}

// MARK: - App Theme

enum AppTheme: String, Codable, CaseIterable {
    case system
    case light
    case dark
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}
