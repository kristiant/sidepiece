import AppKit

/// Service for clipboard operations
final class ClipboardService {
    
    // MARK: - Properties
    
    private let pasteboard = NSPasteboard.general
    
    // MARK: - Public Methods
    
    /// Copies the given text to the system clipboard
    /// - Parameter text: The text to copy
    /// - Returns: Whether the operation was successful
    @discardableResult
    func copy(_ text: String) -> Bool {
        pasteboard.clearContents()
        return pasteboard.setString(text, forType: .string)
    }
    
    /// Simulates Cmd+V to paste the current clipboard content
    func paste() {
        let source = CGEventSource(stateID: .hidSystemState)
        
        guard let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) else { return } // 0x09 is 'V'
        vDown.flags = .maskCommand
        
        guard let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else { return }
        vUp.flags = .maskCommand
        
        vDown.post(tap: .cgAnnotatedSessionEventTap)
        vUp.post(tap: .cgAnnotatedSessionEventTap)
    }
    
    /// Simulates pressing the Enter key
    func typeEnter() {
        let source = CGEventSource(stateID: .hidSystemState)
        
        guard let enterDown = CGEvent(keyboardEventSource: source, virtualKey: 0x24, keyDown: true) else { return } // 0x24 is Return
        guard let enterUp = CGEvent(keyboardEventSource: source, virtualKey: 0x24, keyDown: false) else { return }
        
        enterDown.post(tap: .cgAnnotatedSessionEventTap)
        enterUp.post(tap: .cgAnnotatedSessionEventTap)
    }
    
    /// Copies rich text (attributed string) to the clipboard
    /// - Parameter attributedString: The attributed string to copy
    /// - Returns: Whether the operation was successful
    @discardableResult
    func copyRichText(_ attributedString: NSAttributedString) -> Bool {
        pasteboard.clearContents()
        
        // Write both RTF and plain text for maximum compatibility
        let rtfData = try? attributedString.data(
            from: NSRange(location: 0, length: attributedString.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
        
        var success = true
        
        if let rtfData = rtfData {
            success = pasteboard.setData(rtfData, forType: .rtf) && success
        }
        
        success = pasteboard.setString(attributedString.string, forType: .string) && success
        
        return success
    }
    
    /// Returns the current plain text content of the clipboard
    /// - Returns: The clipboard text, or nil if empty or not text
    func getClipboardText() -> String? {
        pasteboard.string(forType: .string)
    }
    
    /// Returns whether the clipboard currently contains text
    var hasText: Bool {
        pasteboard.availableType(from: [.string]) != nil
    }
    
    /// Clears the clipboard contents
    func clear() {
        pasteboard.clearContents()
    }
}
