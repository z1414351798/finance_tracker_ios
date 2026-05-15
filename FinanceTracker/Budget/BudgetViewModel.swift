import Foundation
import SwiftUI

struct BudgetItem: Codable, Identifiable {
    var id: String { category }
    var category: String
    var limit: Double
}

@MainActor
class BudgetViewModel: ObservableObject {
    @Published var budgets: [BudgetItem] = []
    @Published var currentExpenses: [String: Double] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let defaultsKey = "budgets"

    var totalBudgeted: Double {
        budgets.reduce(0) { $0 + $1.limit }
    }

    var totalSpent: Double {
        budgets.reduce(0) { $0 + (currentExpenses[$1.category] ?? 0) }
    }

    init() {
        loadFromDefaults()
    }

    // MARK: - Persistence

    private func loadFromDefaults() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([BudgetItem].self, from: data) else { return }
        budgets = decoded
    }

    private func saveToDefaults() {
        if let data = try? JSONEncoder().encode(budgets) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    // MARK: - Network

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let summary = try await APIClient.shared.getSummary()
            var expenses: [String: Double] = [:]
            for stat in summary.expenseCategories {
                expenses[stat.name] = stat.value
            }
            currentExpenses = expenses
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Budget Management

    func addBudget(category: String, limit: Double) {
        let trimmed = category.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, limit > 0 else { return }
        if let idx = budgets.firstIndex(where: { $0.category == trimmed }) {
            budgets[idx].limit = limit
        } else {
            budgets.append(BudgetItem(category: trimmed, limit: limit))
        }
        saveToDefaults()
    }

    func deleteBudget(category: String) {
        budgets.removeAll { $0.category == category }
        saveToDefaults()
    }

    func deleteBudgets(at offsets: IndexSet) {
        budgets.remove(atOffsets: offsets)
        saveToDefaults()
    }
}
