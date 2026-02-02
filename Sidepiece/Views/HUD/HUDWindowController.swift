import AppKit
import SwiftUI

class HUDWindowController: NSWindowController {
    
    init(viewModel: HUDViewModel) {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 600),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .mainMenu
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
    
    required init?(coder: NSCoder) { fatalError() }
    
    func updatePosition() {
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.visibleFrame
        let padding: CGFloat = 24
        
        // Window is 300x600, positioned at bottom right
        let x = screenRect.maxX - 300 - padding
        let y = screenRect.minY + padding
        
        window?.setFrame(NSRect(x: x, y: y, width: 300, height: 600), display: true)
    }
    
    func show() {
        window?.orderFrontRegardless()
    }
}
