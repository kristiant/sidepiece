import SwiftUI
import AppKit

// MARK: - Sidepiece Design Tokens
//
// Semantic colour tokens for the dark-mode palette.
// All views must reference these tokens instead of
// raw colours or opacity hacks.
//
// Raw values (dark mode):
//   Background:          #121212
//   Panel:               #1F1F1F
//   Elevated Panel:      #262626
//   Text / Foreground:   #F8F8F8
//   Muted / Icon:        #979797

extension Color {

    // MARK: Surfaces
    /// Primary app background — #121212
    static let spBackground    = Color(hex: "121212")

    /// Standard panel / card surface — #1F1F1F
    static let spPanel         = Color(hex: "1F1F1F")

    /// Elevated panel on top of a panel — #262626
    static let spPanelElevated = Color(hex: "262626")

    // MARK: Foreground
    /// Primary text — #F8F8F8
    static let spText          = Color(hex: "F8F8F8")

    /// Muted text & icons — #979797
    static let spMuted         = Color(hex: "979797")

    /// Brand accent — #4B58F1 (matches AccentColor asset)
    static let spAccent        = Color(hex: "4B58F1")

    // MARK: Semantic aliases
    /// Divider / hairline — panel-elevated at low opacity
    static let spDivider       = Color(hex: "262626")

    /// Hover state tint — white at very low opacity over any surface
    static var spHover: Color  { Color.white.opacity(0.06) }

    /// Pressed / active state tint
    static var spPressed: Color { Color.white.opacity(0.10) }

    /// Drop-target highlight — green tint
    static var spDropTarget: Color { Color.green.opacity(0.12) }
}

// MARK: - NSColor bridge (for AppKit surfaces)
extension NSColor {
    /// Background colour suitable for NSWindow / NSView backgrounds.
    static let spBackground = NSColor(Color.spBackground)
    static let spPanel      = NSColor(Color.spPanel)
}
