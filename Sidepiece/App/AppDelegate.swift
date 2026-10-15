import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let engine = SidepieceEngine.shared
    private let popover = NSPopover()
    private var hud: HUDWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupPopover()
        StatusBarManager.shared.setup(popover: popover)
        hud = HUDWindowController(hudManager: .shared)
        hud?.showWindow(nil)
        HotkeyManager.shared.start()
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.stop()
    }

    private func setupPopover() {
        popover.contentSize = NSSize(width: 950, height: 650)
        popover.behavior = .transient
        popover.appearance = NSAppearance(named: .darkAqua)

        let view = MenuBarPopoverView(
            snippetRepository: .shared,
            configurationManager: .shared,
            onSnippetSelected: { [weak self] in self?.run(.snippet(id: $0.id)) },
            onAppFunctionSelected: { [weak self] in self?.run(.appFunction($0)) }
        )
        .tint(Color.spAccent)
        .preferredColorScheme(.dark)
        .background(Color.spBackground)

        let host = NSHostingController(rootView: view)
        host.view.appearance = NSAppearance(named: .darkAqua)
        popover.contentViewController = host
    }

    private func run(_ action: KeyBinding.Action) {
        engine.executeAction(action)
        popover.performClose(nil)
    }
}
