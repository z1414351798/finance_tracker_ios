import Foundation
import SwiftUI

@MainActor
class RecordViewModel: ObservableObject {
    @Published var type: String = "EXPENSE"
    @Published var amount: String = ""
    @Published var name: String = ""
    @Published var note: String = ""
    @Published var date: Date = Date()
    @Published var selectedCategoryId: Int64? = nil
    @Published var selectedCategoryName: String = ""
    @Published var receiptImage: UIImage? = nil
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var isSaved = false
    @Published var errorMessage: String? = nil

    func loadCategories() async {
        do {
            categories = try await APIClient.shared.getCategories(type: type)
            if let first = categories.first, selectedCategoryId == nil {
                selectedCategoryId = first.id
                selectedCategoryName = first.name
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func switchType(_ newType: String) {
        type = newType
        selectedCategoryId = nil
        selectedCategoryName = ""
        categories = []
        Task { await loadCategories() }
    }

    func save() async {
        guard let amt = Double(amount), amt > 0 else {
            errorMessage = "Please enter a valid amount."
            return
        }
        guard !name.isEmpty else {
            errorMessage = "Please enter a transaction name."
            return
        }
        guard let catId = selectedCategoryId else {
            errorMessage = "Please select a category."
            return
        }

        isLoading = true
        errorMessage = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        let tx = Transaction(
            id: nil,
            text: name,
            amount: amt,
            type: type,
            category: selectedCategoryName,
            categoryId: catId,
            date: dateString,
            note: note.isEmpty ? nil : note,
            imageUrl: nil,
            presignedImageUrl: nil
        )

        do {
            let saved = try await APIClient.shared.addTransaction(tx)
            // If there's a receipt image and the transaction has an id, upload it
            if let image = receiptImage, let txId = saved.id {
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    _ = try? await APIClient.shared.uploadTransactionImage(id: txId, imageData: imageData)
                }
            }
            isSaved = true
            resetForm()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func resetForm() {
        amount = ""
        name = ""
        note = ""
        date = Date()
        receiptImage = nil
        selectedCategoryId = nil
        selectedCategoryName = ""
        type = "EXPENSE"
    }
}
