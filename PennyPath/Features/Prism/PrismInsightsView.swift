//
//  PrismInsightsView.swift
//  PennyPath
//
//  Prism reskin of Coach ("Insights"): this week's headline as a gradient
//  feature box, then the rest as clean neutral tips. Same on-device
//  InsightsEngine — only the look changed.
//

import SwiftUI
import SwiftData

struct PrismInsightsView: View {
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
                                .background(.white.opacity(0.18), in: Capsule())
                        }
                        Text(featured.message)
                            .font(.prismDisplay(19, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .prismGradientCard(Prism.chartGradient(0), padding: 18)
                }

                if insights.count > 1 {
                    PrismOverline(text: "More insights").padding(.top, 2)
                    ForEach(insights.dropFirst()) { insight in
                        tipCard(insight)
                    }
                }

                privacyNote
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(Prism.bg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .tint(Prism.accent)
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(Prism.accent, in: Circle())
                .shadow(color: Prism.accent.opacity(0.4), radius: 8, y: 3)
            VStack(alignment: .leading, spacing: 1) {
                Text("Insights")
                    .font(.prismDisplay(24)).foregroundStyle(Prism.ink)
                Text("Made from your own numbers")
                    .font(.system(.subheadline)).foregroundStyle(Prism.inkSoft)
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
                    .foregroundStyle(Prism.ink)
                Text(insight.message)
                    .font(.footnote)
                    .foregroundStyle(Prism.inkSoft)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .prismSurfaceCard(padding: 16)
    }

    private var privacyNote: some View {
        Text("🔒 Tips are made right here on your phone from your own numbers — they're never sent anywhere. (Only investment price lookups use the internet.)")
            .font(.caption)
            .foregroundStyle(Prism.inkFaint)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
    }
}
