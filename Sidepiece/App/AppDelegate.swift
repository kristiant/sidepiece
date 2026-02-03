import AppKit
import SwiftUI

/// main application entry point and lifecycle coordinator.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Properties
    
    private let configManager = ConfigurationManager.shared
    private let snippetRepo = SnippetRepository.shared
    private let engine = SidepieceEngine.shared
    private let statusBar = StatusBarManager.shared
    private let hotkeyManager = HotkeyManager.shared
    
    private var popover: NSPopover?
    private var hudWindowController: HUDWindowController?
    
    // MARK: - Lifecycle
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupPopover()
        setupStatusBar()
        setupHUD()
        setupHotkeyMonitoring()
        
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager.stop()
    }
    
    // MARK: - Setup Logic
    
    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 950, height: 650)
        popover?.behavior = .transient
        popover?.animates = true
        
        let contentView = MenuBarPopoverView(
            snippetRepository: snippetRepo,
            configurationManager: configManager,
            onSnippetSelected: { [weak self] snippet in
                self?.engine.executeAction(.snippet(id: snippet.id))
                self?.closePopover()
            },
            onAppFunctionSelected: { [weak self] function in
                self?.engine.executeAction(.appFunction(function))
                self?.closePopover()
            }
        )
        popover?.contentViewController = NSHostingController(rootView: contentView)
    }
    
    private func setupStatusBar() {
        guard let popover = popover else { return }
        statusBar.setup(popover: popover)
    }
    
    private func setupHUD() {
        hudWindowController = HUDWindowController(hudManager: HUDManager.shared)
        hudWindowController?.showWindow(nil)
    }
    
    private func setupHotkeyMonitoring() {
        hotkeyManager.start()
    }
    
    private func closePopover() {
        popover?.performClose(nil)
    }
}
