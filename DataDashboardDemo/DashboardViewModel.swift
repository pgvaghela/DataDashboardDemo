import Foundation
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var dailyPrices: [DailyPrice] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    @Published var latestPrice: Double?
    @Published var highestPrice: Double?
    @Published var lowestPrice: Double?
    @Published var percentChange: Double?

    @Published var selectedStartDate: Date
    @Published var selectedEndDate: Date

    private let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    init() {
        let now = Date()
        self.selectedEndDate = now
        self.selectedStartDate = Calendar.current
            .date(byAdding: .day, value: -30, to: now) ?? now
        Task { await loadData() }
    }

    private func isoDateString(from date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = TimeZone(secondsFromGMT: 0)
        return fmt.string(from: date)
    }

    func loadData() async {
        isLoading = true
        errorMessage = nil

        let startStr = isoDateString(from: selectedStartDate)
        let endStr   = isoDateString(from: selectedEndDate)

        do {
            let fetched = try await NetworkService.shared
                .fetchBitcoinHistory(start: startStr, end: endStr)
            dailyPrices = fetched
            calculateSummaries()
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
            dailyPrices = []
            latestPrice = nil
            highestPrice = nil
            lowestPrice = nil
            percentChange = nil
        }

        isLoading = false
    }

    func calculateSummaries() {
        guard !dailyPrices.isEmpty else { return }
        latestPrice  = dailyPrices.last?.price
        highestPrice = dailyPrices.map(\.price).max()
        lowestPrice  = dailyPrices.map(\.price).min()

        if
            let first = dailyPrices.first?.price,
            let last  = dailyPrices.last?.price
        {
            percentChange = (last - first) / first * 100
        }
    }

    func formatted(_ date: Date) -> String {
        displayFormatter.string(from: date)
    }
}
