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
        .background(Color.spBackground)
    }
    
    private var header: some View {
        VStack(spacing: 4) {
            Text("Assign to Hotkey")
                .font(.headline)
            Text(snippet.title)
                .font(.caption)
                .foregroundColor(Color.spMuted)
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
                        .background(selectedCategory == category ? Color.spAccent : Color.spPanelElevated)
                        .foregroundColor(selectedCategory == category ? .white : Color.spText)
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
                    KeyShortcutCell(key: key, label: snippetRepository.getBinding(for: key).map { snippetRepository.label(for: $0.action) }) {
                        snippetRepository.updateBinding(KeyBinding(key: key, action: .snippet(id: snippet.id)))
                        dismiss()
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
}

struct KeyShortcutCell: View {
    let key: NumpadKey
    let label: String?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(key.symbol)
                    .font(.headline)
                if let label {
                    Text(label)
                        .font(.system(size: 8))
                        .foregroundColor(Color.spMuted)
                        .lineLimit(1)
                } else {
                    Text("Available")
                        .font(.system(size: 8))
                        .foregroundColor(.green.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.spPanel)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(label != nil ? Color.spAccent.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
