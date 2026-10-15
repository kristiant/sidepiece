import Foundation
import Combine

@MainActor
final class SnippetRepository: ObservableObject {
    static let shared = SnippetRepository()
    
    private let configurationManager = ConfigurationManager.shared
    
    @Published private(set) var snippets: [Snippet] = []
    @Published private(set) var categories: [SnippetCategory] = []
    
    private init() {
        loadSnippets()
        loadCategories()
    }
    
    func getFolderContents(folderId: UUID) -> [FolderItem] {
        getSubCategories(parentId: folderId).map(FolderItem.folder) + getSnippets(in: folderId).map(FolderItem.snippet)
    }
    
    var activeProfile: Profile? { configurationManager.activeProfile }
    
    func getBinding(for key: NumpadKey) -> KeyBinding? {
        activeProfile?.binding(for: key)
    }
    
    var activeBindings: [KeyBinding] { activeProfile?.bindings ?? [] }
    
    func updateBinding(_ binding: KeyBinding) {
        guard let profile = activeProfile else { return }
        configurationManager.updateProfile(profile.withBinding(binding))
    }
    
    func removeBinding(for key: NumpadKey) {
        guard let profile = activeProfile else { return }
        configurationManager.updateProfile(profile.withoutBinding(for: key))
    }
    
    func importData(snippets: [Snippet], categories: [SnippetCategory]) {
        self.snippets = snippets
        self.categories = categories
        saveSnippets()
        saveCategories()
    }
    
    func recordUsage(for snippet: Snippet) {
        guard var updated = snippets.first(where: { $0.id == snippet.id }) else { return }
        updated.usageCount += 1
        updated.lastUsedAt = Date()
        updateSnippet(updated)
    }
    
    func label(for action: KeyBinding.Action) -> String {
        switch action {
        case .snippet(let id): getSnippet(id: id)?.title ?? "Snippet"
        case .folder(let id): getCategory(id: id)?.name ?? "Folder"
        default: action.displayName
        }
    }

    // MARK: - Snippet CRUD
    
    func addSnippet(_ snippet: Snippet) { snippets.append(snippet); saveSnippets() }
    func updateSnippet(_ snippet: Snippet) {
        guard let i = snippets.firstIndex(where: { $0.id == snippet.id }) else { return }
        snippets[i] = snippet; saveSnippets()
    }
    func deleteSnippet(_ snippet: Snippet) { snippets.removeAll { $0.id == snippet.id }; saveSnippets() }
    
    func getSnippets(in categoryId: UUID) -> [Snippet] {
        snippets.filter { $0.categoryId == categoryId }
    }
    func getSnippet(id: UUID) -> Snippet? {
        snippets.first { $0.id == id }
    }
    
    func getCategory(id: UUID) -> SnippetCategory? {
        categories.first { $0.id == id }
    }
    
    func getSubCategories(parentId: UUID) -> [SnippetCategory] {
        categories.filter { $0.parentId == parentId }
    }
    
    // MARK: - Category CRUD
    
    func addCategory(_ category: SnippetCategory) { categories.append(category); saveCategories() }
    func updateCategory(_ category: SnippetCategory) {
        guard let i = categories.firstIndex(where: { $0.id == category.id }) else { return }
        categories[i] = category; saveCategories()
    }
    func deleteCategory(_ categoryId: UUID) {
        for i in snippets.indices where snippets[i].categoryId == categoryId {
            snippets[i].categoryId = nil
        }
        let category = getCategory(id: categoryId)
        for i in categories.indices where categories[i].parentId == categoryId {
            categories[i].parentId = category?.parentId
        }
        
        categories.removeAll { $0.id == categoryId }
        saveSnippets()
        saveCategories()
    }
    
    // MARK: - Movement
    
    func moveSnippet(_ snippetId: UUID, toCategoryId: UUID?) {
        guard let index = snippets.firstIndex(where: { $0.id == snippetId }) else { return }
        snippets[index].categoryId = toCategoryId
        saveSnippets()
    }
    
    func moveCategory(_ categoryId: UUID, toParentId: UUID?) {
        if let toId = toParentId, isDescendant(of: categoryId, target: toId) { return }
        guard let index = categories.firstIndex(where: { $0.id == categoryId }) else { return }
        categories[index].parentId = toParentId
        saveCategories()
    }
    
    private func isDescendant(of categoryId: UUID, target: UUID) -> Bool {
        categoryId == target || getSubCategories(parentId: categoryId).contains { isDescendant(of: $0.id, target: target) }
    }
    
    // MARK: - Persistence

    private let snippetsURL = Persistence.dir.appending(path: "snippets.json")
    private let categoriesURL = Persistence.dir.appending(path: "categories.json")

    private func loadSnippets() { snippets = Persistence.load(from: snippetsURL, fallback: Snippet.samples) }
    private func saveSnippets() { Persistence.save(snippets, to: snippetsURL) }
    private func loadCategories() { categories = Persistence.load(from: categoriesURL, fallback: SnippetCategory.defaults) }
    private func saveCategories() { Persistence.save(categories, to: categoriesURL) }
}

enum FolderItem {
    case folder(SnippetCategory)
    case snippet(Snippet)

    var name: String {
        switch self {
        case .folder(let c): c.name
        case .snippet(let s): s.title
        }
    }
}
