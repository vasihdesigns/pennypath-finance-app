//
//  ClarityAdviceView.swift
//  PennyPath
//
//  The full coach, pushed from Today's note. Same on-device
//  InsightsEngine, presented as a quiet reading list. Coaching doesn't
//  need a tab of its own — that's part of Clarity's decluttering.
//

import SwiftUI
import SwiftData

struct ClarityAdviceView: View {
    @Query private var accounts: [Account]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var goals: [Goal]
    @Query private var budgets: [CategoryBudget]

    // Same default as ClarityRootView — the two must never disagree.
    @AppStorage("clarityDidOnboard") private var didOnboard = false

    private var insights: [Insight] {
        InsightsEngine.generate(accounts: accounts, expenses: expenses,
                                goals: goals, budgets: budgets)
    }

    /// Map the engine's tones onto Clarity's quiet palette.
    private func tint(for insight: Insight) -> Color {
        switch insight.tone {
        case .positive: return Clarity.good
        case .warning: return Clarity.rust
        case .tip: return Clarity.amber
        case .neutral: return Clarity.cobalt
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    ClarityOverline(text: "Advice")
                    Text("Notes from\nyour numbers.")
                        .font(.clarityDisplay(26))
                        .foregroundStyle(Clarity.ink)
                        .lineSpacing(3)
                }

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(insights.enumerated()), id: \.element.id) { index, insight in
                        adviceRow(insight)
                        if index < insights.count - 1 { ClarityRule() }
                    }
                }

                privacyNote
                replayButton
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(Clarity.paper)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Clarity.cobalt)
    }

    private func adviceRow(_ insight: Insight) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text(insight.emoji).font(.footnote)
                Text(insight.title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(tint(for: insight))
            }
            Text(insight.message)
                .font(.callout)
                .foregroundStyle(Clarity.ink)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 14)
    }

    private var privacyNote: some View {
        Text("Made on your phone from your own numbers — never sent anywhere. Only investment price lookups use the internet.")
            .font(.caption)
            .foregroundStyle(Clarity.inkFaint)
            .lineSpacing(2)
    }

    private var replayButton: some View {
        Button {
            Haptics.tap()
            withAnimation(.easeInOut(duration: 0.4)) { didOnboard = false }
        } label: {
            Label("Replay the Clarity intro", systemImage: "play.rectangle")
                .font(.footnote.weight(.medium))
                .foregroundStyle(Clarity.inkSoft)
        }
        .buttonStyle(.plain)
    }
}
