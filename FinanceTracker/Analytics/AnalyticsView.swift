import SwiftUI
import Charts

struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isLoading {
                        ProgressView("Loading analytics...")
                            .padding(.top, 60)
                    } else {
                        // Bar chart: income vs expense
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Income vs Expense")
                                .font(.headline)
                                .padding(.horizontal)

                            Chart {
                                BarMark(
                                    x: .value("Type", "Income"),
                                    y: .value("Amount", viewModel.totalIncome)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green, .teal],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .cornerRadius(6)

                                BarMark(
                                    x: .value("Type", "Expense"),
                                    y: .value("Amount", viewModel.totalExpense)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.rose, .red],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .cornerRadius(6)
                            }
                            .frame(height: 200)
                            .padding(.horizontal)
                            .chartYAxis {
                                AxisMarks(format: .currency(code: "USD"))
                            }
                        }
                        .padding(.vertical, 16)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)

                        // Summary stats
                        HStack(spacing: 16) {
                            StatCard(title: "Total Income", value: viewModel.totalIncome, color: .green)
                            StatCard(title: "Total Expense", value: viewModel.totalExpense, color: .rose)
                        }
                        .padding(.horizontal)

                        // Pie chart section
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("By Category")
                                    .font(.headline)
                                Spacer()
                                Picker("", selection: $viewModel.selectedChartType) {
                                    Text("Expense").tag("EXPENSE")
                                    Text("Income").tag("INCOME")
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 160)
                            }
                            .padding(.horizontal)

                            if viewModel.selectedCategories.isEmpty {
                                Text("No data available")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                // Pie / Donut chart
                                Chart(viewModel.selectedCategories) { stat in
                                    SectorMark(
                                        angle: .value("Value", stat.value),
                                        innerRadius: .ratio(0.55),
                                        angularInset: 2
                                    )
                                    .foregroundStyle(by: .value("Category", stat.name))
                                    .cornerRadius(4)
                                }
                                .frame(height: 240)
                                .padding(.horizontal)

                                // Legend
                                let total = viewModel.selectedCategories.reduce(0) { $0 + $1.value }
                                VStack(spacing: 10) {
                                    ForEach(viewModel.selectedCategories) { stat in
                                        HStack {
                                            Circle()
                                                .frame(width: 10, height: 10)
                                            Text(stat.name)
                                                .font(.subheadline)
                                            Spacer()
                                            Text("$\(String(format: "%.2f", stat.value))")
                                                .font(.subheadline.bold())
                                            if total > 0 {
                                                Text("(\(Int((stat.value / total) * 100))%)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                                .padding(.bottom, 8)
                            }
                        }
                        .padding(.vertical, 16)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Analytics")
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
            .alert("Error", isPresented: Binding<Bool>(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("$\(String(format: "%.2f", value))")
                .font(.title3.bold())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}
