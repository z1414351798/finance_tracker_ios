import SwiftUI
import PhotosUI

struct RecordView: View {
    @StateObject private var viewModel = RecordViewModel()
    @State private var selectedPhoto: PhotosPickerItem? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Type Toggle
                    HStack(spacing: 0) {
                        TypeButton(
                            title: "EXPENSE",
                            icon: "arrow.up.circle.fill",
                            selected: viewModel.type == "EXPENSE",
                            color: .rose
                        ) {
                            viewModel.switchType("EXPENSE")
                        }
                        TypeButton(
                            title: "INCOME",
                            icon: "arrow.down.circle.fill",
                            selected: viewModel.type == "INCOME",
                            color: .green
                        ) {
                            viewModel.switchType("INCOME")
                        }
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Amount
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Amount", systemImage: "dollarsign.circle.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Text("$")
                                .font(.title2.bold())
                                .foregroundColor(.secondary)
                            TextField("0.00", text: $viewModel.amount)
                                .keyboardType(.decimalPad)
                                .font(.title2.bold())
                        }
                        .padding(14)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // Name
                    FormField(
                        label: "Transaction Name",
                        icon: "tag.fill",
                        placeholder: "e.g. Coffee, Salary...",
                        text: $viewModel.name
                    )
                    .padding(.horizontal)

                    // Note
                    FormField(
                        label: "Note (optional)",
                        icon: "note.text",
                        placeholder: "Add a note...",
                        text: $viewModel.note
                    )
                    .padding(.horizontal)

                    // Date
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Date", systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                            .labelsHidden()
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // Categories
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Category", systemImage: "folder.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        if viewModel.categories.isEmpty {
                            ProgressView()
                                .padding(.horizontal)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(viewModel.categories) { cat in
                                        CategoryChip(
                                            name: cat.name,
                                            isSelected: viewModel.selectedCategoryId == cat.id
                                        ) {
                                            viewModel.selectedCategoryId = cat.id
                                            viewModel.selectedCategoryName = cat.name
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Receipt Photo
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Receipt Photo (optional)", systemImage: "photo.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            HStack {
                                if let image = viewModel.receiptImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    Text("Change photo")
                                        .font(.subheadline)
                                        .foregroundColor(.indigo)
                                } else {
                                    Image(systemName: "camera.fill")
                                        .font(.title3)
                                        .foregroundColor(.indigo)
                                    Text("Add receipt photo")
                                        .font(.subheadline)
                                        .foregroundColor(.indigo)
                                }
                                Spacer()
                            }
                            .padding(14)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .onChange(of: selectedPhoto) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    viewModel.receiptImage = uiImage
                                }
                            }
                        }
                    }

                    // Error
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }

                    // Save Button
                    Button(action: { Task { await viewModel.save() } }) {
                        Group {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Save Transaction")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            viewModel.type == "INCOME"
                                ? LinearGradient(colors: [.green, .teal], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [.rose, .red], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .disabled(viewModel.isLoading)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding(.top)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Record")
            .task {
                await viewModel.loadCategories()
            }
            .alert("Transaction Saved!", isPresented: $viewModel.isSaved) {
                Button("OK") { viewModel.isSaved = false }
            } message: {
                Text("Your transaction has been recorded successfully.")
            }
        }
    }
}

struct TypeButton: View {
    let title: String
    let icon: String
    let selected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selected ? color : Color.clear)
            .foregroundColor(selected ? .white : .secondary)
            .cornerRadius(10)
        }
        .padding(4)
    }
}

struct FormField: View {
    let label: String
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            TextField(placeholder, text: $text)
                .padding(14)
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }
}

struct CategoryChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.indigo : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}
