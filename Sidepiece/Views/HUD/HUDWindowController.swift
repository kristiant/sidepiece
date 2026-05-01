import AppKit
import SwiftUI
import Combine

final class HUDWindowController: NSWindowController {

    private var cancellables = Set<AnyCancellable>()

    // Fixed geometry — window is anchored to the bottom-right of the main screen.
    private let windowWidth: CGFloat = 300
    private let edgePadding: CGFloat = 24
    /// Height when only the pill is visible — tall enough for pill + padding, no more.
    private let pillHeight: CGFloat = 70
    /// Height when the peak panel is open.
    private let peakHeight: CGFloat = 600

    init(hudManager: HUDManager) {
        let panel = NSPanel(
            contentRect: .init(x: 0, y: 0, width: 300, height: 70),
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
        updatePosition(isPeaking: false)

        // Resize the window whenever peak state changes so the panel never
        // covers more screen area than the visible content requires.
        hudManager.$isPeaking
            .receive(on: RunLoop.main)
            .sink { [weak self] isPeaking in
                self?.updatePosition(isPeaking: isPeaking)
            }
            .store(in: &cancellables)
    }

    required init?(coder: NSCoder) { fatalError("use init(hudManager:)") }

    func updatePosition(isPeaking: Bool = false) {
        guard let screen = NSScreen.main else { return }
        let f = screen.visibleFrame
        let height = isPeaking ? peakHeight : pillHeight
        window?.setFrame(
            .init(
                x: f.maxX - windowWidth - edgePadding,
                y: f.minY + edgePadding,
                width: windowWidth,
                height: height
            ),
            display: true
        )
    }

    func show() { window?.orderFrontRegardless() }
}
