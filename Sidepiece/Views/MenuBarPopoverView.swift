import SwiftUI

struct MenuBarPopoverView: View {
    
    @ObservedObject var snippetRepository: SnippetRepository
    @ObservedObject var configurationManager: ConfigurationManager
    let onSnippetSelected: (Snippet) -> Void
    let onAppFunctionSelected: (KeyBinding.AppFunction) -> Void
    
    @State private var selectedCategory: NumpadKey.Category = .numbers
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    tabs
                    Divider()
                    grid
                }
                .frame(width: 350)
                
                Divider()
                
                LibraryView(
                    snippetRepository: snippetRepository,
                    configurationManager: configurationManager
                )
                .frame(maxWidth: .infinity)
            }
            
            Divider()
            footer
        }
        .frame(width: 950, height: 650)
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                configurationManager: configurationManager,
                snippetRepository: snippetRepository
            )
        }
    }
    
    private var header: some View {
        HStack(spacing: 0) {
            // Hotkeys Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "keyboard")
                    Text("Hot Keys")
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.accentColor)
                
                Spacer()
                
                Button("Clear All") {
                    let alert = NSAlert()
                    alert.messageText = "Clear all hotkeys?"
                    alert.informativeText = "Reset all assignments for the current profile."
                    alert.addButton(withTitle: "Clear")
                    alert.addButton(withTitle: "Cancel")
                    alert.alertStyle = .warning
                    if alert.runModal() == .alertFirstButtonReturn {
                        configurationManager.clearAllBindings()
                    }
                }
                .font(.system(size: 10, weight: .bold))
                .buttonStyle(.plain)
                .foregroundColor(.red.opacity(0.8))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.red.opacity(0.1))
                .cornerRadius(4)
            }
            .frame(width: 350)
            .padding(.horizontal, 16)
            
            Divider()
            
            // Library Header
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "folder.fill")
                    Text("Library")
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.accentColor)
                
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 50)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private var tabs: some View {
        HStack(spacing: 4) {
            ForEach(NumpadKey.Category.allCases, id: \.self) { category in
                CategoryTab(
                    category: category,
                    isSelected: selectedCategory == category,
                    bindingCount: count(for: category)
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
    
    private func count(for category: NumpadKey.Category) -> Int {
        NumpadKey.keys(in: category).filter { key in
            snippetRepository.getBinding(for: key) != nil
        }.count
    }
    
    private var grid: some View {
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
                        if let binding = snippetRepository.getBinding(for: key) {
                            onSelect(binding)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private func onSelect(_ binding: KeyBinding) {
        switch binding.action {
        case .snippet(let id):
            if let snippet = snippetRepository.getSnippet(id: id) {
                onSnippetSelected(snippet)
            }
        case .folder:
            break
        case .switchProfile(let id):
            if let profile = configurationManager.profiles.first(where: { $0.id == id }) {
                configurationManager.setActiveProfile(profile)
            }
        case .cycleProfile(let direction):
            configurationManager.cycleProfiles(direction: direction)
        case .appFunction(let function):
            onAppFunctionSelected(function)
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


