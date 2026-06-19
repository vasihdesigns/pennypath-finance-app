//
//  StrataCoachView.swift
//  PennyPath
//
//  Strata reskin of Coach ("Insights"): this week's headline as a feature
//  card, then the rest of the tips. Same on-device InsightsEngine — only
//  the look changed.
//

import SwiftUI
import SwiftData

struct StrataCoachView: View {
    @Query private var accounts: [Account]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var goals: [Goal]
    @Query private var budgets: [CategoryBudget]

    private var insights: [Insight] {
        InsightsEngine.generate(accounts: accounts, expenses: expenses, goals: goals, budgets: budgets)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if let featured = insights.first {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Text(featured.emoji).font(.title2)
                            Text(featured.title)
                                .font(.system(.footnote).weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.vertical, 5).padding(.horizontal, 11)
                                .background(featured.tint, in: Capsule())
                        }
                        Text(featured.message)
                            .font(.strataDisplay(19, weight: .semibold))
                            .foregroundStyle(Strata.ink)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .strataCard(padding: 18)
                }

                if insights.count > 1 {
                    StrataOverline(text: "More insights").padding(.top, 2)
                    ForEach(insights.dropFirst()) { insight in
                        tipCard(insight)
                    }
                }

                privacyNote
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Strata.bg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .tint(Strata.bg)
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Strata.bg)
                .frame(width: 46, height: 46)
                .background(.white, in: Circle())
                .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
            VStack(alignment: .leading, spacing: 1) {
                Text("Insights")
                    .font(.strataDisplay(22)).foregroundStyle(Strata.onBrand)
                Text("Made from your own numbers")
                    .font(.system(.subheadline)).foregroundStyle(Strata.onBrandSoft)
            }
            Spacer(minLength: 0)
        }
    }

    private func tipCard(_ insight: Insight) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(insight.emoji)
                .font(.body)
                .frame(width: 38, height: 38)
                .background(insight.tint.opacity(0.14), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(insight.title)
                    .font(.system(.subheadline).weight(.bold))
                    .foregroundStyle(Strata.ink)
                Text(insight.message)
                    .font(.footnote)
                    .foregroundStyle(Strata.inkSoft)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .strataCard(padding: 16)
    }

    private var privacyNote: some View {
        Text("🔒 Tips are made right here on your phone from your own numbers — they're never sent anywhere. (Only investment price lookups use the internet.)")
            .font(.caption)
            .foregroundStyle(Strata.onBrandSoft)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
    }
}
