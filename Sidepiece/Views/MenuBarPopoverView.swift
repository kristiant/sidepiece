import SwiftUI

struct MenuBarPopoverView: View {
    
    @ObservedObject var snippetRepository: SnippetRepository
    @ObservedObject var configurationManager: ConfigurationManager
    let onSnippetSelected: (Snippet) -> Void
    let onAppFunctionSelected: (KeyBinding.AppFunction) -> Void
    
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    keysHeader
                    Divider()
                    allKeysGrid
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
        .background(Color.spBackground)
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                configurationManager: configurationManager,
                snippetRepository: snippetRepository
            )
            .background(Color.spBackground)
        }
    }
    
    private var keysHeader: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "keyboard")
                Text("Hot Keys")
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(Color.spText)
            
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
            .foregroundColor(.red.opacity(0.85))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.red.opacity(0.12))
            .cornerRadius(4)
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
        .background(Color.spBackground)
    }
    
    private var allKeysGrid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(NumpadKey.Category.allCases, id: \.self) { category in
                    categorySection(category)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }

    private func categorySection(_ category: NumpadKey.Category) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader(category.rawValue.uppercased())
                .padding(.top, 28)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(NumpadKey.keys(in: category)) { key in
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
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundColor(Color.spMuted.opacity(0.5))
            .padding(.horizontal, 2)
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
            .foregroundColor(Color.spMuted)
            
            Spacer()
            
            Button(action: quitApp) {
                Label("Quit", systemImage: "power")
            }
            .buttonStyle(.plain)
            .foregroundColor(Color.spMuted)
        }
        .font(.caption)
        .padding()
    }
    
    private func quitApp() {
        NSApp.terminate(nil)
    }
}


