import Carbon.HIToolbox

enum NumpadKey: String, Codable, CaseIterable, Identifiable {
    case num0, num1, num2, num3, num4, num5, num6, num7, num8, num9
    case clear, equals, divide, multiply, minus, plus, enter, decimal, insert, del, home, end, pageUp, pageDown
    case f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12, f13, f14, f15, f16, f17, f18, f19

    enum Category: String, CaseIterable {
        case numbers = "Numbers"
        case operators = "Operators"
        case functionKeys = "Function Keys"
    }

    private static let keyCodes: [NumpadKey: Int] = [
        .num0: kVK_ANSI_Keypad0, .num1: kVK_ANSI_Keypad1, .num2: kVK_ANSI_Keypad2,
        .num3: kVK_ANSI_Keypad3, .num4: kVK_ANSI_Keypad4, .num5: kVK_ANSI_Keypad5,
        .num6: kVK_ANSI_Keypad6, .num7: kVK_ANSI_Keypad7, .num8: kVK_ANSI_Keypad8,
        .num9: kVK_ANSI_Keypad9,
        .clear: kVK_ANSI_KeypadClear, .equals: kVK_ANSI_KeypadEquals,
        .divide: kVK_ANSI_KeypadDivide, .multiply: kVK_ANSI_KeypadMultiply,
        .minus: kVK_ANSI_KeypadMinus, .plus: kVK_ANSI_KeypadPlus,
        .enter: kVK_ANSI_KeypadEnter, .decimal: kVK_ANSI_KeypadDecimal,
        .insert: kVK_Help, .del: kVK_ForwardDelete, .home: kVK_Home, .end: kVK_End,
        .pageUp: kVK_PageUp, .pageDown: kVK_PageDown,
        .f1: kVK_F1, .f2: kVK_F2, .f3: kVK_F3, .f4: kVK_F4, .f5: kVK_F5,
        .f6: kVK_F6, .f7: kVK_F7, .f8: kVK_F8, .f9: kVK_F9, .f10: kVK_F10,
        .f11: kVK_F11, .f12: kVK_F12, .f13: kVK_F13, .f14: kVK_F14, .f15: kVK_F15,
        .f16: kVK_F16, .f17: kVK_F17, .f18: kVK_F18, .f19: kVK_F19,
    ]

    private static let byKeyCode = Dictionary(uniqueKeysWithValues: keyCodes.map { ($1, $0) })

    private static let numberRow = [
        kVK_ANSI_0, kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3, kVK_ANSI_4,
        kVK_ANSI_5, kVK_ANSI_6, kVK_ANSI_7, kVK_ANSI_8, kVK_ANSI_9,
    ]

    /// Digits in numpad layout order, top row first, used to slot folder contents onto keys.
    static let folderSlots: [NumpadKey] = [.num7, .num8, .num9, .num4, .num5, .num6, .num1, .num2, .num3, .num0]

    var id: String { rawValue }

    var keyCode: UInt16 { UInt16(Self.keyCodes[self]!) }

    init?(keyCode: UInt16) {
        guard let key = Self.byKeyCode[Int(keyCode)] else { return nil }
        self = key
    }

    /// Maps a number-row key to its numpad twin so keyboards without a numpad can drive the HUD.
    init?(numberRowKeyCode: UInt16) {
        guard let digit = Self.numberRow.firstIndex(of: Int(numberRowKeyCode)) else { return nil }
        self = Self.allCases[digit]
    }

    var category: Category {
        switch self {
        case .num0, .num1, .num2, .num3, .num4, .num5, .num6, .num7, .num8, .num9: .numbers
        case .clear, .equals, .divide, .multiply, .minus, .plus, .enter, .decimal, .insert, .del, .home, .end, .pageUp, .pageDown: .operators
        default: .functionKeys
        }
    }

    var displayName: String {
        switch self {
        case .clear: "Clear"
        case .equals: "="
        case .divide: "/"
        case .multiply: "*"
        case .minus: "-"
        case .plus: "+"
        case .enter: "Enter"
        case .decimal: "."
        case .insert: "Insert"
        case .del: "Del"
        case .home: "Home"
        case .pageUp: "Page Up"
        case .pageDown: "Page Down"
        case .end: "End"
        default: category == .numbers ? String(rawValue.dropFirst(3)) : rawValue.uppercased()
        }
    }

    var symbol: String {
        switch self {
        case .clear: "CLR"
        case .divide: "÷"
        case .multiply: "×"
        case .minus: "−"
        case .enter: "↵"
        case .del: "⌦"
        case .home: "↖"
        case .end: "↘"
        case .pageUp: "⇞"
        case .pageDown: "⇟"
        default: displayName
        }
    }

    static func keys(in category: Category) -> [NumpadKey] {
        allCases.filter { $0.category == category }
    }
}
