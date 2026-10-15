import Foundation

struct SnippetCategory: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var parentId: UUID?
    var color = "#007AFF"
    var icon = "folder"
    var createdAt = Date()
    var updatedAt = Date()
}

extension SnippetCategory {
    static let defaults = [
        SnippetCategory(name: "Email", color: "#FF3B30", icon: "envelope"),
        SnippetCategory(name: "Code", color: "#5856D6", icon: "chevron.left.forwardslash.chevron.right"),
        SnippetCategory(name: "AI Prompts", color: "#AF52DE", icon: "sparkles"),
        SnippetCategory(name: "Personal", color: "#34C759", icon: "person"),
        SnippetCategory(name: "Work", color: "#007AFF", icon: "briefcase"),
    ]
}
