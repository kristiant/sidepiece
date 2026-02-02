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
        NavigationStack {
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
            .navigationDestination(for: String.self) { destination in
                if destination == "settings" {
                    SettingsView(
                        configurationManager: configurationManager,
                        snippetRepository: snippetRepository
                    )
                }
            }
        }
        .sheet(isPresented: $isEditingSnippet) {
            KeyBindingEditorSheet(
                binding: $editingBinding,
                snippetRepository: snippetRepository,
                configurationManager: configurationManager,
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
            NavigationLink("Manage Profiles...", value: "settings")
                .buttonStyle(.plain)
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
                        isSelected: selectedKey == key,
                        configurationManager: configurationManager,
                        snippetRepository: snippetRepository
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
        HStack(spacing: 16) {
            accessibilityButton
            
            Spacer()
            
            NavigationLink(value: "settings") {
                HStack(spacing: 4) {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            
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
                Text(hasAccessibility ? "Enabled" : "Pending Access")
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
    
    
    // MARK: - Actions
    
    private func editBinding(for key: NumpadKey) {
        if let existing = snippetRepository.getBinding(for: key) {
            editingBinding = existing
        } else {
            // Create a new binding with an empty snippet as default
            editingBinding = KeyBinding(key: key, action: .snippet(Snippet(title: "", content: "")))
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
    @ObservedObject var configurationManager: ConfigurationManager
    @ObservedObject var snippetRepository: SnippetRepository
    let onTap: () -> Void
    
    @State private var isHovered = false
    
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
    
    private var actionLabel: some View {
        Group {
            if let binding = binding {
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

// Obsolete SnippetEditorSheet removed - now using KeyBindingEditorSheet.swift

// MARK: - Snippet Editor Sheet Styles and Constants

#Preview {
    KeyBindingConfigView(
        snippetRepository: SnippetRepository(configurationManager: ConfigurationManager()),
        configurationManager: ConfigurationManager()
    )
}
