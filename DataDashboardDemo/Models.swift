import Foundation

// Top‐level response matching CoinDesk JSON

struct CoinGeckoRangeResponse: Codable {
    let prices: [[Double]]   // [ [timestamp, price], … ]
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
