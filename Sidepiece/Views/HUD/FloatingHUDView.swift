import SwiftUI

struct FloatingHUDView: View {
    @ObservedObject var viewModel: HUDViewModel
    
    private var isIdle: Bool {
        viewModel.activeFolderName == nil && viewModel.feedbackMessage == nil
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            if viewModel.isPeaking {
                peakView.transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            ZStack {
                if isIdle && !viewModel.isPeaking {
                    Circle().fill(Color.primary.opacity(0.8)).frame(width: 4, height: 4)
                } else if !viewModel.isPeaking {
                    statusContent
                }
            }
            .padding(.horizontal, isIdle && !viewModel.isPeaking ? 6 : 10)
            .padding(.vertical, 6)
            .background(VisualEffectView(material: .hudWindow, blendingMode: .withinWindow).clipShape(Capsule()))
            .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(12)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isIdle || viewModel.isPeaking)
    }
    
    private var statusContent: some View {
        HStack(spacing: 6) {
            if let folder = viewModel.activeFolderName {
                Label(folder, systemImage: "folder.fill")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.15))
                    .cornerRadius(4)
            }
            
            if let feedback = viewModel.feedbackMessage, let icon = viewModel.feedbackIcon {
                Label(feedback, systemImage: icon)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.green.opacity(0.9))
            }
        }
    }
    
    private var peakView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 85))], spacing: 4) {
            ForEach(viewModel.peakingAssignments, id: \.key) { item in
                HStack(spacing: 4) {
                    Text(item.key)
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .frame(width: 14, height: 14)
                        .background(Color.accentColor.opacity(0.25))
                        .cornerRadius(2)
                    
                    Text(item.label.uppercased())
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary.opacity(0.8))
                        .lineLimit(1)
                }
                .padding(3)
                .background(Color.white.opacity(0.02))
                .cornerRadius(4)
            }
        }
        .padding(8)
        .frame(width: 260)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .withinWindow).clipShape(RoundedRectangle(cornerRadius: 10)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.05), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
    }
}

// Helper for blur effect
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
    let vm = HUDViewModel()
    vm.activeFolderName = "Projects"
    vm.feedbackMessage = "Copied: Email Signature"
    vm.feedbackIcon = "doc.on.doc.fill"
    vm.isVisible = true
    return FloatingHUDView(viewModel: vm)
        .padding()
}
