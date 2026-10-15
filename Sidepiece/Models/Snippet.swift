import Foundation

struct Snippet: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var content: String
    var categoryId: UUID?
    var tags: [String] = []
    var usageCount = 0
    var lastUsedAt: Date?
    var createdAt = Date()
    var updatedAt = Date()

    var preview: String {
        content.count <= 50 ? content : content.prefix(50) + "..."
    }
}

extension Snippet {
    static let samples = [
        Snippet(title: "Polite Greeting", content: "Hi there! Thanks for reaching out. I hope you're having a great day."),
        Snippet(title: "Email Sign-off", content: "Best regards,\nKristian"),
        Snippet(title: "Meeting Request", content: "Would you be available for a quick call this week? Let me know what times work for you."),
        Snippet(title: "Code Review", content: "Thanks for the PR! I've left some comments. Overall looks good, just a few minor suggestions."),
        Snippet(title: "AI Prompt - Explain", content: "Please explain the following code in simple terms, highlighting the key concepts and any potential issues:"),
        Snippet(title: "AI Prompt - Refactor", content: "Please refactor this code to be more readable, maintainable, and follow best practices. Explain your changes."),
    ]
}
