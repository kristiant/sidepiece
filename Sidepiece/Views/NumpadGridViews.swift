import SwiftUI

// MARK: - Category Tab

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

// MARK: - Key Cell

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
        Button(action: onTap) {
            VStack(spacing: 6) {
                keyBadge
                actionLabel
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(cellBackground)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(borderColor, lineWidth: (isSelected || isTargeted) ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .onDrop(of: [.text], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
        }
    }
    
    private var keyBadge: some View {
        Text(key.symbol)
            .font(.system(.body, design: .rounded, weight: .semibold))
            .foregroundColor(hasBinding ? .white : .primary)
            .frame(width: 32, height: 28)
            .background(hasBinding ? (isTargeted ? Color.green : Color.accentColor) : Color.secondary.opacity(0.2))
            .cornerRadius(6)
    }
    
    private var actionLabel: some View {
        Group {
            if isTargeted {
                Text("Drop to Bind")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.green)
            } else if let binding = binding {
                VStack(spacing: 2) {
                    actionIcon(for: binding.action)
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                    
                    Text(actionDisplayName(for: binding.action))
                        .font(.system(size: 9))
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                }
            } else {
                Text("Empty")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
    }
    
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadObject(ofClass: NSString.self) { string, _ in
                guard let idString = string as? String, let id = UUID(uuidString: idString) else { return }
                
                DispatchQueue.main.async {
                    if let snippet = snippetRepository.getSnippet(id: id) {
                        let newBinding = KeyBinding(key: key, action: .snippet(snippet))
                        snippetRepository.updateBinding(newBinding)
                    } else if let category = snippetRepository.getCategory(id: id) {
                        let newBinding = KeyBinding(key: key, action: .folder(category.id))
                        snippetRepository.updateBinding(newBinding)
                    }
                }
            }
        }
        return true
    }
    
    @ViewBuilder
    private func actionIcon(for action: KeyBinding.Action) -> some View {
        switch action {
        case .snippet:
            Image(systemName: "doc.text.fill")
        case .folder:
            Image(systemName: "folder.fill")
        case .switchProfile:
            Image(systemName: "person.fill")
        case .cycleProfile:
            Image(systemName: "person.2.fill")
        }
    }
    
    private func actionDisplayName(for action: KeyBinding.Action) -> String {
        switch action {
        case .snippet(let snippet):
            return snippet.title.isEmpty ? "Untitled" : snippet.title
        case .folder(let id):
            return snippetRepository.categories.first(where: { $0.id == id })?.name ?? "Unknown Folder"
        case .switchProfile(let id):
            return configurationManager.profiles.first(where: { $0.id == id })?.name ?? "Unknown Profile"
        case .cycleProfile(let direction):
            return "Cycle \(direction.rawValue.capitalized)"
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
