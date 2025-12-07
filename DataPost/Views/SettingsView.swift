import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @AppStorage("autoSync") private var autoSync = true
    @AppStorage("syncOnWifiOnly") private var syncOnWifiOnly = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("uploadQuality") private var uploadQuality = "Original"
    @State private var showSignOutAlert = false
    @State private var showClearDataAlert = false
    
    let uploadQualityOptions = ["Original", "Compressed", "Minimal"]
    
    var body: some View {
        NavigationStack {
            Form {
                // Sync Settings
                Section {
                    Toggle(isOn: $autoSync) {
                        Label("Auto-Sync", systemImage: "arrow.triangle.2.circlepath")
                    }
                    
                    Toggle(isOn: $syncOnWifiOnly) {
                        Label("Sync on WiFi Only", systemImage: "wifi")
                    }
                    
                    Picker(selection: $uploadQuality) {
                        ForEach(uploadQualityOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    } label: {
                        Label("Upload Quality", systemImage: "photo")
                    }
                } header: {
                    Text("Sync Settings")
                }
                
                // Notifications
                Section {
                    Toggle(isOn: $notificationsEnabled) {
                        Label("Push Notifications", systemImage: "bell")
                    }
                } header: {
                    Text("Notifications")
                }
                
                // Storage
                Section {
                    HStack {
                        Label("Downloaded Bundles", systemImage: "folder")
                        Spacer()
                        Text(formatBytes(FileTransferManager.shared.downloadedBytesTotal))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Pending Uploads", systemImage: "arrow.up.doc")
                        Spacer()
                        Text(formatBytes(FileTransferManager.shared.pendingUploadBytesTotal))
                            .foregroundColor(.secondary)
                    }
                    
                    Button(role: .destructive) {
                        showClearDataAlert = true
                    } label: {
                        Label("Clear Local Data", systemImage: "trash")
                    }
                } header: {
                    Text("Storage")
                }
                
                // About
                Section {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://worldpossible.org")!) {
                        Label("World Possible Website", systemImage: "globe")
                    }
                    
                    Link(destination: URL(string: "https://worldpossible.org/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    
                    Link(destination: URL(string: "https://worldpossible.org/support")!) {
                        Label("Support", systemImage: "questionmark.circle")
                    }
                } header: {
                    Text("About")
                }
                
                // Account
                Section {
                    Button(role: .destructive) {
                        showSignOutAlert = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                } header: {
                    Text("Account")
                } footer: {
                    Text("Signed in as \(authManager.userEmail ?? "Unknown")")
                }
            }
            .navigationTitle("Settings")
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Clear Data", isPresented: $showClearDataAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    FileTransferManager.shared.clearLocalData()
                }
            } message: {
                Text("This will delete all downloaded bundles and pending uploads. This action cannot be undone.")
            }
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager.shared)
}
