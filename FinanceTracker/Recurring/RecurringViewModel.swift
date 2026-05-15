import Foundation
import SwiftUI

@MainActor
class RecurringViewModel: ObservableObject {
    @Published var items: [RecurringTransaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var showAddSheet = false

    // Form fields for adding new recurring transaction
    @Published var formName = ""
    @Published var formAmount = ""
    @Published var formType = "EXPENSE"
    @Published var formFrequency = "MONTHLY"
    @Published var formStartDate = Date()
    @Published var formCategoryId: Int64? = nil
    @Published var formCategoryName = ""
    @Published var formCategories: [Category] = []
    @Published var isSaving = false

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            items = try await APIClient.shared.getRecurring()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func toggle(item: RecurringTransaction) async {
        guard let id = item.id else { return }
        do {
            let updated = try await APIClient.shared.toggleRecurring(id: id)
            if let idx = items.firstIndex(where: { $0.id == id }) {
                items[idx] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(item: RecurringTransaction) async {
        guard let id = item.id else { return }
        do {
            try await APIClient.shared.deleteRecurring(id: id)
            items.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadCategories() async {
        do {
            formCategories = try await APIClient.shared.getCategories(type: formType)
            if let first = formCategories.first, formCategoryId == nil {
                formCategoryId = first.id
                formCategoryName = first.name
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func switchFormType(_ newType: String) {
        formType = newType
        formCategoryId = nil
        formCategoryName = ""
        formCategories = []
        Task { await loadCategories() }
    }

    func saveRecurring() async {
        guard !formName.isEmpty else {
            errorMessage = "Please enter a name."
            return
        }
        guard let amt = Double(formAmount), amt > 0 else {
            errorMessage = "Please enter a valid amount."
            return
        }

        isSaving = true
        errorMessage = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let startDateStr = formatter.string(from: formStartDate)

        let rt = RecurringTransaction(
            id: nil,
            name: formName,
            amount: amt,
            type: formType,
            frequency: formFrequency,
            startDate: startDateStr,
            nextRunDate: nil,
            active: true,
            categoryId: formCategoryId
        )

        do {
            let saved = try await APIClient.shared.addRecurring(rt)
            items.insert(saved, at: 0)
            resetForm()
            showAddSheet = false
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    func resetForm() {
        formName = ""
        formAmount = ""
        formType = "EXPENSE"
        formFrequency = "MONTHLY"
        formStartDate = Date()
        formCategoryId = nil
        formCategoryName = ""
        formCategories = []
    }
}
