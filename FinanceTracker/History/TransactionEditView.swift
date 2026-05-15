import SwiftUI
import PhotosUI

struct TransactionEditView: View {
    @StateObject private var viewModel: TransactionEditViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var showFullImage = false

    init(transaction: Transaction) {
        _viewModel = StateObject(wrappedValue: TransactionEditViewModel(transaction: transaction))
    }

    var isIncome: Bool { viewModel.type == "INCOME" }
    let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // ── Receipt Image ──────────────────────────────────────
                    receiptSection

                    // ── Type Toggle ────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Type", systemImage: "arrow.left.arrow.right")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)

                        HStack(spacing: 0) {
                            ForEach(["EXPENSE", "INCOME"], id: \.self) { t in
                                Button {
                                    viewModel.type = t
                                    viewModel.categoryId = nil
                                    viewModel.selectedCategoryName = ""
                                    Task { await viewModel.loadCategories() }
                                } label: {
                                    Text(t.capitalized)
                                        .font(.subheadline.bold())
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(viewModel.type == t
                                            ? (t == "INCOME" ? Color.green : Color.red)
                                            : Color(.systemGray5))
                                        .foregroundColor(viewModel.type == t ? .white : .primary)
                                }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .editCard()

                    // ── Amount ─────────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Amount", systemImage: "dollarsign.circle")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        HStack {
                            Text("$")
                                .font(.title2.bold())
                                .foregroundColor(isIncome ? .green : .red)
                            TextField("0.00", text: $viewModel.amount)
                                .font(.title2.bold())
                                .keyboardType(.decimalPad)
                                .foregroundColor(isIncome ? .green : .red)
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    .editCard()

                    // ── Description ────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Description", systemImage: "text.alignleft")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        TextField("What is this for?", text: $viewModel.text)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .editCard()

                    // ── Date ───────────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Date", systemImage: "calendar")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(.indigo)
                    }
                    .editCard()

                    // ── Category ───────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Category", systemImage: "tag")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)

                        if viewModel.categories.isEmpty {
                            Text("No categories")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 8) {
                                ForEach(viewModel.categories) { cat in
                                    let isSelected = viewModel.categoryId == cat.id
                                    Button {
                                        viewModel.categoryId = isSelected ? nil : cat.id
                                        viewModel.selectedCategoryName = isSelected ? "" : cat.name
                                    } label: {
                                        Text(cat.name)
                                            .font(.caption.bold())
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 7)
                                            .frame(maxWidth: .infinity)
                                            .background(isSelected ? Color.indigo : Color(.systemGray6))
                                            .foregroundColor(isSelected ? .white : .primary)
                                            .cornerRadius(10)
                                    }
                                }
                            }
                        }
                    }
                    .editCard()

                    // ── Note ───────────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Note", systemImage: "note.text")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        TextField("Add a note...", text: $viewModel.note, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .editCard()

                    // ── Save Button ────────────────────────────────────────
                    Button {
                        Task { await viewModel.save() }
                    } label: {
                        Group {
                            if viewModel.isSaving || viewModel.isUploadingImage {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Save Changes")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [.indigo, .blue],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .disabled(viewModel.isSaving || viewModel.isUploadingImage)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
                .padding(.top, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task { await viewModel.loadCategories() }
            .onChange(of: viewModel.savedSuccessfully) { success in
                if success { dismiss() }
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            // Full-screen image viewer
            .fullScreenCover(isPresented: $showFullImage) {
                FullImageViewer(
                    imageURL: viewModel.existingImageURL,
                    imageData: viewModel.newImageData
                )
            }
        }
    }

    // MARK: - Receipt Section

    @ViewBuilder
    var receiptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Receipt Photo", systemImage: "photo")
                .font(.caption.bold())
                .foregroundColor(.secondary)

            // Show existing or newly picked image
            if let data = viewModel.newImageData, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(12)
                    .onTapGesture { showFullImage = true }
                    .overlay(alignment: .topTrailing) { imageActionButtons }

            } else if let urlStr = viewModel.existingImageURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(12)
                            .onTapGesture { showFullImage = true }
                    case .empty:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .frame(height: 200)
                            .overlay(ProgressView())
                    default:
                        photoPickerPlaceholder
                    }
                }
                .overlay(alignment: .topTrailing) { imageActionButtons }

            } else {
                photoPickerPlaceholder
            }
        }
        .editCard()
        .onChange(of: selectedPhoto) { item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    viewModel.newImageData = data
                }
            }
        }
    }

    var imageActionButtons: some View {
        HStack(spacing: 8) {
            // Replace photo
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption.bold())
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            // Expand
            Button { showFullImage = true } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.caption.bold())
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
        .padding(8)
    }

    var photoPickerPlaceholder: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            VStack(spacing: 8) {
                Image(systemName: "plus.rectangle.on.folder")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)
                Text("Tap to attach photo")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - Full-screen image viewer

struct FullImageViewer: View {
    let imageURL: String?
    let imageData: Data?
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            if let data = imageData, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .gesture(MagnificationGesture()
                        .onChanged { scale = $0 }
                        .onEnded { _ in withAnimation { scale = max(1, scale) } }
                    )
            } else if let urlStr = imageURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                            .gesture(MagnificationGesture()
                                .onChanged { scale = $0 }
                                .onEnded { _ in withAnimation { scale = max(1, scale) } }
                            )
                    case .empty:
                        ProgressView().tint(.white)
                    default:
                        Image(systemName: "photo").foregroundColor(.white).font(.largeTitle)
                    }
                }
            }

            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
            }
        }
        .onTapGesture(count: 2) {
            withAnimation { scale = scale > 1.5 ? 1.0 : 2.5 }
        }
    }
}

// MARK: - View Modifier helper

private extension View {
    func editCard() -> some View {
        self
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
            .padding(.horizontal)
    }
}
