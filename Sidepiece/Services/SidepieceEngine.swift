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
        NotificationCenter.default.addObserver(
            forName: .didAutoExitFolder, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.hud.clearFolderPath() }
        }
    }

    private func setupHotkeys() {
        hotkeyManager.onKeyPressed = { [weak self] key in self?.handleKeyPress(key) }
        hotkeyManager.shouldConsumeKey = { [weak self] key in
            guard let self else { return false }
            return self.navigation.currentFolderId != nil ||
                   self.snippetRepo.getBinding(for: key) != nil
        }
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
            if configManager.configuration.autoPeakFolderContents { peakSnippets(toggle: false) }
        } else if let snippet = item as? Snippet {
            executeSnippet(snippet)
            if configManager.configuration.autoExitFolderAfterSelection {
                navigation.exitFolder()
                hud.clearFolderPath()
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
                if configManager.configuration.autoPeakFolderContents { peakSnippets(toggle: false) }
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
        case .peakSnippets: peakSnippets()
        }
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
