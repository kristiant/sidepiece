import Carbon.HIToolbox
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

    private init() {
        setupHotkeys()
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
        let m = hotkeyManager.monitor
        m.onKeyPressed = { [weak self] in self?.handleKeyPress($0) }
        m.onNumberRowKey = { [weak self] in self?.handleKeyPress($0) }
        m.shouldConsumeKey = { [weak self] key in
            guard let self else { return false }
            return navigation.currentFolderId != nil || snippetRepo.getBinding(for: key) != nil
        }
        m.peakTriggerKeyCode = { [weak self] in self?.configManager.configuration.peakHotkey?.keyCode }
        m.isPeaking = { [weak self] in self?.hud.isPeaking ?? false }
        m.onPeakTrigger = { [weak self] in self?.peakSnippets() }
        m.onDismissPeak = { [weak self] in self?.hud.dismissPeak() }
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
            if hud.isPeaking { peakSnippets(toggle: false) }
            return
        }

        let items = snippetRepo.getFolderContents(folderId: folderId)
        guard let index = NumpadKey.folderSlots.firstIndex(of: key), items.indices.contains(index) else { return }

        switch items[index] {
        case .folder(let sub):
            open(sub)
        case .snippet(let snippet):
            executeSnippet(snippet)
            if configManager.configuration.autoExitFolderAfterSelection {
                navigation.exitFolder()
                hud.clearFolderPath()
                hud.dismissPeak()
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
            snippetRepo.getCategory(id: id).map(open)
        case .switchProfile(let id):
            configManager.activeProfileId = id
            announceProfile()
        case .cycleProfile(let direction):
            configManager.cycleProfiles(direction: direction)
            announceProfile()
        case .appFunction(let function):
            handleAppFunction(function)
        case .launchApp(let bundleId):
            launchApplication(bundleId: bundleId)
        case .runCommand(let command):
            runShellCommand(command)
        }
    }

    private func open(_ folder: SnippetCategory) {
        navigation.enterFolder(folder.id, name: folder.name)
        hud.pushFolder(id: folder.id, name: folder.name)
        if hud.isPeaking || configManager.configuration.autoPeakFolderContents {
            peakSnippets(toggle: false)
        }
    }

    private func announceProfile() {
        guard let active = configManager.activeProfile else { return }
        hud.showFeedback(message: "Profile: \(active.name)", icon: "person.2.fill")
    }

    /// Navigate to a breadcrumb ancestor. depth == -1 returns to root.
    func navigateFolderToDepth(_ depth: Int) {
        navigation.navigateTo(depth: depth)
        hud.navigateFolderToDepth(depth)
        if hud.isPeaking { peakSnippets(toggle: false) }
    }

    private func executeSnippet(_ snippet: Snippet) {
        Clipboard.copy(snippet.content)
        snippetRepo.recordUsage(for: snippet)
        if configManager.configuration.playSoundOnCopy { NSSound(named: "Submarine")?.play() }
        if configManager.configuration.autoPaste {
            Task {
                try? await Task.sleep(for: .milliseconds(100))
                Clipboard.paste()
                if configManager.configuration.autoEnterAfterPaste {
                    try? await Task.sleep(for: .milliseconds(50))
                    Clipboard.typeEnter()
                }
            }
        }
        hud.showFeedback(message: "Copied: \(snippet.title)", icon: "doc.on.doc.fill")
    }

    private func handleAppFunction(_ function: KeyBinding.AppFunction) {
        switch function {
        case .peakSnippets:   peakSnippets()
        case .cycleWindows:   Keyboard.press(kVK_ANSI_Grave, flags: .maskCommand, tap: .cghidEventTap)
        case .appExpose:      Keyboard.press(kVK_DownArrow, flags: .maskControl, tap: .cghidEventTap)
        case .missionControl: Keyboard.press(kVK_UpArrow, flags: .maskControl, tap: .cghidEventTap)
        }
    }

    private func launchApplication(bundleId: String) {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            logger.error("Cannot find app with bundle ID: \(bundleId)")
            hud.showFeedback(message: "App not found", icon: "exclamationmark.triangle.fill")
            return
        }
        let name = FileManager.default.displayName(atPath: appURL.path)
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

    func peakSnippets(toggle: Bool = true) {
        if toggle && hud.isPeaking { hud.dismissPeak(); return }

        let keys = NumpadKey.folderSlots
        let items: [PeakItem]
        if let folderId = navigation.currentFolderId {
            items = zip(keys, snippetRepo.getFolderContents(folderId: folderId)).compactMap { key, item in
                item.name.isEmpty ? nil : PeakItem(key: key, label: item.name.uppercased())
            }
        } else {
            items = keys.compactMap { key in
                snippetRepo.getBinding(for: key).map { PeakItem(key: key, label: snippetRepo.label(for: $0.action).uppercased()) }
            }
        }
        hud.peak(assignments: items)

    }
}
