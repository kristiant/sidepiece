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
    
    // MARK: - Initialisation
    
    init(
        launchAtLogin: Bool = false,
        showMenuBarIcon: Bool = true,
        playSoundOnCopy: Bool = true,
        showNotificationOnCopy: Bool = false,
        activeProfileId: UUID? = nil,
        requireModifierKey: Bool = false,
        modifierKey: ModifierKeyOption = .fn,
        theme: AppTheme = .system
    ) {
        self.launchAtLogin = launchAtLogin
        self.showMenuBarIcon = showMenuBarIcon
        self.playSoundOnCopy = playSoundOnCopy
        self.showNotificationOnCopy = showNotificationOnCopy
        self.activeProfileId = activeProfileId
        self.requireModifierKey = requireModifierKey
        self.modifierKey = modifierKey
        self.theme = theme
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
