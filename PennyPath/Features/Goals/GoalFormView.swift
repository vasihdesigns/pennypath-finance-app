//
//  GoalFormView.swift
//  PennyPath
//
//  Add or edit a savings goal.
//

import SwiftUI
import SwiftData

struct GoalFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var goal: Goal?

    @State private var name = ""
    @State private var emoji = "⭐️"
    @State private var target: Double = 0
    @State private var hasDate = false
    @State private var targetDate = Date.now.adding(months: 6)

    private let emojiChoices = ["⭐️", "🚲", "🎮", "✈️", "🏠", "📱", "🎁", "🐷",
                                "💻", "🎧", "📚", "🚗", "💍", "🏝️", "🎸", "👟"]

    private var isEditing: Bool { goal != nil }
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && target > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Space.lg) {
                    AmountField(title: "How much do you need?", amount: $target, tint: Theme.gold)
                        .card(padding: Theme.Space.xl)

                    FieldCard(label: "What are you saving for?") {
                        TextField("e.g. New bike", text: $name)
                            .textInputAutocapitalization(.words)
                    }

                    FieldCard(label: "Pick an icon") {
                        emojiPicker
                    }

                    FieldCard(label: "Target date") {
                        VStack(spacing: Theme.Space.sm) {
                            Toggle("Aim for a date", isOn: $hasDate)
                                .tint(Theme.gold)
                            if hasDate {
                                DatePicker("", selection: $targetDate, in: Date.now..., displayedComponents: .date)
                                    .labelsHidden()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }

                    if isEditing {
                        Button("Delete goal", role: .destructive) { deleteGoal() }
                            .buttonStyle(SoftButtonStyle(tint: Theme.red))
                    }
                }
                .padding(Theme.Space.lg)
            }
            .background(Theme.background)
            .navigationTitle(isEditing ? "Edit goal" : "New goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.bold().disabled(!canSave)
                }
            }
            .tint(Theme.gold)
        }
        .onAppear(perform: load)
    }

    private var emojiPicker: some View {
        let columns = [GridItem(.adaptive(minimum: 52), spacing: Theme.Space.sm)]
        return LazyVGrid(columns: columns, spacing: Theme.Space.sm) {
            ForEach(emojiChoices, id: \.self) { choice in
                let selected = choice == emoji
                Button { emoji = choice } label: {
                    Text(choice)
                        .font(.system(size: 26))
                        .frame(width: 52, height: 52)
                        .background(selected ? Theme.gold.opacity(0.18) : Theme.well,
                                    in: RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous)
                                .strokeBorder(selected ? Theme.gold : .clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func load() {
        guard let goal else { return }
        name = goal.name
        emoji = goal.emoji
        target = goal.targetAmount
        if let date = goal.targetDate {
            hasDate = true
            targetDate = date
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let date = hasDate ? targetDate : nil
        if let goal {
            goal.name = trimmed
            goal.emoji = emoji
            goal.targetAmount = max(0, target)
            goal.targetDate = date
        } else {
            context.insert(Goal(name: trimmed, emoji: emoji, targetAmount: target, targetDate: date))
        }
        dismiss()
    }

    private func deleteGoal() {
        if let goal { context.delete(goal) }
        dismiss()
    }
}
