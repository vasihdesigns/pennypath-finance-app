//
//  SummitInsightsView.swift
//  PennyPath
//
//  Summit's AI Insights screen: this week's headline as a feature card, then
//  the rest of the tips. Same on-device InsightsEngine — nothing leaves the
//  phone. Each insight is tappable and jumps to the tab it's about, so a tip
//  is a starting point, not a dead end.
//

import SwiftUI
import SwiftData

struct SummitInsightsView: View {
    /// Lets an insight send the user to the screen it's about.
    var selectTab: (SummitTab) -> Void

    @Query private var accounts: [Account]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var goals: [Goal]
    @Query private var budgets: [CategoryBudget]

    @State private var showingSettings = false

    private var insights: [Insight] {
        InsightsEngine.generate(accounts: accounts, expenses: expenses, goals: goals, budgets: budgets)
    }

    private func tint(for insight: Insight) -> Color {
        switch insight.tone {
        case .positive: return Summit.accent
        case .warning:  return Summit.down
        case .tip:      return Summit.gold
        case .neutral:  return Summit.inkSoft
        }
    }

    /// Best guess at the screen an insight is about, from its wording.
    private func destination(for insight: Insight) -> SummitTab {
        let text = (insight.title + " " + insight.message).lowercased()
        if text.contains("goal") || text.contains("save for")
            || text.contains("saved up") || text.contains("set aside") {
            return .goals
        }
        if text.contains("net worth") || text.contains("owe")
            || text.contains("rainy-day") || text.contains("cash and savings") {
            return .worth
        }
        return .spend   // spending, budget, pace, categories
    }

    private func destinationLabel(_ tab: SummitTab) -> String {
        switch tab {
        case .worth:    return "View net worth"
        case .spend:    return "View spending"
        case .goals:    return "View goals"
        case .insights: return "View"
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let featured = insights.first {
                    featuredCard(featured)
                }
                if insights.count > 1 {
                    SummitOverline(text: "More insights").padding(.top, 4)
                    ForEach(insights.dropFirst()) { insight in
                        tipCard(insight)
                    }
                }
                privacyNote
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .background(Summit.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) {
            SummitTopBar(title: "AI Insights",
                         onSettings: { showingSettings = true })
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 10)
                .background(Summit.canvas)
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .tint(Summit.accent)
    }

    private func featuredCard(_ insight: Insight) -> some View {
        let dest = destination(for: insight)
        return Button {
            Haptics.tap()
            selectTab(dest)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Text(insight.emoji).font(.title2)
                    Text(insight.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 5).padding(.horizontal, 11)
                        .background(tint(for: insight), in: Capsule())
                }
                Text(insight.message)
                    .font(.summitSerif(19, weight: .regular))
                    .foregroundStyle(Summit.ink)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 4) {
                    Text(destinationLabel(dest))
                        .font(.summitText(13, weight: .semibold))
                    Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(Summit.accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .summitCard(padding: 18)
        }
        .buttonStyle(.plain)
    }

    private func tipCard(_ insight: Insight) -> some View {
        Button {
            Haptics.tap()
            selectTab(destination(for: insight))
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Text(insight.emoji)
                    .font(.body)
                    .frame(width: 38, height: 38)
                    .background(tint(for: insight).opacity(0.14), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(insight.title)
                        .font(.summitText(15, weight: .semibold))
                        .foregroundStyle(Summit.ink)
                    Text(insight.message)
                        .font(.summitText(13))
                        .foregroundStyle(Summit.inkSoft)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Summit.inkFaint)
            }
            .summitCard(padding: 16)
        }
        .buttonStyle(.plain)
    }

    private var privacyNote: some View {
        Text("🔒 Made right here on your phone from your own numbers — never sent anywhere. (Only investment price lookups use the internet.)")
            .font(.summitText(12))
            .foregroundStyle(Summit.inkFaint)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
    }
}
