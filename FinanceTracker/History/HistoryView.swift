import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var csvShareItem: ShareableCSV? = nil
    @State private var isExporting = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search & Filter bar
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search transactions...", text: $viewModel.searchText)
                            .onChange(of: viewModel.searchText) { _ in
                                viewModel.applyFilters()
                            }
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    // Filter pills
                    HStack(spacing: 10) {
                        ForEach(["ALL", "INCOME", "EXPENSE"], id: \.self) { type in
                            Button(action: {
                                viewModel.filterType = type
                                viewModel.applyFilters()
                            }) {
                                Text(type.capitalized)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(viewModel.filterType == type ? Color.indigo : Color(.systemGray6))
                                    .foregroundColor(viewModel.filterType == type ? .white : .primary)
                                    .cornerRadius(16)
                            }
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))

                Divider()

                // Transaction list
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading...")
                    Spacer()
                } else if viewModel.filteredTransactions.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No transactions found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.filteredTransactions) { tx in
                            NavigationLink(destination: TransactionEditView(transaction: tx)
                                .onDisappear { Task { await viewModel.load() } }
                            ) {
                                HistoryRowView(transaction: tx)
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task { await viewModel.delete(transaction: tx) }
                                } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                }
                            }
                            .onAppear {
                                if tx.id == viewModel.filteredTransactions.last?.id {
                                    Task { await viewModel.loadMore() }
                                }
                            }
                        }
                        if viewModel.isLoadingMore {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            isExporting = true
                            do {
                                let data = try await APIClient.shared.exportTransactionsCsv()
                                csvShareItem = ShareableCSV(data: data)
                            } catch {
                                viewModel.errorMessage = "Export failed: \(error.localizedDescription)"
                            }
                            isExporting = false
                        }
                    } label: {
                        if isExporting {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
            .sheet(item: $csvShareItem) { item in
                ShareSheet(activityItems: [item.url])
            }
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
            .alert("Error", isPresented: Binding<Bool>(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

// MARK: - Helpers

struct ShareableCSV: Identifiable {
    let id = UUID()
    let data: Data
    var url: URL {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("transactions_\(Date().timeIntervalSince1970).csv")
        try? data.write(to: tmp)
        return tmp
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}

struct HistoryRowView: View {
    let transaction: Transaction
    @State private var flipped = false
    @State private var degrees: Double = 0

    var isIncome: Bool { transaction.type == "INCOME" }

    var body: some View {
        ZStack {
            if degrees < 90 {
                frontFace
            } else {
                backFace
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 80)
        .rotation3DEffect(.degrees(degrees), axis: (x: 0, y: 1, z: 0))
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: degrees)
        .onTapGesture {
            degrees = flipped ? 0 : 180
            flipped.toggle()
        }
    }

    // MARK: Front
    var frontFace: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isIncome ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .frame(width: 46, height: 46)
                Image(systemName: isIncome ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .foregroundColor(isIncome ? .green : Color(red: 0.93, green: 0.24, blue: 0.24))
                    .font(.title3)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.text)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if let cat = transaction.category {
                        Text(cat)
                            .font(.caption)
                            .padding(.horizontal, 8).padding(.vertical, 2)
                            .background(Color.indigo.opacity(0.1))
                            .foregroundColor(.indigo)
                            .cornerRadius(8)
                    }
                    Text(transaction.date)
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text((isIncome ? "+" : "-") + "$" + String(format: "%.2f", abs(transaction.amount)))
                    .font(.subheadline.bold())
                    .foregroundColor(isIncome ? .green : Color(red: 0.93, green: 0.24, blue: 0.24))
                Image(systemName: "arrow.left.and.right")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.5))
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }

    // MARK: Back
    var backFace: some View {
        HStack(spacing: 14) {
            // Receipt thumbnail or placeholder
            Group {
                if let urlStr = transaction.presignedImageUrl ?? transaction.imageUrl,
                   let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2)))
                        default:
                            receiptPlaceholder
                        }
                    }
                } else {
                    receiptPlaceholder
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("NOTE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.45))
                    .tracking(1.5)
                Text(transaction.note?.isEmpty == false ? transaction.note! : "No note added")
                    .font(.subheadline)
                    .foregroundColor(transaction.note?.isEmpty == false ? .white : .white.opacity(0.35))
                    .lineLimit(3)
                    .italic(transaction.note?.isEmpty != false)
            }
            Spacer()
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color(red: 0.09, green: 0.12, blue: 0.20), Color(red: 0.05, green: 0.07, blue: 0.14)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
    }

    var receiptPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.08))
                .frame(width: 56, height: 56)
            Image(systemName: "doc.text")
                .foregroundColor(.white.opacity(0.25))
                .font(.title3)
        }
    }
}
