import Foundation
import Combine

/// Repository for managing snippets and key bindings
final class SnippetRepository: ObservableObject {
    
    private let configurationManager: ConfigurationManager
    
    @Published private(set) var snippets: [Snippet] = []
    @Published private(set) var categories: [SnippetCategory] = []
    
    init(configurationManager: ConfigurationManager) {
        self.configurationManager = configurationManager
        loadSnippets()
        loadCategories()
    }
    
    var activeProfile: Profile? { configurationManager.activeProfile }
    
    func getBinding(for key: NumpadKey) -> KeyBinding? {
        activeProfile?.binding(for: key)
    }
    
    var activeBindings: [KeyBinding] { activeProfile?.bindings ?? [] }
    
    func updateBinding(_ binding: KeyBinding) {
        guard var profile = activeProfile else { return }
        profile = profile.withBinding(binding)
        configurationManager.updateProfile(profile)
    }
    
    func removeBinding(for key: NumpadKey) {
        guard var profile = activeProfile else { return }
        profile = profile.withoutBinding(for: key)
        configurationManager.updateProfile(profile)
    }
    
    func recordUsage(for snippet: Snippet) {
        guard var updated = snippets.first(where: { $0.id == snippet.id }) else { return }
        updated.usageCount += 1
        updated.lastUsedAt = Date()
        updateSnippet(updated)
    }
    
    // MARK: - Snippet CRUD
    
    func addSnippet(_ snippet: Snippet) { snippets.append(snippet); saveSnippets() }
    func updateSnippet(_ snippet: Snippet) {
        guard let i = snippets.firstIndex(where: { $0.id == snippet.id }) else { return }
        snippets[i] = snippet; saveSnippets()
    }
    func deleteSnippet(_ snippet: Snippet) { snippets.removeAll { $0.id == snippet.id }; saveSnippets() }
    
    // MARK: - Persistence
    
    private var appSupport: URL {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Sidepiece")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    
    private func loadSnippets() {
        let url = appSupport.appendingPathComponent("snippets.json")
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Snippet].self, from: data) else {
            snippets = Snippet.samples; saveSnippets(); return
        }
        snippets = decoded
    }
    
    private func saveSnippets() {
        let url = appSupport.appendingPathComponent("snippets.json")
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted]
        guard let data = try? encoder.encode(snippets) else { return }
        try? data.write(to: url, options: .atomic)
    }
    
    private func loadCategories() {
        let url = appSupport.appendingPathComponent("categories.json")
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([SnippetCategory].self, from: data) else {
            categories = SnippetCategory.defaults; saveCategories(); return
        }
        categories = decoded
    }
    
    private func saveCategories() {
        let url = appSupport.appendingPathComponent("categories.json")
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted]
        guard let data = try? encoder.encode(categories) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
