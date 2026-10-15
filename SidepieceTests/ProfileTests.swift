import XCTest
@testable import Sidepiece

final class ProfileTests: XCTestCase {
    
    func testProfileCreation() {
        let profile = Profile(name: "Test Profile")
        
        XCTAssertEqual(profile.name, "Test Profile")
        XCTAssertTrue(profile.bindings.isEmpty)
        XCTAssertFalse(profile.isActive)
    }
    
    func testDefaultProfileHasBindings() {
        let defaultProfile = Profile.createDefault()
        
        XCTAssertEqual(defaultProfile.name, "Default")
        XCTAssertTrue(defaultProfile.isActive)
        XCTAssertFalse(defaultProfile.bindings.isEmpty)
    }
    
    func testAddBinding() {
        let profile = Profile(name: "Test")
        let snippet = Snippet(title: "Test", content: "Content")
        let binding = KeyBinding(key: .num1, action: .snippet(id: snippet.id))
        
        let updated = profile.withBinding(binding)
        
        XCTAssertEqual(updated.bindings.count, 1)
        XCTAssertEqual(updated.binding(for: .num1)?.action, .snippet(id: snippet.id))
    }
    
    func testRemoveBinding() {
        let snippet = Snippet(title: "Test", content: "Content")
        let binding = KeyBinding(key: .num1, action: .snippet(id: snippet.id))
        let profile = Profile(name: "Test", bindings: [binding])
        
        let updated = profile.withoutBinding(for: .num1)
        
        XCTAssertTrue(updated.bindings.isEmpty)
    }
    
    func testBindingCount() {
        let snippets = [
            Snippet(title: "A", content: "A"),
            Snippet(title: "B", content: "B")
        ]
        let bindings = [
            KeyBinding(key: .num1, action: .snippet(id: snippets[0].id), isEnabled: true),
            KeyBinding(key: .num2, action: .snippet(id: snippets[1].id), isEnabled: false)
        ]
        let profile = Profile(name: "Test", bindings: bindings)
        
        XCTAssertEqual(profile.bindingCount, 2)
        XCTAssertEqual(profile.enabledBindingCount, 1)
    }
}
