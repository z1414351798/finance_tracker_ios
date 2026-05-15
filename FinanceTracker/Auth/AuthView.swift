import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isSignUp = false
    @State private var username = ""
    @State private var password = ""
    @State private var email = ""
    @State private var confirmPassword = ""

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.indigo, Color.blue.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 40)

                    // Logo / Title
                    VStack(spacing: 8) {
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.white)
                        Text("FinanceTracker")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        Text("Smart money management")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    // Card
                    VStack(spacing: 20) {
                        // Toggle
                        HStack {
                            Button(action: { withAnimation { isSignUp = false } }) {
                                Text("Login")
                                    .fontWeight(isSignUp ? .regular : .bold)
                                    .foregroundColor(isSignUp ? .secondary : .indigo)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(isSignUp ? Color.clear : Color.indigo.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            Button(action: { withAnimation { isSignUp = true } }) {
                                Text("Sign Up")
                                    .fontWeight(isSignUp ? .bold : .regular)
                                    .foregroundColor(isSignUp ? .indigo : .secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(isSignUp ? Color.indigo.opacity(0.1) : Color.clear)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(4)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                        // Fields
                        VStack(spacing: 16) {
                            AuthTextField(
                                placeholder: "Username",
                                text: $username,
                                systemImage: "person.fill"
                            )

                            if isSignUp {
                                AuthTextField(
                                    placeholder: "Email",
                                    text: $email,
                                    systemImage: "envelope.fill",
                                    keyboardType: .emailAddress
                                )
                            }

                            AuthTextField(
                                placeholder: "Password",
                                text: $password,
                                systemImage: "lock.fill",
                                isSecure: true
                            )

                            if isSignUp {
                                AuthTextField(
                                    placeholder: "Confirm Password",
                                    text: $confirmPassword,
                                    systemImage: "lock.fill",
                                    isSecure: true
                                )
                            }
                        }

                        // Error
                        if let error = authViewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }

                        // Action button
                        Button(action: {
                            Task {
                                if isSignUp {
                                    if password != confirmPassword {
                                        authViewModel.errorMessage = "Passwords do not match."
                                        return
                                    }
                                    await authViewModel.signup(username: username, password: password, email: email)
                                } else {
                                    await authViewModel.login(username: username, password: password)
                                }
                            }
                        }) {
                            Group {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(colors: [Color.indigo, Color.blue], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(authViewModel.isLoading)
                    }
                    .padding(24)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                    .padding(.horizontal, 24)

                    Spacer(minLength: 40)
                }
            }
        }
    }
}

struct AuthTextField: View {
    let placeholder: String
    @Binding var text: String
    let systemImage: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundColor(.secondary)
                .frame(width: 20)
            if isSecure {
                SecureField(placeholder, text: $text)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
        }
        .padding(14)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
