import SwiftUI
import Combine

@MainActor
final class HUDManager: ObservableObject {
    static let shared = HUDManager()
    
    @Published var folderStore: [String] = [] 
    @Published var activeFolderName: String? = nil
    @Published var feedbackMessage: String? = nil
    @Published var feedbackIcon: String? = nil
    @Published var isVisible: Bool = true
    @Published var isPeaking: Bool = false
    @Published var peakingAssignments: [(key: String, label: String)] = []
    
    private init() {}
    
    private var dismissTimer: Timer?
    private var peakTimer: Timer?
    
    func peak(assignments: [(key: String, label: String)]) {
        peakingAssignments = assignments
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isPeaking = true }
        
        peakTimer?.invalidate()
        peakTimer = .scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.dismissPeak() }
        }
    }
    
    func dismissPeak() {
        peakTimer?.invalidate()
        peakTimer = nil
        withAnimation(.spring()) { isPeaking = false }
    }
    
    func showFeedback(message: String, icon: String) {
        feedbackMessage = message
        feedbackIcon = icon
        
        dismissTimer?.invalidate()
        dismissTimer = .scheduledTimer(withTimeInterval: 3, repeats: false) { [weak self] _ in
            withAnimation {
                self?.feedbackMessage = nil
                self?.feedbackIcon = nil
            }
        }
    }
    
    func updateFolder(name: String?) {
        activeFolderName = name
    }
}
