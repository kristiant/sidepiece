import SwiftUI

/// The popover view shown when clicking the menu bar icon
struct MenuBarPopoverView: View {
    
    @ObservedObject var snippetRepository: SnippetRepository
    @ObservedObject var configurationManager: ConfigurationManager
    let onSnippetSelected: (Snippet) -> Void
    
    @State private var selectedCategory: NumpadKey.Category = .numbers
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            
            HStack(spacing: 0) {
                // Left: Hotkeys
                VStack(spacing: 0) {
                    categoryPicker
                    Divider()
                    keyGrid
                }
                .frame(width: 350)
                
                Divider()
                
                // Folders & Snippets (LibraryView now handles both horizontally)
                LibraryView(
                    snippetRepository: snippetRepository,
                    configurationManager: configurationManager
                )
                .frame(maxWidth: .infinity)
            }
            
            Divider()
            footer
        }
        .frame(width: 1000, height: 600)
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                configurationManager: configurationManager,
                snippetRepository: snippetRepository
            )
        }
    }
    
    private var header: some View {
        HStack {
            HStack {
                HStack {
                    Image(systemName: "keyboard")
                        .foregroundColor(.accentColor)
                    Text("Hot Keys")
                        .font(.headline)
                }
                
                Spacer()
                
                Button(action: {
                    let alert = NSAlert()
                    alert.messageText = "Clear all hotkeys?"
                    alert.informativeText = "This will remove all snippet assignments from the current profile. This cannot be undone."
                    alert.addButton(withTitle: "Clear All")
                    alert.addButton(withTitle: "Cancel")
                    alert.alertStyle = .warning
                    
                    if alert.runModal() == .alertFirstButtonReturn {
                        configurationManager.clearAllBindings()
                    }
                }) {
                    Text("Clear All")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.red.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }
            .frame(width: 330, alignment: .leading)
            .padding(.trailing, 20)
            
            Spacer()
            
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundColor(.accentColor)
                Text("Folders")
                    .font(.headline)
            }
            .frame(width: 250, alignment: .leading)
            
            Spacer()
            
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.accentColor)
                Text("Snippets")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
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
    
    private var keyGrid: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(NumpadKey.keys(in: selectedCategory)) { key in
                    KeyCell(
                        key: key,
                        binding: snippetRepository.getBinding(for: key),
                        isSelected: false,
                        configurationManager: configurationManager,
                        snippetRepository: snippetRepository
                    ) {
                        // In the popover, clicking a key triggers it
                        if let binding = snippetRepository.getBinding(for: key) {
                            handleBindingSelected(binding)
                        } else {
                            // If empty, maybe open editor?
                            // For now just show help
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private func handleBindingSelected(_ binding: KeyBinding) {
        switch binding.action {
        case .snippet(let snippet):
            onSnippetSelected(snippet)
        case .folder(let id):
            // Folders could navigate the library? 
            // For now just logs
            print("Folder selected: \(id)")
        case .switchProfile(let id):
            if let profile = configurationManager.profiles.first(where: { $0.id == id }) {
                configurationManager.setActiveProfile(profile)
            }
        case .cycleProfile(let direction):
            configurationManager.cycleProfiles(direction: direction)
        }
    }
    
    private var footer: some View {
        HStack {
            Button(action: { showingSettings = true }) {
                Label("Settings", systemImage: "gear")
            }
            .buttonStyle(.plain)
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
    
    private func quitApp() {
        NSApp.terminate(nil)
    }
}


