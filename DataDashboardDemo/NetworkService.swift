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
        let urlString = "https://api.coindesk.com/v1/bpi/historical/close.json?start=\(start)&end=\(end)"
        guard let url = URL(string: urlString) else {
            throw NetworkError.badURL
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResp = response as? HTTPURLResponse,
                  (200...299).contains(httpResp.statusCode)
            else {
                throw NetworkError.invalidResponse
            }

            let decoder = JSONDecoder()
            // The API’s dates are keys like "2024-01-01"; we’ll parse them manually below
            let result = try decoder.decode(BitcoinHistoryResponse.self, from: data)

            // Convert dictionary [String: Double] → [DailyPrice]
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dailyPrices: [DailyPrice] = result.bpi.compactMap { (dateString, value) in
                guard let date = dateFormatter.date(from: dateString) else { return nil }
                return DailyPrice(date: date, price: value)
            }
            return dailyPrices.sorted { $0.date < $1.date }
        }
        catch let decodeErr as DecodingError {
            throw NetworkError.decodingFailed(decodeErr)
        }
        catch {
            throw NetworkError.requestFailed(error)
        }
    }
}
