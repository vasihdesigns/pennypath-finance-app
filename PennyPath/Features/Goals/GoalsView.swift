//
//  GoalsView.swift
//  PennyPath
//
//  The GOLD pillar. Things you're saving toward, with a bar that fills as you go.
//

import SwiftUI
import SwiftData

struct GoalsView: View {
    @Query(sort: \Goal.createdAt, order: .forward) private var goals: [Goal]
    @State private var showingAdd = false

    private var totalSaved: Double { goals.reduce(0) { $0 + $1.savedAmount } }
    private var totalTarget: Double { goals.reduce(0) { $0 + $1.targetAmount } }
    private var overallProgress: Double {
        totalTarget > 0 ? min(1, totalSaved / totalTarget) : 0
    }

    var body: some View {
        ScrollView {
            if goals.isEmpty {
                EmptyState(
                    emoji: "🎯",
                    title: "Set your first goal",
                    message: "Pick something you'd love to save for — a bike, a trip, a rainy-day fund — and watch the gold bar fill up.",
                    actionTitle: "Add a goal",
                    tint: Theme.gold
                ) { showingAdd = true }
            } else {
                VStack(spacing: Theme.Space.lg) {
                    summaryCard
                    VStack(spacing: Theme.Space.md) {
                        ForEach(goals) { goal in
                            NavigationLink {
                                GoalDetailView(goal: goal)
                            } label: {
                                GoalCard(goal: goal)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(Theme.Space.lg)
            }
        }
        .background(Theme.background)
        .navigationTitle("Goals")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAdd) { GoalFormView() }
        .tint(Theme.gold)
    }

    private var summaryCard: some View {
        HStack(spacing: Theme.Space.lg) {
            ZStack {
                ProgressRing(value: overallProgress, tint: Theme.gold, lineWidth: 10)
                Text(percentText(overallProgress))
                    .font(.amount(16))
                    .foregroundStyle(Theme.ink)
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 3) {
                Text("Saved so far")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.inkSecondary)
                Text(money(totalSaved))
                    .font(.amount(28))
                    .foregroundStyle(Theme.gold)
                Text("of \(money(totalTarget)) across \(goals.count) goal\(goals.count == 1 ? "" : "s")")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkTertiary)
            }
            Spacer(minLength: 0)
        }
        .card(padding: Theme.Space.xl)
    }
}

struct GoalCard: View {
    let goal: Goal

    var body: some View {
        VStack(spacing: Theme.Space.md) {
            HStack(spacing: Theme.Space.md) {
                EmojiBadge(emoji: goal.emoji, tint: Theme.gold)
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.name)
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    if let date = goal.targetDate {
                        Text("by \(date.monthYear)")
                            .font(.caption)
                            .foregroundStyle(Theme.inkSecondary)
                    }
                }
                Spacer(minLength: Theme.Space.sm)
                Text(goal.isComplete ? "Done 🎉" : percentText(goal.progress))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(goal.isComplete ? Theme.green : Theme.gold)
            }

            ProgressBar(value: goal.progress, tint: goal.isComplete ? Theme.green : Theme.gold)

            HStack {
                Text("\(money(goal.savedAmount)) of \(money(goal.targetAmount))")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
                Spacer()
                if !goal.isComplete {
                    Text("\(money(goal.remaining)) to go")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.inkTertiary)
                }
            }
        }
        .card()
    }
}
