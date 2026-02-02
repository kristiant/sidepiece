import SwiftUI

/// Main sheet for editing key bindings
struct KeyBindingEditorSheet: View {
    
    @Binding var binding: KeyBinding?
    @ObservedObject var snippetRepository: SnippetRepository
    @ObservedObject var configurationManager: ConfigurationManager
    
    let onSave: (KeyBinding) -> Void
    let onDelete: (KeyBinding) -> Void
    
    @State private var selectedActionType: ActionType = .newSnippet
    
    // New Snippet State
    @State private var snippetTitle = ""
    @State private var snippetContent = ""
    
    // Existing Snippet State
    @State private var selectedSnippet: Snippet?
    
    // Profile State
    @State private var profileActionType: ProfileActionType = .specific
    @State private var selectedProfileId: UUID?
    @State private var cycleDirection: KeyBinding.CycleDirection = .next
    
    // Folder State
    @State private var selectedFolderId: UUID?
    
    // Category for new snippet
    @State private var selectedCategoryId: UUID?
    
    // Function State
    @State private var selectedFunction: KeyBinding.AppFunction = .peakSnippets
    
    @Environment(\.dismiss) private var dismiss
    
    enum ActionType: String, CaseIterable, Identifiable {
        case newSnippet = "New Snippet"
        case existingSnippet = "Existing Snippet"
        case folder = "Folder"
        case switchProfile = "Switch Profile"
        case appFunction = "App Function"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .newSnippet: return "plus.square.fill"
            case .existingSnippet: return "doc.on.doc.fill"
            case .folder: return "folder.fill"
            case .switchProfile: return "person.fill"
            case .appFunction: return "bolt.fill"
            }
        }
    }
    
    enum ProfileActionType: String, CaseIterable, Identifiable {
        case specific = "Specific Profile"
        case cycle = "Cycle Profiles"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            sheetHeader
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    keyInfoSection
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Action Type")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Picker("", selection: $selectedActionType) {
                            ForEach(ActionType.allCases) { type in
                                Label(type.rawValue, systemImage: type.icon).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Divider()
                    
                    switch selectedActionType {
                    case .newSnippet:
                        newSnippetFields
                    case .existingSnippet:
                        existingSnippetPicker
                    case .folder:
                        folderPicker
                    case .switchProfile:
                        combinedProfileFields
                    case .appFunction:
                        appFunctionPicker
                    }
                }
                .padding()
            }
            
            Divider()
            sheetFooter
        }
        .frame(width: 420, height: 520)
        .onAppear {
            if let binding = binding {
                switch binding.action {
                case .snippet(let snippet):
                    // Check if this snippet exists in our repository to decide if it's "Existing" or "New"
                    if snippetRepository.snippets.contains(where: { $0.id == snippet.id }) {
                        selectedActionType = .existingSnippet
                        selectedSnippet = snippet
                    } else {
                        selectedActionType = .newSnippet
                        snippetTitle = snippet.title
                        snippetContent = snippet.content
                        selectedCategoryId = snippet.categoryId
                    }
                case .folder(let id):
                    selectedActionType = .folder
                    selectedFolderId = id
                case .switchProfile(let id):
                    selectedActionType = .switchProfile
                    profileActionType = .specific
                    selectedProfileId = id
                case .cycleProfile(let direction):
                    selectedActionType = .switchProfile
                    profileActionType = .cycle
                    cycleDirection = direction
                case .appFunction(let function):
                    selectedActionType = .appFunction
                    selectedFunction = function
                }
            } else {
                selectedProfileId = configurationManager.profiles.first?.id
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
    
    private var newSnippetFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Title")
                    .font(.subheadline)
                    .fontWeight(.medium)
                TextField("e.g., Reload Packages", text: $snippetTitle)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Content")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(snippetContent.count) chars")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                TextEditor(text: $snippetContent)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 150)
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Assign to Folder")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("", selection: $selectedCategoryId) {
                    Text("None").tag(nil as UUID?)
                    ForEach(snippetRepository.categories) { category in
                        Text(category.name).tag(category.id as UUID?)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
    
    private var existingSnippetPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose a Snippet")
                .font(.subheadline)
                .fontWeight(.medium)
            
            List(snippetRepository.snippets, id: \.id, selection: $selectedSnippet) { snippet in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(snippet.title)
                            .fontWeight(.medium)
                        Text(snippet.preview)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if selectedSnippet?.id == snippet.id {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedSnippet = snippet
                }
            }
            .frame(height: 200)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
        }
    }
    
    private var folderPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Folder")
                .font(.subheadline)
                .fontWeight(.medium)
            
            List {
                ForEach(snippetRepository.categories.filter { $0.parentId == nil }) { category in
                    HierarchicalCategoryRow(
                        category: category,
                        level: 0,
                        selectedId: $selectedFolderId,
                        snippetRepository: snippetRepository
                    )
                }
            }
            .frame(height: 200)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
            
            Text("Pressing this key will open this folder on your numpad. Press 0 or Clear to go back.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var combinedProfileFields: some View {
        VStack(alignment: .leading, spacing: 20) {
            Picker("Action", selection: $profileActionType) {
                ForEach(ProfileActionType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.radioGroup)
            
            Divider()
            
            if profileActionType == .specific {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Profile")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("", selection: $selectedProfileId) {
                        ForEach(configurationManager.profiles) { profile in
                            Text(profile.name).tag(profile.id as UUID?)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Text("Pressing this key will immediately switch Sidepiece to using this profile.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cycle Direction")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("", selection: $cycleDirection) {
                        Text("Next Profile").tag(KeyBinding.CycleDirection.next)
                        Text("Previous Profile").tag(KeyBinding.CycleDirection.previous)
                    }
                    .pickerStyle(.radioGroup)
                    
                    Text("Each press will move to the next or previous profile in your list.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var appFunctionPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select App Function")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Picker("", selection: $selectedFunction) {
                ForEach(KeyBinding.AppFunction.allCases, id: \.self) { function in
                    Text(function.displayName).tag(function)
                }
            }
            .pickerStyle(.radioGroup)
            
            Text("Assigning an app function allows you to trigger special actions directly from your numpad.")
                .font(.caption)
                .foregroundColor(.secondary)
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
            .disabled(!canSave)
        }
        .padding()
    }
    
    private var isNewBinding: Bool {
        guard let binding = binding else { return true }
        return snippetRepository.getBinding(for: binding.key) == nil
    }
    
    private var canSave: Bool {
        switch selectedActionType {
        case .newSnippet:
            return !snippetTitle.isEmpty && !snippetContent.isEmpty
        case .existingSnippet:
            return selectedSnippet != nil
        case .folder:
            return selectedFolderId != nil
        case .switchProfile:
            if profileActionType == .specific {
                return selectedProfileId != nil
            }
            return true
        case .appFunction:
            return true
        }
    }
    
    private func saveChanges() {
        guard var updatedBinding = binding else { return }
        
        switch selectedActionType {
        case .newSnippet:
            let snippet = Snippet(title: snippetTitle, content: snippetContent, categoryId: selectedCategoryId)
            updatedBinding.action = .snippet(snippet)
        case .existingSnippet:
            if let snippet = selectedSnippet {
                updatedBinding.action = .snippet(snippet)
            }
        case .folder:
            if let folderId = selectedFolderId {
                updatedBinding.action = .folder(folderId)
            }
        case .switchProfile:
            if profileActionType == .specific {
                if let profileId = selectedProfileId {
                    updatedBinding.action = .switchProfile(profileId)
                }
            } else {
                updatedBinding.action = .cycleProfile(direction: cycleDirection)
            }
        case .appFunction:
            updatedBinding.action = .appFunction(selectedFunction)
        }
        
        updatedBinding.updatedAt = Date()
        onSave(updatedBinding)
    }
}

struct HierarchicalCategoryRow: View {
    let category: SnippetCategory
    let level: Int
    @Binding var selectedId: UUID?
    let snippetRepository: SnippetRepository
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(Color(hex: category.color))
                    .padding(.leading, CGFloat(level * 16))
                
                Text(category.name)
                    .fontWeight(selectedId == category.id ? .bold : .medium)
                
                Spacer()
                
                if selectedId == category.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
            .onTapGesture {
                selectedId = category.id
            }
            
            ForEach(snippetRepository.getSubCategories(parentId: category.id)) { sub in
                HierarchicalCategoryRow(
                    category: sub,
                    level: level + 1,
                    selectedId: $selectedId,
                    snippetRepository: snippetRepository
                )
            }
        }
    }
}
