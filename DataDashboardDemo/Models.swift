import Foundation

// Top‐level response matching CoinDesk JSON
struct BitcoinHistoryResponse: Codable {
    let bpi: [String: Double]
    let disclaimer: String?
    let time: TimeInfo?
}

struct TimeInfo: Codable {
    let updated: String
    let updatedISO: String
}

// Parsed form to feed into Swift Charts
struct DailyPrice: Identifiable {
    let id = UUID()
    let date: Date
    let price: Double
}
