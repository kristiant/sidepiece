import SwiftUI
import Combine

class HUDViewModel: ObservableObject {
    @Published var folderStore: [String] = [] // For breadcrumbs if needed
    @Published var activeFolderName: String? = nil
    @Published var feedbackMessage: String? = nil
    @Published var feedbackIcon: String? = nil
    @Published var isVisible: Bool = true
    @Published var isPeaking: Bool = false
    @Published var peakingAssignments: [(key: String, label: String)] = []
    
    private var dismissTimer: Timer?
    private var peakTimer: Timer?
    
    func peak(assignments: [(key: String, label: String)]) {
        peakingAssignments = assignments
        withAnimation(.spring(response: 0.3)) { isPeaking = true }
        
        peakTimer?.invalidate()
        peakTimer = .scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            withAnimation(.spring()) { self?.isPeaking = false }
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
