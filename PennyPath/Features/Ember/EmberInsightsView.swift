//
//  EmberInsightsView.swift
//  PennyPath
//
//  Ember's Insights screen: this week's headline as a feature card, then the
//  rest of the tips. Same on-device InsightsEngine the app has always used —
//  nothing leaves the phone. Each tip is tappable and jumps to the tab it's
//  about, so an insight is a starting point, not a dead end.
//

import SwiftUI
import SwiftData

struct EmberInsightsView: View {
    /// Lets an insight send the user to the screen it's about.
    var selectTab: (EmberTab) -> Void

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
        case .positive: return Color.adaptive(light: 0x2E7D5B, dark: 0x6FD3A6)
        case .warning:  return Color.adaptive(light: 0xB23B2E, dark: 0xF0917F)
        case .tip:      return Ember.accent
        case .neutral:  return Ember.onCanvasSoft
        }
    }

    /// Best guess at the screen an insight is about, from its wording.
    private func destination(for insight: Insight) -> EmberTab {
        let text = (insight.title + " " + insight.message).lowercased()
        if text.contains("goal") || text.contains("save for")
            || text.contains("saved up") || text.contains("set aside") {
            return .goals
        }
        if text.contains("net worth") || text.contains("owe")
            || text.contains("rainy-day") || text.contains("cash and savings") {
            return .netWorth
        }
        return .expenses   // spending, budget, pace, categories
    }

    private func destinationLabel(_ tab: EmberTab) -> String {
        switch tab {
        case .netWorth: return "View net worth"
        case .expenses: return "View spending"
        case .goals:    return "View goals"
        case .insights: return "View"
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                EmberHeader(title: "Insights") { showingSettings = true }

                greeting

                if let featured = insights.first {
                    featuredCard(featured)
                }
                ForEach(insights.dropFirst()) { tipCard($0) }
                privacyNote
            }
            .padding(.horizontal, 22)
            .padding(.top, 10)
            .padding(.bottom, 96)   // clear the floating tab bar
        }
        .scrollIndicators(.hidden)
        .background(Ember.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingSettings) { SettingsView() }
    }

    private var greeting: some View {
        Text("\(InsightsEngine.greeting())! Here's what I'm noticing.")
            .font(.system(size: 15))
            .foregroundStyle(Ember.onCanvasSoft)
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
                        .foregroundStyle(Ember.plusInk)
                        .padding(.vertical, 5).padding(.horizontal, 11)
                        .background(tint(for: insight), in: Capsule())
                }
                Text(insight.message)
                    .font(.system(size: 17))
                    .foregroundStyle(Ember.onCanvas)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 4) {
                    Text(destinationLabel(dest))
                        .font(.system(size: 13, weight: .semibold))
                    Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(Ember.accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .emberPanel()
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
                    .frame(width: 40, height: 40)
                    .background(tint(for: insight).opacity(0.16), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(insight.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Ember.onCanvas)
                    Text(insight.message)
                        .font(.system(size: 13))
                        .foregroundStyle(Ember.onCanvasSoft)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Ember.onCanvasSoft)
            }
            .emberPanel(padding: 16)
        }
        .buttonStyle(.plain)
    }

    private var privacyNote: some View {
        Text("🔒 Made right here on your phone from your own numbers — never sent anywhere. (Only investment price lookups use the internet.)")
            .font(.system(size: 12))
            .foregroundStyle(Ember.onCanvasSoft)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
    }
}
