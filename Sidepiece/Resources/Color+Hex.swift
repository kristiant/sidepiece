import SwiftUI

extension Color {
    /// Accepts `RRGGBB` with or without a leading `#`.
    init(hex: String) {
        let rgb = UInt32(hex.trimmingPrefix("#"), radix: 16) ?? 0
        self.init(
            .sRGB,
            red: Double(rgb >> 16 & 0xFF) / 255,
            green: Double(rgb >> 8 & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}
