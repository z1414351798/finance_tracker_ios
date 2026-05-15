import SwiftUI

struct RecurringView: View {
    @StateObject private var viewModel = RecurringViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.items.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "arrow.clockwise.circle")
                        .font(.system(size: 56))
                        .foregroundColor(.secondary)
                    Text("No recurring transactions")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Button("Add Recurring") {
                        viewModel.showAddSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.items) { item in
                        RecurringRowView(item: item) {
                            Task { await viewModel.toggle(item: item) }
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await viewModel.delete(item: item) }
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .background(Color(.systemGroupedBackground))
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Recurring")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { viewModel.showAddSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .sheet(isPresented: $viewModel.showAddSheet) {
            AddRecurringSheet(viewModel: viewModel)
        }
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

struct RecurringRowView: View {
    let item: RecurringTransaction
    let onToggle: () -> Void

    var isIncome: Bool { item.type == "INCOME" }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isIncome ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .frame(width: 46, height: 46)
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(isIncome ? .green : .rose)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline.bold())
                HStack(spacing: 6) {
                    FrequencyBadge(frequency: item.frequency)
                    Text(item.type.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let next = item.nextRunDate {
                    Text("Next: \(next)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("$\(String(format: "%.2f", item.amount))")
                    .font(.subheadline.bold())
                    .foregroundColor(isIncome ? .green : .rose)

                Toggle("", isOn: Binding<Bool>(
                    get: { item.active },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
                .tint(.indigo)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct FrequencyBadge: View {
    let frequency: String

    var color: Color {
        switch frequency {
        case "DAILY": return .orange
        case "WEEKLY": return .blue
        default: return .indigo
        }
    }

    var body: some View {
        Text(frequency.capitalized)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

struct AddRecurringSheet: View {
    @ObservedObject var viewModel: RecurringViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Type toggle
                    HStack(spacing: 0) {
                        TypeButton(
                            title: "EXPENSE",
                            icon: "arrow.up.circle.fill",
                            selected: viewModel.formType == "EXPENSE",
                            color: .rose
                        ) {
                            viewModel.switchFormType("EXPENSE")
                        }
                        TypeButton(
                            title: "INCOME",
                            icon: "arrow.down.circle.fill",
                            selected: viewModel.formType == "INCOME",
                            color: .green
                        ) {
                            viewModel.switchFormType("INCOME")
                        }
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Name
                    FormField(
                        label: "Name",
                        icon: "tag.fill",
                        placeholder: "Rent, Netflix...",
                        text: $viewModel.formName
                    )
                    .padding(.horizontal)

                    // Amount
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Amount", systemImage: "dollarsign.circle.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Text("$")
                                .font(.title3.bold())
                                .foregroundColor(.secondary)
                            TextField("0.00", text: $viewModel.formAmount)
                                .keyboardType(.decimalPad)
                                .font(.title3.bold())
                        }
                        .padding(14)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // Frequency
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Frequency", systemImage: "repeat")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("Frequency", selection: $viewModel.formFrequency) {
                            Text("Daily").tag("DAILY")
                            Text("Weekly").tag("WEEKLY")
                            Text("Monthly").tag("MONTHLY")
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal)

                    // Start Date
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Start Date", systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        DatePicker("", selection: $viewModel.formStartDate, displayedComponents: .date)
                            .labelsHidden()
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // Category
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Category", systemImage: "folder.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        if viewModel.formCategories.isEmpty {
                            ProgressView()
                                .padding(.horizontal)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(viewModel.formCategories) { cat in
                                        CategoryChip(
                                            name: cat.name,
                                            isSelected: viewModel.formCategoryId == cat.id
                                        ) {
                                            viewModel.formCategoryId = cat.id
                                            viewModel.formCategoryName = cat.name
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }

                    Button(action: { Task { await viewModel.saveRecurring() } }) {
                        Group {
                            if viewModel.isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Add Recurring")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(LinearGradient(colors: [.indigo, .blue], startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .disabled(viewModel.isSaving)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding(.top)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add Recurring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.resetForm()
                        dismiss()
                    }
                }
            }
            .task { await viewModel.loadCategories() }
        }
    }
}
