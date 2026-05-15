import SwiftUI

struct BudgetView: View {
    @StateObject private var viewModel = BudgetViewModel()
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Overall summary
                    BudgetSummaryCard(
                        totalBudgeted: viewModel.totalBudgeted,
                        totalSpent: viewModel.totalSpent
                    )
                    .padding(.horizontal)

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if viewModel.budgets.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.pie")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("No budgets yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Tap + to set a monthly spending limit per category.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.budgets) { item in
                                BudgetRowCard(
                                    item: item,
                                    spent: viewModel.currentExpenses[item.category] ?? 0
                                )
                                .padding(.horizontal)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        viewModel.deleteBudget(category: item.category)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Budget")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.indigo)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddBudgetSheet(viewModel: viewModel)
            }
            .task {
                await viewModel.load()
            }
            .refreshable {
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

// MARK: - Summary Card

struct BudgetSummaryCard: View {
    let totalBudgeted: Double
    let totalSpent: Double

    var overBudget: Bool { totalSpent > totalBudgeted && totalBudgeted > 0 }

    var body: some View {
        VStack(spacing: 8) {
            Text("Monthly Overview")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text(totalBudgeted.currencyFormatted)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("Budgeted")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.75))
                }
                VStack(spacing: 4) {
                    Text(totalSpent.currencyFormatted)
                        .font(.title2.bold())
                        .foregroundColor(overBudget ? Color.yellow : .white)
                    Text("Spent")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.75))
                }
                VStack(spacing: 4) {
                    Text(max(totalBudgeted - totalSpent, 0).currencyFormatted)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("Remaining")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.75))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal)
        .background(
            LinearGradient(
                colors: overBudget ? [Color.red, Color.rose] : [Color.indigo, Color.blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: Color.indigo.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Budget Row Card

struct BudgetRowCard: View {
    let item: BudgetItem
    let spent: Double

    var progress: Double {
        guard item.limit > 0 else { return 0 }
        return min(spent / item.limit, 1.0)
    }

    var isOver: Bool { spent > item.limit }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(item.category)
                    .font(.subheadline.bold())
                Spacer()
                Text(isOver ? "Over budget!" : "\(Int(progress * 100))%")
                    .font(.caption.bold())
                    .foregroundColor(isOver ? .red : .secondary)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isOver ? Color.red : Color.green)
                        .frame(width: geo.size.width * progress, height: 10)
                }
            }
            .frame(height: 10)

            HStack {
                Text("Spent: \(spent.currencyFormatted)")
                    .font(.caption)
                    .foregroundColor(isOver ? .red : .green)
                Spacer()
                Text("Limit: \(item.limit.currencyFormatted)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Add Budget Sheet

struct AddBudgetSheet: View {
    @ObservedObject var viewModel: BudgetViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var category = ""
    @State private var limitText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    TextField("e.g. Food, Transport, Entertainment", text: $category)
                        .autocorrectionDisabled()
                }
                Section("Monthly Limit") {
                    TextField("Amount", text: $limitText)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("New Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let limit = Double(limitText) {
                            viewModel.addBudget(category: category, limit: limit)
                            dismiss()
                        }
                    }
                    .disabled(category.trimmingCharacters(in: .whitespaces).isEmpty || Double(limitText) == nil)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
