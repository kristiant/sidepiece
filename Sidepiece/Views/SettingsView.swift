import SwiftUI

struct SettingsView: View {
    private enum Tab: String, CaseIterable {
        case profiles = "Profiles"
        case general = "General"
        case snippets = "Snippets"
    }
    
    @ObservedObject var configurationManager: ConfigurationManager
    @ObservedObject var snippetRepository: SnippetRepository
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: Tab = .general
    
    var body: some View {
        VStack(spacing: 0) {
            settingsHeader
            Divider()
            
            content
                .frame(maxHeight: .infinity)
        }
        .frame(width: 400, height: 500)
        .background(Color.spBackground)
    }
    
    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .general:
            GeneralSettingsView(
                configurationManager: configurationManager,
                snippetRepository: snippetRepository
            )
        case .profiles:
            ProfilesSettingsView(configurationManager: configurationManager)
        case .snippets:
            SnippetsSettingsView(snippetRepository: snippetRepository)
        }
    }
    
    private var settingsHeader: some View {
        VStack(spacing: 12) {
            Text("Settings")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    Button { dismiss() } label: {
                        Label("Back", systemImage: "chevron.left").foregroundColor(Color.spAccent)
                    }
                    .buttonStyle(.plain)
                }

            Picker("", selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .padding()
    }
}

struct SnippetsSettingsView: View {
    @ObservedObject var snippetRepository: SnippetRepository
    @State private var newCategoryName = ""
    @State private var selectedParentId: UUID?
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                Section(header: Text("Folders / Categories")) {
                    ForEach(rootCategories) { category in
                        CategoryRow(category: category, level: 0, snippetRepository: snippetRepository)
                    }
                }
                
                Section(header: Text("Add New Folder")) {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Folder Name", text: $newCategoryName)
                            .textFieldStyle(.roundedBorder)
                        
                        Picker("Parent Folder", selection: $selectedParentId) {
                            Text("None (Root)").tag(nil as UUID?)
                            ForEach(snippetRepository.categories) { category in
                                Text(category.name).tag(category.id as UUID?)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Button(action: addCategory) {
                            Label("Add Folder", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    private var rootCategories: [SnippetCategory] {
        snippetRepository.categories.filter { $0.parentId == nil }
    }
    
    private func addCategory() {
        let name = newCategoryName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        
        snippetRepository.addCategory(SnippetCategory(name: name, parentId: selectedParentId))
        newCategoryName = ""
        selectedParentId = nil
    }
}

struct CategoryRow: View {
    let category: SnippetCategory
    let level: Int
    @ObservedObject var snippetRepository: SnippetRepository
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(Color(hex: category.color))
                    .padding(.leading, CGFloat(level * 20))
                
                Text(category.name)
                
                Spacer()
                
                Button(action: { snippetRepository.deleteCategory(category.id) }) {
                    Image(systemName: "trash")
                        .foregroundColor(Color.spMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
            
            ForEach(snippetRepository.getSubCategories(parentId: category.id)) { sub in
                CategoryRow(category: sub, level: level + 1, snippetRepository: snippetRepository)
            }
        }
    }
}

struct ProfilesSettingsView: View {
    @ObservedObject var configurationManager: ConfigurationManager
    
    @State private var newProfileName = ""
    @State private var editingProfile: Profile?
    @State private var editingName = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsPanel("Your Profiles") {
                    VStack(spacing: 1) {
                        ForEach(configurationManager.profiles) { profile in
                            profileRow(for: profile)
                            
                            if profile.id != configurationManager.profiles.last?.id {
                                Divider()
                                    .padding(.leading, 8)
                            }
                        }
                    }
                    .background(Color.spPanelElevated)
                    .cornerRadius(8)
                }

                SettingsPanel("Create New Profile") {
                    HStack {
                        TextField("Profile Name", text: $newProfileName)
                            .textFieldStyle(.roundedBorder)
                        
                        Button(action: addProfile) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(Color.spAccent)
                        .disabled(newProfileName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func profileRow(for profile: Profile) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                if editingProfile?.id == profile.id {
                    TextField("Name", text: $editingName)
                        .onSubmit(saveProfileName)
                        .textFieldStyle(.roundedBorder)
                } else {
                    Text(profile.name)
                        .fontWeight(profile.isActive ? .bold : .regular)
                        .foregroundColor(Color.spText)
                    Text("\(profile.bindings.count) keys bound")
                        .font(.caption2)
                        .foregroundColor(Color.spMuted)
                }
            }
            
            Spacer()
            
            if editingProfile?.id == profile.id {
                Button("Save") { saveProfileName() }
                    .buttonStyle(.plain)
                    .foregroundColor(Color.spAccent)
            } else {
                if !profile.isActive {
                    Button("Activate") {
                        configurationManager.setActiveProfile(profile)
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundColor(Color.spAccent.opacity(0.9))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.spAccent.opacity(0.12))
                    .cornerRadius(4)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                
                Menu {
                    Button("Rename") {
                        editingProfile = profile
                        editingName = profile.name
                    }
                    Button("Delete", role: .destructive) {
                        configurationManager.deleteProfile(profile)
                    }
                    .disabled(configurationManager.profiles.count <= 1)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(Color.spMuted)
                        .padding(4)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
    
    private func addProfile() {
        let name = newProfileName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        configurationManager.addProfile(Profile(name: name))
        newProfileName = ""
    }
    
    private func saveProfileName() {
        guard var profile = editingProfile else { return }
        let name = editingName.trimmingCharacters(in: .whitespaces)
        if !name.isEmpty {
            profile.name = name
            configurationManager.updateProfile(profile)
        }
        editingProfile = nil
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var configurationManager: ConfigurationManager
    @ObservedObject var snippetRepository: SnippetRepository
    @State private var showingClearAlert = false

    var body: some View {
        let cfg = configurationManager
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsPanel("Appearance & Sound") {
                    Toggle("Launch at login", isOn: cfg.binding(\.launchAtLogin))
                    Toggle("Play sound on copy", isOn: cfg.binding(\.playSoundOnCopy))
                    Toggle("Show notification on copy", isOn: cfg.binding(\.showNotificationOnCopy))
                }

                SettingsPanel("Interaction") {
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Show HUD overlay", isOn: cfg.binding(\.showHUD))
                        Caption("Uncheck to run in stealth mode - no visual indicator on screen.")
                    }
                    Divider()
                    Toggle("Auto-paste after trigger", isOn: cfg.binding(\.autoPaste))
                    if cfg.configuration.autoPaste {
                        Toggle("Press Enter after paste", isOn: cfg.binding(\.autoEnterAfterPaste))
                    }
                    Toggle("Auto-exit folder mode (5s)", isOn: cfg.binding(\.autoExitFolderMode))
                    Toggle("Auto-exit folder after selection", isOn: cfg.binding(\.autoExitFolderAfterSelection))
                    Toggle("Auto-peek folder contents", isOn: cfg.binding(\.autoPeakFolderContents))
                    Caption("Automatically return to root after 5s of inactivity, or peek contents when entering.")
                }

                SettingsPanel("Keyboard Mode") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Peak trigger key").font(.subheadline)
                        Picker("", selection: cfg.binding(\.peakHotkey)) {
                            Text("None (numpad only)").tag(nil as NumpadKey?)
                            ForEach(NumpadKey.keys(in: .functionKeys)) { key in
                                Text(key.displayName).tag(key as NumpadKey?)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        Caption("While the peak panel is open, press 1–9 or 0 on the number row to trigger items. Press Esc to dismiss.")
                    }
                }

                SettingsPanel("Permissions") {
                    HStack {
                        Text("Accessibility")
                        Spacer()
                        AccessibilityStatusView()
                    }
                }

                SettingsPanel("Data Management") {
                    HStack(spacing: 12) {
                        Button(action: exportAllData) {
                            Label("Export All...", systemImage: "square.and.arrow.up")
                        }
                        Button(action: importAllData) {
                            Label("Import All...", systemImage: "square.and.arrow.down")
                        }
                    }
                    .buttonStyle(.bordered)
                    .padding(.vertical, 4)
                    Caption("Backup or restore all profiles, snippets, and app settings to a JSON file.")
                    Divider().padding(.vertical, 8)
                    Button { showingClearAlert = true } label: {
                        Label("Clear all key bindings", systemImage: "trash")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(.red.opacity(0.85))
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    Caption("This will remove all snippets assigned to keys in the active profile.")
                }
            }
            .padding()
        }
        .alert("Clear All Bindings?", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) { cfg.clearAllBindings() }
        } message: {
            Text("Are you sure you want to remove all key bindings in the current profile? This cannot be undone.")
        }
    }

    private func exportAllData() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.title = "Export Sidepiece Configuration"
        panel.message = "Choose where to save your backup"
        panel.nameFieldStringValue = "sidepiece-backup-\(Date.now.formatted(.iso8601.year().month().day())).json"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try configurationManager.exportUnifiedData(
                    snippets: snippetRepository.snippets,
                    categories: snippetRepository.categories,
                    to: url
                )
            } catch {
                print("Sidepiece: export failed: \(error)")
            }
        }
    }

    private func importAllData() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.title = "Import Sidepiece Configuration"
        panel.message = "Choose a Sidepiece backup file to restore"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                let data = try configurationManager.importUnifiedData(from: url)
                snippetRepository.importData(snippets: data.snippets, categories: data.categories)
            } catch {
                print("Sidepiece: import failed: \(error)")
            }
        }
    }
}

private struct SettingsPanel<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            content
        }
        .padding()
        .background(Color.spPanel)
        .cornerRadius(12)
    }
}

private struct Caption: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text).font(.caption).foregroundColor(Color.spMuted)
    }
}

struct AccessibilityStatusView: View {
    @ObservedObject private var hotkeys = HotkeyManager.shared

    var body: some View {
        if hotkeys.isAuthorized {
            HStack(spacing: 6) {
                Circle().fill(.green).frame(width: 8, height: 8)
                Text("Granted").foregroundColor(.green)
            }
        } else {
            VStack(alignment: .trailing, spacing: 4) {
                Button(action: requestPermission) {
                    HStack(spacing: 6) {
                        Circle().fill(.red).frame(width: 8, height: 8)
                        Text("Click to Authorize").fontWeight(.medium)
                        Image(systemName: "lock.fill").font(.caption2)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                    .foregroundColor(.red)
                }
                .buttonStyle(.plain)

                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
                } label: {
                    Text("App not in list? Click to show in Finder, then drag it in.")
                        .font(.system(size: 9))
                        .foregroundColor(Color.spMuted)
                        .underline()
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func requestPermission() {
        AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary)
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
}

#Preview {
    SettingsView(
        configurationManager: ConfigurationManager.shared,
        snippetRepository: SnippetRepository.shared
    )
}
