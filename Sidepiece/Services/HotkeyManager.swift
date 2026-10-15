import AppKit
import OSLog

/// Owns the global hotkey monitor and keeps it running while accessibility access is granted.
@MainActor
final class HotkeyManager: ObservableObject {
    static let shared = HotkeyManager()
    private let logger = Logger(subsystem: "com.sidepiece.app", category: "Hotkey")

    let monitor = GlobalHotkeyMonitor()
    @Published private(set) var isAuthorized = false

    private init() {
        checkPermissions()
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkPermissions() }
        }
    }

    func start() {
        guard checkPermissions() else { return logger.error("Cannot start monitor, not authorised") }
        monitor.start()
    }

    func stop() { monitor.stop() }

    @discardableResult
    func checkPermissions() -> Bool {
        let trusted = AXIsProcessTrusted()
        guard trusted != isAuthorized else { return trusted }
        logger.info("Accessibility access \(trusted ? "granted" : "revoked")")
        isAuthorized = trusted
        trusted ? monitor.start() : monitor.stop()
        return trusted
    }
}
