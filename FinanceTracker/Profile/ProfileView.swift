import SwiftUI
import PhotosUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var languageManager: LanguageManager
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var showPasswordSection = false
    @State private var showEmailSection = false
    @State private var showDeleteConfirm = false
    @State private var isDeletingAccount = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Avatar section
                VStack(spacing: 14) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        ZStack(alignment: .bottomTrailing) {
                            Group {
                                if let img = viewModel.avatarImage {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else if let urlStr = viewModel.avatarURL, let url = URL(string: urlStr) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let img):
                                            img.resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .clipShape(Circle())
                                        default:
                                            defaultAvatar
                                        }
                                    }
                                } else {
                                    defaultAvatar
                                }
                            }

                            ZStack {
                                Circle()
                                    .fill(Color.indigo)
                                    .frame(width: 28, height: 28)
                                Image(systemName: "camera.fill")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .onChange(of: selectedPhoto) { item in
                        Task {
                            if let data = try? await item?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                await viewModel.uploadAvatar(image: uiImage)
                            }
                        }
                    }

                    Text(viewModel.username)
                        .font(.title2.bold())
                    Text(viewModel.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)

                // Sections
                VStack(spacing: 0) {
                    // Email section
                    DisclosureGroup(
                        isExpanded: $showEmailSection,
                        content: {
                            VStack(spacing: 14) {
                                ProfileTextField(
                                    label: "New Email",
                                    text: $viewModel.newEmail,
                                    icon: "envelope.fill",
                                    keyboardType: .emailAddress
                                )
                                Button(action: { Task { await viewModel.updateEmail() } }) {
                                    actionButtonLabel(title: "Update Email", isLoading: viewModel.isSaving)
                                }
                                .disabled(viewModel.isSaving)
                            }
                            .padding(.vertical, 10)
                        },
                        label: {
                            Label("Change Email", systemImage: "envelope.fill")
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                        }
                    )
                    .padding()
                    .background(Color(.systemBackground))

                    Divider()

                    // Password section
                    DisclosureGroup(
                        isExpanded: $showPasswordSection,
                        content: {
                            VStack(spacing: 14) {
                                ProfileTextField(
                                    label: "Current Password",
                                    text: $viewModel.currentPassword,
                                    icon: "lock.fill",
                                    isSecure: true
                                )
                                ProfileTextField(
                                    label: "New Password",
                                    text: $viewModel.newPassword,
                                    icon: "lock.fill",
                                    isSecure: true
                                )
                                ProfileTextField(
                                    label: "Confirm New Password",
                                    text: $viewModel.confirmNewPassword,
                                    icon: "lock.fill",
                                    isSecure: true
                                )
                                Button(action: { Task { await viewModel.changePassword() } }) {
                                    actionButtonLabel(title: "Change Password", isLoading: viewModel.isSaving)
                                }
                                .disabled(viewModel.isSaving)
                            }
                            .padding(.vertical, 10)
                        },
                        label: {
                            Label("Change Password", systemImage: "lock.fill")
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                        }
                    )
                    .padding()
                    .background(Color(.systemBackground))
                }
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                .padding(.horizontal)

                // Language Section
                VStack(spacing: 0) {
                    HStack {
                        Label("Language", systemImage: "globe")
                            .font(.subheadline.bold())
                        Spacer()
                        Picker("", selection: $languageManager.languageCode) {
                            Text("EN").tag("en")
                            Text("中文").tag("zh")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                }
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                .padding(.horizontal)

                // Privacy & Legal
                VStack(spacing: 0) {
                    NavigationLink(destination: PrivacyPolicyView()) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color(.systemBackground))

                    Divider()

                    Link(destination: URL(string: "https://www.wisefintrakr.com/terms")!) {
                        HStack {
                            Label("Terms of Service", systemImage: "doc.text.fill")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                    }
                }
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                .padding(.horizontal)

                // Logout
                Button(action: { authViewModel.logout() }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Logout")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(14)
                }
                .padding(.horizontal)

                // Delete Account
                Button(action: { showDeleteConfirm = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "trash.fill")
                        Text("Delete Account")
                            .fontWeight(.semibold)
                        if isDeletingAccount {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.62, green: 0.07, blue: 0.24)))
                                .scaleEffect(0.8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(red: 1.0, green: 0.94, blue: 0.95))
                    .foregroundColor(Color(red: 0.62, green: 0.07, blue: 0.24))
                    .cornerRadius(14)
                }
                .disabled(isDeletingAccount)
                .padding(.horizontal)
                .padding(.bottom, 20)
                .alert("Delete Account?", isPresented: $showDeleteConfirm) {
                    Button("Delete Forever", role: .destructive) {
                        Task {
                            isDeletingAccount = true
                            do {
                                try await APIClient.shared.deleteAccount()
                                authViewModel.logout()
                            } catch {
                                viewModel.errorMessage = "Failed to delete account: \(error.localizedDescription)"
                            }
                            isDeletingAccount = false
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("This will permanently delete your account, all transactions, categories, goals, and uploaded images. This cannot be undone.")
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Profile")
        .task { await viewModel.load() }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .padding(20)
                    .background(Color(.systemBackground).opacity(0.9))
                    .cornerRadius(12)
            }
        }
        .alert("Error", isPresented: Binding<Bool>(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Success", isPresented: Binding<Bool>(
            get: { viewModel.successMessage != nil },
            set: { if !$0 { viewModel.successMessage = nil } }
        )) {
            Button("OK") { viewModel.successMessage = nil }
        } message: {
            Text(viewModel.successMessage ?? "")
        }
    }

    var defaultAvatar: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [.indigo, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 100, height: 100)
            Image(systemName: "person.fill")
                .font(.system(size: 44))
                .foregroundColor(.white)
        }
    }

    @ViewBuilder
    func actionButtonLabel(title: String, isLoading: Bool) -> some View {
        Group {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text(title)
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(LinearGradient(colors: [.indigo, .blue], startPoint: .leading, endPoint: .trailing))
        .foregroundColor(.white)
        .cornerRadius(10)
    }
}

struct ProfileTextField: View {
    let label: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 18)
                if isSecure {
                    SecureField(label, text: $text)
                        .autocapitalization(.none)
                } else {
                    TextField(label, text: $text)
                        .keyboardType(keyboardType)
                        .autocapitalization(.none)
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}
