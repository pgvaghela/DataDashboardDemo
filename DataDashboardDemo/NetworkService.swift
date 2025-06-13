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

    /// Fetches Bitcoin prices between `start` and `end` (YYYY-MM-DD),
    /// clamping to the last 365 days on the free API, then filtering client-side.
    func fetchBitcoinHistory(start: String, end: String) async throws -> [DailyPrice] {
        // 1️⃣ Parse start/end in UTC
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = TimeZone(secondsFromGMT: 0)

        guard
            let startDate = df.date(from: start),
            let endDateBase = df.date(from: end)
        else {
            throw NetworkError.badURL
        }
        // end at midnight *after* the end day
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: endDateBase)!

        // 2️⃣ Clamp start to max 365 days ago
        let oneYearAgo = Calendar.current.date(
            byAdding: .day,
            value: -365,
            to: Date()
        )!
        let clampedStart = max(startDate, oneYearAgo)
        if clampedStart > startDate {
            print("⚠️ Clamping start from \(start) to one year ago (\(df.string(from: oneYearAgo))) due to free API limit")
        }

        // 3️⃣ Build /range endpoint URL
        guard var comps = URLComponents(string:
            "https://api.coingecko.com/api/v3/coins/bitcoin/market_chart/range"
        ) else {
            throw NetworkError.badURL
        }
        comps.queryItems = [
            URLQueryItem(name: "vs_currency", value: "usd"),
            URLQueryItem(
                name: "from",
                value: "\(Int(clampedStart.timeIntervalSince1970))"
            ),
            URLQueryItem(
                name: "to",
                value: "\(Int(endDate.timeIntervalSince1970))"
            )
        ]
        guard let url = comps.url else {
            throw NetworkError.badURL
        }
        print("📡 Fetching range:", url.absoluteString)

        // 4️⃣ Download
        let (data, resp) = try await URLSession.shared.data(from: url)

        // 5️⃣ Write raw JSON for inspection
        if let docs = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask).first
        {
            let out = docs.appendingPathComponent("coin_history.json")
            try? data.write(to: out)
            print("💾 Wrote JSON to:", out.path)
        }

        // 6️⃣ Log status & snippet
        if let http = resp as? HTTPURLResponse {
            print("✅ HTTP status:", http.statusCode)
        }
        if let txt = String(data: data, encoding: .utf8) {
            print("🔍 JSON snippet:\n", txt.prefix(500))
        }

        // 7️⃣ Validate HTTP
        guard let http = resp as? HTTPURLResponse,
              (200...299).contains(http.statusCode)
        else {
            throw NetworkError.invalidResponse
        }

        // 8️⃣ Decode
        let decoded: CoinGeckoRangeResponse
        do {
            decoded = try JSONDecoder().decode(
                CoinGeckoRangeResponse.self,
                from: data
            )
        } catch {
            print("❌ Decode failed:", error)
            throw NetworkError.decodingFailed(error)
        }

        // 9️⃣ Map & filter
        let points = decoded.prices.compactMap { pair -> DailyPrice? in
            guard pair.count == 2 else { return nil }
            let date  = Date(timeIntervalSince1970: pair[0] / 1000)
            let price = pair[1]
            return DailyPrice(date: date, price: price)
        }

        let filtered = points.filter { dp in
            dp.date >= clampedStart && dp.date < endDate
        }

        return filtered.sorted { $0.date < $1.date }
    }
}
