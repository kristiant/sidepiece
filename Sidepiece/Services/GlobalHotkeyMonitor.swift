import AppKit
import Carbon.HIToolbox

/// Monitors global keyboard events for numpad key presses
final class GlobalHotkeyMonitor {
    
    // MARK: - Types
    
    typealias KeyHandler = (NumpadKey) -> Void
    typealias ShouldConsumeHandler = (NumpadKey) -> Bool
    
    // MARK: - Properties
    
    /// Called when a supported numpad key is pressed
    var onKeyPressed: KeyHandler?
    
    /// Called to check if a key should be consumed (only consume if binding exists)
    var shouldConsumeKey: ShouldConsumeHandler?
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isRunning = false
    
    // MARK: - Public Methods
    
    /// Starts monitoring for global key events
    func start() {
        guard !isRunning else { return }
        guard hasAccessibilityPermissions() else {
            print("Sidepiece: Cannot start hotkey monitor - accessibility permissions required")
            return
        }
        
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        // Create event tap
        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                
                let monitor = Unmanaged<GlobalHotkeyMonitor>.fromOpaque(refcon).takeUnretainedValue()
                return monitor.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            NSLog("Sidepiece: Failed to create event tap - permission might be lost or binary signature invalid")
            return
        }
        
        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        
        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        
        CGEvent.tapEnable(tap: tap, enable: true)
        isRunning = true
        
        NSLog("Sidepiece: Global hotkey monitor successfully started and enabled.")
    }
    
    /// Stops monitoring for global key events
    func stop() {
        guard isRunning else { return }
        
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        
        eventTap = nil
        runLoopSource = nil
        isRunning = false
        
        print("Sidepiece: Global hotkey monitor stopped")
    }
    
    // MARK: - Accessibility Permissions
    
    /// Checks if the app has accessibility permissions
    func hasAccessibilityPermissions() -> Bool {
        AXIsProcessTrusted()
    }
    
    /// Prompts the user to grant accessibility permissions
    func requestAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    /// Opens System Preferences to the Accessibility pane
    func openAccessibilityPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    
    // MARK: - Event Handling
    
    private func handleEvent(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        
        // Handle tap disabled events (can happen if system suspends the tap)
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            NSLog("Sidepiece: Event tap disabled (\(type.rawValue)), re-enabling...")
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }
        
        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }
        
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        
        // Check if this is a supported numpad key
        guard let numpadKey = NumpadKey(keyCode: keyCode) else {
            // Not a key we care about, pass it through
            return Unmanaged.passUnretained(event)
        }
        
        // Check if we should consume this key (only if binding exists)
        let shouldConsume = shouldConsumeKey?(numpadKey) ?? false
        
        if shouldConsume {
            // Dispatch to handler on main thread
            DispatchQueue.main.async { [weak self] in
                self?.onKeyPressed?(numpadKey)
            }
            
            // Consume the event (don't pass to other apps)
            return nil
        } else {
            // No binding for this key, pass it through to other apps
            return Unmanaged.passUnretained(event)
        }
    }
}
