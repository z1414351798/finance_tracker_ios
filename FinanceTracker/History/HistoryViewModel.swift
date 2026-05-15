import Foundation
import SwiftUI

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String? = nil
    @Published var searchText: String = ""
    @Published var filterType: String = "ALL"
    @Published var totalPages: Int = 1

    private var currentPage = 0
    private var allTransactions: [Transaction] = []

    var filteredTransactions: [Transaction] {
        var result = allTransactions
        if !searchText.isEmpty {
            result = result.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
        }
        if filterType != "ALL" {
            result = result.filter { $0.type == filterType }
        }
        return result
    }

    func load() async {
        isLoading = true
        currentPage = 0
        errorMessage = nil
        do {
            let page = try await APIClient.shared.getHistory(page: 0, size: 20)
            allTransactions = page.content
            transactions = filteredTransactions
            totalPages = page.totalPages ?? 1
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadMore() async {
        guard currentPage + 1 < totalPages, !isLoadingMore else { return }
        isLoadingMore = true
        currentPage += 1
        do {
            let page = try await APIClient.shared.getHistory(page: currentPage, size: 20)
            allTransactions.append(contentsOf: page.content)
            transactions = filteredTransactions
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingMore = false
    }

    func delete(transaction: Transaction) async {
        guard let id = transaction.id else { return }
        do {
            try await APIClient.shared.deleteTransaction(id: id)
            allTransactions.removeAll { $0.id == id }
            transactions = filteredTransactions
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func applyFilters() {
        transactions = filteredTransactions
    }
}
