import SwiftUI
import Combine

class HUDViewModel: ObservableObject {
    @Published var folderStore: [String] = [] // For breadcrumbs if needed
    @Published var activeFolderName: String? = nil
    @Published var feedbackMessage: String? = nil
    @Published var feedbackIcon: String? = nil
    @Published var isVisible: Bool = true
    
    private var dismissTimer: Timer?
    
    func showFeedback(message: String, icon: String) {
        feedbackMessage = message
        feedbackIcon = icon
        
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
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
