import Foundation

/// Represents a RACHEL access point / WiFi network
struct AccessPoint: Identifiable, Equatable {
    let id: String
    let ssid: String
    let macAddress: String
    let signalStrength: Int
    
    /// Whether this is a verified RACHEL device
    var isRachel: Bool {
        ssid.lowercased().contains("rachel")
    }
    
    /// Signal quality description
    var signalQuality: String {
        switch signalStrength {
        case -50...0: return "Excellent"
        case -60...(-49): return "Good"
        case -70...(-59): return "Fair"
        default: return "Weak"
        }
    }
    
    init(ssid: String, macAddress: String, signalStrength: Int) {
        self.id = macAddress
        self.ssid = ssid
        self.macAddress = macAddress
        self.signalStrength = signalStrength
    }
}

/// RACHEL device information received after connecting
struct RachelDevice: Codable {
    let macAddress: String
    let deviceName: String
    let firmwareVersion: String?
    let availableBundles: [String]?
    let storageTotal: Int64?
    let storageFree: Int64?
}
