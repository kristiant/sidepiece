import XCTest
import Carbon.HIToolbox
@testable import Sidepiece

final class NumpadKeyTests: XCTestCase {
    
    func testAllKeysHaveDisplayName() {
        for key in NumpadKey.allCases {
            XCTAssertFalse(key.displayName.isEmpty, "\(key) should have a display name")
        }
    }
    
    func testAllKeysHaveSymbol() {
        for key in NumpadKey.allCases {
            XCTAssertFalse(key.symbol.isEmpty, "\(key) should have a symbol")
        }
    }
    
    func testKeyCategoryGrouping() {
        let numbers = NumpadKey.keys(in: .numbers)
        XCTAssertEqual(numbers.count, 10)
        
        let operators = NumpadKey.keys(in: .operators)
        XCTAssertEqual(operators.count, 14)
        
        let functionKeys = NumpadKey.keys(in: .functionKeys)
        XCTAssertEqual(functionKeys.count, 19)
    }
    
    func testKeyCodeRoundTrip() {
        for key in NumpadKey.allCases {
            let keyCode = key.keyCode
            let reconstructed = NumpadKey(keyCode: keyCode)
            XCTAssertEqual(reconstructed, key, "Key code round trip failed for \(key)")
        }
    }
    
    func testUnknownKeyCodeReturnsNil() {
        XCTAssertNil(NumpadKey(keyCode: 9999))
    }
}

final class NumpadKeyMappingTests: XCTestCase {
    func testNumberRowMapsToNumpadDigits() {
        XCTAssertEqual(NumpadKey(numberRowKeyCode: UInt16(kVK_ANSI_0)), .num0)
        XCTAssertEqual(NumpadKey(numberRowKeyCode: UInt16(kVK_ANSI_7)), .num7)
        XCTAssertNil(NumpadKey(numberRowKeyCode: UInt16(kVK_ANSI_A)))
    }

    func testDisplayNames() {
        XCTAssertEqual(NumpadKey.num5.displayName, "5")
        XCTAssertEqual(NumpadKey.f12.displayName, "F12")
        XCTAssertEqual(NumpadKey.pageUp.displayName, "Page Up")
    }

    func testFolderSlotsCoverEveryDigitOnce() {
        XCTAssertEqual(Set(NumpadKey.folderSlots), Set(NumpadKey.keys(in: .numbers)))
    }
}
