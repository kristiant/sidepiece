import AppKit
import Carbon.HIToolbox

enum Clipboard {
    static func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    static func paste() { Keyboard.press(kVK_ANSI_V, flags: .maskCommand) }

    static func typeEnter() { Keyboard.press(kVK_Return) }
}

enum Keyboard {
    static func press(_ key: Int, flags: CGEventFlags = [], tap: CGEventTapLocation = .cgAnnotatedSessionEventTap) {
        let src = CGEventSource(stateID: .hidSystemState)
        for down in [true, false] {
            let e = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(key), keyDown: down)
            e?.flags = flags
            e?.post(tap: tap)
        }
    }
}
