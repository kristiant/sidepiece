import Foundation
import AppKit

/// The central coordinator for Sidepiece. Bridges hotkeys, snippets, and UI.
@MainActor
final class SidepieceEngine: ObservableObject {
    static let shared = SidepieceEngine()
    
    private let configManager = ConfigurationManager.shared
    private let snippetRepo = SnippetRepository.shared
    private let navigation = NavigationEngine.shared
    private let hotkeyManager = HotkeyManager.shared
    private let hud = HUDManager.shared
    private let clipboard = ClipboardService()
    
    private init() {
        setupHotkeys()
    }
    
    private func setupHotkeys() {
        hotkeyManager.onKeyPressed = { [weak self] key in self?.handleKeyPress(key) }
        
        hotkeyManager.shouldConsumeKey = { [weak self] key in
            guard let self = self else { return false }
            return self.navigation.currentFolderId != nil || 
                   self.snippetRepo.getBinding(for: key) != nil
        }
    }
    
    private func handleKeyPress(_ key: NumpadKey) {
        NSLog("Sidepiece Engine: Handling key press: \(key.displayName)")
        if let folderId = navigation.currentFolderId {
            handleFolderKeyPress(key, folderId: folderId)
            return
        }
        
        guard let binding = snippetRepo.getBinding(for: key) else { return }
        executeAction(binding.action)
    }
    
    private func handleFolderKeyPress(_ key: NumpadKey, folderId: UUID) {
        if key == .clear {
            navigation.exitFolder()
            hud.updateFolder(name: nil)
            return
        }
        
        let items = snippetRepo.getFolderContents(folderId: folderId)
        let keys: [NumpadKey] = [.num7, .num8, .num9, .num4, .num5, .num6, .num1, .num2, .num3, .num0]
        
        if let index = keys.firstIndex(of: key), index < items.count {
            let item = items[index]
            if let subCategory = item as? SnippetCategory {
                navigation.enterFolder(subCategory.id)
                hud.updateFolder(name: subCategory.name)
                if configManager.configuration.autoPeakFolderContents {
                    peakSnippets(toggle: false)
                }
            } else if let snippet = item as? Snippet {
                executeSnippet(snippet)
                if configManager.configuration.autoExitFolderAfterSelection {
                    navigation.exitFolder()
                    hud.updateFolder(name: nil)
                } else {
                    navigation.resetTimer()
                }
            }
        }
    }
    
    func executeAction(_ action: KeyBinding.Action) {
        switch action {
        case .snippet(let id):
            if let snippet = snippetRepo.getSnippet(id: id) {
                executeSnippet(snippet)
            }
        case .folder(let id):
            navigation.enterFolder(id)
            if let folder = snippetRepo.getCategory(id: id) {
                hud.updateFolder(name: folder.name)
                if configManager.configuration.autoPeakFolderContents {
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
        }
    }
    
    private func executeSnippet(_ snippet: Snippet) {
        clipboard.copy(snippet.content)
        snippetRepo.recordUsage(for: snippet)
        
        if configManager.configuration.playSoundOnCopy {
            NSSound(named: "Submarine")?.play()
        }
        
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
        case .peakSnippets:
            peakSnippets()
        }
    }
    
    func peakSnippets(toggle: Bool = true) {
        if toggle && hud.isPeaking {
            hud.dismissPeak()
            return
        }

        let keys: [NumpadKey] = [.num7, .num8, .num9, .num4, .num5, .num6, .num1, .num2, .num3, .num0]
        let assignments: [(key: String, label: String)]
        
        if let folderId = navigation.currentFolderId {
            let items = snippetRepo.getFolderContents(folderId: folderId)
            assignments = keys.enumerated().compactMap { idx, key in
                guard idx < items.count else { return nil }
                let item = items[idx]
                let label = (item as? SnippetCategory)?.name ?? (item as? Snippet)?.title ?? ""
                return label.isEmpty ? nil : (key.symbol, label.uppercased())
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
                return (key.symbol, label.uppercased())
            }
        }
        
        hud.peak(assignments: assignments)
    }
}
