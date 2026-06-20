//
//  GoalDetailView.swift
//  PennyPath
//
//  One goal up close: a big ring, a pacing tip, and buttons to add or take out money.
//

import SwiftUI
import SwiftData

struct GoalDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var goal: Goal

    /// Which way the update-savings sheet should open.
    private enum ContributeMode: String, Identifiable {
        case add, withdraw
        var id: String { rawValue }
    }

    @State private var showingEdit = false
    @State private var contribute: ContributeMode?

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Space.lg) {
                ringCard
                if let monthly = goal.suggestedMonthly, let date = goal.targetDate {
                    paceCard(monthly: monthly, date: date)
                }
                actions
            }
            .padding(Theme.Space.lg)
        }
        .background(Theme.background)
        .navigationTitle(goal.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) { GoalFormView(goal: goal) }
        .sheet(item: $contribute) { mode in
            GoalContributeView(goal: goal, startAdding: mode == .add)
        }
        .tint(Theme.gold)
    }

    private var ringCard: some View {
        VStack(spacing: Theme.Space.lg) {
            ZStack {
                ProgressRing(value: goal.progress, tint: goal.isComplete ? Theme.green : Theme.gold, lineWidth: 16)
                VStack(spacing: 2) {
                    Text(goal.emoji).font(.system(size: 40))
                    Text(percentText(goal.progress))
                        .font(.amount(26))
                        .foregroundStyle(Theme.ink)
                }
            }
            .frame(width: 180, height: 180)
            .padding(.top, Theme.Space.sm)

            VStack(spacing: 4) {
                Text("\(money(goal.savedAmount)) of \(money(goal.targetAmount))")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                if goal.isComplete {
                    Text("Goal reached — amazing! 🎉")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.green)
                } else {
                    Text("\(money(goal.remaining)) to go")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .card(padding: Theme.Space.xl)
    }

    private func paceCard(monthly: Double, date: Date) -> some View {
        HStack(spacing: Theme.Space.md) {
            EmojiBadge(emoji: "🧭", tint: Theme.gold, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text("Save \(money(monthly)) a month")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                Text("to reach this by \(date.monthYear)")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer(minLength: 0)
        }
        .card()
    }

    private var actions: some View {
        VStack(spacing: Theme.Space.md) {
            Button {
                contribute = .add
            } label: {
                Label("Add money", systemImage: "plus")
            }
            .buttonStyle(PrimaryButtonStyle(tint: Theme.gold, foreground: .white))

            if goal.savedAmount > 0 {
                Button("Take some out") { contribute = .withdraw }
                    .buttonStyle(SoftButtonStyle(tint: Theme.ink))
            }
        }
    }
}

// MARK: - Add / remove money sheet

struct GoalContributeView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var goal: Goal

    @State private var amount: Double = 0
    @State private var isAdding: Bool
    @FocusState private var amountFocused: Bool

    init(goal: Goal, startAdding: Bool = true) {
        _goal = Bindable(goal)
        _isAdding = State(initialValue: startAdding)
    }

    private var canSave: Bool { amount > 0 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("", selection: $isAdding) {
                        Text("Add money").tag(true)
                        Text("Take out").tag(false)
                    }
                    .pickerStyle(.segmented)

                    amountHero

                    Text("Saved now: \(money(goal.savedAmount)) of \(money(goal.targetAmount))")
                        .font(.footnote)
                        .foregroundStyle(Spectrum.onCanvasSoft)

                    Text("Goal savings are their own tally — this doesn't move money in or out of your accounts.")
                        .font(.caption)
                        .foregroundStyle(Spectrum.onCanvasSoft.opacity(0.8))
                        .multilineTextAlignment(.center)

                    saveButton
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
            .background(Spectrum.canvas.ignoresSafeArea())
            .navigationTitle("Update savings")
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
    }

    private var amountHero: some View {
        VStack(spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(AppSettings.currencySymbol)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Spectrum.onCanvasSoft)
                TextField("0", value: $amount, format: .number.precision(.fractionLength(0...2)))
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(Spectrum.onCanvas)
                    .keyboardType(.decimalPad)
                    .focused($amountFocused)
                    .fixedSize()
            }
            .fixedSize()
            .frame(maxWidth: .infinity)

            Text(isAdding ? "Add to \(goal.name)" : "Take out of \(goal.name)")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Spectrum.onCanvasSoft)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 26)
        .frame(maxWidth: .infinity)
        .spectrumPanel(padding: 0)
    }

    private var saveButton: some View {
        Button { apply() } label: {
            Text(isAdding ? "Add money" : "Take out")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Spectrum.plusInk)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(canSave ? Spectrum.plus : Spectrum.plus.opacity(0.4), in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
    }

    private func apply() {
        if isAdding {
            goal.savedAmount += amount
        } else {
            goal.savedAmount = max(0, goal.savedAmount - amount)
        }
        dismiss()
    }
}
