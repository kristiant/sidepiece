import AppKit
import SwiftUI

/// Manages the menu bar icon and its associated popover/menu
@MainActor
final class StatusBarManager: NSObject {
    static let shared = StatusBarManager()
    
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    
    private override init() {
        super.init()
    }
    
    func setup(popover: NSPopover) {
        self.popover = popover
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let button = statusItem?.button else {
            NSLog("Sidepiece Error: Failed to create status item button")
            return
        }
        
        // Use a more common symbol that exists on macOS 13+
        if let image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Sidepiece") {
            image.isTemplate = true
            button.image = image
        } else {
            button.title = "Sidepiece"
        }
        
        button.action = #selector(handleAction(_:))
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }
    
    @objc private func handleAction(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showContextMenu(sender)
        } else {
            togglePopover(sender)
        }
    }
    
    func togglePopover(_ sender: NSStatusBarButton) {
        guard let popover = popover else { return }
        
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    private func showContextMenu(_ sender: NSStatusBarButton) {
        let menu = NSMenu()
        menu.addItem(withTitle: "About Sidepiece", action: #selector(showAbout), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit Sidepiece", action: #selector(quitApp), keyEquivalent: "q")
        
        statusItem?.menu = menu
        sender.performClick(nil)
        statusItem?.menu = nil // Reset so next click is handled by handleAction
    }
    
    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
