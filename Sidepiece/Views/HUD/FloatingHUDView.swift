import SwiftUI

struct FloatingHUDView: View {
    @ObservedObject var hudManager: HUDManager = .shared

    private var isIdle: Bool { hudManager.folderPath.isEmpty && hudManager.feedbackMessage == nil }

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            if hudManager.isPeaking {
                peakView.transition(.move(edge: .bottom).combined(with: .opacity))
            }
            pill
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(12)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isIdle || hudManager.isPeaking)
    }

    // MARK: - Pill

    private var pill: some View {
        pillContent
            .padding(.horizontal, isIdle && !hudManager.isPeaking ? 6 : 10)
            .padding(.vertical, 6)
            .background(Color.spPanel.clipShape(Capsule()))
            .overlay(Capsule().stroke(Color.spMuted.opacity(0.15), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
            .contentShape(Capsule())
            .onTapGesture {
                hudManager.isPeaking ? hudManager.dismissPeak() : SidepieceEngine.shared.peakSnippets(toggle: false)
            }
    }

    @ViewBuilder private var pillContent: some View {
        if isIdle && !hudManager.isPeaking {
            Circle().fill(Color.spMuted.opacity(0.9)).frame(width: 4, height: 4)
        } else if !hudManager.isPeaking {
            HStack(spacing: 4) {
                // Breadcrumb trail in the pill — each ancestor is a back button
                if !hudManager.folderPath.isEmpty {
                    PillBreadcrumb(path: hudManager.folderPath)
                }
                if let msg = hudManager.feedbackMessage, let icon = hudManager.feedbackIcon {
                    Label(msg, systemImage: icon)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.green)
                }
            }
        }
    }

    // MARK: - Peak panel

    private var peakView: some View {
        VStack(alignment: .leading, spacing: 0) {
            progressBar.padding(.bottom, 10)

            // Clickable breadcrumb trail
            PeakBreadcrumb(path: hudManager.folderPath)
                .padding(.bottom, hudManager.folderPath.isEmpty ? 0 : 8)

            // 3-column grid in numpad order: 7 8 9 / 4 5 6 / 1 2 3 / 0
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: 3), spacing: 4) {
                ForEach(hudManager.peakingAssignments, id: \.key) { item in
                    PeakItemButton(keySymbol: item.key, label: item.label) {
                        SidepieceEngine.shared.trigger(item.numpadKey)
                    }
                }
            }
        }
        .padding(8)
        .frame(width: 260)
        .background(Color.spPanel.clipShape(RoundedRectangle(cornerRadius: 10)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.spMuted.opacity(0.12), lineWidth: 0.5))
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2).fill(Color.spPanelElevated).frame(height: 3)
                RoundedRectangle(cornerRadius: 2)
                    .fill(peakBarColor)
                    .frame(width: geo.size.width * hudManager.peakProgress, height: 3)
                    .animation(.linear(duration: 1 / 60), value: hudManager.peakProgress)
            }
        }
        .frame(height: 3)
        .overlay(alignment: .trailing) {
            if hudManager.isPeakPaused {
                HStack(spacing: 4) {
                    Text("TAP TO RESUME")
                        .font(.system(size: 6, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.spText.opacity(0.8))
                        .padding(.horizontal, 4).padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 3).fill(Color.spBackground.opacity(0.9)))
                    Image(systemName: "pause.fill")
                        .font(.system(size: 6, weight: .bold))
                        .foregroundColor(Color.spMuted)
                }
            }
        }
        .contentShape(Rectangle().inset(by: -8))
        .onTapGesture { hudManager.togglePeakPause() }
    }

    private var peakBarColor: Color {
        switch hudManager.peakProgress {
        case 0.5...: Color.spAccent
        case 0.2...: .orange
        default:     .red
        }
    }
}

// MARK: - Peak breadcrumb (full-width, in the peak panel)

struct PeakBreadcrumb: View {
    let path: [(id: UUID, name: String)]

    var body: some View {
        if !path.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 3) {
                    BreadcrumbCrumb(label: "ROOT", isLast: false) {
                        SidepieceEngine.shared.navigateFolderToDepth(-1)
                    }
                    ForEach(path.indices, id: \.self) { index in
                        Image(systemName: "chevron.right")
                            .font(.system(size: 5, weight: .bold))
                            .foregroundColor(Color.spMuted.opacity(0.5))
                        BreadcrumbCrumb(
                            label: path[index].name.uppercased(),
                            isLast: index == path.count - 1
                        ) {
                            SidepieceEngine.shared.navigateFolderToDepth(index)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Pill breadcrumb (compact, inside the status pill)

struct PillBreadcrumb: View {
    let path: [(id: UUID, name: String)]

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "house.fill")
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(path.count > 1 ? Color.spAccent.opacity(0.8) : Color.spMuted)
                .onTapGesture { SidepieceEngine.shared.navigateFolderToDepth(-1) }

            ForEach(path.indices, id: \.self) { index in
                Text("›")
                    .font(.system(size: 9, weight: .light, design: .rounded))
                    .foregroundColor(Color.spMuted.opacity(0.5))
                Text(path[index].name.uppercased())
                    .font(.system(size: 9, weight: index == path.count - 1 ? .bold : .medium, design: .rounded))
                    .foregroundColor(index == path.count - 1 ? Color.spText : Color.spMuted)
                    .onTapGesture {
                        if index < path.count - 1 {
                            SidepieceEngine.shared.navigateFolderToDepth(index)
                        }
                    }
            }
        }
    }
}

// MARK: - Single breadcrumb crumb

private struct BreadcrumbCrumb: View {
    let label: String
    let isLast: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Text(label)
            .font(.system(size: 7, weight: isLast ? .heavy : .bold, design: .monospaced))
            .foregroundColor(isLast ? Color.spText : Color.spAccent.opacity(0.85))
            .padding(.horizontal, 4).padding(.vertical, 2)
            .background(isHovered && !isLast ? Color.spPanelElevated : Color.clear)
            .cornerRadius(3)
            .contentShape(Rectangle())
            .onHover { hovered in
                isHovered = hovered
                hovered ? NSCursor.pointingHand.push() : NSCursor.pop()
            }
            .onTapGesture { if !isLast { action() } }
            .animation(.easeOut(duration: 0.1), value: isHovered)
    }
}

// MARK: - Peak item button

struct PeakItemButton: View {
    let keySymbol: String
    let label: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 4) {
            Text(keySymbol)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(isHovered ? .white : Color.spText)
                .frame(width: 14, height: 14)
                .background(isHovered ? Color.spAccent.opacity(0.6) : Color.spAccent.opacity(0.22))
                .cornerRadius(2)
            Text(label.uppercased())
                .font(.system(size: 7, weight: isHovered ? .heavy : .bold, design: .monospaced))
                .foregroundColor(isHovered ? Color.spText : Color.spMuted)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(3)
        .background(isHovered ? Color.spPanelElevated : Color.spPanelElevated.opacity(0.4))
        .cornerRadius(4)
        .contentShape(Rectangle())
        .onHover { hovered in
            isHovered = hovered
            hovered ? NSCursor.pointingHand.push() : NSCursor.pop()
        }
        .onTapGesture { action() }
        .animation(.easeOut(duration: 0.1), value: isHovered)
    }
}

// MARK: - Pointing-hand cursor helper

extension View {
    @ViewBuilder func cursor(_ cursor: NSCursor) -> some View {
        self.overlay(CursorView(cursor: cursor))
    }
}

private struct CursorView: NSViewRepresentable {
    let cursor: NSCursor
    func makeNSView(context: Context) -> NSView { TrackingView(cursor: cursor) }
    func updateNSView(_ nsView: NSView, context: Context) {}

    private class TrackingView: NSView {
        let cursor: NSCursor
        private var area: NSTrackingArea?

        init(cursor: NSCursor) { self.cursor = cursor; super.init(frame: .zero) }
        required init?(coder: NSCoder) { fatalError() }

        override func hitTest(_ point: NSPoint) -> NSView? { nil }

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            area.map { removeTrackingArea($0) }
            area = NSTrackingArea(
                rect: bounds,
                options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                owner: self,
                userInfo: nil
            )
            addTrackingArea(area!)
        }

        override func mouseEntered(with event: NSEvent) { cursor.push() }
        override func mouseExited(with event: NSEvent)  { NSCursor.pop() }
    }
}

// MARK: - Vibrancy

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

#Preview {
    FloatingHUDView(hudManager: {
        let vm = HUDManager.shared
        vm.folderPath = [
            (id: UUID(), name: "Projects"),
            (id: UUID(), name: "Work")
        ]
        vm.isVisible = true
        return vm
    }())
    .padding()
}
