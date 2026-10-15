import AppKit

/// Menu bar icon. Left click toggles the popover, right click shows a small menu.
@MainActor
final class StatusBarManager: NSObject {
    static let shared = StatusBarManager()

    private var item: NSStatusItem?
    private var popover: NSPopover?

    func setup(popover: NSPopover) {
        self.popover = popover
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let button = item.button!
        button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Sidepiece")
        button.image?.isTemplate = true
        button.action = #selector(handleClick)
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        self.item = item
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        NSApp.currentEvent?.type == .rightMouseUp ? showMenu(sender) : togglePopover(sender)
    }

    private func togglePopover(_ sender: NSStatusBarButton) {
        guard let popover else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func showMenu(_ sender: NSStatusBarButton) {
        let menu = NSMenu()
        menu.addItem(withTitle: "About Sidepiece", action: #selector(showAbout), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Sidepiece", action: #selector(NSApplication.terminate), keyEquivalent: "q")
        // Attach only for this click so the next left click still reaches handleClick.
        item?.menu = menu
        sender.performClick(nil)
        item?.menu = nil
    }

    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
