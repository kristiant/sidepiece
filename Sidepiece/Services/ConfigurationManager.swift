import Foundation

/// Manages persistence of app configuration and profiles
final class ConfigurationManager: ObservableObject {
    
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
    
    init() {
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
    
    // MARK: - Configuration
    
    func updateConfiguration(_ config: AppConfiguration) {
        configuration = config
        saveConfiguration()
    }
    
    private func loadConfiguration() {
        guard fileManager.fileExists(atPath: configurationFileURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: configurationFileURL)
            configuration = try JSONDecoder().decode(AppConfiguration.self, from: data)
        } catch {
            print("Sidepiece: Failed to load configuration: \(error)")
        }
    }
    
    private func saveConfiguration() {
        do {
            let data = try JSONEncoder().encode(configuration)
            try data.write(to: configurationFileURL, options: .atomic)
        } catch {
            print("Sidepiece: Failed to save configuration: \(error)")
        }
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
    
    private func loadProfiles() {
        // Ensure profiles directory exists
        try? fileManager.createDirectory(at: profilesDirectoryURL, withIntermediateDirectories: true)
        
        guard let files = try? fileManager.contentsOfDirectory(at: profilesDirectoryURL, includingPropertiesForKeys: nil) else {
            return
        }
        
        let jsonFiles = files.filter { $0.pathExtension == "json" }
        
        profiles = jsonFiles.compactMap { url -> Profile? in
            do {
                let data = try Data(contentsOf: url)
                return try JSONDecoder().decode(Profile.self, from: data)
            } catch {
                print("Sidepiece: Failed to load profile at \(url): \(error)")
                return nil
            }
        }
    }
    
    private func saveProfiles() {
        // Ensure profiles directory exists
        try? fileManager.createDirectory(at: profilesDirectoryURL, withIntermediateDirectories: true)
        
        for profile in profiles {
            let filename = "\(profile.id.uuidString).json"
            let fileURL = profilesDirectoryURL.appendingPathComponent(filename)
            
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(profile)
                try data.write(to: fileURL, options: .atomic)
            } catch {
                print("Sidepiece: Failed to save profile '\(profile.name)': \(error)")
            }
        }
    }
    
    // MARK: - Import/Export
    
    func exportConfiguration(to url: URL) throws {
        let exportData = ExportData(
            configuration: configuration,
            profiles: profiles
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(exportData)
        try data.write(to: url, options: .atomic)
    }
    
    func importConfiguration(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let exportData = try JSONDecoder().decode(ExportData.self, from: data)
        
        configuration = exportData.configuration
        profiles = exportData.profiles
        
        saveConfiguration()
        saveProfiles()
    }
}

// MARK: - Export Format

private struct ExportData: Codable {
    let configuration: AppConfiguration
    let profiles: [Profile]
}
