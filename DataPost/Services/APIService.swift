import Foundation

/// Service for making API calls to the DataPost gateway server
class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL = "http://52.212.194.99:3000"
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Courier Stats
    
    /// Fetch courier statistics for the given email
    func fetchCourierStats(email: String) async throws -> CourierStats {
        guard let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/courier-stats?email=\(encodedEmail)") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        do {
            let stats = try JSONDecoder().decode(CourierStats.self, from: data)
            return stats
        } catch {
            print("Decoding error: \(error)")
            throw APIError.decodingError(error)
        }
    }
    
    // MARK: - File Upload
    
    /// Upload a file to the gateway server
    func uploadFile(at fileURL: URL, email: String, deviceMac: String) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/emule") else {
            throw APIError.invalidURL
        }
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add email field
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"email\"\r\n\r\n")
        body.append("\(email)\r\n")
        
        // Add device MAC field
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"device\"\r\n\r\n")
        body.append("\(deviceMac)\r\n")
        
        // Add file
        let fileName = fileURL.lastPathComponent
        let fileData = try Data(contentsOf: fileURL)
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: application/octet-stream\r\n\r\n")
        body.append(fileData)
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")
        
        request.httpBody = body
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        return httpResponse.statusCode == 200
    }
    
    // MARK: - Account Deletion
    
    /// Request account deletion for the given email
    func deleteAccount(email: String) async throws {
        guard let url = URL(string: "\(baseURL)/delete-account") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
    }
    
    // MARK: - Bundle List
    
    /// Fetch available bundles from a RACHEL device
    func fetchBundles(from rachelIP: String) async throws -> [ContentBundle] {
        guard let url = URL(string: "http://\(rachelIP)/admin/modules.json") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        // Parse RACHEL module list - format varies by RACHEL version
        // This is a simplified implementation
        let bundles = try JSONDecoder().decode([ContentBundle].self, from: data)
        return bundles
    }
    
    // MARK: - Download
    
    /// Download a file from RACHEL device
    func downloadFile(from url: URL, to destination: URL, progress: @escaping (Double) -> Void) async throws {
        let (asyncBytes, response) = try await session.bytes(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let totalSize = httpResponse.expectedContentLength
        var downloadedBytes: Int64 = 0
        var data = Data()
        
        for try await byte in asyncBytes {
            data.append(byte)
            downloadedBytes += 1
            
            if totalSize > 0 {
                let currentProgress = Double(downloadedBytes) / Double(totalSize)
                await MainActor.run {
                    progress(currentProgress)
                }
            }
        }
        
        try data.write(to: destination)
    }
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "Server error: \(statusCode)"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Data Extension

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
