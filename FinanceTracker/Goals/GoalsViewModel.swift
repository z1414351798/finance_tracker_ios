import Foundation
import SwiftUI

struct SavingsGoal: Codable, Identifiable {
    var id: UUID
    var name: String
    var targetAmount: Double
    var savedAmount: Double
    var emoji: String
    var createdAt: Date

    var progress: Double { min(savedAmount / targetAmount, 1.0) }
    var isCompleted: Bool { savedAmount >= targetAmount }
}

@MainActor
class GoalsViewModel: ObservableObject {
    @Published var goals: [SavingsGoal] = []

    private let defaultsKey = "savings_goals"

    init() {
        loadFromDefaults()
    }

    // MARK: - Persistence

    private func loadFromDefaults() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([SavingsGoal].self, from: data) {
            goals = decoded
        }
    }

    private func saveToDefaults() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(goals) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    // MARK: - Goal Management

    func addGoal(name: String, targetAmount: Double, emoji: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, targetAmount > 0 else { return }
        let goal = SavingsGoal(
            id: UUID(),
            name: trimmed,
            targetAmount: targetAmount,
            savedAmount: 0,
            emoji: emoji,
            createdAt: Date()
        )
        goals.append(goal)
        saveToDefaults()
    }

    func addContribution(goalId: UUID, amount: Double) {
        guard amount > 0, let idx = goals.firstIndex(where: { $0.id == goalId }) else { return }
        goals[idx].savedAmount += amount
        saveToDefaults()
    }

    func deleteGoal(id: UUID) {
        goals.removeAll { $0.id == id }
        saveToDefaults()
    }

    func deleteGoals(at offsets: IndexSet) {
        goals.remove(atOffsets: offsets)
        saveToDefaults()
    }
}
