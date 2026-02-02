import SwiftUI

/// Main settings window view
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
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("Settings")
                    .font(.headline)
                
                Spacer()
                
                // Ghost button for centering
                Text("Back")
                    .opacity(0)
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
        
        let newCategory = SnippetCategory(name: name, parentId: selectedParentId)
        snippetRepository.addCategory(newCategory)
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
                        .foregroundColor(.secondary)
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
                // Profiles List Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Profiles")
                        .font(.headline)
                    
                    VStack(spacing: 1) {
                        ForEach(configurationManager.profiles) { profile in
                            profileRow(for: profile)
                            
                            if profile.id != configurationManager.profiles.last?.id {
                                Divider()
                                    .padding(.leading, 8)
                            }
                        }
                    }
                    .background(Color.primary.opacity(0.03))
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(12)
                
                // Create New Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Create New Profile")
                        .font(.headline)
                    
                    HStack {
                        TextField("Profile Name", text: $newProfileName)
                            .textFieldStyle(.roundedBorder)
                        
                        Button(action: addProfile) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                        .disabled(newProfileName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(12)
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func profileRow(for profile: Profile) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                if editingProfile?.id == profile.id {
                    TextField("Name", text: $editingName, onCommit: saveProfileName)
                        .textFieldStyle(.roundedBorder)
                } else {
                    Text(profile.name)
                        .fontWeight(profile.isActive ? .bold : .regular)
                    Text("\(profile.bindings.count) keys bound")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if editingProfile?.id == profile.id {
                Button("Save") { saveProfileName() }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
            } else {
                if !profile.isActive {
                    Button("Activate") {
                        configurationManager.setActiveProfile(profile)
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.1))
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
                        .foregroundColor(.secondary)
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
        
        let newProfile = Profile(name: name)
        configurationManager.addProfile(newProfile)
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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Appearance & Sound")
                        .font(.headline)
                    
                    Toggle("Launch at login", isOn: Binding(
                        get: { configurationManager.configuration.launchAtLogin },
                        set: { newValue in
                            var config = configurationManager.configuration
                            config.launchAtLogin = newValue
                            configurationManager.updateConfiguration(config)
                        }
                    ))
                    
                    Toggle("Play sound on copy", isOn: Binding(
                        get: { configurationManager.configuration.playSoundOnCopy },
                        set: { newValue in
                            var config = configurationManager.configuration
                            config.playSoundOnCopy = newValue
                            configurationManager.updateConfiguration(config)
                        }
                    ))
                    
                    Toggle("Show notification on copy", isOn: Binding(
                        get: { configurationManager.configuration.showNotificationOnCopy },
                        set: { newValue in
                            var config = configurationManager.configuration
                            config.showNotificationOnCopy = newValue
                            configurationManager.updateConfiguration(config)
                        }
                    ))
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Interaction")
                        .font(.headline)
                    
                    Toggle("Auto-paste after trigger", isOn: Binding(
                        get: { configurationManager.configuration.autoPaste },
                        set: { newValue in
                            var config = configurationManager.configuration
                            config.autoPaste = newValue
                            configurationManager.updateConfiguration(config)
                        }
                    ))
                    
                    if configurationManager.configuration.autoPaste {
                        Toggle("Press Enter after paste", isOn: Binding(
                            get: { configurationManager.configuration.autoEnterAfterPaste },
                            set: { newValue in
                                var config = configurationManager.configuration
                                config.autoEnterAfterPaste = newValue
                                configurationManager.updateConfiguration(config)
                            }
                        ))
                    }
                    
                    Toggle("Auto-exit folder mode (5s)", isOn: Binding(
                        get: { configurationManager.configuration.autoExitFolderMode },
                        set: { newValue in
                            var config = configurationManager.configuration
                            config.autoExitFolderMode = newValue
                            configurationManager.updateConfiguration(config)
                        }
                    ))
                    
                    Text("Automatically return to the top-level (root) macros after 5 seconds of inactivity in a folder.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Permissions")
                        .font(.headline)
                    
                    HStack {
                        Text("Accessibility")
                        Spacer()
                        AccessibilityStatusView()
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Data Management")
                        .font(.headline)
                    
                    Button {
                        showingClearAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear all key bindings")
                            Spacer()
                        }
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    
                    Text("This will remove all snippets assigned to keys in the active profile.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(12)
            }
            .padding()
        }
        .alert("Clear All Bindings?", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                snippetRepository.clearAllBindings()
            }
        } message: {
            Text("Are you sure you want to remove all key bindings in the current profile? This cannot be undone.")
        }
    }
}

struct AccessibilityStatusView: View {
    @State private var hasPermission = false
    
    var body: some View {
        HStack(spacing: 6) {
            if hasPermission {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text("Granted")
                    .foregroundColor(.secondary)
            } else {
                Button(action: {
                    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                    NSWorkspace.shared.open(url)
                }) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("Not Granted")
                            .fontWeight(.medium)
                        Image(systemName: "arrow.up.forward.app")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                    .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Open System Settings")
            }
        }
        .onAppear { checkPermission() }
    }
    
    private func checkPermission() {
        hasPermission = AXIsProcessTrusted()
    }
}

#Preview {
    let config = ConfigurationManager()
    return SettingsView(
        configurationManager: config,
        snippetRepository: SnippetRepository(configurationManager: config)
    )
}
