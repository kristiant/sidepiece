import AppKit
import SwiftUI
import Combine

struct HUDWindowState: Equatable {
    let isPeaking: Bool
    let hasContent: Bool

    @MainActor
    init(_ hud: HUDManager) {
        self.init(isPeaking: hud.isPeaking, hasFolderPath: !hud.folderPath.isEmpty, hasFeedback: hud.feedbackMessage != nil)
    }

    init(isPeaking: Bool, hasFolderPath: Bool, hasFeedback: Bool) {
        self.isPeaking = isPeaking
        hasContent = hasFolderPath || hasFeedback
    }

    /// Idle size wraps the dot tightly, as any spare transparent area swallows clicks meant for apps behind it.
    var size: CGSize {
        if isPeaking { return CGSize(width: 300, height: 600) }
        if hasContent { return CGSize(width: 300, height: 70) }
        return CGSize(width: 40, height: 40)
    }
}

final class HUDWindowController: NSWindowController {
    private let edgePadding: CGFloat = 24
    private var cancellables = Set<AnyCancellable>()

    @MainActor
    init(hudManager hud: HUDManager) {
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
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false

        // A plain container stops SwiftUI sizing from feeding back into window resizes.
        let host = NSHostingView(rootView: FloatingHUDView(hudManager: hud).tint(Color.spAccent).preferredColorScheme(.dark))
        host.sizingOptions = []
        host.autoresizingMask = [.width, .height]
        let container = NSView()
        container.addSubview(host)
        panel.contentView = container
        host.frame = container.bounds

        super.init(window: panel)

        updatePosition(state: HUDWindowState(hud))

        Publishers.CombineLatest3(
            hud.$isPeaking,
            hud.$folderPath.map { !$0.isEmpty },
            hud.$feedbackMessage.map { $0 != nil }
        )
        .map(HUDWindowState.init)
        .removeDuplicates()
        .receive(on: RunLoop.main)
        .sink { [weak self] in self?.updatePosition(state: $0) }
        .store(in: &cancellables)

        ConfigurationManager.shared.$configuration
            .map(\.showHUD)
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] show in
                guard let self else { return }
                if show {
                    updatePosition(state: HUDWindowState(hud))
                    window?.orderFrontRegardless()
                } else {
                    window?.orderOut(nil)
                }
            }
            .store(in: &cancellables)
    }

    required init?(coder: NSCoder) { fatalError("use init(hudManager:)") }

    @MainActor
    private func updatePosition(state: HUDWindowState) {
        guard ConfigurationManager.shared.configuration.showHUD, let screen = NSScreen.main else { return }
        let f = screen.visibleFrame
        let size = state.size
        window?.setFrame(
            .init(x: f.maxX - size.width - edgePadding, y: f.minY + edgePadding, width: size.width, height: size.height),
            display: true
        )
    }
}
