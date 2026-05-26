import AppKit
import Carbon.HIToolbox
import OSLog

/// Monitors global keyboard events for numpad key presses, the peak trigger
/// hotkey, and — while the HUD peak panel is open — the regular number row.
final class GlobalHotkeyMonitor {
    private let logger = Logger(subsystem: "com.sidepiece.app", category: "Monitor")

    // MARK: - Types

    typealias KeyHandler            = (NumpadKey) -> Void
    typealias ShouldConsumeHandler  = (NumpadKey) -> Bool

    // MARK: - Numpad (existing)

    /// Called when a monitored numpad key is pressed.
    var onKeyPressed: KeyHandler?

    /// Return true to consume the event and prevent it reaching other apps.
    var shouldConsumeKey: ShouldConsumeHandler?

    // MARK: - Peak trigger

    /// Returns the key code of the hotkey that should open/toggle the peak panel,
    /// or nil if no such hotkey is configured. Evaluated on every event so
    /// configuration changes are picked up without restarting the monitor.
    var peakTriggerKeyCode: (() -> UInt16?)?

    /// Called when the peak trigger key is pressed.
    var onPeakTrigger: (() -> Void)?

    // MARK: - Keyboard mode (while peaking)

    /// Returns true when the HUD peak panel is currently visible.
    /// Queried on every key event — keep the implementation fast.
    var isPeaking: (() -> Bool)?

    /// Called when a regular number-row key (0–9) is pressed while peaking.
    /// The key is already translated to its NumpadKey equivalent.
    var onNumberRowKey: KeyHandler?

    /// Called when Escape is pressed while the peak panel is visible.
    var onDismissPeak: (() -> Void)?

    // MARK: - Internal

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private(set) var isRunning = false

    // MARK: - Monitoring

    func start() {
        guard !isRunning else { return }
        guard hasAccessibilityPermissions() else {
            logger.error("Cannot start hotkey monitor - accessibility permissions required")
            return
        }

        // Listen for both keyDown events.
        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { proxy, type, event, refcon in
                guard let refcon else { return Unmanaged.passUnretained(event) }
                let monitor = Unmanaged<GlobalHotkeyMonitor>.fromOpaque(refcon).takeUnretainedValue()
                return monitor.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            logger.error("Failed to create event tap - permission might be lost or binary changed")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        CGEvent.tapEnable(tap: tap, enable: true)
        isRunning = true
        logger.info("Global hotkey monitor started.")
    }

    func stop() {
        guard isRunning else { return }
        if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let source = runLoopSource { CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes) }
        eventTap = nil
        runLoopSource = nil
        isRunning = false
        logger.info("Global hotkey monitor stopped.")
    }

    func hasAccessibilityPermissions() -> Bool { AXIsProcessTrusted() }

    // MARK: - Event Handling

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .keyDown else { return Unmanaged.passUnretained(event) }

        let rawCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))

        // ── 1. Peak trigger hotkey ──────────────────────────────────────────
        // Always checked first so the trigger works even outside peak mode.
        if let triggerCode = peakTriggerKeyCode?(), rawCode == triggerCode {
            logger.info("Peak trigger key pressed (code \(rawCode))")
            DispatchQueue.main.async { [weak self] in self?.onPeakTrigger?() }
            return nil  // consume
        }

        // ── 2. Keys active only while the peak panel is open ────────────────
        if isPeaking?() == true {

            // Escape → dismiss
            if rawCode == UInt16(kVK_Escape) {
                logger.info("Escape pressed while peaking — dismissing")
                DispatchQueue.main.async { [weak self] in self?.onDismissPeak?() }
                return nil  // consume
            }

            // Regular number row (0–9) → map to numpad equivalent
            if let numpadKey = NumpadKey(numberRowKeyCode: rawCode) {
                logger.info("Number-row key \(numpadKey.displayName) pressed while peaking")
                DispatchQueue.main.async { [weak self] in self?.onNumberRowKey?(numpadKey) }
                return nil  // consume
            }
        }

        // ── 3. Standard numpad key handling ─────────────────────────────────
        guard let numpadKey = NumpadKey(keyCode: rawCode) else {
            return Unmanaged.passUnretained(event)
        }

        let shouldConsume = shouldConsumeKey?(numpadKey) ?? false
        if shouldConsume {
            logger.info("Consuming numpad key: \(numpadKey.displayName)")
            DispatchQueue.main.async { [weak self] in self?.onKeyPressed?(numpadKey) }
            return nil
        }

        logger.debug("Passing through key: \(numpadKey.displayName)")
        return Unmanaged.passUnretained(event)
    }
}
