import Foundation
import Combine

/// Manages file transfers between the app and RACHEL devices / gateway server
class FileTransferManager: ObservableObject {
    static let shared = FileTransferManager()
    
    // MARK: - Published Properties
    
    @Published var isConnectedToRachel: Bool = false
    @Published var connectedDevice: RachelDevice?
    @Published var availableAccessPoints: [AccessPoint] = []
    
    // Download state
    @Published var isDownloading: Bool = false
    @Published var downloadProgress: Double = 0
    @Published var currentDownloadFile: String = ""
    @Published var pendingDownloads: Int = 0
    
    // Upload state
    @Published var isUploading: Bool = false
    @Published var uploadProgress: Double = 0
    @Published var currentUploadFile: String = ""
    @Published var pendingUploads: Int = 0
    
    // Storage stats
    @Published var downloadedBytesTotal: Int64 = 0
    @Published var pendingUploadBytesTotal: Int64 = 0
    
    // MARK: - Private Properties
    
    private let fileManager = FileManager.default
    private let apiService = APIService.shared
    private var downloadQueue: [ContentBundle] = []
    private var uploadQueue: [PendingUpload] = []
    
    /// Base directory for downloaded content
    private var downloadsDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("Downloads", isDirectory: true)
    }
    
    /// Directory for files pending upload
    private var uploadsDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("Uploads", isDirectory: true)
    }
    
    // MARK: - Initialization
    
    private init() {
        createDirectoriesIfNeeded()
        loadPendingUploads()
        calculateStorageUsage()
    }
    
    private func createDirectoriesIfNeeded() {
        try? fileManager.createDirectory(at: downloadsDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: uploadsDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Connection Management
    
    /// Check if currently connected to a RACHEL WiFi network
    func checkConnectionStatus() {
        // In a real implementation, this would check the current WiFi SSID
        // iOS requires NEHotspotHelper entitlement for WiFi scanning
        // For now, we'll use a simulated check
        
        // Could also ping a known RACHEL endpoint to verify
        Task {
            // Simulate network check
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                // Keep existing state - in real app, would verify connection
            }
        }
    }
    
    /// Connect to a RACHEL access point
    func connect(to accessPoint: AccessPoint) {
        // Note: iOS doesn't allow programmatic WiFi connection
        // We would need to use NEHotspotConfiguration (requires entitlement)
        // For now, simulate successful connection
        
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                self.isConnectedToRachel = true
                self.connectedDevice = RachelDevice(
                    macAddress: accessPoint.macAddress,
                    deviceName: accessPoint.ssid,
                    firmwareVersion: "3.2.1",
                    availableBundles: nil,
                    storageTotal: nil,
                    storageFree: nil
                )
            }
        }
    }
    
    /// Disconnect from current RACHEL device
    func disconnect() {
        isConnectedToRachel = false
        connectedDevice = nil
    }
    
    // MARK: - Sync Operations
    
    /// Start sync with connected RACHEL device
    func startSync() {
        guard isConnectedToRachel else { return }
        
        // 1. Download files from RACHEL (content for delivery)
        processDownloadQueue()
        
        // 2. Upload files to RACHEL (collected from other devices)
        processUploadQueue()
    }
    
    // MARK: - Download Operations
    
    /// Add a bundle to the download queue
    func downloadBundle(_ bundle: ContentBundle) {
        downloadQueue.append(bundle)
        pendingDownloads = downloadQueue.count
        
        if !isDownloading {
            processDownloadQueue()
        }
    }
    
    /// Remove a downloaded bundle
    func deleteBundle(_ bundle: ContentBundle) {
        let bundlePath = downloadsDirectory.appendingPathComponent(bundle.id)
        try? fileManager.removeItem(at: bundlePath)
        calculateStorageUsage()
    }
    
    private func processDownloadQueue() {
        guard !downloadQueue.isEmpty, !isDownloading else { return }
        
        let bundle = downloadQueue.removeFirst()
        pendingDownloads = downloadQueue.count
        
        isDownloading = true
        currentDownloadFile = bundle.title
        downloadProgress = 0
        
        Task {
            // Simulate download - in real app, would download from RACHEL
            for i in 0...100 {
                try? await Task.sleep(nanoseconds: 50_000_000)
                await MainActor.run {
                    self.downloadProgress = Double(i) / 100.0
                }
            }
            
            await MainActor.run {
                self.isDownloading = false
                self.currentDownloadFile = ""
                self.calculateStorageUsage()
                
                // Process next in queue
                if !self.downloadQueue.isEmpty {
                    self.processDownloadQueue()
                }
            }
        }
    }
    
    // MARK: - Upload Operations
    
    /// Add a file to the upload queue
    func queueFileForUpload(at url: URL) throws {
        let fileName = url.lastPathComponent
        let destination = uploadsDirectory.appendingPathComponent(fileName)
        
        // Copy file to uploads directory
        if url != destination {
            try fileManager.copyItem(at: url, to: destination)
        }
        
        let attributes = try fileManager.attributesOfItem(atPath: destination.path)
        let fileSize = (attributes[.size] as? Int64) ?? 0
        
        let upload = PendingUpload(
            id: UUID().uuidString,
            fileName: fileName,
            filePath: destination.path,
            sizeBytes: fileSize,
            createdAt: Date(),
            uploadProgress: nil,
            status: .pending
        )
        
        uploadQueue.append(upload)
        pendingUploads = uploadQueue.count
        saveUploadQueue()
        calculateStorageUsage()
    }
    
    private func processUploadQueue() {
        guard !uploadQueue.isEmpty, !isUploading else { return }
        guard let email = AuthManager.shared.userEmail else { return }
        
        var upload = uploadQueue.removeFirst()
        pendingUploads = uploadQueue.count
        
        isUploading = true
        currentUploadFile = upload.fileName
        uploadProgress = 0
        upload.status = .uploading
        
        Task {
            do {
                let fileURL = URL(fileURLWithPath: upload.filePath)
                let deviceMac = connectedDevice?.macAddress ?? "unknown"
                
                let success = try await apiService.uploadFile(at: fileURL, email: email, deviceMac: deviceMac)
                
                await MainActor.run {
                    if success {
                        // Delete uploaded file
                        try? self.fileManager.removeItem(at: fileURL)
                        upload.status = .completed
                    } else {
                        upload.status = .failed
                        self.uploadQueue.append(upload) // Re-queue for retry
                    }
                    
                    self.isUploading = false
                    self.currentUploadFile = ""
                    self.pendingUploads = self.uploadQueue.count
                    self.saveUploadQueue()
                    self.calculateStorageUsage()
                    
                    // Process next
                    if !self.uploadQueue.isEmpty {
                        self.processUploadQueue()
                    }
                }
            } catch {
                await MainActor.run {
                    upload.status = .failed
                    self.uploadQueue.append(upload) // Re-queue for retry
                    self.isUploading = false
                    self.currentUploadFile = ""
                    self.pendingUploads = self.uploadQueue.count
                    self.saveUploadQueue()
                }
            }
        }
    }
    
    // MARK: - Storage Management
    
    /// Clear all local data
    func clearLocalData() {
        try? fileManager.removeItem(at: downloadsDirectory)
        try? fileManager.removeItem(at: uploadsDirectory)
        createDirectoriesIfNeeded()
        
        downloadQueue.removeAll()
        uploadQueue.removeAll()
        pendingDownloads = 0
        pendingUploads = 0
        calculateStorageUsage()
    }
    
    private func calculateStorageUsage() {
        downloadedBytesTotal = calculateDirectorySize(downloadsDirectory)
        pendingUploadBytesTotal = calculateDirectorySize(uploadsDirectory)
    }
    
    private func calculateDirectorySize(_ url: URL) -> Int64 {
        var totalSize: Int64 = 0
        
        if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        }
        
        return totalSize
    }
    
    // MARK: - Persistence
    
    private func saveUploadQueue() {
        if let data = try? JSONEncoder().encode(uploadQueue) {
            UserDefaults.standard.set(data, forKey: "pending_uploads")
        }
    }
    
    private func loadPendingUploads() {
        if let data = UserDefaults.standard.data(forKey: "pending_uploads"),
           let uploads = try? JSONDecoder().decode([PendingUpload].self, from: data) {
            uploadQueue = uploads.filter { $0.status != .completed }
            pendingUploads = uploadQueue.count
        }
    }
}
