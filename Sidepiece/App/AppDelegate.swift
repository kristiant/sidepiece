import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Properties
    
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    
    private let hotkeyMonitor = GlobalHotkeyMonitor()
    private let clipboardService = ClipboardService()
    private let configurationManager = ConfigurationManager()
    private let snippetRepository: SnippetRepository
    
    // MARK: - Initialisation
    
    override init() {
        self.snippetRepository = SnippetRepository(configurationManager: configurationManager)
        super.init()
    }
    
    // MARK: - App Lifecycle
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        setupHotkeyMonitor()
        
        // Ensure we don't show in dock (backup to Info.plist setting)
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        hotkeyMonitor.stop()
    }
    
    // MARK: - Status Item Setup
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let button = statusItem?.button else { return }
        
        // Use SF Symbol for menu bar icon
        if let image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Sidepiece") {
            image.isTemplate = true
            button.image = image
        }
        
        button.action = #selector(togglePopover)
        button.target = self
        
        // Right-click menu
        let menu = createContextMenu()
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusItem?.menu = nil // We'll handle clicks manually
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 380, height: 520)
        popover?.behavior = .transient
        popover?.animates = true
        popover?.contentViewController = NSHostingController(
            rootView: KeyBindingConfigView(
                snippetRepository: snippetRepository,
                configurationManager: configurationManager
            )
        )
    }
    
    private func setupHotkeyMonitor() {
        hotkeyMonitor.onKeyPressed = { [weak self] key in
            self?.handleNumpadKeyPress(key)
        }
        
        // Only consume keys that have bindings configured
        hotkeyMonitor.shouldConsumeKey = { [weak self] key in
            guard let self = self else { return false }
            return self.snippetRepository.getBinding(for: key) != nil
        }
        
        // Check for accessibility permissions before starting
        NSLog("Sidepiece: Checking accessibility permissions...")
        let hasPerms = hotkeyMonitor.hasAccessibilityPermissions()
        NSLog("Sidepiece: Has permissions = \(hasPerms)")
        if hasPerms {
            NSLog("Sidepiece: Starting monitor...")
            hotkeyMonitor.start()
        } else {
            NSLog("Sidepiece: No permissions, requesting...")
            // Will prompt user for permissions
            hotkeyMonitor.requestAccessibilityPermissions()
        }
    }
    
    // MARK: - Context Menu
    
    private func createContextMenu() -> NSMenu {
        let menu = NSMenu()
        
        menu.addItem(withTitle: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "About Sidepiece", action: #selector(showAbout), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit Sidepiece", action: #selector(quitApp), keyEquivalent: "q")
        
        return menu
    }
    
    // MARK: - Actions
    
    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            // Show context menu on right-click
            statusItem?.menu = createContextMenu()
            statusItem?.button?.performClick(nil)
            statusItem?.menu = nil
        } else {
            // Toggle popover on left-click
            if let popover = popover, popover.isShown {
                closePopover()
            } else {
                showPopover()
            }
        }
    }
    
    private func showPopover() {
        guard let button = statusItem?.button, let popover = popover else { return }
        startMonitoring() // Check permissions and start if possible
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func closePopover() {
        popover?.performClose(nil)
    }
    
    @objc private func openPreferences() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func startMonitoring() {
        if hotkeyMonitor.hasAccessibilityPermissions() {
            NSLog("Sidepiece: Has permissions, starting monitor...")
            hotkeyMonitor.start()
        } else {
            NSLog("Sidepiece: Still no permissions.")
        }
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    // MARK: - Hotkey Handling
    
    private func handleNumpadKeyPress(_ key: NumpadKey) {
        guard let binding = snippetRepository.getBinding(for: key), binding.isEnabled else {
            return
        }
        
        copySnippetToClipboard(binding.snippet)
        
        // Paste after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.pasteFromClipboard()
        }
        
        showCopiedFeedback(for: binding.snippet)
    }
    
    private func copySnippetToClipboard(_ snippet: Snippet) {
        clipboardService.copyText(snippet.content)
        snippetRepository.recordUsage(for: snippet)
    }
    
    private func pasteFromClipboard() {
        // Simulate Cmd+V keystroke
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Key down for V with Command modifier
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) // 0x09 = V
        keyDown?.flags = .maskCommand
        
        // Key up for V
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyUp?.flags = .maskCommand
        
        // Post the events
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
    
    private func showCopiedFeedback(for snippet: Snippet) {
        // Play sound if enabled
        if configurationManager.configuration.playSoundOnCopy {
            NSSound(named: .pop)?.play()
        }
        
        // Show notification if enabled
        if configurationManager.configuration.showNotificationOnCopy {
            showNotification(title: "Copied!", body: snippet.title)
        }
    }
    
    private func showNotification(title: String, body: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = body
        notification.soundName = nil
        NSUserNotificationCenter.default.deliver(notification)
    }
}

// MARK: - NSSound Extension

extension NSSound.Name {
    static let pop = NSSound.Name("Pop")
}
