import SwiftUI

/// The popover view shown when clicking the menu bar icon
struct MenuBarPopoverView: View {
    
    @ObservedObject var snippetRepository: SnippetRepository
    let onSnippetSelected: (Snippet) -> Void
    
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            snippetList
            Divider()
            footer
        }
        .frame(width: 320, height: 400)
    }
    
    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "keyboard")
                    .font(.title2)
                Text("Sidepiece")
                    .font(.headline)
                Spacer()
                if let profile = snippetRepository.activeProfile {
                    Text(profile.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            TextField("Search snippets...", text: $searchText)
                .textFieldStyle(.roundedBorder)
        }
        .padding()
    }
    
    private var snippetList: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(filteredBindings) { binding in
                    SnippetRow(binding: binding) {
                        onSnippetSelected(binding.snippet)
                    }
                }
                
                if filteredBindings.isEmpty {
                    emptyState
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    private var filteredBindings: [KeyBinding] {
        let bindings = snippetRepository.activeBindings.filter(\.isEnabled)
        
        guard !searchText.isEmpty else { return bindings }
        
        let query = searchText.lowercased()
        return bindings.filter {
            $0.snippet.title.lowercased().contains(query) ||
            $0.snippet.content.lowercased().contains(query)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("No snippets configured")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Open Preferences to add snippets")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var footer: some View {
        HStack {
            Button(action: openPreferences) {
                Label("Preferences", systemImage: "gear")
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
    
    private func openPreferences() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func quitApp() {
        NSApp.terminate(nil)
    }
}

struct SnippetRow: View {
    let binding: KeyBinding
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(binding.key.symbol)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.accentColor)
                    .cornerRadius(6)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(binding.snippet.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(binding.snippet.preview)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
