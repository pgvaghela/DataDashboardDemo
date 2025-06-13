import SwiftUI
import Charts
import UIKit   // for UIColor

struct ContentView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        dateRangeSection
                        summarySection
                        chartSection
                    }
                    .padding()
                    .refreshable {
                        await viewModel.loadData()
                    }
                }

                if viewModel.isLoading {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView("Loading…")
                        .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(12)
                }
            }
            .navigationTitle("Bitcoin Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await viewModel.loadData() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        // animate when the count changes
        .animation(.easeOut(duration: 0.5), value: viewModel.dailyPrices.count)
    }

    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Date Range:")
                .font(.headline)

            HStack {
                VStack(alignment: .leading) {
                    Text("Start:")
                        .font(.subheadline)
                    DatePicker("", selection: $viewModel.selectedStartDate,
                               in: ...viewModel.selectedEndDate,
                               displayedComponents: .date)
                        .labelsHidden()
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("End:")
                        .font(.subheadline)
                    DatePicker("", selection: $viewModel.selectedEndDate,
                               in: viewModel.selectedStartDate...Date(),
                               displayedComponents: .date)
                        .labelsHidden()
                }
            }
        }
    }

    private var summarySection: some View {
        LazyVGrid(columns:
            Array(repeating: .init(.flexible()), count: 4),
            spacing: 16
        ) {
            metricCard(title: "Latest",
                       value: viewModel.latestPrice.map { "$\(String(format: "%.2f", $0))" } ?? "--")
            metricCard(title: "High",
                       value: viewModel.highestPrice.map { "$\(String(format: "%.2f", $0))" } ?? "--")
            metricCard(title: "Low",
                       value: viewModel.lowestPrice.map { "$\(String(format: "%.2f", $0))" } ?? "--")
            metricCard(title: "Change",
                       value: viewModel.percentChange.map { String(format: "%.2f%%", $0) } ?? "--")
        }
    }

    private func metricCard(title: String, value: String) -> some View {
        VStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .bold()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(radius: 2, x: 0, y: 1)
    }

    private var chartSection: some View {
        VStack(alignment: .leading) {
            Text("Price Over Time")
                .font(.headline)

            Chart {
                ForEach(viewModel.dailyPrices) { entry in
                    AreaMark(
                        x: .value("Date", entry.date),
                        y: .value("Price", entry.price)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.accentColor.opacity(0.3))

                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Price", entry.price)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.accentColor)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 300)
            .padding(8)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .shadow(radius: 2, x: 0, y: 1)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView().preferredColorScheme(.light)
            ContentView().preferredColorScheme(.dark)
        }
    }
}
