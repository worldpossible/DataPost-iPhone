import Foundation

/// Represents a content bundle that can be synced with RACHEL devices
struct ContentBundle: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let sizeBytes: Int64
    var isDownloaded: Bool
    let category: String
    
    /// Progress of current download (0.0 to 1.0)
    var downloadProgress: Double?
    
    /// Local file path if downloaded
    var localPath: String?
    
    /// Version/checksum for sync verification
    var version: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case sizeBytes
        case isDownloaded
        case category
        case downloadProgress
        case localPath
        case version
    }
    
    init(id: String, title: String, description: String, sizeBytes: Int64, isDownloaded: Bool, category: String) {
        self.id = id
        self.title = title
        self.description = description
        self.sizeBytes = sizeBytes
        self.isDownloaded = isDownloaded
        self.category = category
        self.downloadProgress = nil
        self.localPath = nil
        self.version = nil
    }
}

/// Represents files pending upload to the gateway server
struct PendingUpload: Identifiable, Codable {
    let id: String
    let fileName: String
    let filePath: String
    let sizeBytes: Int64
    let createdAt: Date
    var uploadProgress: Double?
    var status: UploadStatus
    
    enum UploadStatus: String, Codable {
        case pending
        case uploading
        case completed
        case failed
    }
}
