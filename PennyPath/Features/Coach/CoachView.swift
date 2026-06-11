//
//  CoachView.swift
//  PennyPath
//
//  The AI coach tab: a friendly header plus a stack of personalized tip cards.
//

import SwiftUI
import SwiftData

struct CoachView: View {
    @Query private var accounts: [Account]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var goals: [Goal]
    @Query private var budgets: [CategoryBudget]

    private var insights: [Insight] {
        InsightsEngine.generate(accounts: accounts, expenses: expenses, goals: goals, budgets: budgets)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Space.lg) {
                hero
                ForEach(insights) { InsightCard(insight: $0) }
                privacyNote
            }
            .padding(Theme.Space.lg)
        }
        .background(Theme.background)
        .navigationTitle("Coach")
    }

    private var hero: some View {
        HStack(spacing: Theme.Space.md) {
            EmojiBadge(emoji: "✨", tint: Theme.gold, size: 52)
            VStack(alignment: .leading, spacing: 3) {
                Text("Your money coach")
                    .font(.display(20))
                    .foregroundStyle(Theme.ink)
                Text("\(InsightsEngine.greeting())! Here's what I'm noticing.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer(minLength: 0)
        }
        .card()
    }

    private var privacyNote: some View {
        Text("🔒 Tips are made right here on your phone from your own numbers — they're never sent anywhere. (Only investment price lookups use the internet.)")
            .font(.caption)
            .foregroundStyle(Theme.inkTertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Theme.Space.lg)
            .padding(.top, Theme.Space.xs)
    }
}

struct InsightCard: View {
    let insight: Insight

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Space.md) {
            EmojiBadge(emoji: insight.emoji, tint: insight.tint, size: 46)
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text(insight.message)
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .card()
        .overlay(alignment: .leading) {
            Capsule()
                .fill(insight.tint)
                .frame(width: 4)
                .padding(.vertical, Theme.Space.md)
        }
    }
}
