import Foundation
import SwiftUI

/// Manages the navigation state within snippets, including folder traversal and auto-exit timers.
@MainActor
final class NavigationEngine: ObservableObject {
    static let shared = NavigationEngine()
    
    @Published private(set) var currentFolderId: UUID? = nil
    
    private var folderModeTimer: Timer?
    private let autoExitInterval: TimeInterval = 5.0
    
    private init() {}
    
    func enterFolder(_ folderId: UUID) {
        currentFolderId = folderId
        resetTimer()
    }
    
    func exitFolder() {
        invalidateTimer()
        currentFolderId = nil
    }
    
    func resetTimer() {
        invalidateTimer()
        folderModeTimer = Timer.scheduledTimer(withTimeInterval: autoExitInterval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.exitFolder()
                // Post notification for local feedback if needed
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
