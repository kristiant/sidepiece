import SwiftUI

struct FloatingHUDView: View {
    @ObservedObject var viewModel: HUDViewModel
    
    private var isIdle: Bool {
        viewModel.activeFolderName == nil && viewModel.feedbackMessage == nil
    }
    
    var body: some View {
        ZStack {
            ZStack {
                if isIdle {
                    Circle()
                        .fill(Color.primary.opacity(0.8))
                        .frame(width: 6, height: 6)
                } else {
                    HStack(spacing: 8) {
                        if let folder = viewModel.activeFolderName {
                            HStack(spacing: 4) {
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.accentColor)
                                Text(folder)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.12))
                            .cornerRadius(6)
                        }
                        
                        if viewModel.activeFolderName != nil && viewModel.feedbackMessage != nil {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(width: 1, height: 14)
                        }
                        
                        if let feedback = viewModel.feedbackMessage, let icon = viewModel.feedbackIcon {
                            HStack(spacing: 6) {
                                Image(systemName: icon)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.green)
                                Text(feedback)
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                            }
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                        }
                    }
                }
            }
            .padding(.horizontal, isIdle ? 8 : 12)
            .padding(.vertical, isIdle ? 8 : 8)
            .background(
                VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                    .clipShape(RoundedRectangle(cornerRadius: isIdle ? 12 : 16, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: isIdle ? 12 : 16, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.2), radius: isIdle ? 4 : 10, x: 0, y: isIdle ? 2 : 5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(10) // Small breather from the actual window edge
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isIdle)
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
