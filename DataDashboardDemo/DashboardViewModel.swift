import Foundation
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var dailyPrices: [DailyPrice] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    @Published var latestPrice: Double?
    @Published var highestPrice: Double?
    @Published var lowestPrice: Double?

    @Published var selectedStartDate: Date
    @Published var selectedEndDate: Date

    private let displayFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        return fmt
    }()

    init() {
        // Default: last 30 days
        let now = Date()
        self.selectedEndDate = now
        self.selectedStartDate = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now

        // Fetch immediately
        Task {
            await loadData()
        }
    }

    private func isoDateString(from date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }

    func loadData() async {
        isLoading = true
        errorMessage = nil

        let startStr = isoDateString(from: selectedStartDate)
        let endStr = isoDateString(from: selectedEndDate)

        do {
            let fetched = try await NetworkService.shared.fetchBitcoinHistory(start: startStr, end: endStr)
            dailyPrices = fetched
            calculateSummaries()
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
            dailyPrices = []
            latestPrice = nil
            highestPrice = nil
            lowestPrice = nil
        }

        isLoading = false
    }

    private func calculateSummaries() {
        guard !dailyPrices.isEmpty else { return }
        latestPrice = dailyPrices.last?.price
        highestPrice = dailyPrices.map { $0.price }.max()
        lowestPrice = dailyPrices.map { $0.price }.min()
    }

    func formatted(date: Date) -> String {
        displayFormatter.string(from: date)
    }
}
