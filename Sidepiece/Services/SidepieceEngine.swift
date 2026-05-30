import Foundation
import AppKit
import OSLog

/// The central coordinator for Sidepiece. Bridges hotkeys, snippets, and UI.
@MainActor
final class SidepieceEngine: ObservableObject {
    static let shared = SidepieceEngine()
    private let logger = Logger(subsystem: "com.sidepiece.app", category: "Engine")

    private let configManager = ConfigurationManager.shared
    private let snippetRepo = SnippetRepository.shared
    private let navigation = NavigationEngine.shared
    private let hotkeyManager = HotkeyManager.shared
    private let hud = HUDManager.shared
    private let clipboard = ClipboardService()

    private init() {
        setupHotkeys()
        // Keep HUD in sync when the auto-exit timer fires inside NavigationEngine.
        // Dismiss the peak too — its content is now stale (folder context is gone).
        NotificationCenter.default.addObserver(
            forName: .didAutoExitFolder, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.hud.clearFolderPath()
                self?.hud.dismissPeak()
            }
        }
    }

    private func setupHotkeys() {
        hotkeyManager.onKeyPressed = { [weak self] key in self?.handleKeyPress(key) }
        hotkeyManager.shouldConsumeKey = { [weak self] key in
            guard let self else { return false }
            return self.navigation.currentFolderId != nil ||
                   self.snippetRepo.getBinding(for: key) != nil
        }
        // Peak trigger — closure so config changes are reflected immediately.
        hotkeyManager.peakTriggerKeyCode = { [weak self] in
            self?.configManager.configuration.peakHotkey?.keyCode
        }
        hotkeyManager.isPeaking    = { [weak self] in self?.hud.isPeaking ?? false }
        hotkeyManager.onPeakTrigger  = { [weak self] in self?.peakSnippets() }
        hotkeyManager.onNumberRowKey = { [weak self] key in self?.handleKeyPress(key) }
        hotkeyManager.onDismissPeak  = { [weak self] in self?.hud.dismissPeak() }
    }

    /// Simulate a numpad key press from the GUI (identical path to hardware events).
    func trigger(_ key: NumpadKey) { handleKeyPress(key) }

    private func handleKeyPress(_ key: NumpadKey) {
        logger.info("Handling key press: \(key.displayName)")
        if let folderId = navigation.currentFolderId {
            handleFolderKeyPress(key, folderId: folderId)
            return
        }
        guard let binding = snippetRepo.getBinding(for: key) else { return }
        executeAction(binding.action)
    }

    private func handleFolderKeyPress(_ key: NumpadKey, folderId: UUID) {
        if key == .clear {
            navigation.popFolder()
            hud.popFolder()
            // Refresh peak to show the parent level's contents.
            if hud.isPeaking { peakSnippets(toggle: false) }
            return
        }

        let items = snippetRepo.getFolderContents(folderId: folderId)
        let keys: [NumpadKey] = [.num7, .num8, .num9, .num4, .num5, .num6, .num1, .num2, .num3, .num0]

        guard let index = keys.firstIndex(of: key), index < items.count else { return }
        let item = items[index]

        if let subCategory = item as? SnippetCategory {
            navigation.enterFolder(subCategory.id, name: subCategory.name)
            hud.pushFolder(id: subCategory.id, name: subCategory.name)
            // Always refresh the peak if it's already open — keeps displayed content
            // accurate regardless of the autoPeakFolderContents preference.
            if hud.isPeaking || configManager.configuration.autoPeakFolderContents {
                peakSnippets(toggle: false)
            }
        } else if let snippet = item as? Snippet {
            executeSnippet(snippet)
            if configManager.configuration.autoExitFolderAfterSelection {
                navigation.exitFolder()
                hud.clearFolderPath()
                hud.dismissPeak()  // peak content is now stale after exiting folder
            } else {
                navigation.resetTimer()
            }
        }
    }

    func executeAction(_ action: KeyBinding.Action) {
        switch action {
        case .snippet(let id):
            if let snippet = snippetRepo.getSnippet(id: id) { executeSnippet(snippet) }
        case .folder(let id):
            if let folder = snippetRepo.getCategory(id: id) {
                navigation.enterFolder(id, name: folder.name)
                hud.pushFolder(id: id, name: folder.name)
                if hud.isPeaking || configManager.configuration.autoPeakFolderContents {
                    peakSnippets(toggle: false)
                }
            }
        case .switchProfile(let id):
            configManager.activeProfileId = id
            if let active = configManager.activeProfile {
                hud.showFeedback(message: "Profile: \(active.name)", icon: "person.2.fill")
            }
        case .cycleProfile(let direction):
            configManager.cycleProfiles(direction: direction)
            if let active = configManager.activeProfile {
                hud.showFeedback(message: "Profile: \(active.name)", icon: "person.2.fill")
            }
        case .appFunction(let function):
            handleAppFunction(function)
        case .launchApp(let bundleId):
            launchApplication(bundleId: bundleId)
        case .runCommand(let command):
            runShellCommand(command)
        }
    }

    /// Navigate to a breadcrumb ancestor. depth == -1 returns to root.
    func navigateFolderToDepth(_ depth: Int) {
        navigation.navigateTo(depth: depth)
        hud.navigateFolderToDepth(depth)
        if hud.isPeaking { peakSnippets(toggle: false) }
    }

    private func executeSnippet(_ snippet: Snippet) {
        clipboard.copy(snippet.content)
        snippetRepo.recordUsage(for: snippet)
        if configManager.configuration.playSoundOnCopy { NSSound(named: "Submarine")?.play() }
        if configManager.configuration.autoPaste {
            Task {
                try? await Task.sleep(nanoseconds: 100_000_000)
                clipboard.paste()
                if configManager.configuration.autoEnterAfterPaste {
                    try? await Task.sleep(nanoseconds: 50_000_000)
                    clipboard.typeEnter()
                }
            }
        }
        hud.showFeedback(message: "Copied: \(snippet.title)", icon: "doc.on.doc.fill")
    }

    private func handleAppFunction(_ function: KeyBinding.AppFunction) {
        switch function {
        case .peakSnippets:   peakSnippets()
        case .cycleWindows:   cycleFrontmostAppWindows()
        case .appExpose:      triggerAppExpose()
        case .missionControl: triggerMissionControl()
        }
    }

    private func launchApplication(bundleId: String) {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            logger.error("Cannot find app with bundle ID: \(bundleId)")
            hud.showFeedback(message: "App not found", icon: "exclamationmark.triangle.fill")
            return
        }
        let name = Bundle(url: appURL)?.infoDictionary?["CFBundleDisplayName"] as? String
            ?? Bundle(url: appURL)?.infoDictionary?["CFBundleName"] as? String
            ?? bundleId
        NSWorkspace.shared.open(appURL)
        hud.showFeedback(message: "Opening \(name)", icon: "arrow.up.forward.app.fill")
        logger.info("Launching \(bundleId) at \(appURL.path)")
    }

    /// Runs an arbitrary shell command via `/bin/sh -c` on a background thread.
    private func runShellCommand(_ command: String) {
        hud.showFeedback(message: "Running command", icon: "terminal.fill")
        logger.info("Running shell command: \(command)")
        Task.detached(priority: .userInitiated) { [weak self] in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/sh")
            process.arguments = ["-c", command]
            // Inherit the user's environment so PATH, HOME etc. are available.
            process.environment = ProcessInfo.processInfo.environment
            do {
                try process.run()
                process.waitUntilExit()
                let status = process.terminationStatus
                await self?.logger.info("Command exited with status \(status)")
            } catch {
                await self?.logger.error("Command failed to launch: \(error)")
            }
        }
    }

    /// Simulates ⌘` — macOS "Cycle Through Windows".
    private func cycleFrontmostAppWindows() {
        postSystemKey(virtualKey: 0x32, flags: .maskCommand)  // kVK_ANSI_Grave
        logger.info("Cycling windows via ⌘`")
    }

    /// Simulates ⌃↓ — macOS "App Exposé" (show all windows of the frontmost app).
    private func triggerAppExpose() {
        postSystemKey(virtualKey: 0x7D, flags: .maskControl)  // kVK_DownArrow
        logger.info("Triggering App Exposé via ⌃↓")
    }

    /// Simulates ⌃↑ — macOS "Mission Control" (show all windows of all apps).
    private func triggerMissionControl() {
        postSystemKey(virtualKey: 0x7E, flags: .maskControl)  // kVK_UpArrow
        logger.info("Triggering Mission Control via ⌃↑")
    }

    /// Posts a synthetic key-down + key-up pair at the HID event tap level.
    private func postSystemKey(virtualKey: CGKeyCode, flags: CGEventFlags) {
        let source  = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: true)
        let keyUp   = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: false)
        keyDown?.flags = flags
        keyUp?.flags   = flags
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    func peakSnippets(toggle: Bool = true) {
        if toggle && hud.isPeaking { hud.dismissPeak(); return }

        let keys: [NumpadKey] = [.num7, .num8, .num9, .num4, .num5, .num6, .num1, .num2, .num3, .num0]
        let assignments: [(key: String, label: String, numpadKey: NumpadKey)]

        if let folderId = navigation.currentFolderId {
            let items = snippetRepo.getFolderContents(folderId: folderId)
            assignments = keys.enumerated().compactMap { idx, key in
                guard idx < items.count else { return nil }
                let item = items[idx]
                let label = (item as? SnippetCategory)?.name ?? (item as? Snippet)?.title ?? ""
                return label.isEmpty ? nil : (key.symbol, label.uppercased(), key)
            }
        } else {
            assignments = keys.compactMap { key in
                guard let action = snippetRepo.getBinding(for: key)?.action else { return nil }
                let label: String
                switch action {
                case .folder(let id): label = snippetRepo.getCategory(id: id)?.name ?? "FOLDER"
                case .snippet(let id): label = snippetRepo.getSnippet(id: id)?.title ?? "SNIPPET"
                default: label = action.displayName
                }
                return (key.symbol, label.uppercased(), key)
            }
        }

        hud.peak(assignments: assignments)
    }
}
