import SwiftUI

struct StatusView: View {
    @StateObject private var transferManager = FileTransferManager.shared
    @State private var selectedAccessPoint: AccessPoint?
    @State private var isScanning = false
    @State private var showBundleList = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Connection Status Card
                connectionStatusCard
                
                Divider()
                    .padding(.vertical)
                
                // Transfer Status
                transferStatusSection
                
                Spacer()
                
                // Action Buttons
                actionButtonsSection
            }
            .padding()
            .navigationTitle("Status")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshStatus) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showBundleList) {
                BundleListView()
            }
        }
    }
    
    private var connectionStatusCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: transferManager.isConnectedToRachel ? "wifi" : "wifi.slash")
                    .font(.title)
                    .foregroundColor(transferManager.isConnectedToRachel ? .green : .gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(transferManager.isConnectedToRachel ? "Connected to RACHEL" : "Not Connected")
                        .font(.headline)
                    
                    if let ap = selectedAccessPoint {
                        Text(ap.ssid)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Connect to a RACHEL WiFi network")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isScanning {
                    ProgressView()
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Available Access Points
            if !transferManager.availableAccessPoints.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Available Networks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(transferManager.availableAccessPoints) { ap in
                        Button(action: { connectToAccessPoint(ap) }) {
                            HStack {
                                Image(systemName: "wifi")
                                Text(ap.ssid)
                                Spacer()
                                if ap.id == selectedAccessPoint?.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
        }
    }
    
    private var transferStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transfer Status")
                .font(.headline)
            
            // Download Progress
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(.blue)
                VStack(alignment: .leading) {
                    Text("Downloads")
                        .font(.subheadline)
                    if transferManager.isDownloading {
                        ProgressView(value: transferManager.downloadProgress)
                            .progressViewStyle(.linear)
                        Text(transferManager.currentDownloadFile)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(transferManager.pendingDownloads) files pending")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // Upload Progress
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(.green)
                VStack(alignment: .leading) {
                    Text("Uploads")
                        .font(.subheadline)
                    if transferManager.isUploading {
                        ProgressView(value: transferManager.uploadProgress)
                            .progressViewStyle(.linear)
                        Text(transferManager.currentUploadFile)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(transferManager.pendingUploads) files pending")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: { showBundleList = true }) {
                HStack {
                    Image(systemName: "folder")
                    Text("View Bundles")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            HStack(spacing: 12) {
                Button(action: startSync) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Sync Now")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(transferManager.isConnectedToRachel ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(!transferManager.isConnectedToRachel)
                
                Button(action: scanForNetworks) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Scan")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
    }
    
    private func refreshStatus() {
        transferManager.checkConnectionStatus()
    }
    
    private func scanForNetworks() {
        isScanning = true
        // Note: iOS doesn't allow programmatic WiFi scanning
        // This would need to use NEHotspotHelper (requires entitlement from Apple)
        // For demo, we'll simulate finding networks
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                transferManager.availableAccessPoints = [
                    AccessPoint(ssid: "RACHEL-Demo", macAddress: "00:11:22:33:44:55", signalStrength: -45),
                    AccessPoint(ssid: "RACHEL-Library", macAddress: "00:11:22:33:44:56", signalStrength: -60)
                ]
                isScanning = false
            }
        }
    }
    
    private func connectToAccessPoint(_ ap: AccessPoint) {
        selectedAccessPoint = ap
        transferManager.connect(to: ap)
    }
    
    private func startSync() {
        transferManager.startSync()
    }
}

#Preview {
    StatusView()
}
