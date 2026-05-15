import SwiftUI
import PhotosUI

@MainActor
class TransactionEditViewModel: ObservableObject {
    // Editable fields
    @Published var text: String
    @Published var amount: String
    @Published var type: String
    @Published var date: Date
    @Published var note: String
    @Published var categoryId: Int64?
    @Published var selectedCategoryName: String

    // Receipt image
    @Published var existingImageURL: String?
    @Published var newImageData: Data? = nil
    @Published var showFullImage = false

    // Categories
    @Published var categories: [Category] = []

    // State
    @Published var isSaving = false
    @Published var isUploadingImage = false
    @Published var errorMessage: String? = nil
    @Published var savedSuccessfully = false

    private var originalTransaction: Transaction

    init(transaction: Transaction) {
        self.originalTransaction = transaction
        self.text = transaction.text
        self.amount = String(format: "%.2f", abs(transaction.amount))
        self.type = transaction.type
        self.note = transaction.note ?? ""
        self.categoryId = transaction.categoryId
        self.selectedCategoryName = transaction.category ?? ""
        self.existingImageURL = transaction.presignedImageUrl ?? transaction.imageUrl

        // Parse date string → Date
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        self.date = df.date(from: transaction.date) ?? Date()
    }

    func loadCategories() async {
        do {
            categories = try await APIClient.shared.getCategories(type: type)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save() async {
        isSaving = true
        errorMessage = nil
        do {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            let finalAmount = type == "EXPENSE" ? -abs(Double(amount) ?? 0) : abs(Double(amount) ?? 0)

            var updated = originalTransaction
            updated.text = text
            updated.amount = finalAmount
            updated.type = type
            updated.date = df.string(from: date)
            updated.note = note.isEmpty ? nil : note
            updated.categoryId = categoryId

            try await APIClient.shared.updateTransaction(updated)

            // Upload new image if picked
            if let imgData = newImageData, let id = updated.id {
                isUploadingImage = true
                let result = try await APIClient.shared.uploadTransactionImage(id: id, imageData: imgData)
                existingImageURL = result.presignedImageUrl ?? result.imageUrl
                newImageData = nil
                isUploadingImage = false
            }

            originalTransaction = updated
            savedSuccessfully = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
