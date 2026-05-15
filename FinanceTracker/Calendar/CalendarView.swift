import SwiftUI

struct CalendarReportView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var showDaySheet = false

    private let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Month navigation header
                    HStack {
                        Button(action: { viewModel.previousMonth() }) {
                            Image(systemName: "chevron.left")
                                .font(.title3.bold())
                                .foregroundColor(.indigo)
                        }
                        Spacer()
                        Text(monthFormatter.string(from: viewModel.displayMonth))
                            .font(.title2.bold())
                        Spacer()
                        Button(action: { viewModel.nextMonth() }) {
                            Image(systemName: "chevron.right")
                                .font(.title3.bold())
                                .foregroundColor(.indigo)
                        }
                    }
                    .padding(.horizontal)

                    // Weekday headers
                    HStack(spacing: 0) {
                        ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                            Text(LocalizedStringKey(day))
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 4)

                    // 6x7 grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
                        ForEach(0..<42, id: \.self) { i in
                            if let date = viewModel.calendarDates[i] {
                                let dateStr = viewModel.dateString(date)
                                let inc = viewModel.income(for: dateStr)
                                let exp = viewModel.expense(for: dateStr)
                                let isSelected = viewModel.selectedDate == dateStr
                                DayCell(date: date, income: inc, expense: exp, isSelected: isSelected)
                                    .onTapGesture {
                                        viewModel.selectedDate = dateStr
                                        showDaySheet = true
                                    }
                            } else {
                                Color.clear.frame(height: 56)
                            }
                        }
                    }
                    .padding(.horizontal, 4)

                    // Monthly totals summary card
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Income", systemImage: "arrow.down.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text("$\(viewModel.monthTotalIncome, specifier: "%.2f")")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Label("Expense", systemImage: "arrow.up.circle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text("$\(viewModel.monthTotalExpense, specifier: "%.2f")")
                                .font(.headline)
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)
                }
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Calendar")
            .task { await viewModel.loadMonth() }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(20)
                        .background(Color(.systemBackground).opacity(0.9))
                        .cornerRadius(12)
                }
            }
            .sheet(isPresented: $showDaySheet) {
                DayTransactionSheet(viewModel: viewModel, isPresented: $showDaySheet)
            }
        }
    }
}

// MARK: - DayCell

struct DayCell: View {
    let date: Date
    let income: Double
    let expense: Double
    let isSelected: Bool

    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f
    }()

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                if isToday {
                    Circle()
                        .fill(Color.indigo.opacity(0.15))
                        .frame(width: 28, height: 28)
                }
                Text(dayFormatter.string(from: date))
                    .font(isToday ? .subheadline.bold() : .subheadline)
                    .foregroundColor(isSelected ? .white : (isToday ? .indigo : .primary))
            }

            // Dots for income/expense
            HStack(spacing: 2) {
                if income > 0 {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 5, height: 5)
                }
                if expense > 0 {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 5, height: 5)
                }
            }
        }
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.indigo : Color.clear)
        )
    }
}

// MARK: - Day Transaction Sheet

struct DayTransactionSheet: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Binding var isPresented: Bool

    private let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    private var displayDate: String {
        guard let dateStr = viewModel.selectedDate,
              let date = DateFormatter().date(from: dateStr) else {
            return viewModel.selectedDate ?? ""
        }
        return displayFormatter.string(from: date)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.selectedTransactions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No transactions on this day")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.selectedTransactions) { tx in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tx.text)
                                    .font(.subheadline)
                                if let cat = tx.category, !cat.isEmpty {
                                    Text(cat)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Text(tx.type == "INCOME" ? "+$\(tx.amount, specifier: "%.2f")" : "-$\(tx.amount, specifier: "%.2f")")
                                .font(.subheadline.bold())
                                .foregroundColor(tx.type == "INCOME" ? .green : .red)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(viewModel.selectedDate ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { isPresented = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
