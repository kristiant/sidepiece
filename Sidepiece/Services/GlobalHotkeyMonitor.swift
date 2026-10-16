import AppKit
import Carbon.HIToolbox
import OSLog

/// Event tap for numpad keys and the peak hotkey. While peaking it also handles Escape and the number row.
/// Closures are queried on every event, so config changes apply without restarting the tap.
final class GlobalHotkeyMonitor {
    private let logger = Logger(category: "Monitor")

    var onKeyPressed: ((NumpadKey) -> Void)?
    var shouldConsumeKey: ((NumpadKey) -> Bool)?
    var peakTriggerKeyCode: (() -> UInt16?)?
    var onPeakTrigger: (() -> Void)?
    var isPeaking: (() -> Bool)?
    var onNumberRowKey: ((NumpadKey) -> Void)?
    var onDismissPeak: (() -> Void)?

    private var tap: CFMachPort?
    private var source: CFRunLoopSource?

    func start() {
        guard tap == nil, AXIsProcessTrusted() else { return }

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue),
            callback: { _, type, event, refcon in
                let monitor = Unmanaged<GlobalHotkeyMonitor>.fromOpaque(refcon!).takeUnretainedValue()
                return monitor.handle(type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return logger.error("Failed to create event tap")
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        self.tap = tap
        self.source = source
        logger.info("Hotkey monitor started")
    }

    func stop() {
        guard let tap else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        self.tap = nil
        source = nil
        logger.info("Hotkey monitor stopped")
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let pass = Unmanaged.passUnretained(event)
        guard type == .keyDown else { return pass }

        let code = UInt16(event.getIntegerValueField(.keyboardEventKeycode))

        if code == peakTriggerKeyCode?() {
            return consume { $0.onPeakTrigger?() }
        }

        if isPeaking?() == true {
            if code == kVK_Escape {
                return consume { $0.onDismissPeak?() }
            }
            if let key = NumpadKey(numberRowKeyCode: code) {
                return consume { $0.onNumberRowKey?(key) }
            }
        }

        guard let key = NumpadKey(keyCode: code), shouldConsumeKey?(key) == true else { return pass }
        return consume { $0.onKeyPressed?(key) }
    }

    private func consume(_ action: @escaping (GlobalHotkeyMonitor) -> Void) -> Unmanaged<CGEvent>? {
        DispatchQueue.main.async { [weak self] in self.map(action) }
        return nil
    }
}
