import Carbon.HIToolbox

/// Represents all supported numpad and function keys
enum NumpadKey: String, Codable, CaseIterable, Identifiable {
    
    // MARK: - Number Keys
    
    case num0
    case num1
    case num2
    case num3
    case num4
    case num5
    case num6
    case num7
    case num8
    case num9
    
    // MARK: - Operator Keys
    
    case clear
    case equals
    case divide
    case multiply
    case minus
    case plus
    case enter
    case decimal
    
    // MARK: - Function Keys (F1-F19 for Apple Extended Keyboards)
    
    case f1
    case f2
    case f3
    case f4
    case f5
    case f6
    case f7
    case f8
    case f9
    case f10
    case f11
    case f12
    case f13
    case f14
    case f15
    case f16
    case f17
    case f18
    case f19
    
    // MARK: - Identifiable
    
    var id: String { rawValue }
    
    // MARK: - Display Properties
    
    /// Human-readable display name for the key
    var displayName: String {
        switch self {
        case .num0: return "0"
        case .num1: return "1"
        case .num2: return "2"
        case .num3: return "3"
        case .num4: return "4"
        case .num5: return "5"
        case .num6: return "6"
        case .num7: return "7"
        case .num8: return "8"
        case .num9: return "9"
        case .clear: return "Clear"
        case .equals: return "="
        case .divide: return "/"
        case .multiply: return "*"
        case .minus: return "-"
        case .plus: return "+"
        case .enter: return "Enter"
        case .decimal: return "."
        case .f1: return "F1"
        case .f2: return "F2"
        case .f3: return "F3"
        case .f4: return "F4"
        case .f5: return "F5"
        case .f6: return "F6"
        case .f7: return "F7"
        case .f8: return "F8"
        case .f9: return "F9"
        case .f10: return "F10"
        case .f11: return "F11"
        case .f12: return "F12"
        case .f13: return "F13"
        case .f14: return "F14"
        case .f15: return "F15"
        case .f16: return "F16"
        case .f17: return "F17"
        case .f18: return "F18"
        case .f19: return "F19"
        }
    }
    
    /// Symbol representation for compact display
    var symbol: String {
        switch self {
        case .num0, .num1, .num2, .num3, .num4,
             .num5, .num6, .num7, .num8, .num9:
            return displayName
        case .clear: return "CLR"
        case .equals: return "="
        case .divide: return "÷"
        case .multiply: return "×"
        case .minus: return "−"
        case .plus: return "+"
        case .enter: return "↵"
        case .decimal: return "."
        case .f1, .f2, .f3, .f4, .f5, .f6, .f7, .f8, .f9, .f10,
             .f11, .f12, .f13, .f14, .f15, .f16, .f17, .f18, .f19:
            return displayName
        }
    }
    
    /// The CGKeyCode for this key
    var keyCode: UInt16 {
        switch self {
        case .num0: return UInt16(kVK_ANSI_Keypad0)
        case .num1: return UInt16(kVK_ANSI_Keypad1)
        case .num2: return UInt16(kVK_ANSI_Keypad2)
        case .num3: return UInt16(kVK_ANSI_Keypad3)
        case .num4: return UInt16(kVK_ANSI_Keypad4)
        case .num5: return UInt16(kVK_ANSI_Keypad5)
        case .num6: return UInt16(kVK_ANSI_Keypad6)
        case .num7: return UInt16(kVK_ANSI_Keypad7)
        case .num8: return UInt16(kVK_ANSI_Keypad8)
        case .num9: return UInt16(kVK_ANSI_Keypad9)
        case .clear: return UInt16(kVK_ANSI_KeypadClear)
        case .equals: return UInt16(kVK_ANSI_KeypadEquals)
        case .divide: return UInt16(kVK_ANSI_KeypadDivide)
        case .multiply: return UInt16(kVK_ANSI_KeypadMultiply)
        case .minus: return UInt16(kVK_ANSI_KeypadMinus)
        case .plus: return UInt16(kVK_ANSI_KeypadPlus)
        case .enter: return UInt16(kVK_ANSI_KeypadEnter)
        case .decimal: return UInt16(kVK_ANSI_KeypadDecimal)
        case .f1: return UInt16(kVK_F1)
        case .f2: return UInt16(kVK_F2)
        case .f3: return UInt16(kVK_F3)
        case .f4: return UInt16(kVK_F4)
        case .f5: return UInt16(kVK_F5)
        case .f6: return UInt16(kVK_F6)
        case .f7: return UInt16(kVK_F7)
        case .f8: return UInt16(kVK_F8)
        case .f9: return UInt16(kVK_F9)
        case .f10: return UInt16(kVK_F10)
        case .f11: return UInt16(kVK_F11)
        case .f12: return UInt16(kVK_F12)
        case .f13: return UInt16(kVK_F13)
        case .f14: return UInt16(kVK_F14)
        case .f15: return UInt16(kVK_F15)
        case .f16: return UInt16(kVK_F16)
        case .f17: return UInt16(kVK_F17)
        case .f18: return UInt16(kVK_F18)
        case .f19: return UInt16(kVK_F19)
        }
    }
    
    // MARK: - Initialisation from Key Code
    
    /// Creates a NumpadKey from a CGKeyCode
    init?(keyCode: UInt16) {
        switch Int(keyCode) {
        case kVK_ANSI_Keypad0: self = .num0
        case kVK_ANSI_Keypad1: self = .num1
        case kVK_ANSI_Keypad2: self = .num2
        case kVK_ANSI_Keypad3: self = .num3
        case kVK_ANSI_Keypad4: self = .num4
        case kVK_ANSI_Keypad5: self = .num5
        case kVK_ANSI_Keypad6: self = .num6
        case kVK_ANSI_Keypad7: self = .num7
        case kVK_ANSI_Keypad8: self = .num8
        case kVK_ANSI_Keypad9: self = .num9
        case kVK_ANSI_KeypadClear: self = .clear
        case kVK_ANSI_KeypadEquals: self = .equals
        case kVK_ANSI_KeypadDivide: self = .divide
        case kVK_ANSI_KeypadMultiply: self = .multiply
        case kVK_ANSI_KeypadMinus: self = .minus
        case kVK_ANSI_KeypadPlus: self = .plus
        case kVK_ANSI_KeypadEnter: self = .enter
        case kVK_ANSI_KeypadDecimal: self = .decimal
        case kVK_F1: self = .f1
        case kVK_F2: self = .f2
        case kVK_F3: self = .f3
        case kVK_F4: self = .f4
        case kVK_F5: self = .f5
        case kVK_F6: self = .f6
        case kVK_F7: self = .f7
        case kVK_F8: self = .f8
        case kVK_F9: self = .f9
        case kVK_F10: self = .f10
        case kVK_F11: self = .f11
        case kVK_F12: self = .f12
        case kVK_F13: self = .f13
        case kVK_F14: self = .f14
        case kVK_F15: self = .f15
        case kVK_F16: self = .f16
        case kVK_F17: self = .f17
        case kVK_F18: self = .f18
        case kVK_F19: self = .f19
        default: return nil
        }
    }
    
    // MARK: - Grouping
    
    /// Groups keys by their category for UI display
    enum Category: String, CaseIterable {
        case numbers = "Numbers"
        case operators = "Operators"
        case functionKeys = "Function Keys"
    }
    
    var category: Category {
        switch self {
        case .num0, .num1, .num2, .num3, .num4,
             .num5, .num6, .num7, .num8, .num9:
            return .numbers
        case .clear, .equals, .divide, .multiply,
             .minus, .plus, .enter, .decimal:
            return .operators
        case .f1, .f2, .f3, .f4, .f5, .f6, .f7, .f8, .f9, .f10,
             .f11, .f12, .f13, .f14, .f15, .f16, .f17, .f18, .f19:
            return .functionKeys
        }
    }
    
    /// All keys in a specific category
    static func keys(in category: Category) -> [NumpadKey] {
        allCases.filter { $0.category == category }
    }
}
