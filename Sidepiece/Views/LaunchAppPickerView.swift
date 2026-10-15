import SwiftUI
import AppKit

struct InstalledApp: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: NSImage
}

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
                        Image(nsImage: app.icon)
                            .resizable()
                            .frame(width: 20, height: 20)
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

    @MainActor
    private func loadApps() async {
        apps = await Task.detached(priority: .userInitiated) { Self.scanInstalledApps() }.value
        isLoading = false
    }

    private static func scanInstalledApps() -> [InstalledApp] {
        let fm = FileManager.default
        let dirs = ["/Applications", "/Applications/Utilities", "/System/Applications", NSHomeDirectory() + "/Applications"]
        let bundles = dirs
            .flatMap { (try? fm.contentsOfDirectory(at: URL(filePath: $0), includingPropertiesForKeys: nil, options: .skipsHiddenFiles)) ?? [] }
            .filter { $0.pathExtension == "app" }
            .compactMap(Bundle.init(url:))

        var seen = Set<String>()
        return bundles
            .compactMap { bundle -> InstalledApp? in
                guard let id = bundle.bundleIdentifier, seen.insert(id).inserted else { return nil }
                let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                    ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
                    ?? bundle.bundleURL.deletingPathExtension().lastPathComponent
                let icon = NSWorkspace.shared.icon(forFile: bundle.bundlePath)
                icon.size = NSSize(width: 20, height: 20)
                return InstalledApp(id: id, name: name, icon: icon)
            }
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }
}
