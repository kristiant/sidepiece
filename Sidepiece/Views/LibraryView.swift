import SwiftUI
import UniformTypeIdentifiers

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
            VStack(spacing: 0) {
                folderHeader
                Divider()
                folderList
            }
            .frame(width: 250)
            
            Divider()
            
            VStack(spacing: 0) {
                snippetFilterHeader
                Divider()
                snippetList
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
        HStack(spacing: 8) {
            breadcrumbContainer
            Spacer()
            newFolderButton
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
    }

    private var breadcrumbContainer: some View {
        HStack(spacing: 4) {
            BreadcrumbItem(title: "Library", isBold: navigationPath.isEmpty) {
                withAnimation { navigationPath.removeAll() }
            } onDrop: { onDrop($0, to: nil) }
            
            ForEach(navigationPath.indices, id: \.self) { index in
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.5))
                
                BreadcrumbItem(title: navigationPath[index].name, isBold: index == navigationPath.count - 1) {
                    withAnimation { navigationPath = Array(navigationPath.prefix(index + 1)) }
                } onDrop: { onDrop($0, to: navigationPath[index].id) }
            }
        }
    }

    private var newFolderButton: some View {
        Button(action: { isShowingCreateFolder = true }) {
            Image(systemName: "folder.badge.plus")
                .foregroundColor(.accentColor)
        }
        .buttonStyle(.plain)
        .help("New Folder")
    }
    
    private var snippetFilterHeader: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                TextField("Search...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(6)
            
            Button(action: { isShowingCreateSnippet = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.accentColor)
                    .frame(width: 20, height: 20)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)
            .help("New Snippet")
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
    }
    
    private func bind(_ snippet: Snippet) {
        assigningSnippet = snippet
    }
    
    private var folderList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(currentFolder == nil ? rootCategories : subCategories) { category in
                    FolderRow(
                        category: category,
                        repository: snippetRepository,
                        onTap: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                navigationPath.append(category)
                            }
                        },
                        onDrop: { onDrop($0, to: category.id) }
                    )
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
            onDrop(providers, to: currentFolder?.id)
        }
    }
    
    private var snippetList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                let snippets = searchText.isEmpty ? displayedSnippets : snippetRepository.snippets.filter {
                    $0.title.lowercased().contains(searchText.lowercased()) ||
                    $0.content.lowercased().contains(searchText.lowercased())
                }
                
                if searchText.isEmpty {
                    sectionHeader("SNIPS")
                }

                ForEach(snippets) { snippet in
                    snippetRow(snippet)
                }

                if searchText.isEmpty {
                    sectionHeader("FNCS")
                        .padding(.top, 12)
                    
                    ForEach(KeyBinding.AppFunction.allCases, id: \.self) {
                        AppFunctionRow(function: $0)
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
                
            }
            .padding(8)
            .frame(maxWidth: .infinity, minHeight: 500, alignment: .topLeading)
            .contentShape(Rectangle())
        }
    }
    
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundColor(.secondary.opacity(0.3))
            .padding(.horizontal, 10)
    }
    
    private func snippetRow(_ snippet: Snippet) -> some View {
        SnippetLibraryRow(
            snippet: snippet,
            categoryName: snippet.categoryId.flatMap { snippetRepository.getCategory(id: $0)?.name },
            onEdit: { editingSnippet = snippet },
            onDelete: { snippetRepository.deleteSnippet(snippet) }
        )
        .contextMenu {
            Button { bind(snippet) } label: { Label("Bind", systemImage: "keyboard") }
            Divider()
            Button(role: .destructive) { snippetRepository.deleteSnippet(snippet) } label: { Label("Delete", systemImage: "trash") }
        }
    }
    
    private func onDrop(_ providers: [NSItemProvider], to targetId: UUID?) -> Bool {
        for provider in providers {
            _ = provider.loadObject(ofClass: NSString.self) { str, _ in
                guard let idStr = str as? String, let id = UUID(uuidString: idStr) else { return }
                
                DispatchQueue.main.async {
                    if snippetRepository.getSnippet(id: id) != nil {
                        snippetRepository.moveSnippet(id, toCategoryId: targetId)
                    } else if snippetRepository.getCategory(id: id) != nil {
                        snippetRepository.moveCategory(id, toParentId: targetId)
                    }
                }
            }
        }
        return true
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
                .font(.system(size: 11, weight: isBold ? .bold : .medium))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(isTargeted ? Color.accentColor.opacity(0.15) : (isBold ? Color.accentColor.opacity(0.05) : Color.clear))
                .foregroundColor(isBold ? .primary : .secondary)
                .cornerRadius(6)
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
        HStack(spacing: 12) {
            Image(systemName: isTargeted ? "folder.fill.badge.plus" : "folder.fill")
                .foregroundColor(isTargeted ? .green : .accentColor)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 0) {
                Text(category.name)
                    .font(.system(size: 13, weight: .medium))
                
                let count = repository.getSnippets(in: category.id).count
                Text("\(count) \(count == 1 ? "snippet" : "snippets")")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(isTargeted ? Color.green.opacity(0.1) : (isHovered ? Color.accentColor.opacity(0.08) : Color.clear))
        .cornerRadius(10)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onHover { isHovered = $0 }
        .onDrop(of: [.text], isTargeted: $isTargeted) { providers in
            onDrop(providers)
        }
        .onDrag { NSItemProvider(object: category.id.uuidString as NSString) }
    }
}

struct SnippetLibraryRow: View {
    let snippet: Snippet
    let categoryName: String?
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.8))
                .frame(width: 32, height: 32)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(snippet.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    if let categoryName = categoryName {
                        Text(categoryName)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    Text(snippet.preview)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if isHovered {
                HStack(spacing: 10) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red.opacity(0.7))
                }
                .transition(.opacity)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(isHovered ? Color.accentColor.opacity(0.08) : Color.clear)
        .cornerRadius(10)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contentShape(Rectangle())
        .onDrag { NSItemProvider(object: snippet.id.uuidString as NSString) }
    }
}

struct AppFunctionRow: View {
    let function: KeyBinding.AppFunction
    @State private var hovered = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: function.icon).font(.system(size: 10)).foregroundColor(.accentColor)
                .frame(width: 24, height: 24).background(Color.accentColor.opacity(0.1)).cornerRadius(6)
            Text(function.displayName.uppercased()).font(.system(size: 10, weight: .bold, design: .monospaced))
            Spacer()
        }
        .padding(.vertical, 4).padding(.horizontal, 8)
        .background(hovered ? Color.accentColor.opacity(0.05) : .clear).cornerRadius(6)
        .onHover { hovered = $0 }.contentShape(Rectangle())
        .onDrag { NSItemProvider(object: "fnc:\(function.rawValue)" as NSString) }
    }
}

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
        VStack(alignment: .leading, spacing: 12) {
            Text("EDIT SNIP").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.secondary)
            
            TextField("TITLE", text: $title).textFieldStyle(.plain)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .padding(8).background(Color.secondary.opacity(0.05)).cornerRadius(6)
            
            TextEditor(text: $content).font(.system(size: 11, design: .monospaced))
                .frame(height: 120).padding(4).background(Color.secondary.opacity(0.03)).cornerRadius(6)
            
            HStack {
                Button("CANCEL") { dismiss() }.font(.system(size: 10, weight: .bold, design: .monospaced))
                Spacer()
                Button("SAVE") {
                    var up = snippet
                    up.title = title
                    up.content = content
                    if repository.getSnippet(id: up.id) != nil { repository.updateSnippet(up) }
                    else { repository.addSnippet(up) }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
            }
        }
        .padding(16).frame(width: 380)
    }
}
