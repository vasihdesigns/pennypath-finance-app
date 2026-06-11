//
//  SageCoachView.swift
//  PennyPath
//
//  Sage reskin of Coach: a quiet header with the coach's green orb,
//  this week's headline insight as a feature card, then the rest of the
//  tips. Same on-device InsightsEngine — only the look changed.
//

import SwiftUI
import SwiftData

struct SageCoachView: View {
    @Query private var accounts: [Account]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var goals: [Goal]
    @Query private var budgets: [CategoryBudget]

    private var insights: [Insight] {
        InsightsEngine.generate(accounts: accounts, expenses: expenses, goals: goals, budgets: budgets)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                if let featured = insights.first {
                    VStack(alignment: .leading, spacing: 12) {
                        SageOverline(text: "This week's insight")
                        Text(featured.message)
                            .font(.sageDisplay(21, weight: .medium))
                            .foregroundStyle(Sage.ink)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(featured.title)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(featured.tint)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .sageCard(padding: 24)
                }

                if insights.count > 1 {
                    VStack(alignment: .leading, spacing: 12) {
                        SageOverline(text: "More from your coach")
                        VStack(spacing: 12) {
                            ForEach(insights.dropFirst()) { insight in
                                tipCard(insight)
                            }
                        }
                    }
                }

                privacyNote
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Sage.bg)
        .toolbar(.hidden, for: .navigationBar)
        .tint(Sage.green)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 16) {
            orb
            VStack(alignment: .leading, spacing: 2) {
                Text("Coach")
                    .font(.sageDisplay(28))
                    .foregroundStyle(Sage.ink)
                Text("Knows your full picture")
                    .font(.subheadline)
                    .foregroundStyle(Sage.inkSoft)
            }
            Spacer(minLength: 0)
        }
    }

    /// The coach's face: a soft green sphere.
    private var orb: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.adaptive(light: 0x8FBF9A, dark: 0xA8D2B3),
                        Color.adaptive(light: 0x3F6B4D, dark: 0x4E7F5E)
                    ],
                    center: .init(x: 0.32, y: 0.28),
                    startRadius: 2, endRadius: 48
                )
            )
            .frame(width: 54, height: 54)
            .shadow(color: Sage.green.opacity(0.35), radius: 10, y: 4)
    }

    // MARK: Tip cards

    private func tipCard(_ insight: Insight) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(insight.emoji)
                .font(.body)
                .frame(width: 36, height: 36)
                .background(insight.tint.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(insight.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Sage.ink)
                Text(insight.message)
                    .font(.footnote)
                    .foregroundStyle(Sage.inkSoft)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .sageCard(padding: 16)
    }

    private var privacyNote: some View {
        Text("🔒 Tips are made right here on your phone from your own numbers — they're never sent anywhere. (Only investment price lookups use the internet.)")
            .font(.caption)
            .foregroundStyle(Sage.inkFaint)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
    }
}
