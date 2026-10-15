import SwiftUI

struct KeyBindingEditorSheet: View {
    let binding: KeyBinding
    @ObservedObject var snippetRepository: SnippetRepository
    @ObservedObject var configurationManager: ConfigurationManager
    
    let onSave: (KeyBinding) -> Void
    let onDelete: (KeyBinding) -> Void
    
    @State private var selectedActionType: ActionType = .newSnippet
    @State private var snippetTitle = ""
    @State private var snippetContent = ""
    @State private var selectedCategoryId: UUID?
    @State private var selectedSnippet: Snippet?
    @State private var profileActionType: ProfileActionType = .specific
    @State private var selectedProfileId: UUID?
    @State private var cycleDirection: KeyBinding.CycleDirection = .next
    @State private var selectedFolderId: UUID?
    @State private var selectedFunction: KeyBinding.AppFunction = .peakSnippets
    @State private var selectedBundleId = ""
    @State private var shellCommand = ""

    @Environment(\.dismiss) private var dismiss
    
    enum ActionType: String, CaseIterable, Identifiable {
        case newSnippet      = "New Snippet"
        case existingSnippet = "Existing Snippet"
        case folder          = "Folder"
        case switchProfile   = "Switch Profile"
        case appFunction     = "App Function"
        case launchApp       = "Launch App"
        case runCommand      = "Run Command"

        var id: Self { self }

        var icon: String {
            switch self {
            case .newSnippet:      "plus.square.fill"
            case .existingSnippet: "doc.on.doc.fill"
            case .folder:          "folder.fill"
            case .switchProfile:   "person.fill"
            case .appFunction:     "bolt.fill"
            case .launchApp:       "arrow.up.forward.app.fill"
            case .runCommand:      "terminal.fill"
            }
        }
    }
    
    enum ProfileActionType: String, CaseIterable, Identifiable {
        case specific = "Specific Profile"
        case cycle = "Cycle Profiles"

        var id: Self { self }
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

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                            ForEach(ActionType.allCases) { type in
                                Button {
                                    selectedActionType = type
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 14, weight: .semibold))
                                        Text(type.rawValue)
                                            .font(.system(size: 9, weight: .medium))
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(selectedActionType == type ? Color.spAccent : Color.spPanelElevated)
                                    .foregroundColor(selectedActionType == type ? .white : Color.spText)
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Divider()

                    switch selectedActionType {
                    case .newSnippet:      newSnippetFields
                    case .existingSnippet: existingSnippetPicker
                    case .folder:          folderPicker
                    case .switchProfile:   combinedProfileFields
                    case .appFunction:     appFunctionPicker
                    case .launchApp:       launchAppPicker
                    case .runCommand:      runCommandEditor
                    }
                }
                .padding()
            }

            Divider()
            sheetFooter
        }
        .frame(width: 460, height: 560)
        .background(Color.spBackground)
        .onAppear {
            load(binding.action)
        }
    }

    private func load(_ action: KeyBinding.Action) {
        switch action {
        case .snippet(let id):
            selectedActionType = .existingSnippet
            selectedSnippet = snippetRepository.getSnippet(id: id)
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
        case .launchApp(let bundleId):
            selectedActionType = .launchApp
            selectedBundleId = bundleId
        case .runCommand(let command):
            selectedActionType = .runCommand
            shellCommand = command
        }
    }

    private var sheetHeader: some View {
        HStack {
            Text(isNewBinding ? "Add Binding" : "Edit Binding")
                .font(.headline)
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Color.spMuted)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
    
    private var keyInfoSection: some View {
        HStack(spacing: 12) {
            Text(binding.key.symbol)
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 50, height: 44)
                .background(Color.spAccent)
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Key: \(binding.key.displayName)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Category: \(binding.key.category.rawValue)")
                    .font(.caption)
                    .foregroundColor(Color.spMuted)
            }
            Spacer()
        }
        .padding()
        .background(Color.spPanel)
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
                        .foregroundColor(Color.spMuted)
                }
                
                TextEditor(text: $snippetContent)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 150)
                    .codeEditorStyle()
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
                            .foregroundColor(Color.spMuted)
                    }
                    Spacer()
                    if selectedSnippet?.id == snippet.id {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.spAccent)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedSnippet = snippet
                }
            }
            .frame(height: 200)
            .background(Color.spPanel)
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
            .background(Color.spPanel)
            .cornerRadius(8)
            
            Text("Pressing this key will open this folder on your numpad. Press 0 or Clear to go back.")
                .font(.caption)
                .foregroundColor(Color.spMuted)
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
                        .foregroundColor(Color.spMuted)
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
                        .foregroundColor(Color.spMuted)
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
                .foregroundColor(Color.spMuted)
        }
    }

    private var launchAppPicker: some View {
        LaunchAppPickerView(selectedBundleId: $selectedBundleId)
    }

    private var runCommandEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Shell Command")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Button("Test") {
                        SidepieceEngine.shared.executeAction(.runCommand(command: command))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(command.isEmpty)
                }

                TextEditor(text: $shellCommand)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 100)
                    .codeEditorStyle()
            }

            Text("Paste any shell command. It runs via /bin/sh so pipes, redirects, and environment variables all work.")
                .font(.caption)
                .foregroundColor(Color.spMuted)
        }
    }

    private var sheetFooter: some View {
        HStack {
            if !isNewBinding {
                Button("Remove Binding", role: .destructive) {
                    onDelete(binding)
                }
                .foregroundColor(.red)
            }
            
            Spacer()
            
            Button("Cancel") { dismiss() }
                .keyboardShortcut(.escape)

            Button("Save", action: saveChanges)
            .keyboardShortcut(.return)
            .buttonStyle(.borderedProminent)
            .disabled(!canSave)
        }
        .padding()
    }
    
    private var isNewBinding: Bool {
        snippetRepository.getBinding(for: binding.key) == nil
    }
    
    private var command: String { shellCommand.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// The action picked in the form, or nil if incomplete. New snippets are created on save.
    private var pickedAction: KeyBinding.Action? {
        switch selectedActionType {
        case .newSnippet: nil
        case .existingSnippet: selectedSnippet.map { .snippet(id: $0.id) }
        case .folder: selectedFolderId.map { .folder(id: $0) }
        case .switchProfile:
            profileActionType == .cycle
                ? .cycleProfile(direction: cycleDirection)
                : selectedProfileId.map { .switchProfile(id: $0) }
        case .appFunction: .appFunction(selectedFunction)
        case .launchApp: selectedBundleId.isEmpty ? nil : .launchApp(bundleId: selectedBundleId)
        case .runCommand: command.isEmpty ? nil : .runCommand(command: command)
        }
    }

    private var canSave: Bool {
        selectedActionType == .newSnippet
            ? !snippetTitle.isEmpty && !snippetContent.isEmpty
            : pickedAction != nil
    }

    private func saveChanges() {
        var updated = binding
        if selectedActionType == .newSnippet {
            let snippet = Snippet(title: snippetTitle, content: snippetContent, categoryId: selectedCategoryId)
            snippetRepository.addSnippet(snippet)
            updated.action = .snippet(id: snippet.id)
        } else if let action = pickedAction {
            updated.action = action
        }
        updated.updatedAt = Date()
        onSave(updated)
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
                        .foregroundColor(Color.spAccent)
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

private extension View {
    func codeEditorStyle() -> some View {
        padding(8)
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.spPanelElevated, lineWidth: 1))
    }
}
