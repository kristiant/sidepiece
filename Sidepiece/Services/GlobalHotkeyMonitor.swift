import AppKit
import Carbon.HIToolbox
import OSLog

/// Monitors global keyboard events for numpad key presses
final class GlobalHotkeyMonitor {
    private let logger = Logger(subsystem: "com.sidepiece.app", category: "Monitor")
    
    // MARK: - Types
    
    typealias KeyHandler = (NumpadKey) -> Void
    typealias ShouldConsumeHandler = (NumpadKey) -> Bool
    
    // MARK: - Properties
    
    /// Called when a monitored key is pressed
    var onKeyPressed: KeyHandler?
    
    /// Called to determine if a key should be consumed or passed through
    var shouldConsumeKey: ShouldConsumeHandler?
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private(set) var isRunning = false
    
    // MARK: - Monitoring
    
    /// Starts monitoring for global key events
    func start() {
        guard !isRunning else { return }
        guard hasAccessibilityPermissions() else {
            logger.error("Cannot start hotkey monitor - accessibility permissions required")
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
            logger.error("Failed to create event tap - permission might be lost or binary signature invalid")
            return
        }
        
        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        
        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        
        CGEvent.tapEnable(tap: tap, enable: true)
        isRunning = true
        
        logger.info("Global hotkey monitor successfully started and enabled.")
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
        
        logger.info("Global hotkey monitor stopped")
    }
    
    // MARK: - Accessibility Permissions
    
    /// Checks if the application has accessibility permissions required for event taps
    func hasAccessibilityPermissions() -> Bool {
        return AXIsProcessTrusted()
    }
    
    // MARK: - Event Handling
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .keyDown else { return Unmanaged.passUnretained(event) }
        
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        guard let numpadKey = NumpadKey(keyCode: UInt16(keyCode)) else {
            return Unmanaged.passUnretained(event)
        }
        
        // Check if we should consume this key (only if binding exists)
        let shouldConsume = shouldConsumeKey?(numpadKey) ?? false
        
        if shouldConsume {
            logger.info("Consuming key: \(numpadKey.displayName)")
            // Dispatch to handler on main thread
            DispatchQueue.main.async { [weak self] in
                self?.onKeyPressed?(numpadKey)
            }
            
            // Consume the event (don't pass to other apps)
            return nil
        } else {
            logger.debug("Passing through key: \(numpadKey.displayName)")
            // No binding for this key, pass it through to other apps
            return Unmanaged.passUnretained(event)
        }
    }
}
