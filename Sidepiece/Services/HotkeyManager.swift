import Foundation
import AppKit
import OSLog

@MainActor
final class HotkeyManager: ObservableObject {
    static let shared = HotkeyManager()
    private let logger = Logger(subsystem: "com.sidepiece.app", category: "Hotkey")
    
    private let monitor = GlobalHotkeyMonitor()
    @Published private(set) var isAuthorized: Bool = false
    
    var onKeyPressed: ((NumpadKey) -> Void)? {
        get { monitor.onKeyPressed }
        set { monitor.onKeyPressed = newValue }
    }
    
    var shouldConsumeKey: ((NumpadKey) -> Bool)? {
        get { monitor.shouldConsumeKey }
        set { monitor.shouldConsumeKey = newValue }
    }
    
    private var permissionTimer: Timer?
    
    private init() {
        checkPermissions()
        startPermissionPolling()
    }
    
    func start() {
        if checkPermissions() {
            logger.info("Starting hotkey monitor...")
            monitor.start()
        } else {
            logger.error("Cannot start monitor - not authorized")
        }
    }
    
    func stop() {
        monitor.stop()
    }
    
    @discardableResult
    func checkPermissions() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        let authorizedWithOptions = AXIsProcessTrustedWithOptions(options)
        let authorizedSimple = AXIsProcessTrusted()
        
        if authorizedWithOptions != isAuthorized {
            logger.info("Permission state changed. Simple: \(authorizedSimple), WithOptions: \(authorizedWithOptions)")
        }
        
        if authorizedWithOptions && !isAuthorized {
            logger.info("Accessibility permissions GRANTED. Starting monitor.")
            isAuthorized = true
            monitor.start()
        } else if !authorizedWithOptions && isAuthorized {
            logger.info("Accessibility permissions REVOKED.")
            isAuthorized = false
            monitor.stop()
        }
        
        return authorizedWithOptions
    }
    
    private func startPermissionPolling() {
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPermissions()
            }
        }
    }
}
