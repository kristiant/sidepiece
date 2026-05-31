import AppKit
import SwiftUI
import Combine

// Captures all HUD state properties that influence window sizing in one place.
struct HUDWindowState: Equatable {
    let isPeaking: Bool
    let hasFolderPath: Bool
    let hasFeedback: Bool

    /// True when the HUD is fully idle and only the small dot is visible.
    var isIdleDot: Bool { !isPeaking && !hasFolderPath && !hasFeedback }
}

final class HUDWindowController: NSWindowController {

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Geometry constants

    /// Full width used for the pill (with content) and peak panel.
    private let windowWidth: CGFloat  = 300
    /// Gap between the window edge and the screen edge.
    private let edgePadding: CGFloat  = 24
    /// Window height when the pill has content (breadcrumbs / feedback) but is not peaking.
    private let pillHeight: CGFloat   = 70
    /// Window height when the peak panel is open.
    private let peakHeight: CGFloat   = 600
    /// Window size when fully idle — just the dot.
    ///
    /// Calculated to tightly wrap the visible dot:
    ///   • dot circle: 4 pt
    ///   • capsule padding: 6 pt each side → capsule = 16 pt
    ///   • VStack outer padding: 12 pt each side
    ///   → total: 16 + 24 = 40 pt
    ///
    /// Keeping this tight is essential: any extra transparent area blocks
    /// mouse events for the apps that sit behind the HUD window.
    private let dotWindowSize: CGFloat = 40

    // MARK: - Init

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

        // Size the window correctly from the start.
        let initial = HUDWindowState(
            isPeaking: hudManager.isPeaking,
            hasFolderPath: !hudManager.folderPath.isEmpty,
            hasFeedback: hudManager.feedbackMessage != nil
        )
        updatePosition(state: initial)

        // Resize whenever *any* of the three sizing-relevant properties change.
        Publishers.CombineLatest3(
            hudManager.$isPeaking,
            hudManager.$folderPath.map { !$0.isEmpty },
            hudManager.$feedbackMessage.map { $0 != nil }
        )
        .map { HUDWindowState(isPeaking: $0, hasFolderPath: $1, hasFeedback: $2) }
        .removeDuplicates()
        .receive(on: RunLoop.main)
        .sink { [weak self] state in
            self?.updatePosition(state: state)
        }
        .store(in: &cancellables)

        // Show or hide the window whenever the stealth-mode setting changes.
        ConfigurationManager.shared.$configuration
            .map(\.showHUD)
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] showHUD in
                guard let self else { return }
                if showHUD {
                    let currentState = HUDWindowState(
                        isPeaking: hudManager.isPeaking,
                        hasFolderPath: !hudManager.folderPath.isEmpty,
                        hasFeedback: hudManager.feedbackMessage != nil
                    )
                    updatePosition(state: currentState)
                    window?.orderFrontRegardless()
                } else {
                    window?.orderOut(nil)
                }
            }
            .store(in: &cancellables)
    }

    required init?(coder: NSCoder) { fatalError("use init(hudManager:)") }

    // MARK: - Positioning

    func updatePosition(state: HUDWindowState) {
        // Don't resize/show while in stealth mode.
        guard ConfigurationManager.shared.configuration.showHUD else { return }
        guard let screen = NSScreen.main else { return }
        let f = screen.visibleFrame

        let width:  CGFloat
        let height: CGFloat

        if state.isPeaking {
            // Full peak panel
            width  = windowWidth
            height = peakHeight
        } else if state.hasFolderPath || state.hasFeedback {
            // Pill with visible content (breadcrumbs / feedback toast)
            width  = windowWidth
            height = pillHeight
        } else {
            // Idle — only the tiny dot is rendered.
            // The window MUST be this small; a larger transparent window
            // would silently eat mouse clicks in apps behind the HUD.
            width  = dotWindowSize
            height = dotWindowSize
        }

        window?.setFrame(
            .init(
                x: f.maxX - width  - edgePadding,
                y: f.minY          + edgePadding,
                width:  width,
                height: height
            ),
            display: true,
            animate: false
        )
    }

    // MARK: - Visibility

    func show() { window?.orderFrontRegardless() }
    func hide() { window?.orderOut(nil) }
}
