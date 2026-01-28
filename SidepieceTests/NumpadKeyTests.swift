import XCTest
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
        XCTAssertEqual(operators.count, 8)
        
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
