import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Greeting
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.greeting)
                                .font(.title2.bold())
                            Text("Here's your financial overview")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chart.pie.fill")
                            .font(.title)
                            .foregroundColor(.indigo)
                    }
                    .padding(.horizontal)

                    // Balance card
                    BalanceCard(balance: viewModel.totalBalance)
                        .padding(.horizontal)

                    // Income / Expense cards
                    HStack(spacing: 16) {
                        SummaryCard(
                            title: "Income",
                            amount: viewModel.summary?.cashFlow.totalIncome ?? 0,
                            icon: "arrow.down.circle.fill",
                            gradient: [Color.green, Color.teal]
                        )
                        SummaryCard(
                            title: "Expense",
                            amount: viewModel.summary?.cashFlow.totalExpense ?? 0,
                            icon: "arrow.up.circle.fill",
                            gradient: [Color.rose, Color.red]
                        )
                    }
                    .padding(.horizontal)

                    // Recent transactions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Transactions")
                            .font(.headline)
                            .padding(.horizontal)

                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if viewModel.recentTransactions.isEmpty {
                            Text("No transactions yet.")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            ForEach(viewModel.recentTransactions) { tx in
                                TransactionRowView(transaction: tx)
                                    .padding(.horizontal)
                                Divider()
                                    .padding(.leading)
                            }
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .refreshable {
                await viewModel.load()
            }
            .task {
                await viewModel.load()
            }
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

struct BalanceCard: View {
    let balance: Double

    var body: some View {
        VStack(spacing: 8) {
            Text("Total Balance")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
            Text(balance.currencyFormatted)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
            Text(balance >= 0 ? "You're in the green!" : "Spending exceeds income")
                .font(.caption)
                .foregroundColor(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            LinearGradient(
                colors: [Color.indigo, Color.blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: Color.indigo.opacity(0.4), radius: 12, x: 0, y: 6)
    }
}

struct SummaryCard: View {
    let title: String
    let amount: Double
    let icon: String
    let gradient: [Color]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                Spacer()
            }
            Text(amount.currencyFormatted)
                .font(.title3.bold())
                .foregroundColor(.white)
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
        .cornerRadius(16)
        .shadow(color: gradient.first?.opacity(0.35) ?? .clear, radius: 8, x: 0, y: 4)
    }
}

struct TransactionRowView: View {
    let transaction: Transaction

    var isIncome: Bool { transaction.type == "INCOME" }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isIncome ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: isIncome ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .foregroundColor(isIncome ? .green : .rose)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.text)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                HStack(spacing: 4) {
                    if let cat = transaction.category {
                        Text(cat)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(transaction.date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text((isIncome ? "+" : "-") + transaction.amount.currencyFormatted)
                .font(.subheadline.bold())
                .foregroundColor(isIncome ? .green : .rose)
        }
        .padding(.vertical, 6)
    }
}

extension Double {
    var currencyFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: abs(self))) ?? "$\(String(format: "%.2f", abs(self)))"
    }
}

extension Color {
    static let rose = Color(red: 0.95, green: 0.15, blue: 0.35)
}
