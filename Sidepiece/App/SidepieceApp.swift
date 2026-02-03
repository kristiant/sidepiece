import SwiftUI

@main
@MainActor
struct SidepieceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            // Hide the system settings since we have in-app settings
            EmptyView()
        }
    }
}
