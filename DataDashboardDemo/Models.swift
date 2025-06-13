import Foundation

struct CoinGeckoRangeResponse: Codable {
    let prices: [[Double]]
    let market_caps: [[Double]]?
    let total_volumes: [[Double]]?
}

/// Conform to Equatable so `Array<DailyPrice>` is Equatable and animations work
struct DailyPrice: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let price: Double
}
