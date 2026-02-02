import SwiftUI

struct HotkeyPickerSheet: View {
    let snippet: Snippet
    @ObservedObject var snippetRepository: SnippetRepository
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedCategory: NumpadKey.Category = .numbers
    
    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            categoryPicker
            Divider()
            keyGrid
            Divider()
            footer
        }
        .frame(width: 380, height: 480)
    }
    
    private var header: some View {
        VStack(spacing: 4) {
            Text("Assign to Hotkey")
                .font(.headline)
            Text(snippet.title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var categoryPicker: some View {
        HStack(spacing: 8) {
            ForEach(NumpadKey.Category.allCases, id: \.self) { category in
                Button(action: { selectedCategory = category }) {
                    Text(category.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedCategory == category ? Color.accentColor : Color.secondary.opacity(0.1))
                        .foregroundColor(selectedCategory == category ? .white : .primary)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }
    
    private var keyGrid: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(NumpadKey.keys(in: selectedCategory)) { key in
                    KeyShortcutCell(
                        key: key,
                        existingBinding: snippetRepository.getBinding(for: key)
                    ) {
                        assign(to: key)
                    }
                }
            }
            .padding()
        }
    }
    
    private var footer: some View {
        HStack {
            Button("Cancel") { dismiss() }
            Spacer()
        }
        .padding()
    }
    
    private func assign(to key: NumpadKey) {
        let binding = KeyBinding(key: key, action: .snippet(snippet))
        snippetRepository.updateBinding(binding)
        dismiss()
    }
}

struct KeyShortcutCell: View {
    let key: NumpadKey
    let existingBinding: KeyBinding?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(key.symbol)
                    .font(.headline)
                if let binding = existingBinding {
                    Text(bindingTitle(binding))
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Available")
                        .font(.system(size: 8))
                        .foregroundColor(.green.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(existingBinding != nil ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func bindingTitle(_ binding: KeyBinding) -> String {
        switch binding.action {
        case .snippet(let s): return s.title
        case .folder(let id): return "Folder"
        default: return "Reserved"
        }
    }
}
