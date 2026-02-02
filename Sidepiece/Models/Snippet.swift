import Foundation

/// A text snippet that can be copied to the clipboard
struct Snippet: Identifiable, Codable, Equatable, Hashable {
    
    // MARK: - Properties
    
    let id: UUID
    var title: String
    var content: String
    var categoryId: UUID?
    var tags: [String]
    var usageCount: Int
    var lastUsedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Initialisation
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        categoryId: UUID? = nil,
        tags: [String] = [],
        usageCount: Int = 0,
        lastUsedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.categoryId = categoryId
        self.tags = tags
        self.usageCount = usageCount
        self.lastUsedAt = lastUsedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    
    /// Preview of the content, truncated for display
    var preview: String {
        let maxLength = 50
        if content.count <= maxLength {
            return content
        }
        return String(content.prefix(maxLength)) + "..."
    }
    
    /// Number of characters in the content
    var characterCount: Int {
        content.count
    }
    
    /// Number of lines in the content
    var lineCount: Int {
        content.components(separatedBy: .newlines).count
    }
}

// MARK: - Sample Data

extension Snippet {
    
    /// Sample snippets for testing and first-run experience
    static let samples: [Snippet] = [
        Snippet(
            title: "Polite Greeting",
            content: "Hi there! Thanks for reaching out. I hope you're having a great day."
        ),
        Snippet(
            title: "Email Sign-off",
            content: "Best regards,\nKristian"
        ),
        Snippet(
            title: "Meeting Request",
            content: "Would you be available for a quick call this week? Let me know what times work for you."
        ),
        Snippet(
            title: "Code Review",
            content: "Thanks for the PR! I've left some comments. Overall looks good, just a few minor suggestions."
        ),
        Snippet(
            title: "AI Prompt - Explain",
            content: "Please explain the following code in simple terms, highlighting the key concepts and any potential issues:"
        ),
        Snippet(
            title: "AI Prompt - Refactor",
            content: "Please refactor this code to be more readable, maintainable, and follow best practices. Explain your changes."
        )
    ]
}
