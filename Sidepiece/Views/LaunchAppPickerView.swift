import SwiftUI
import AppKit

// MARK: - Installed app model

struct InstalledApp: Identifiable, Hashable {
    let id: String          // bundle identifier — used as the stored value
    let name: String
    let url: URL
    var icon: NSImage?

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: InstalledApp, rhs: InstalledApp) -> Bool { lhs.id == rhs.id }
}

// MARK: - Picker view

struct LaunchAppPickerView: View {
    @Binding var selectedBundleId: String
    @State private var apps: [InstalledApp] = []
    @State private var query = ""
    @State private var isLoading = true

    private var filtered: [InstalledApp] {
        query.isEmpty ? apps : apps.filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select App")
                .font(.subheadline)
                .fontWeight(.medium)

            TextField("Search apps...", text: $query)
                .textFieldStyle(.roundedBorder)

            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(height: 180)
            } else {
                List(filtered, selection: Binding(
                    get: { filtered.first { $0.id == selectedBundleId } },
                    set: { selectedBundleId = $0?.id ?? "" }
                )) { app in
                    HStack(spacing: 8) {
                        if let icon = app.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 20, height: 20)
                        }
                        Text(app.name)
                            .fontWeight(app.id == selectedBundleId ? .semibold : .regular)
                        Spacer()
                        if app.id == selectedBundleId {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.spAccent)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { selectedBundleId = app.id }
                }
                .frame(height: 180)
                .background(Color.spPanel)
                .cornerRadius(8)
            }

            if !selectedBundleId.isEmpty {
                Text("Bundle ID: \(selectedBundleId)")
                    .font(.caption2)
                    .foregroundColor(Color.spMuted)
                    .lineLimit(1)
            }

            Text("Pressing this key will open or bring the selected app to the front.")
                .font(.caption)
                .foregroundColor(Color.spMuted)
        }
        .task { await loadApps() }
    }

    // MARK: - App scanning

    @MainActor
    private func loadApps() async {
        isLoading = true
        let found = await Task.detached(priority: .userInitiated) {
            Self.scanInstalledApps()
        }.value
        apps = found
        isLoading = false
    }

    private static func scanInstalledApps() -> [InstalledApp] {
        let fm = FileManager.default
        let searchDirs: [URL] = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/Applications/Utilities"),
            URL(fileURLWithPath: "/System/Applications"),
            URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Applications")
        ].filter { fm.fileExists(atPath: $0.path) }

        var seen = Set<String>()
        var result: [InstalledApp] = []

        for dir in searchDirs {
            guard let entries = try? fm.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for entry in entries where entry.pathExtension == "app" {
                guard
                    let bundle = Bundle(url: entry),
                    let bundleId = bundle.bundleIdentifier,
                    !seen.contains(bundleId)
                else { continue }

                seen.insert(bundleId)
                let name = bundle.infoDictionary?["CFBundleDisplayName"] as? String
                    ?? bundle.infoDictionary?["CFBundleName"] as? String
                    ?? entry.deletingPathExtension().lastPathComponent

                // Load icon on background thread — NSWorkspace is thread-safe for this
                let icon = NSWorkspace.shared.icon(forFile: entry.path)
                icon.size = NSSize(width: 20, height: 20)

                result.append(InstalledApp(id: bundleId, name: name, url: entry, icon: icon))
            }
        }

        return result.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }
}
