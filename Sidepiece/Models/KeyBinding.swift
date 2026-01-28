import Foundation

/// Represents a mapping between a numpad key and a snippet
struct KeyBinding: Identifiable, Codable, Equatable {
    
    // MARK: - Properties
    
    let id: UUID
    var key: NumpadKey
    var snippet: Snippet
    var isEnabled: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Initialisation
    
    init(
        id: UUID = UUID(),
        key: NumpadKey,
        snippet: Snippet,
        isEnabled: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.key = key
        self.snippet = snippet
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Mutations
    
    /// Returns a copy with the enabled state toggled
    func toggled() -> KeyBinding {
        var copy = self
        copy.isEnabled = !isEnabled
        copy.updatedAt = Date()
        return copy
    }
    
    /// Returns a copy with an updated snippet
    func withSnippet(_ snippet: Snippet) -> KeyBinding {
        var copy = self
        copy.snippet = snippet
        copy.updatedAt = Date()
        return copy
    }
}
