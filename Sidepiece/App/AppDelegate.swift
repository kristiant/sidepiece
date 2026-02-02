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
    
    /// The currently active folder for numpad navigation
    private var currentFolderId: UUID?
    
    // HUD Properties
    private let hudViewModel = HUDViewModel()
    private var hudWindowController: HUDWindowController?
    
    /// Timer to automatically exit folder mode after inactivity
    private var folderModeTimer: Timer?
    
    // MARK: - Initialisation
    
    override init() {
        self.snippetRepository = SnippetRepository(configurationManager: configurationManager)
        super.init()
        self.hudWindowController = HUDWindowController(viewModel: hudViewModel)
    }
    
    // MARK: - App Lifecycle
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        hudWindowController?.show()
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
        popover?.contentSize = NSSize(width: 1000, height: 600)
        popover?.behavior = .transient
        popover?.animates = true
        popover?.contentViewController = NSHostingController(
            rootView: MenuBarPopoverView(
                snippetRepository: snippetRepository,
                configurationManager: configurationManager,
                onSnippetSelected: { [weak self] snippet in
                    self?.executeSnippetAction(snippet)
                    self?.closePopover()
                },
                onAppFunctionSelected: { [weak self] function in
                    self?.handleAppFunction(function)
                    self?.closePopover()
                }
            )
        )
    }
    
    private func setupHotkeyMonitor() {
        hotkeyMonitor.onKeyPressed = { [weak self] key in
            self?.handleNumpadKeyPress(key)
        }
        
        // Only consume keys that have bindings configured (or if we are in a folder)
        hotkeyMonitor.shouldConsumeKey = { [weak self] key in
            guard let self = self else { return false }
            
            // If in a folder, we want to intercept navigation keys
            if self.currentFolderId != nil {
                // Consume 0-9 and clear for navigation
                return key.category == .numbers || key == .clear
            }
            
            return self.snippetRepository.getBinding(for: key) != nil
        }
        
        // Initial check and auto-start if possible
        checkAccessibilityAndStart()
        
        // Setup a timer to check again if not granted, so user doesn't have to restart app
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkAccessibilityAndStart()
        }
    }
    
    private func checkAccessibilityAndStart() {
        if hotkeyMonitor.hasAccessibilityPermissions() {
            if !hotkeyMonitor.isRunning {
                print("🎯 Sidepiece: Accessibility GRANTED. Starting monitor...")
                hotkeyMonitor.start()
            }
        } else {
            // Only log once in a while or just stay quiet
        }
    }
    
    // MARK: - Context Menu
    
    private func createContextMenu() -> NSMenu {
        let menu = NSMenu()
        
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
        checkAccessibilityAndStart() // Final check before showing UI
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func closePopover() {
        popover?.performClose(nil)
    }
    
    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    // MARK: - Hotkey Handling
    
    private func handleNumpadKeyPress(_ key: NumpadKey) {
        let navKeys: [NumpadKey] = [.num1, .num2, .num3, .num4, .num5, .num6, .num7, .num8, .num9, .num0, .clear]
        
        if let folderId = currentFolderId, navKeys.contains(key) {
            if let binding = snippetRepository.getBinding(for: key), 
               case .appFunction = binding.action {
                // App function takes precedence
            } else {
                handleFolderKeyPress(key, folderId: folderId)
                return
            }
        }
        
        guard let binding = snippetRepository.getBinding(for: key), binding.isEnabled else {
            return
        }
        
        switch binding.action {
        case .snippet(let snippet):
            executeSnippetAction(snippet)
        case .folder(let folderId):
            enterFolder(folderId)
        case .switchProfile(let profileId):
            if let profile = configurationManager.profiles.first(where: { $0.id == profileId }) {
                configurationManager.setActiveProfile(profile)
                showActionFeedback(title: "Profile: \(profile.name)", icon: "person.fill")
            }
        case .cycleProfile(let direction):
            configurationManager.cycleProfiles(direction: direction)
            if let active = configurationManager.activeProfile {
                showActionFeedback(title: "Profile: \(active.name)", icon: "person.2.fill")
            }
        case .appFunction(let function):
            handleAppFunction(function)
        }
    }
    
    private func handleAppFunction(_ function: KeyBinding.AppFunction) {
        switch function {
        case .peakSnippets:
            peakSnippets()
        }
    }
    
    private func peakSnippets(toggle: Bool = true) {
        if toggle && hudViewModel.isPeaking {
            hudViewModel.dismissPeak()
            return
        }

        let keys: [NumpadKey] = [.num1, .num2, .num3, .num4, .num5, .num6, .num7, .num8, .num9, .num0, .clear]
        let assignments: [(String, String)]
        
        if let folderId = currentFolderId {
            let subCategories = snippetRepository.getSubCategories(parentId: folderId)
            let folderSnippets = snippetRepository.getSnippets(in: folderId)
            let items: [Any] = subCategories + folderSnippets
            
            assignments = keys.compactMap { key in
                if key == .num0 || key == .clear { return (key.symbol, "BACK") }
                let idx = getIndex(for: key)
                guard idx >= 0 && idx < items.count else { return nil }
                let item = items[idx]
                let label = (item as? SnippetCategory)?.name ?? (item as? Snippet)?.title ?? ""
                return label.isEmpty ? nil : (key.symbol, label.uppercased())
            }
        } else {
            assignments = keys.compactMap { key in
                guard let action = snippetRepository.getBinding(for: key)?.action else { return nil }
                let label: String
                switch action {
                case .folder(let id): label = snippetRepository.getCategory(id: id)?.name ?? "FOLDER"
                default: label = action.displayName
                }
                return (key.symbol, label.uppercased())
            }
        }
        
        hudViewModel.peak(assignments: assignments)
    }
    
    private func enterFolder(_ folderId: UUID) {
        currentFolderId = folderId
        resetFolderTimer()
        if let category = snippetRepository.getCategory(id: folderId) {
            let subCategories = snippetRepository.getSubCategories(parentId: folderId)
            let folderSnippets = snippetRepository.getSnippets(in: folderId)
            let isEmpty = subCategories.isEmpty && folderSnippets.isEmpty
            
            hudViewModel.updateFolder(name: category.name)
            
            if isEmpty {
                showActionFeedback(title: "Empty Folder: \(category.name)", icon: "folder.badge.minus")
            } else {
                showActionFeedback(title: "Folder: \(category.name)", icon: "folder.fill")
            }
            
            if configurationManager.configuration.autoPeakFolderContents || hudViewModel.isPeaking {
                peakSnippets(toggle: false)
            }
        }
    }
    
    private func resetFolderTimer() {
        folderModeTimer?.invalidate()
        folderModeTimer = nil
        
        guard configurationManager.configuration.autoExitFolderMode else { return }
        
        folderModeTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.exitFolderMode(withFeedback: true)
            }
        }
    }
    
    private func exitFolderMode(withFeedback: Bool = false) {
        folderModeTimer?.invalidate()
        folderModeTimer = nil
        currentFolderId = nil
        hudViewModel.updateFolder(name: nil)
        
        if configurationManager.configuration.autoPeakFolderContents || hudViewModel.isPeaking {
            peakSnippets(toggle: false)
        }
        
        if withFeedback {
            showActionFeedback(title: "Auto-Exit: Back to Root", icon: "timer")
        }
    }
    
    private func handleFolderKeyPress(_ key: NumpadKey, folderId: UUID) {
        resetFolderTimer() // User interacted, reset the timer
        
        // 'clear' or 'num0' to go back
        if key == .clear || key == .num0 {
            if let currentFolder = snippetRepository.getCategory(id: folderId),
               let parentId = currentFolder.parentId {
                enterFolder(parentId)
            } else {
                exitFolderMode()
                showActionFeedback(title: "Back to Root", icon: "arrow.left")
            }
            return
        }
        
        let subCategories = snippetRepository.getSubCategories(parentId: folderId)
        let folderSnippets = snippetRepository.getSnippets(in: folderId)
        
        // Combine them: subfolders first, then snippets
        let items: [Any] = subCategories + folderSnippets
        
        // Map keys 1-9 to indices 0-8
        let index: Int?
        switch key {
        case .num1: index = 0
        case .num2: index = 1
        case .num3: index = 2
        case .num4: index = 3
        case .num5: index = 4
        case .num6: index = 5
        case .num7: index = 6
        case .num8: index = 7
        case .num9: index = 8
        default: index = nil
        }
        
        if let index = index, index < items.count {
            let item = items[index]
            if let subCategory = item as? SnippetCategory {
                enterFolder(subCategory.id)
            } else if let snippet = item as? Snippet {
                executeSnippetAction(snippet)
                // Stop the timer since we acted on a selection
                folderModeTimer?.invalidate()
                folderModeTimer = nil
            }
        }
    }
    
    private func executeSnippetAction(_ snippet: Snippet) {
        copySnippetToClipboard(snippet)
        
        // Paste if enabled
        if configurationManager.configuration.autoPaste {
            // Paste after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.pasteFromClipboard()
                
                // Press Enter if enabled (and we just pasted)
                if self.configurationManager.configuration.autoEnterAfterPaste {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.pressEnterKey()
                    }
                }
            }
        }
        
        showActionFeedback(title: "Copied: \(snippet.title)", icon: "doc.on.doc.fill")
    }
    
    private func copySnippetToClipboard(_ snippet: Snippet) {
        clipboardService.copyText(snippet.content)
        snippetRepository.recordUsage(for: snippet)
    }
    
    private func showActionFeedback(title: String, icon: String) {
        // Play sound if enabled
        if configurationManager.configuration.playSoundOnCopy {
            NSSound(named: .pop)?.play()
        }
        
        // Show in HUD
        hudViewModel.showFeedback(message: title, icon: icon)
        
        // For now, let's log it
        NSLog("Sidepiece Action: \(title)")
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
    
    private func pressEnterKey() {
        // Simulate Enter keystroke
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Key down for Enter
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x24, keyDown: true) // 0x24 = Return
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x24, keyDown: false)
        
        // Post the events
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
    
    private func showNotification(title: String, body: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = body
        notification.soundName = nil
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    private func getIndex(for key: NumpadKey) -> Int {
        switch key {
        case .num1: return 0
        case .num2: return 1
        case .num3: return 2
        case .num4: return 3
        case .num5: return 4
        case .num6: return 5
        case .num7: return 6
        case .num8: return 7
        case .num9: return 8
        default: return -1
        }
    }
}

// MARK: - NSSound Extension

extension NSSound.Name {
    static let pop = NSSound.Name("Pop")
}
