//
//  VividCoachView.swift
//  PennyPath
//
//  Vivid reskin of Coach: a violet orb header, this week's headline insight
//  as a bold feature card, then the rest of the tips. Same on-device
//  InsightsEngine — only the look changed.
//

import SwiftUI
import SwiftData

struct VividCoachView: View {
    @Query private var accounts: [Account]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var goals: [Goal]
    @Query private var budgets: [CategoryBudget]

    private var insights: [Insight] {
        InsightsEngine.generate(accounts: accounts, expenses: expenses, goals: goals, budgets: budgets)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                if let featured = insights.first {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 10) {
                            Text(featured.emoji).font(.title2)
                            Text(featured.title)
                                .font(.system(.footnote, design: .rounded).weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 12)
                                .background(featured.tint, in: Capsule())
                        }
                        Text(featured.message)
                            .font(.vividDisplay(21, weight: .semibold))
                            .foregroundStyle(Vivid.ink)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .vividCard(padding: 22)
                }

                if insights.count > 1 {
                    VStack(alignment: .leading, spacing: 12) {
                        VividOverline(text: "More from your coach")
                        VStack(spacing: 12) {
                            ForEach(insights.dropFirst()) { insight in
                                tipCard(insight)
                            }
                        }
                    }
                }

                privacyNote
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Vivid.bg)
        .toolbar(.hidden, for: .navigationBar)
        .tint(Vivid.violet)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 16) {
            orb
            VStack(alignment: .leading, spacing: 2) {
                Text("Coach")
                    .font(.vividDisplay(26))
                    .foregroundStyle(Vivid.ink)
                Text("Knows your full picture")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Vivid.inkSoft)
            }
            Spacer(minLength: 0)
        }
    }

    /// The coach's face: a glowing violet sphere.
    private var orb: some View {
        ZStack {
            Circle()
                .fill(Vivid.brandGradient)
                .frame(width: 54, height: 54)
                .shadow(color: Vivid.violet.opacity(0.45), radius: 10, y: 4)
            Image(systemName: "sparkles")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    // MARK: Tip cards

    private func tipCard(_ insight: Insight) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(insight.emoji)
                .font(.body)
                .frame(width: 40, height: 40)
                .background(insight.tint.opacity(0.14), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(insight.title)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(Vivid.ink)
                Text(insight.message)
                    .font(.footnote)
                    .foregroundStyle(Vivid.inkSoft)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .vividCard(padding: 16)
    }

    private var privacyNote: some View {
        Text("🔒 Tips are made right here on your phone from your own numbers — they're never sent anywhere. (Only investment price lookups use the internet.)")
            .font(.caption)
            .foregroundStyle(Vivid.inkFaint)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
    }
}
