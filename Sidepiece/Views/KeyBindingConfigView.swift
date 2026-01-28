import SwiftUI
import Combine

/// Main view for configuring key-to-snippet bindings
struct KeyBindingConfigView: View {
    
    @ObservedObject var snippetRepository: SnippetRepository
    @ObservedObject var configurationManager: ConfigurationManager
    
    @State private var selectedCategory: NumpadKey.Category = .numbers
    @State private var selectedKey: NumpadKey?
    @State private var isEditingSnippet = false
    @State private var editingBinding: KeyBinding?
    @State private var searchText = ""
    
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
        .frame(width: 380, height: 520)
        .sheet(isPresented: $isEditingSnippet) {
            SnippetEditorSheet(
                binding: $editingBinding,
                snippetRepository: snippetRepository,
                onSave: saveBinding,
                onDelete: deleteBinding
            )
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "keyboard")
                .font(.title2)
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Sidepiece")
                    .font(.headline)
                Text("Configure your shortcuts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            profileBadge
        }
        .padding()
    }
    
    private var profileBadge: some View {
        Menu {
            ForEach(configurationManager.profiles) { profile in
                Button(action: { configurationManager.setActiveProfile(profile) }) {
                    HStack {
                        Text(profile.name)
                        if profile.id == configurationManager.configuration.activeProfileId {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            Divider()
            Button("Manage Profiles...") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
        } label: {
            HStack(spacing: 4) {
                Text(snippetRepository.activeProfile?.name ?? "Default")
                    .font(.caption)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.15))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Category Picker
    
    private var categoryPicker: some View {
        HStack(spacing: 4) {
            ForEach(NumpadKey.Category.allCases, id: \.self) { category in
                CategoryTab(
                    category: category,
                    isSelected: selectedCategory == category,
                    bindingCount: bindingCount(for: category)
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedCategory = category
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private func bindingCount(for category: NumpadKey.Category) -> Int {
        NumpadKey.keys(in: category).filter { key in
            snippetRepository.getBinding(for: key) != nil
        }.count
    }
    
    // MARK: - Key Grid
    
    private var keyGrid: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 8) {
                ForEach(NumpadKey.keys(in: selectedCategory)) { key in
                    KeyCell(
                        key: key,
                        binding: snippetRepository.getBinding(for: key),
                        isSelected: selectedKey == key
                    ) {
                        selectedKey = key
                        editBinding(for: key)
                    }
                }
            }
            .padding()
        }
    }
    
    private var gridColumns: [GridItem] {
        switch selectedCategory {
        case .numbers:
            return Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
        case .operators:
            return Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
        case .functionKeys:
            return Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
        }
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack {
            accessibilityButton
            
            Spacer()
            
            Text("\(totalBindings) bindings configured")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: quitApp) {
                Label("Quit", systemImage: "power")
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .font(.caption)
        .padding()
    }
    
    @State private var hasAccessibility = AXIsProcessTrusted()
    
    // Timer to periodically check accessibility status
    private let accessibilityTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    private var accessibilityButton: some View {
        Button(action: {
            openAccessibilitySettings()
            // Also refresh status when button is clicked
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                hasAccessibility = AXIsProcessTrusted()
            }
        }) {
            HStack(spacing: 4) {
                Circle()
                    .fill(hasAccessibility ? Color.green : Color.orange)
                    .frame(width: 6, height: 6)
                Text(hasAccessibility ? "Enabled" : "Enable Access")
                    .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(hasAccessibility ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .foregroundColor(hasAccessibility ? .green : .orange)
        .onAppear {
            hasAccessibility = AXIsProcessTrusted()
        }
        .onReceive(accessibilityTimer) { _ in
            let newStatus = AXIsProcessTrusted()
            if newStatus != hasAccessibility {
                hasAccessibility = newStatus
            }
        }
    }
    
    private var totalBindings: Int {
        snippetRepository.activeBindings.count
    }
    
    // MARK: - Actions
    
    private func editBinding(for key: NumpadKey) {
        if let existing = snippetRepository.getBinding(for: key) {
            editingBinding = existing
        } else {
            // Create a new binding with an empty snippet
            let newSnippet = Snippet(title: "", content: "")
            editingBinding = KeyBinding(key: key, snippet: newSnippet)
        }
        isEditingSnippet = true
    }
    
    private func saveBinding(_ binding: KeyBinding) {
        snippetRepository.updateBinding(binding)
        isEditingSnippet = false
        editingBinding = nil
    }
    
    private func deleteBinding(_ binding: KeyBinding) {
        snippetRepository.removeBinding(for: binding.key)
        isEditingSnippet = false
        editingBinding = nil
    }
    
    private func openAccessibilitySettings() {
        // Open System Settings directly to Privacy & Security > Accessibility
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    
    private func quitApp() {
        NSApp.terminate(nil)
    }
}

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
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                keyBadge
                snippetLabel
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(cellBackground)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(borderColor, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
    
    private var keyBadge: some View {
        Text(key.symbol)
            .font(.system(.body, design: .rounded, weight: .semibold))
            .foregroundColor(hasBinding ? .white : .primary)
            .frame(width: 32, height: 28)
            .background(hasBinding ? Color.accentColor : Color.secondary.opacity(0.2))
            .cornerRadius(6)
    }
    
    private var snippetLabel: some View {
        Group {
            if let binding = binding {
                Text(binding.snippet.title.isEmpty ? "Untitled" : binding.snippet.title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            } else {
                Text("Empty")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
    }
    
    private var hasBinding: Bool {
        binding != nil
    }
    
    private var cellBackground: Color {
        if isHovered {
            return Color.accentColor.opacity(0.1)
        }
        return hasBinding ? Color.accentColor.opacity(0.05) : Color.secondary.opacity(0.05)
    }
    
    private var borderColor: Color {
        if isSelected {
            return Color.accentColor
        }
        return hasBinding ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.2)
    }
}

// MARK: - Snippet Editor Sheet

struct SnippetEditorSheet: View {
    
    @Binding var binding: KeyBinding?
    @ObservedObject var snippetRepository: SnippetRepository
    
    let onSave: (KeyBinding) -> Void
    let onDelete: (KeyBinding) -> Void
    
    @State private var snippetTitle = ""
    @State private var snippetContent = ""
    @State private var showingExistingSnippets = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            sheetHeader
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    keyInfoSection
                    titleSection
                    contentSection
                    existingSnippetsSection
                }
                .padding()
            }
            
            Divider()
            sheetFooter
        }
        .frame(width: 400, height: 480)
        .onAppear {
            if let binding = binding {
                snippetTitle = binding.snippet.title
                snippetContent = binding.snippet.content
            }
        }
    }
    
    private var sheetHeader: some View {
        HStack {
            Text(isNewBinding ? "Add Binding" : "Edit Binding")
                .font(.headline)
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
    
    private var keyInfoSection: some View {
        HStack(spacing: 12) {
            if let key = binding?.key {
                Text(key.symbol)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 44)
                    .background(Color.accentColor)
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Key: \(key.displayName)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Category: \(key.category.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Title")
                .font(.subheadline)
                .fontWeight(.medium)
            TextField("e.g., Reload Packages", text: $snippetTitle)
                .textFieldStyle(.roundedBorder)
        }
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Content")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(snippetContent.count) characters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            TextEditor(text: $snippetContent)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                )
            
            Text("This text will be copied to your clipboard when you press the key.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var existingSnippetsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { showingExistingSnippets.toggle() }) {
                HStack {
                    Text("Use existing snippet")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: showingExistingSnippets ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            
            if showingExistingSnippets {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(snippetRepository.snippets) { snippet in
                            ExistingSnippetChip(snippet: snippet) {
                                snippetTitle = snippet.title
                                snippetContent = snippet.content
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var sheetFooter: some View {
        HStack {
            if !isNewBinding {
                Button("Remove Binding", role: .destructive) {
                    if let binding = binding {
                        onDelete(binding)
                    }
                }
                .foregroundColor(.red)
            }
            
            Spacer()
            
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.escape)
            
            Button("Save") {
                saveChanges()
            }
            .keyboardShortcut(.return)
            .buttonStyle(.borderedProminent)
            .disabled(snippetTitle.isEmpty || snippetContent.isEmpty)
        }
        .padding()
    }
    
    private var isNewBinding: Bool {
        guard let binding = binding else { return true }
        return snippetRepository.getBinding(for: binding.key) == nil
    }
    
    private func saveChanges() {
        guard var updatedBinding = binding else { return }
        
        var updatedSnippet = updatedBinding.snippet
        updatedSnippet.title = snippetTitle
        updatedSnippet.content = snippetContent
        updatedSnippet.updatedAt = Date()
        
        updatedBinding.snippet = updatedSnippet
        updatedBinding.updatedAt = Date()
        
        onSave(updatedBinding)
    }
}

// MARK: - Existing Snippet Chip

struct ExistingSnippetChip: View {
    let snippet: Snippet
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 2) {
                Text(snippet.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(snippet.preview)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isHovered ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

#Preview {
    KeyBindingConfigView(
        snippetRepository: SnippetRepository(configurationManager: ConfigurationManager()),
        configurationManager: ConfigurationManager()
    )
}
