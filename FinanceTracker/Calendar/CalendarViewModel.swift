import SwiftUI

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var displayMonth: Date = {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: Date())
        return cal.date(from: comps) ?? Date()
    }()
    @Published var transactionsByDate: [String: [Transaction]] = [:]
    @Published var selectedDate: String? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    func loadMonth() async {
        isLoading = true
        errorMessage = nil
        do {
            let page = try await APIClient.shared.getHistory(page: 0, size: 200)
            let cal = Calendar.current
            let monthStart = displayMonth
            let monthEnd = cal.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!

            var dict: [String: [Transaction]] = [:]
            for tx in page.content {
                guard let txDate = dateFormatter.date(from: tx.date) else { continue }
                if txDate >= monthStart && txDate <= monthEnd {
                    var arr = dict[tx.date] ?? []
                    arr.append(tx)
                    dict[tx.date] = arr
                }
            }
            transactionsByDate = dict
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func previousMonth() {
        displayMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayMonth)!
        Task { await loadMonth() }
    }

    func nextMonth() {
        displayMonth = Calendar.current.date(byAdding: .month, value: +1, to: displayMonth)!
        Task { await loadMonth() }
    }

    var calendarDates: [Date?] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: displayMonth) else { return [] }

        // Get weekday of the 1st (Sun=1, Mon=2, ...)
        let weekdayOfFirst = cal.component(.weekday, from: displayMonth)
        let leadingNils = weekdayOfFirst - 1  // Sunday = index 0

        var dates: [Date?] = Array(repeating: nil, count: leadingNils)
        for day in range {
            let date = cal.date(byAdding: .day, value: day - 1, to: displayMonth)
            dates.append(date)
        }
        // Pad to 42
        while dates.count < 42 {
            dates.append(nil)
        }
        return dates
    }

    var selectedTransactions: [Transaction] {
        guard let d = selectedDate else { return [] }
        return transactionsByDate[d] ?? []
    }

    func income(for dateStr: String) -> Double {
        (transactionsByDate[dateStr] ?? [])
            .filter { $0.type == "INCOME" }
            .reduce(0) { $0 + $1.amount }
    }

    func expense(for dateStr: String) -> Double {
        (transactionsByDate[dateStr] ?? [])
            .filter { $0.type == "EXPENSE" }
            .reduce(0) { $0 + $1.amount }
    }

    func dateString(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    var monthTotalIncome: Double {
        transactionsByDate.values.flatMap { $0 }.filter { $0.type == "INCOME" }.reduce(0) { $0 + $1.amount }
    }

    var monthTotalExpense: Double {
        transactionsByDate.values.flatMap { $0 }.filter { $0.type == "EXPENSE" }.reduce(0) { $0 + $1.amount }
    }
}
