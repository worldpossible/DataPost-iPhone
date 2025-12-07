import Foundation

/// Courier statistics from the server API
struct CourierStats: Codable, Equatable {
    let email: String
    let devices: Int
    let deliveries: Int
    let pickups: Int
    let totalCouriers: Int
    let rankByDevices: Int
    let rankByDeliveries: Int
    
    enum CodingKeys: String, CodingKey {
        case email
        case devices
        case deliveries
        case pickups
        case totalCouriers
        case rankByDevices
        case rankByDeliveries
    }
}
