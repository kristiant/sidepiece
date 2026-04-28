import AppKit
import SwiftUI

final class HUDWindowController: NSWindowController {

    init(hudManager: HUDManager) {
        let panel = NSPanel(
            contentRect: .init(x: 0, y: 0, width: 300, height: 600),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .mainMenu
        panel.hasShadow = false
        panel.ignoresMouseEvents = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        let hudView = FloatingHUDView(hudManager: hudManager)
            .tint(Color.spAccent)
            .preferredColorScheme(.dark)
        panel.contentView = NSHostingView(rootView: hudView)

        super.init(window: panel)
        updatePosition()
    }

    required init?(coder: NSCoder) { fatalError("use init(hudManager:)") }

    func updatePosition() {
        guard let screen = NSScreen.main else { return }
        let f = screen.visibleFrame
        window?.setFrame(.init(x: f.maxX - 324, y: f.minY + 24, width: 300, height: 600), display: true)
    }

    func show() { window?.orderFrontRegardless() }
}
