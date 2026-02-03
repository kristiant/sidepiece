import Foundation
import SwiftUI

/// Manages persistence of app configuration and profiles
@MainActor
final class ConfigurationManager: ObservableObject {
    static let shared = ConfigurationManager()
    
    // MARK: - Published Properties
    
    @Published private(set) var configuration: AppConfiguration
    @Published private(set) var profiles: [Profile]
    
    // MARK: - File Paths
    
    private let fileManager = FileManager.default
    
    private var appSupportDirectory: URL {
        let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupport = urls.first!.appendingPathComponent("Sidepiece", isDirectory: true)
        
        // Ensure directory exists
        try? fileManager.createDirectory(at: appSupport, withIntermediateDirectories: true)
        
        return appSupport
    }
    
    private var configurationFileURL: URL {
        appSupportDirectory.appendingPathComponent("config.json")
    }
    
    private var profilesDirectoryURL: URL {
        appSupportDirectory.appendingPathComponent("profiles", isDirectory: true)
    }
    
    // MARK: - Initialisation
    
    var activeProfileId: UUID? {
        get { configuration.activeProfileId }
        set {
            self.configuration.activeProfileId = newValue
            saveConfiguration()
        }
    }

    private init() {
        // Load existing or create defaults
        self.configuration = AppConfiguration.default
        self.profiles = []
        
        loadConfiguration()
        loadProfiles()
        
        // Create default profile if none exist
        if profiles.isEmpty {
            let defaultProfile = Profile.createDefault()
            profiles = [defaultProfile]
            configuration.activeProfileId = defaultProfile.id
            saveProfiles()
            saveConfiguration()
        }
    }
    
    // MARK: - Generic Binding Helper
    
    /// Generates a SwiftUI Binding that automatically persists changes to disk
    func binding<T>(_ keyPath: WritableKeyPath<AppConfiguration, T>) -> Binding<T> {
        Binding(
            get: { self.configuration[keyPath: keyPath] },
            set: { newValue in
                var config = self.configuration
                config[keyPath: keyPath] = newValue
                self.configuration = config
                self.saveConfiguration()
            }
        )
    }

    // MARK: - Configuration
    
    func updateConfiguration(_ configuration: AppConfiguration) {
        self.configuration = configuration
        saveConfiguration()
    }
    
    private func loadConfiguration() {
        configuration = Persistence.load(from: configurationFileURL, fallback: .default)
    }
    
    private func saveConfiguration() {
        Persistence.save(configuration, to: configurationFileURL)
    }
    
    // MARK: - Profiles
    
    var activeProfile: Profile? {
        profiles.first { $0.id == configuration.activeProfileId }
    }
    
    func setActiveProfile(_ profile: Profile) {
        configuration.activeProfileId = profile.id
        
        // Update isActive flag on all profiles
        for index in profiles.indices {
            profiles[index].isActive = (profiles[index].id == profile.id)
        }
        
        saveConfiguration()
        saveProfiles()
    }
    
    func cycleProfiles(direction: KeyBinding.CycleDirection) {
        guard !profiles.isEmpty else { return }
        
        let currentIndex = profiles.firstIndex(where: { $0.id == configuration.activeProfileId }) ?? 0
        var nextIndex: Int
        
        switch direction {
        case .next:
            nextIndex = (currentIndex + 1) % profiles.count
        case .previous:
            nextIndex = (currentIndex - 1 + profiles.count) % profiles.count
        }
        
        setActiveProfile(profiles[nextIndex])
    }
    
    func addProfile(_ profile: Profile) {
        profiles.append(profile)
        saveProfiles()
    }
    
    func updateProfile(_ profile: Profile) {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        profiles[index] = profile
        saveProfiles()
    }
    
    func deleteProfile(_ profile: Profile) {
        // Don't delete the last profile
        guard profiles.count > 1 else { return }
        
        profiles.removeAll { $0.id == profile.id }
        
        // If we deleted the active profile, activate another one
        if configuration.activeProfileId == profile.id {
            if let firstProfile = profiles.first {
                setActiveProfile(firstProfile)
            }
        }
        
        saveProfiles()
    }
    
    func clearAllBindings() {
        guard var profile = activeProfile else { return }
        profile.bindings = []
        profile.updatedAt = Date()
        updateProfile(profile)
    }
    
    private func loadProfiles() {
        try? fileManager.createDirectory(at: profilesDirectoryURL, withIntermediateDirectories: true)
        
        guard let files = try? fileManager.contentsOfDirectory(at: profilesDirectoryURL, includingPropertiesForKeys: nil) else {
            return
        }
        
        profiles = files.filter { $0.pathExtension == "json" }
            .compactMap { url in
                Persistence.load(from: url, silent: false)
            }
    }
    
    private func saveProfiles() {
        try? fileManager.createDirectory(at: profilesDirectoryURL, withIntermediateDirectories: true)
        
        for profile in profiles {
            let url = profilesDirectoryURL.appendingPathComponent("\(profile.id.uuidString).json")
            Persistence.save(profile, to: url, pretty: true)
        }
    }
    
    // MARK: - Import/Export
    
    func exportUnifiedData(snippets: [Snippet], categories: [SnippetCategory], to url: URL) throws {
        let exportData = UnifiedExportData(
            configuration: configuration,
            profiles: profiles,
            snippets: snippets,
            categories: categories,
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(exportData)
        try data.write(to: url, options: .atomic)
    }
    
    func importUnifiedData(from url: URL) throws -> UnifiedExportData {
        let data = try Data(contentsOf: url)
        let exportData = try JSONDecoder().decode(UnifiedExportData.self, from: data)
        
        // Update local state
        self.configuration = exportData.configuration
        self.profiles = exportData.profiles
        
        saveConfiguration()
        saveProfiles()
        
        return exportData
    }
}

// MARK: - Export Format

struct UnifiedExportData: Codable {
    let configuration: AppConfiguration
    let profiles: [Profile]
    let snippets: [Snippet]
    let categories: [SnippetCategory]
    let exportDate: Date
    let appVersion: String
}
