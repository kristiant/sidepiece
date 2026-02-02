import SwiftUI
import UniformTypeIdentifiers


struct CategoryTab: View {
    let category: NumpadKey.Category
    let isSelected: Bool
    let bindingCount: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: categoryIcon)
                    .font(.caption)
                Text(category.rawValue)
                    .font(.caption)
                if bindingCount > 0 {
                    Text("\(bindingCount)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : Color.accentColor.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color.clear)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    private var categoryIcon: String {
        switch category {
        case .numbers: return "number"
        case .operators: return "plus.forwardslash.minus"
        case .functionKeys: return "function"
        }
    }
}


struct KeyCell: View {
    let key: NumpadKey
    let binding: KeyBinding?
    let isSelected: Bool
    @ObservedObject var configurationManager: ConfigurationManager
    @ObservedObject var snippetRepository: SnippetRepository
    let onTap: () -> Void
    
    @State private var isHovered = false
    @State private var isTargeted = false
    
    var body: some View {
        VStack(spacing: 8) {
            keyBadge
            actionLabel
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(cellBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(borderColor, lineWidth: (isSelected || isTargeted) ? 2 : 1)
        )
        .scaleEffect(isTargeted ? 1.05 : (isHovered ? 1.02 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isTargeted || isHovered)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onHover { isHovered = $0 }
        .onDrop(of: [.plainText, .text], isTargeted: $isTargeted) { providers in
            onDrop(providers)
        }
        .contextMenu {
            if hasBinding {
                Button(role: .destructive) {
                    withAnimation {
                        snippetRepository.removeBinding(for: key)
                    }
                } label: {
                    Label("Clear Key", systemImage: "trash")
                }
            }
        }
    }
    
    private var keyBadge: some View {
        Text(key.symbol)
            .font(.system(.body, design: .rounded, weight: .bold))
            .foregroundColor(hasBinding ? .white : .primary)
            .frame(width: 36, height: 32)
            .background(hasBinding ? (isTargeted ? Color.green : Color.accentColor) : Color.secondary.opacity(0.15))
            .cornerRadius(8)
            .shadow(color: hasBinding ? Color.accentColor.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
    }
    
    private var actionLabel: some View {
        Group {
            if isTargeted {
                Image(systemName: "square.and.arrow.down.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.green)
                    .transition(.scale.combined(with: .opacity))
            } else if let binding = binding {
                VStack(spacing: 1) {
                    Text(actionName(for: binding.action))
                        .font(.system(size: 10, weight: .semibold))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    Text(binding.action.displayName)
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            } else {
                Text("—")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 6)
    }
    
    private func onDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadObject(ofClass: NSString.self) { str, _ in
                guard let droppedStr = str as? String else { return }
                
                DispatchQueue.main.async {
                    if droppedStr.hasPrefix("fnc:"),
                       let fncType = KeyBinding.AppFunction(rawValue: String(droppedStr.dropFirst(4))) {
                        snippetRepository.updateBinding(KeyBinding(key: key, action: .appFunction(fncType)))
                    } else if let id = UUID(uuidString: droppedStr) {
                        if let snippet = snippetRepository.getSnippet(id: id) {
                            snippetRepository.updateBinding(KeyBinding(key: key, action: .snippet(snippet)))
                        } else if let cat = snippetRepository.getCategory(id: id) {
                            snippetRepository.updateBinding(KeyBinding(key: key, action: .folder(cat.id)))
                        }
                    }
                }
            }
        }
        return true
    }
    
    
    private func actionName(for action: KeyBinding.Action) -> String {
        switch action {
        case .snippet(let snippet):
            return snippet.title.isEmpty ? "Untitled" : snippet.title
        case .folder(let id):
            return snippetRepository.categories.first(where: { $0.id == id })?.name ?? "Unknown Folder"
        case .switchProfile(let id):
            return configurationManager.profiles.first(where: { $0.id == id })?.name ?? "Unknown Profile"
        case .cycleProfile(let direction):
            return "Cycle \(direction.rawValue.capitalized)"
        case .appFunction(let function):
            return function.displayName
        }
    }
    
    private var hasBinding: Bool {
        binding != nil
    }
    
    private var cellBackground: Color {
        if isTargeted {
            return Color.green.opacity(0.1)
        }
        if isHovered {
            return Color.accentColor.opacity(0.1)
        }
        return hasBinding ? Color.accentColor.opacity(0.05) : Color.secondary.opacity(0.05)
    }
    
    private var borderColor: Color {
        if isTargeted {
            return Color.green
        }
        if isSelected {
            return Color.accentColor
        }
        return hasBinding ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.2)
    }
}
