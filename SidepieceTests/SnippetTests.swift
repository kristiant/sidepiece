import XCTest
@testable import Sidepiece

final class SnippetTests: XCTestCase {
    
    func testSnippetInitialisation() {
        let snippet = Snippet(
            title: "Test Snippet",
            content: "Hello, World!"
        )
        
        XCTAssertEqual(snippet.title, "Test Snippet")
        XCTAssertEqual(snippet.content, "Hello, World!")
        XCTAssertEqual(snippet.usageCount, 0)
        XCTAssertNil(snippet.lastUsedAt)
        XCTAssertTrue(snippet.tags.isEmpty)
    }
    
    func testSnippetPreview() {
        let shortSnippet = Snippet(title: "Short", content: "Hello")
        XCTAssertEqual(shortSnippet.preview, "Hello")
        
        let longContent = String(repeating: "a", count: 100)
        let longSnippet = Snippet(title: "Long", content: longContent)
        XCTAssertTrue(longSnippet.preview.hasSuffix("..."))
        XCTAssertEqual(longSnippet.preview.count, 53) // 50 chars + "..."
    }
    
    func testSnippetCharacterCount() {
        let snippet = Snippet(title: "Test", content: "12345")
        XCTAssertEqual(snippet.characterCount, 5)
    }
    
    func testSnippetLineCount() {
        let singleLine = Snippet(title: "Single", content: "Hello")
        XCTAssertEqual(singleLine.lineCount, 1)
        
        let multiLine = Snippet(title: "Multi", content: "Line 1\nLine 2\nLine 3")
        XCTAssertEqual(multiLine.lineCount, 3)
    }
}
