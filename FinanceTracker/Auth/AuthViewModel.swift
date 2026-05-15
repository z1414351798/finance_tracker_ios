import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    init() {
        isLoggedIn = APIClient.shared.token != nil
    }

    func login(username: String, password: String) async {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter username and password."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let token = try await APIClient.shared.login(username: username, password: password)
            APIClient.shared.token = token
            isLoggedIn = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signup(username: String, password: String, email: String) async {
        guard !username.isEmpty, !password.isEmpty, !email.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await APIClient.shared.signup(username: username, password: password, email: email)
            // After signup, auto-login
            let token = try await APIClient.shared.login(username: username, password: password)
            APIClient.shared.token = token
            isLoggedIn = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func logout() {
        APIClient.shared.token = nil
        isLoggedIn = false
    }
}
