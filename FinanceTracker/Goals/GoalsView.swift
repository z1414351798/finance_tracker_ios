import SwiftUI

struct GoalsView: View {
    @StateObject private var viewModel = GoalsViewModel()
    @State private var showAddSheet = false
    @State private var selectedGoal: SavingsGoal? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.goals.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "target")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("No savings goals yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Tap + to create your first savings goal.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(viewModel.goals) { goal in
                                GoalCard(goal: goal)
                                    .padding(.horizontal)
                                    .onTapGesture {
                                        selectedGoal = goal
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            viewModel.deleteGoal(id: goal.id)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.indigo)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddGoalSheet(viewModel: viewModel)
            }
            .sheet(item: $selectedGoal) { goal in
                ContributionSheet(viewModel: viewModel, goal: goal)
            }
        }
    }
}

// MARK: - Goal Card

struct GoalCard: View {
    let goal: SavingsGoal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(goal.emoji)
                    .font(.title)
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(goal.name)
                            .font(.headline)
                        if goal.isCompleted {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                                .font(.subheadline)
                        }
                    }
                    Text("\(Int(goal.progress * 100))% complete")
                        .font(.caption)
                        .foregroundColor(goal.isCompleted ? .green : .secondary)
                }
                Spacer()
                if !goal.isCompleted {
                    Text("Tap to add")
                        .font(.caption2)
                        .foregroundColor(.indigo)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 12)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(goal.isCompleted ? Color.green : Color.indigo)
                        .frame(width: geo.size.width * goal.progress, height: 12)
                }
            }
            .frame(height: 12)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Saved")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(goal.savedAmount.currencyFormatted)
                        .font(.subheadline.bold())
                        .foregroundColor(goal.isCompleted ? .green : .primary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Target")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(goal.targetAmount.currencyFormatted)
                        .font(.subheadline.bold())
                }
            }
        }
        .padding()
        .background(
            goal.isCompleted
                ? Color.green.opacity(0.08)
                : Color(.systemBackground)
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(goal.isCompleted ? Color.green.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Add Goal Sheet

struct AddGoalSheet: View {
    @ObservedObject var viewModel: GoalsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var targetText = ""
    @State private var selectedEmoji = "💰"

    let emojiOptions = ["🏠", "✈️", "🚗", "💻", "💰", "🎓", "💍", "🏋️"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Name") {
                    TextField("e.g. New Car, Vacation, Emergency Fund", text: $name)
                        .autocorrectionDisabled()
                }
                Section("Target Amount") {
                    TextField("Amount", text: $targetText)
                        .keyboardType(.decimalPad)
                }
                Section("Pick an Emoji") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(emojiOptions, id: \.self) { emoji in
                                Text(emoji)
                                    .font(.largeTitle)
                                    .padding(10)
                                    .background(
                                        selectedEmoji == emoji
                                            ? Color.indigo.opacity(0.15)
                                            : Color.clear
                                    )
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedEmoji == emoji ? Color.indigo : Color.clear, lineWidth: 2)
                                    )
                                    .onTapGesture {
                                        selectedEmoji = emoji
                                    }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let target = Double(targetText) {
                            viewModel.addGoal(name: name, targetAmount: target, emoji: selectedEmoji)
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || Double(targetText) == nil)
                }
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Contribution Sheet

struct ContributionSheet: View {
    @ObservedObject var viewModel: GoalsViewModel
    let goal: SavingsGoal
    @Environment(\.dismiss) private var dismiss

    @State private var amountText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(goal.emoji).font(.title)
                        VStack(alignment: .leading) {
                            Text(goal.name).font(.headline)
                            Text("\(goal.savedAmount.currencyFormatted) / \(goal.targetAmount.currencyFormatted)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Section("Add Contribution") {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Savings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let amount = Double(amountText) {
                            viewModel.addContribution(goalId: goal.id, amount: amount)
                            dismiss()
                        }
                    }
                    .disabled(Double(amountText) == nil)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
