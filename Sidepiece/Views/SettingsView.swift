import SwiftUI

/// Main settings window view
struct SettingsView: View {
    
    private enum Tab: String, CaseIterable {
        case bindings = "Bindings"
        case snippets = "Snippets"
        case profiles = "Profiles"
        case general = "General"
    }
    
    @State private var selectedTab: Tab = .bindings
    
    var body: some View {
        TabView(selection: $selectedTab) {
            BindingsSettingsView()
                .tabItem { Label("Bindings", systemImage: "keyboard") }
                .tag(Tab.bindings)
            
            SnippetsSettingsView()
                .tabItem { Label("Snippets", systemImage: "doc.text") }
                .tag(Tab.snippets)
            
            ProfilesSettingsView()
                .tabItem { Label("Profiles", systemImage: "person.2") }
                .tag(Tab.profiles)
            
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gear") }
                .tag(Tab.general)
        }
        .frame(width: 600, height: 450)
    }
}

struct BindingsSettingsView: View {
    var body: some View {
        VStack {
            Text("Key Bindings")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Configure which snippets are triggered by each numpad key.")
                .foregroundColor(.secondary)
            
            Spacer()
            
            // TODO: Implement key binding grid
            Text("Coming soon...")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

struct SnippetsSettingsView: View {
    var body: some View {
        VStack {
            Text("Snippets")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Manage your text snippets.")
                .foregroundColor(.secondary)
            
            Spacer()
            
            // TODO: Implement snippet list/editor
            Text("Coming soon...")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

struct ProfilesSettingsView: View {
    var body: some View {
        VStack {
            Text("Profiles")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create and switch between different snippet sets.")
                .foregroundColor(.secondary)
            
            Spacer()
            
            // TODO: Implement profile management
            Text("Coming soon...")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("playSoundOnCopy") private var playSoundOnCopy = true
    @AppStorage("showNotificationOnCopy") private var showNotification = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
                Toggle("Play sound on copy", isOn: $playSoundOnCopy)
                Toggle("Show notification on copy", isOn: $showNotification)
            } header: {
                Text("Behaviour")
            }
            
            Section {
                HStack {
                    Text("Accessibility")
                    Spacer()
                    AccessibilityStatusView()
                }
            } header: {
                Text("Permissions")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct AccessibilityStatusView: View {
    @State private var hasPermission = false
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(hasPermission ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Text(hasPermission ? "Granted" : "Not Granted")
                .foregroundColor(.secondary)
            
            if !hasPermission {
                Button("Open Settings") {
                    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                    NSWorkspace.shared.open(url)
                }
                .buttonStyle(.link)
            }
        }
        .onAppear { checkPermission() }
    }
    
    private func checkPermission() {
        hasPermission = AXIsProcessTrusted()
    }
}

#Preview {
    SettingsView()
}
