//
//  GoalFormView.swift
//  PennyPath
//
//  Add or edit a savings goal. Styled to the Spectrum brand (flat canvas,
//  smoked-glass panels, an amount hero and a capsule CTA) so the Goals tab's
//  "+" opens a form that matches Add Item and Add Account — not the legacy
//  gold theme it grew out of.
//

import SwiftUI
import SwiftData

struct GoalFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    var goal: Goal?

    @State private var name = ""
    @State private var emoji = "⭐️"
    @State private var target: Double = 0
    @State private var hasDate = false
    @State private var targetDate = Date.now.adding(months: 6)
    @FocusState private var amountFocused: Bool

    private let emojiChoices = ["⭐️", "🚲", "🎮", "✈️", "🏠", "📱", "🎁", "🐷",
                                "💻", "🎧", "📚", "🚗", "💍", "🏝️", "🎸", "👟"]

    private var isEditing: Bool { goal != nil }
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && target > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    amountHero

                    labeled("What are you saving for?") {
                        TextField("e.g. New bike", text: $name)
                            .textInputAutocapitalization(.words)
                            .foregroundStyle(Spectrum.onCanvas)
                    }

                    labeled("Pick an icon") {
                        emojiPicker
                    }

                    labeled("Target date") {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: $hasDate.animation(.snappy)) {
                                Text("Aim for a date")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Spectrum.onCanvas)
                            }
                            .tint(Spectrum.accent)
                            if hasDate {
                                DatePicker("", selection: $targetDate, in: Date.now...,
                                           displayedComponents: .date)
                                    .labelsHidden()
                                    .tint(Spectrum.accent)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }

                    if isEditing { deleteButton }
                    saveButton
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
            .background(Spectrum.canvas.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit goal" : "New goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { amountFocused = false }.bold()
                }
            }
            .tint(Spectrum.accent)
        }
        .onAppear(perform: load)
    }

    // MARK: Amount hero — the target, in the app's base currency

    private var amountHero: some View {
        VStack(spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(AppSettings.currencySymbol)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Spectrum.onCanvasSoft)
                TextField("0", value: $target, format: .number.precision(.fractionLength(0...2)))
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(Spectrum.onCanvas)
                    .keyboardType(.decimalPad)
                    .focused($amountFocused)
                    .fixedSize()
            }
            .fixedSize()
            .frame(maxWidth: .infinity)

            Text("How much do you need?")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Spectrum.onCanvasSoft)
        }
        .padding(.vertical, 26)
        .frame(maxWidth: .infinity)
        .spectrumPanel(padding: 0)
    }

    private var emojiPicker: some View {
        let columns = [GridItem(.adaptive(minimum: 52), spacing: 10)]
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(emojiChoices, id: \.self) { choice in
                let selected = choice == emoji
                Button {
                    Haptics.tap()
                    emoji = choice
                } label: {
                    Text(choice)
                        .font(.system(size: 26))
                        .frame(width: 52, height: 52)
                        .background(selected ? Spectrum.accent.opacity(0.18)
                                             : Spectrum.glassFill(dark: scheme == .dark),
                                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(selected ? Spectrum.accent
                                                       : Spectrum.glassStroke(dark: scheme == .dark),
                                              lineWidth: selected ? 2 : 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            deleteGoal()
        } label: {
            Text("Delete goal")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Spectrum.spend)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Spectrum.spend.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var saveButton: some View {
        Button { save() } label: {
            Text(isEditing ? "Save changes" : "Add goal")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Spectrum.plusInk)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(canSave ? Spectrum.plus : Spectrum.plus.opacity(0.4), in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
    }

    // MARK: Titled smoked-glass panel (matches Add Item / Add Account)

    private func labeled<Content: View>(_ title: String,
                                        @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Spectrum.onCanvasSoft)
                .tracking(0.5)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .spectrumPanel(padding: 0)
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
        Haptics.success()
        dismiss()
    }

    private func deleteGoal() {
        if let goal { context.delete(goal) }
        dismiss()
    }
}
