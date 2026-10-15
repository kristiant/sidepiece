import AppKit
import Carbon.HIToolbox

enum Clipboard {
    static func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    static func paste() { press(kVK_ANSI_V, flags: .maskCommand) }

    static func typeEnter() { press(kVK_Return) }

    private static func press(_ key: Int, flags: CGEventFlags = []) {
        let src = CGEventSource(stateID: .hidSystemState)
        for down in [true, false] {
            let e = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(key), keyDown: down)
            e?.flags = flags
            e?.post(tap: .cgAnnotatedSessionEventTap)
        }
    }
}
