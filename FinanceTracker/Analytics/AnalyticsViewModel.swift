import Foundation
import SwiftUI

@MainActor
class AnalyticsViewModel: ObservableObject {
    @Published var summary: SummaryResponse? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var selectedChartType: String = "EXPENSE"

    var totalIncome: Double { summary?.cashFlow.totalIncome ?? 0 }
    var totalExpense: Double { summary?.cashFlow.totalExpense ?? 0 }

    var incomeCategories: [CategoryStat] { summary?.incomeCategories ?? [] }
    var expenseCategories: [CategoryStat] { summary?.expenseCategories ?? [] }

    var selectedCategories: [CategoryStat] {
        selectedChartType == "INCOME" ? incomeCategories : expenseCategories
    }

    var barData: [(label: String, income: Double, expense: Double)] {
        [("Current", totalIncome, totalExpense)]
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            summary = try await APIClient.shared.getSummary()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
