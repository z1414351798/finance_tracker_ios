import Foundation
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var summary: SummaryResponse? = nil
    @Published var recentTransactions: [Transaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<21: return "Good Evening"
        default: return "Good Night"
        }
    }

    var totalBalance: Double {
        guard let s = summary else { return 0 }
        return (s.cashFlow.totalIncome ?? 0) - (s.cashFlow.totalExpense ?? 0)
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            async let summaryResult = APIClient.shared.getSummary()
            async let historyResult = APIClient.shared.getHistory(page: 0, size: 5)
            let (s, h) = try await (summaryResult, historyResult)
            summary = s
            recentTransactions = h.content
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
