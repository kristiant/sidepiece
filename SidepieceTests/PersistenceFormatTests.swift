import XCTest
@testable import Sidepiece

final class PersistenceFormatTests: XCTestCase {
    func testConfigurationFallsBackToDefaultsForMissingKeys() throws {
        let cfg = try JSONDecoder().decode(AppConfiguration.self, from: Data(#"{"autoPaste": false}"#.utf8))
        XCTAssertFalse(cfg.autoPaste)
        XCTAssertEqual(cfg.showHUD, AppConfiguration.default.showHUD)
        XCTAssertNil(cfg.peakHotkey)
    }

    func testConfigurationRoundTrips() throws {
        var cfg = AppConfiguration()
        cfg.peakHotkey = .f13
        cfg.autoEnterAfterPaste = true
        let decoded = try JSONDecoder().decode(AppConfiguration.self, from: JSONEncoder().encode(cfg))
        XCTAssertEqual(decoded, cfg)
    }

    func testLegacyBindingWithSnippetDecodesAsSnippetAction() throws {
        let snippet = Snippet(title: "T", content: "C")
        let legacy: [String: Any] = [
            "id": UUID().uuidString, "key": "num1", "isEnabled": true,
            "createdAt": 0, "updatedAt": 0,
            "snippet": try JSONSerialization.jsonObject(with: JSONEncoder().encode(snippet)),
        ]
        let binding = try JSONDecoder().decode(KeyBinding.self, from: JSONSerialization.data(withJSONObject: legacy))
        XCTAssertEqual(binding.action, .snippet(id: snippet.id))
    }

    func testDefaultProfileBindsSamplesToOneThroughSix() {
        let keys = Profile.createDefault().bindings.map(\.key)
        XCTAssertEqual(keys, [.num1, .num2, .num3, .num4, .num5, .num6])
    }

    func testHUDWindowSizes() {
        XCTAssertEqual(HUDWindowState(isPeaking: false, hasFolderPath: false, hasFeedback: false).size, CGSize(width: 40, height: 40))
        XCTAssertEqual(HUDWindowState(isPeaking: false, hasFolderPath: true, hasFeedback: false).size.height, 70)
        XCTAssertEqual(HUDWindowState(isPeaking: true, hasFolderPath: false, hasFeedback: true).size.height, 600)
    }
}
