import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()

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

struct HistoryRowView: View {
    let transaction: Transaction

    var isIncome: Bool { transaction.type == "INCOME" }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isIncome ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .frame(width: 46, height: 46)
                Image(systemName: isIncome ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .foregroundColor(isIncome ? .green : .rose)
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
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.indigo.opacity(0.1))
                            .foregroundColor(.indigo)
                            .cornerRadius(8)
                    }
                    Text(transaction.date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let note = transaction.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text((isIncome ? "+" : "-") + "$" + String(format: "%.2f", transaction.amount))
                    .font(.subheadline.bold())
                    .foregroundColor(isIncome ? .green : .rose)

                if let urlStr = transaction.presignedImageUrl ?? transaction.imageUrl,
                   let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable()
                                .scaledToFill()
                                .frame(width: 36, height: 36)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        case .failure:
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                                .frame(width: 36, height: 36)
                        case .empty:
                            ProgressView()
                                .frame(width: 36, height: 36)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}
