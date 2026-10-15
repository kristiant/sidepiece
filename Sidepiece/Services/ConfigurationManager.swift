import Foundation
import SwiftUI
import ServiceManagement

@MainActor
final class ConfigurationManager: ObservableObject {
    static let shared = ConfigurationManager()
    
    // MARK: - Published Properties
    
    @Published private(set) var configuration: AppConfiguration {
        didSet {
            if configuration.launchAtLogin != oldValue.launchAtLogin { syncLoginItem() }
        }
    }
    @Published private(set) var profiles: [Profile]
    
    private let configURL = Persistence.dir.appending(path: "config.json")
    private let profilesDir = Persistence.dir.appending(path: "profiles", directoryHint: .isDirectory)

    // MARK: - Initialisation
    
    var activeProfileId: UUID? {
        get { configuration.activeProfileId }
        set {
            self.configuration.activeProfileId = newValue
            saveConfiguration()
        }
    }

    private init() {
        configuration = Persistence.load(from: configURL, fallback: .default)
        profiles = []
        loadProfiles()

        if profiles.isEmpty {
            let defaultProfile = Profile.createDefault()
            profiles = [defaultProfile]
            configuration.activeProfileId = defaultProfile.id
            saveProfiles()
            saveConfiguration()
        }
    }
    
    // MARK: - Generic Binding Helper
    
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

    private func syncLoginItem() {
        do {
            configuration.launchAtLogin ? try SMAppService.mainApp.register() : try SMAppService.mainApp.unregister()
        } catch {
            print("Sidepiece: login item update failed: \(error)")
        }
    }
    
    private func saveConfiguration() {
        Persistence.save(configuration, to: configURL)
    }
    
    // MARK: - Profiles
    
    var activeProfile: Profile? {
        profiles.first { $0.id == configuration.activeProfileId }
    }
    
    func setActiveProfile(_ profile: Profile) {
        configuration.activeProfileId = profile.id
        
        for index in profiles.indices {
            profiles[index].isActive = (profiles[index].id == profile.id)
        }
        
        saveConfiguration()
        saveProfiles()
    }
    
    func cycleProfiles(direction: KeyBinding.CycleDirection) {
        guard !profiles.isEmpty else { return }
        
        let i = profiles.firstIndex { $0.id == configuration.activeProfileId } ?? 0
        let step = direction == .next ? 1 : profiles.count - 1
        setActiveProfile(profiles[(i + step) % profiles.count])
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
        guard profiles.count > 1 else { return }
        profiles.removeAll { $0.id == profile.id }
        if configuration.activeProfileId == profile.id {
            setActiveProfile(profiles[0])
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
        try? FileManager.default.createDirectory(at: profilesDir, withIntermediateDirectories: true)
        let files = (try? FileManager.default.contentsOfDirectory(at: profilesDir, includingPropertiesForKeys: nil)) ?? []
        profiles = files
            .filter { $0.pathExtension == "json" }
            .compactMap { Persistence.load(from: $0, fallback: Profile?.none) }
    }

    private func saveProfiles() {
        for p in profiles {
            Persistence.save(p, to: profilesDir.appending(path: "\(p.id.uuidString).json"))
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
