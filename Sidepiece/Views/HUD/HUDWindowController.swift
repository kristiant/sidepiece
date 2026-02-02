import AppKit
import SwiftUI

class HUDWindowController: NSWindowController {
    
    init(viewModel: HUDViewModel) {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 60),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .mainMenu // Very high but safe
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        
        let contentView = NSHostingView(rootView: FloatingHUDView(viewModel: viewModel))
        panel.contentView = contentView
        
        super.init(window: panel)
        
        updatePosition()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updatePosition() {
        guard let screen = NSScreen.main else { return }
        
        // Position at bottom right
        let screenRect = screen.visibleFrame
        let windowWidth: CGFloat = 400
        let windowHeight: CGFloat = 60
        let padding: CGFloat = 20
        
        let x = screenRect.maxX - windowWidth - padding
        let y = screenRect.minY + padding
        
        window?.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
    }
    
    func show() {
        window?.orderFrontRegardless()
    }
}
