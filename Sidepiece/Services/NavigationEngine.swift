import Foundation
import SwiftUI

/// Manages the navigation state within snippets, including folder traversal and auto-exit timers.
@MainActor
final class NavigationEngine: ObservableObject {
    static let shared = NavigationEngine()

    /// Full path from root to the current folder.
    @Published private(set) var folderStack: [(id: UUID, name: String)] = []

    /// Convenience: the ID of the deepest active folder, or nil at root.
    var currentFolderId: UUID? { folderStack.last?.id }

    private var folderModeTimer: Timer?
    private init() {}

    // MARK: - Navigation

    func enterFolder(_ folderId: UUID, name: String) {
        folderStack.append((id: folderId, name: name))
        resetTimer()
    }

    /// Pop one level up. Invalidates timer if we've returned to root.
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

    /// Exit all folders (used by auto-exit timer and post-snippet autoExit).
    func exitFolder() {
        invalidateTimer()
        folderStack.removeAll()
    }

    // MARK: - Timer

    func resetTimer() {
        invalidateTimer()
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
