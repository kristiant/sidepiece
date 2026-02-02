import SwiftUI

struct LibraryView: View {
    @ObservedObject var snippetRepository: SnippetRepository
    @ObservedObject var configurationManager: ConfigurationManager
    
    @State private var navigationPath: [SnippetCategory] = []
    @State private var isShowingCreateFolder = false
    @State private var isShowingCreateSnippet = false
    @State private var targetCategoryIdForNewSnippet: UUID? = nil
    @State private var newFolderName = ""
    @State private var editingSnippet: Snippet? = nil
    @State private var assigningSnippet: Snippet? = nil
    @State private var searchText = ""
    
    var currentFolder: SnippetCategory? {
        navigationPath.last
    }
    
    var subCategories: [SnippetCategory] {
        snippetRepository.getSubCategories(parentId: currentFolder?.id ?? UUID())
    }
    
    var rootCategories: [SnippetCategory] {
        snippetRepository.categories.filter { $0.parentId == nil }
    }
    
    var localSnippets: [Snippet] {
        if let folder = currentFolder {
            return snippetRepository.getSnippets(in: folder.id)
        } else {
            return snippetRepository.snippets.filter { $0.categoryId == nil }
        }
    }
    
    var displayedSnippets: [Snippet] {
        snippetRepository.snippets
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Folders Column
            VStack(spacing: 0) {
                folderHeader
                Divider()
                folderList
            }
            .frame(width: 250)
            
            Divider()
            
            // Snippets Column
            VStack(spacing: 0) {
                snippetFilterHeader
                Divider()
                snippetList
                Divider()
                actionButtons
            }
            .frame(maxWidth: .infinity)
        }
        .sheet(isPresented: $isShowingCreateFolder) {
            createFolderSheet
        }
        .sheet(item: $editingSnippet) { snippet in
            SnippetEditorSheet(snippet: snippet, repository: snippetRepository)
        }
        .sheet(isPresented: $isShowingCreateSnippet) {
            SnippetEditorSheet(snippet: Snippet(title: "", content: "", categoryId: targetCategoryIdForNewSnippet), repository: snippetRepository)
        }
        .sheet(item: $assigningSnippet) { snippet in
            HotkeyPickerSheet(snippet: snippet, snippetRepository: snippetRepository)
        }
    }
    
    private var folderHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                BreadcrumbItem(title: "Library", isBold: navigationPath.isEmpty) {
                    navigationPath.removeAll()
                } onDrop: { providers in
                    handleDrop(providers, into: nil)
                }
                
                ForEach(navigationPath.indices, id: \.self) { index in
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    BreadcrumbItem(title: navigationPath[index].name, isBold: index == navigationPath.count - 1) {
                        navigationPath = Array(navigationPath.prefix(index + 1))
                    } onDrop: { providers in
                        handleDrop(providers, into: navigationPath[index].id)
                    }
                }
                
                Spacer()
                
                Button(action: { isShowingCreateFolder = true }) {
                    Image(systemName: "folder.badge.plus")
                }
                .buttonStyle(.plain)
                .help("New Folder")
            }
        }
        .padding(10)
        .frame(height: 44)
    }
    
    private var snippetFilterHeader: some View {
        VStack(spacing: 8) {
            HStack {
                TextField("Search snippets...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .controlSize(.small)
                
                Button(action: { isShowingCreateSnippet = true }) {
                    Image(systemName: "doc.badge.plus")
                }
                .buttonStyle(.plain)
                .help("New Snippet")
            }
            
        }
        .padding(10)
    }
    
    private func assignShortcut(for snippet: Snippet) {
        assigningSnippet = snippet
    }
    
    private var folderList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                // folders
                ForEach(currentFolder == nil ? rootCategories : subCategories) { category in
                    FolderRow(
                        category: category,
                        repository: snippetRepository,
                        onTap: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                navigationPath.append(category)
                            }
                        },
                        onDrop: { providers in
                            handleDrop(providers, into: category.id)
                        }
                    )
                    .onDrag { NSItemProvider(object: category.id.uuidString as NSString) }
                    .contextMenu {
                        Button(role: .destructive) {
                            snippetRepository.deleteCategory(category.id)
                        } label: {
                            Label("Delete Folder", systemImage: "trash")
                        }
                    }
                }
                
                if !localSnippets.isEmpty {
                    Divider()
                        .padding(.vertical, 8)
                    
                    ForEach(localSnippets) { snippet in
                        SnippetLibraryRow(
                            snippet: snippet,
                            categoryName: currentFolder?.name,
                            onEdit: { editingSnippet = snippet },
                            onDelete: { snippetRepository.deleteSnippet(snippet) }
                        )
                        .onDrag { NSItemProvider(object: snippet.id.uuidString as NSString) }
                    }
                }
                
                if (currentFolder == nil ? rootCategories : subCategories).isEmpty && localSnippets.isEmpty {
                    Text("No contents")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.leading, 12)
                        .padding(.top, 20)
                }
                
                Spacer()
            }
            .padding(8)
            .frame(maxWidth: .infinity, minHeight: 500, alignment: .topLeading)
            .contentShape(Rectangle())
            .contextMenu {
                Button {
                    targetCategoryIdForNewSnippet = currentFolder?.id
                    isShowingCreateSnippet = true
                } label: {
                    Label("New Snippet", systemImage: "doc.badge.plus")
                }
                
                Button {
                    isShowingCreateFolder = true
                } label: {
                    Label("New Folder", systemImage: "folder.badge.plus")
                }
            }
        }
        .onDrop(of: [.text], isTargeted: nil) { providers in
            handleDrop(providers, into: currentFolder?.id)
        }
    }
    
    private var snippetList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                let snippets = searchText.isEmpty ? displayedSnippets : snippetRepository.snippets.filter {
                    $0.title.lowercased().contains(searchText.lowercased()) ||
                    $0.content.lowercased().contains(searchText.lowercased())
                }
                
                ForEach(snippets) { snippet in
                    SnippetLibraryRow(
                        snippet: snippet,
                        categoryName: snippet.categoryId.flatMap { id in snippetRepository.getCategory(id: id)?.name },
                        onEdit: { editingSnippet = snippet },
                        onDelete: { snippetRepository.deleteSnippet(snippet) }
                    )
                    .onDrag { NSItemProvider(object: snippet.id.uuidString as NSString) }
                    .contextMenu {
                        Button {
                            assignShortcut(for: snippet)
                        } label: {
                            Label("Assign to Hotkey...", systemImage: "keyboard")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            snippetRepository.deleteSnippet(snippet)
                        } label: {
                            Label("Delete Snippet", systemImage: "trash")
                        }
                    }
                }
                
                if snippets.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        let emptyMsg: String = {
                            if !searchText.isEmpty {
                                return "No results for \"\(searchText)\""
                            }
                            return "No snippets yet"
                        }()
                        
                        Text(emptyMsg)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
                
                Spacer()
            }
            .padding(8)
            .frame(maxWidth: .infinity, minHeight: 500, alignment: .topLeading)
            .contentShape(Rectangle())
            .contextMenu {
                Button {
                    targetCategoryIdForNewSnippet = nil
                    isShowingCreateSnippet = true
                } label: {
                    Label("New Snippet", systemImage: "doc.badge.plus")
                }
            }
        }
    }
    
    private func handleDrop(_ providers: [NSItemProvider], into targetId: UUID?) -> Bool {
        for provider in providers {
            _ = provider.loadObject(ofClass: NSString.self) { string, _ in
                guard let idString = string as? String, let id = UUID(uuidString: idString) else { return }
                
                DispatchQueue.main.async {
                    if let _ = snippetRepository.getSnippet(id: id) {
                        // It's a snippet
                        snippetRepository.moveSnippet(id, toCategoryId: targetId)
                    } else if let _ = snippetRepository.getCategory(id: id) {
                        // It's a category
                        snippetRepository.moveCategory(id, toParentId: targetId)
                    }
                }
            }
        }
        return true
    }
    
    private var actionButtons: some View {
        HStack {
            Spacer()
            
            Button(action: { 
                targetCategoryIdForNewSnippet = nil
                isShowingCreateSnippet = true 
            }) {
                Label("New Snippet", systemImage: "doc.badge.plus")
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding()
    }
    
    private var createFolderSheet: some View {
        VStack(spacing: 20) {
            Text("Create New Folder")
                .font(.headline)
            
            TextField("Folder Name", text: $newFolderName)
                .textFieldStyle(.roundedBorder)
            
            HStack {
                Button("Cancel") {
                    isShowingCreateFolder = false
                    newFolderName = ""
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Spacer()
                
                Button("Create") {
                    let newCategory = SnippetCategory(
                        name: newFolderName,
                        parentId: currentFolder?.id
                    )
                    snippetRepository.addCategory(newCategory)
                    isShowingCreateFolder = false
                    newFolderName = ""
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .disabled(newFolderName.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
}

struct BreadcrumbItem: View {
    let title: String
    let isBold: Bool
    let action: () -> Void
    let onDrop: ([NSItemProvider]) -> Bool
    
    @State private var isTargeted = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(isBold ? .bold : .regular)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(isTargeted ? Color.accentColor.opacity(0.2) : Color.clear)
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .onDrop(of: [.text], isTargeted: $isTargeted) { providers in
            onDrop(providers)
        }
    }
}

struct FolderRow: View {
    let category: SnippetCategory
    let repository: SnippetRepository
    let onTap: () -> Void
    let onDrop: ([NSItemProvider]) -> Bool
    
    @State private var isHovered = false
    @State private var isTargeted = false
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: isTargeted ? "folder.fill.badge.plus" : "folder.fill")
                    .foregroundColor(isTargeted ? .green : .accentColor)
                    .font(.title3)
                Text(category.name)
                    .fontWeight(isTargeted ? .bold : .regular)
                
                Spacer()
                
                let count = repository.getSnippets(in: category.id).count
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(10)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(isTargeted ? Color.green.opacity(0.1) : (isHovered ? Color.accentColor.opacity(0.1) : Color.clear))
            .cornerRadius(8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .onDrop(of: [.text], isTargeted: $isTargeted) { providers in
            onDrop(providers)
        }
    }
}

struct SnippetLibraryRow: View {
    let snippet: Snippet
    let categoryName: String?
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.title3)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(snippet.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(snippet.preview)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(categoryName ?? "ungrouped")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.accentColor.opacity(0.7))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.body)
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .help("Edit Snippet")
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.body)
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
                .help("Delete Snippet")
            }
        }
        .padding(.vertical, 6)
    }
}

// Simple Snippet Editor for general use
struct SnippetEditorSheet: View {
    @Environment(\.dismiss) var dismiss
    @State var title: String
    @State var content: String
    let snippet: Snippet
    let repository: SnippetRepository
    
    init(snippet: Snippet, repository: SnippetRepository) {
        self.snippet = snippet
        self.repository = repository
        _title = State(initialValue: snippet.title)
        _content = State(initialValue: snippet.content)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Edit Snippet")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Title").font(.caption).foregroundColor(.secondary)
                TextField("Snippet Title", text: $title)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Content").font(.caption).foregroundColor(.secondary)
                TextEditor(text: $content)
                    .frame(height: 150)
                    .border(Color.secondary.opacity(0.2))
            }
            
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Save") {
                    var updated = snippet
                    updated.title = title
                    updated.content = content
                    
                    if repository.getSnippet(id: updated.id) != nil {
                        repository.updateSnippet(updated)
                    } else {
                        repository.addSnippet(updated)
                    }
                    
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400)
    }
}
