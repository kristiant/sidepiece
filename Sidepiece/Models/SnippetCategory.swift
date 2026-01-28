import Foundation

/// A category for organising snippets
struct SnippetCategory: Identifiable, Codable, Equatable {
    
    // MARK: - Properties
    
    let id: UUID
    var name: String
    var color: String  // Hex color code
    var icon: String   // SF Symbol name
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Initialisation
    
    init(
        id: UUID = UUID(),
        name: String,
        color: String = "#007AFF",
        icon: String = "folder",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Default Categories

extension SnippetCategory {
    
    static let defaults: [SnippetCategory] = [
        SnippetCategory(name: "Email", color: "#FF3B30", icon: "envelope"),
        SnippetCategory(name: "Code", color: "#5856D6", icon: "chevron.left.forwardslash.chevron.right"),
        SnippetCategory(name: "AI Prompts", color: "#AF52DE", icon: "sparkles"),
        SnippetCategory(name: "Personal", color: "#34C759", icon: "person"),
        SnippetCategory(name: "Work", color: "#007AFF", icon: "briefcase")
    ]
}
