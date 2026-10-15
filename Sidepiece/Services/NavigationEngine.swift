import Foundation
import SwiftUI

@MainActor
final class NavigationEngine: ObservableObject {
    static let shared = NavigationEngine()

    @Published private(set) var folderStack: [(id: UUID, name: String)] = []

    var currentFolderId: UUID? { folderStack.last?.id }

    private var folderModeTimer: Timer?
    private init() {}

    // MARK: - Navigation

    func enterFolder(_ folderId: UUID, name: String) {
        folderStack.append((id: folderId, name: name))
        resetTimer()
    }

    func popFolder() {
        guard !folderStack.isEmpty else { return }
        folderStack.removeLast()
        folderStack.isEmpty ? invalidateTimer() : resetTimer()
    }

    /// Navigate to a specific stack depth. depth == -1 means root.
    func navigateTo(depth: Int) {
        if depth < 0 {
            folderStack.removeAll()
            invalidateTimer()
        } else {
            folderStack = Array(folderStack.prefix(depth + 1))
            resetTimer()
        }
    }

    func exitFolder() {
        invalidateTimer()
        folderStack.removeAll()
    }

    // MARK: - Timer

    func resetTimer() {
        invalidateTimer()
        guard ConfigurationManager.shared.configuration.autoExitFolderMode else { return }
        folderModeTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.exitFolder()
                NotificationCenter.default.post(name: .didAutoExitFolder, object: nil)
            }
        }
    }

    func invalidateTimer() {
        folderModeTimer?.invalidate()
        folderModeTimer = nil
    }
}

extension Notification.Name {
    static let didAutoExitFolder = Notification.Name("didAutoExitFolder")
}
