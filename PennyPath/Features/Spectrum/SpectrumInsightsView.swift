//
//  SpectrumInsightsView.swift
//  PennyPath
//
//  Spectrum's Insights screen: this week's headline as a feature card, then the
//  rest of the tips. Same on-device InsightsEngine the app has always used —
//  nothing leaves the phone. Each tip is tappable and jumps to the tab it's
//  about, so an insight is a starting point, not a dead end.
//

import SwiftUI
import SwiftData

struct SpectrumInsightsView: View {
    /// Lets an insight send the user to the screen it's about.
    var selectTab: (SpectrumTab) -> Void

    // Archived accounts are hidden everywhere, so they shouldn't drive insights.
    @Query(filter: #Predicate<Account> { !$0.isArchived }) private var accounts: [Account]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query(filter: #Predicate<Goal> { !$0.isArchived }) private var goals: [Goal]
    @Query private var budgets: [CategoryBudget]
    @Query private var upcomingPayments: [UpcomingPayment]
    @Query(sort: \NetWorthSnapshot.date, order: .forward) private var snapshots: [NetWorthSnapshot]

    @State private var showingSettings = false
    /// Newline-joined stable keys of insights the user has put away.
    @AppStorage("spectrumDismissedInsights") private var dismissedRaw = ""

    private var insights: [Insight] {
        InsightsEngine.generate(accounts: accounts, expenses: expenses, goals: goals,
                                budgets: budgets, payments: upcomingPayments, snapshots: snapshots)
    }
    private var dismissed: Set<String> {
        Set(dismissedRaw.split(separator: "\n").map(String.init))
    }
    /// Insights minus the ones the user has dismissed (by stable key).
    private var visible: [Insight] {
        insights.filter { $0.key.isEmpty || !dismissed.contains($0.key) }
    }
    private func dismiss(_ insight: Insight) {
        guard !insight.key.isEmpty else { return }
        var set = dismissed
        set.insert(insight.key)
        withAnimation(.snappy) { dismissedRaw = set.sorted().joined(separator: "\n") }
        Haptics.tap()
    }
    private func restoreDismissed() {
        withAnimation(.snappy) { dismissedRaw = "" }
        Haptics.tap()
    }

    private func tint(for insight: Insight) -> Color {
        switch insight.tone {
        case .positive: return Spectrum.good          // teal
        case .warning:  return Spectrum.spend         // wine
        case .tip:      return Spectrum.accent         // slate
        case .neutral:  return Spectrum.onCanvasSoft
        }
    }

    /// Which screen a tap opens — driven by the insight's own topic, not guessed
    /// from its wording.
    private func destination(for insight: Insight) -> SpectrumTab {
        switch insight.topic {
        case .netWorth, .cushion: return .netWorth
        case .goals:              return .goals
        case .spending, .budget, .subscriptions: return .expenses
        case .general:            return .insights
        }
    }
    /// General tips (e.g. daily wisdom) aren't about a specific screen.
    private func navigates(_ insight: Insight) -> Bool { insight.topic != .general }

    private func destinationLabel(_ tab: SpectrumTab) -> String {
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
                SpectrumHeader(title: "Insights") { showingSettings = true }

                greeting

                let all = visible
                if let featured = all.first {
                    featuredCard(featured)
                }
                let rest = Array(all.dropFirst())
                section("NEEDS ATTENTION", rest.filter { $0.tone == .warning })
                section("WINS", rest.filter { $0.tone == .positive })
                section("TIPS", rest.filter { $0.tone == .tip || $0.tone == .neutral })
                if !dismissed.isEmpty { showDismissedButton }
                privacyNote
            }
            .padding(.horizontal, 22)
            .padding(.top, 10)
            .padding(.bottom, 96)   // clear the floating tab bar
        }
        .scrollIndicators(.hidden)
        .background(Spectrum.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingSettings) { SettingsView() }
    }

    private var greeting: some View {
        Text("\(InsightsEngine.greeting())! Here's what I'm noticing.")
            .font(.system(size: 15))
            .foregroundStyle(Spectrum.onCanvasSoft)
    }

    /// A titled group of cards — only renders when it has something to show.
    @ViewBuilder
    private func section(_ title: String, _ items: [Insight]) -> some View {
        if !items.isEmpty {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(Spectrum.onCanvasSoft)
                .padding(.top, 6)
            ForEach(items) { tipCard($0) }
        }
    }

    private var showDismissedButton: some View {
        Button { restoreDismissed() } label: {
            Label("Show dismissed tips", systemImage: "arrow.uturn.left")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Spectrum.onCanvasSoft)
        }
        .buttonStyle(.plain)
        .padding(.top, 6)
    }

    /// Long-press "Dismiss" — only for cards that carry a stable key.
    @ViewBuilder
    private func dismissButton(_ insight: Insight) -> some View {
        if !insight.key.isEmpty {
            Button(role: .destructive) { dismiss(insight) } label: {
                Label("Dismiss", systemImage: "xmark.circle")
            }
        }
    }

    private func featuredCard(_ insight: Insight) -> some View {
        let dest = destination(for: insight)
        return Button {
            Haptics.tap()
            if navigates(insight) { selectTab(dest) }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Text(insight.emoji).font(.title2)
                    Text(insight.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Spectrum.plusInk)
                        .padding(.vertical, 5).padding(.horizontal, 11)
                        .background(tint(for: insight), in: Capsule())
                }
                Text(insight.message)
                    .font(.system(size: 17))
                    .foregroundStyle(Spectrum.onCanvas)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                if insight.topic == .netWorth, snapshots.count >= 2 {
                    Sparkline(values: snapshots.map(\.value), tint: tint(for: insight))
                        .frame(height: 40)
                        .padding(.top, 2)
                }
                if navigates(insight) {
                    HStack(spacing: 4) {
                        Text(destinationLabel(dest))
                            .font(.system(size: 13, weight: .semibold))
                        Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(Spectrum.accent)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .spectrumPanel()
        }
        .buttonStyle(.plain)
        .contextMenu { dismissButton(insight) }
    }

    private func tipCard(_ insight: Insight) -> some View {
        Button {
            Haptics.tap()
            if navigates(insight) { selectTab(destination(for: insight)) }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Text(insight.emoji)
                    .font(.body)
                    .frame(width: 40, height: 40)
                    .background(tint(for: insight).opacity(0.16), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(insight.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Spectrum.onCanvas)
                    Text(insight.message)
                        .font(.system(size: 13))
                        .foregroundStyle(Spectrum.onCanvasSoft)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 4)
                if navigates(insight) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Spectrum.onCanvasSoft)
                }
            }
            .spectrumPanel(padding: 16)
        }
        .buttonStyle(.plain)
        .contextMenu { dismissButton(insight) }
    }

    private var privacyNote: some View {
        Text("🔒 Made right here on your phone from your own numbers — never sent anywhere. (The app's only network use is fetching prices, exchange rates, and subscription icons for items you add.)")
            .font(.system(size: 12))
            .foregroundStyle(Spectrum.onCanvasSoft)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
    }
}
