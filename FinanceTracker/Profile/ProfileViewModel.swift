import Foundation
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var email: String = ""
    @Published var avatarURL: String? = nil
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String? = nil
    @Published var successMessage: String? = nil

    // Change email
    @Published var newEmail: String = ""

    // Change password
    @Published var currentPassword: String = ""
    @Published var newPassword: String = ""
    @Published var confirmNewPassword: String = ""

    // Avatar
    @Published var avatarImage: UIImage? = nil

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let profile = try await APIClient.shared.getProfile()
            username = profile.username ?? ""
            email = profile.email ?? ""
            newEmail = profile.email ?? ""
            avatarURL = profile.presignedImageUrl
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func updateEmail() async {
        guard !newEmail.isEmpty else {
            errorMessage = "Email cannot be empty."
            return
        }
        isSaving = true
        errorMessage = nil
        do {
            try await APIClient.shared.updateProfile(email: newEmail)
            email = newEmail
            successMessage = "Email updated successfully."
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    func changePassword() async {
        guard !currentPassword.isEmpty else {
            errorMessage = "Please enter your current password."
            return
        }
        guard !newPassword.isEmpty else {
            errorMessage = "Please enter a new password."
            return
        }
        guard newPassword == confirmNewPassword else {
            errorMessage = "New passwords do not match."
            return
        }
        isSaving = true
        errorMessage = nil
        do {
            try await APIClient.shared.changePassword(currentPassword: currentPassword, newPassword: newPassword)
            currentPassword = ""
            newPassword = ""
            confirmNewPassword = ""
            successMessage = "Password changed successfully."
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    func uploadAvatar(image: UIImage) async {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        isSaving = true
        errorMessage = nil
        do {
            let resp = try await APIClient.shared.uploadAvatar(imageData: data)
            avatarURL = resp.presignedImageUrl
            avatarImage = image
            successMessage = "Avatar updated."
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
