import Foundation

enum NetworkError: Error {
    case badURL
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed(Error)
}

class NetworkService {
    static let shared = NetworkService()
    private init() { }

    /// Fetches Bitcoin historical prices from CoinDesk between `start` and `end` (format "YYYY-MM-DD")
    func fetchBitcoinHistory(start: String, end: String) async throws -> [DailyPrice] {
        // 1) Parse your “YYYY-MM-DD” start/end into UNIX timestamps
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard
          let startDate = formatter.date(from: start),
          let endDate   = formatter.date(from: end)
        else {
          throw NetworkError.badURL
        }
        let from = Int(startDate.timeIntervalSince1970)
        // CoinGecko expects “to” > “from”, so add one day to include end date
        let to   = Int(endDate.addingTimeInterval(60*60*24).timeIntervalSince1970)

        // 2) Build URLComponents
        var comps = URLComponents(string: "https://api.coingecko.com/api/v3/coins/bitcoin/market_chart/range")!
        comps.queryItems = [
          URLQueryItem(name: "vs_currency", value: "usd"),
          URLQueryItem(name: "from",        value: "\(from)"),
          URLQueryItem(name: "to",          value: "\(to)")
        ]
        guard let url = comps.url else {
          throw NetworkError.badURL
        }
        print("📡 Fetching: \(url)")

        // 3) Perform request
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
          throw NetworkError.invalidResponse
        }

        // 4) Decode into CoinGeckoRangeResponse
        let decoded = try JSONDecoder().decode(CoinGeckoRangeResponse.self, from: data)

        // 5) Map into [DailyPrice]
        let daily: [DailyPrice] = decoded.prices.compactMap { pair in
          // pair[0] = UNIX ms timestamp, pair[1] = price
          let ms = pair[0]
          let price = pair[1]
          let date = Date(timeIntervalSince1970: ms / 1000.0)
          return DailyPrice(date: date, price: price)
        }

        // 6) Sort by date
        return daily.sorted { $0.date < $1.date }
    }
}
