//
//  HomeViewPremium.swift
//  PennyPath
//
//  An experimental "premium" Home, shown ONLY when Developer Mode is on.
//  The three headline boxes become bold gradient cards (green / red / gold)
//  with a soft glow and a light translucent edge. The real HomeView is untouched.
//

import SwiftUI
import SwiftData

struct HomeViewPremium: View {
    @Binding var selectedTab: AppTab

    @Environment(AppStore.self) private var store
    @Environment(\.modelContext) private var context
    @Query private var accounts: [Account]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var goals: [Goal]
    @Query private var budgets: [CategoryBudget]
    @Query(sort: \NetWorthSnapshot.date, order: .forward) private var snapshots: [NetWorthSnapshot]

    @State private var showingSettings = false

    // MARK: Numbers

    private var netWorth: Double { accounts.reduce(0) { $0 + $1.signedBalance } }
    private var monthSpending: Double {
        expenses.filter { $0.date.isSameMonth(as: .now) }.reduce(0) { $0 + $1.amount }
    }
    private var goalsSaved: Double { goals.reduce(0) { $0 + $1.savedAmount } }
    private var headline: Insight {
        InsightsEngine.headline(accounts: accounts, expenses: expenses, goals: goals, budgets: budgets)
    }
    private var trendValues: [Double] { Array(snapshots.suffix(60)).map(\.value) }
    private var hasTrend: Bool { trendValues.count >= 2 }
    private var monthDelta: Double? {
        guard hasTrend else { return nil }
        let start = Date.now.startOfMonth
        let base = snapshots.last(where: { $0.date <= start })?.value ?? snapshots.first?.value
        guard let base, base != 0 else { return nil }
        return (netWorth - base) / abs(base)
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Space.lg) {
                if store.isDemo { demoBanner }

                netWorthHero
                HStack(spacing: Theme.Space.md) {
                    statCard(label: "Spent this month", value: money(monthSpending),
                             emoji: "💸", gradient: Self.redGradient, glow: Self.redGlow) {
                        selectedTab = .expenses
                    }
                    statCard(label: "Saved in goals", value: money(goalsSaved),
                             emoji: "🎯", gradient: Self.goldGradient, glow: Self.goldGlow) {
                        selectedTab = .goals
                    }
                }

                coachTip
            }
            .padding(Theme.Space.lg)
        }
        .background(Theme.background)
        .navigationTitle(InsightsEngine.greeting())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingSettings = true } label: { Image(systemName: "gearshape") }
                    .tint(Theme.ink)
            }
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .onAppear { syncHistory() }
        .onChange(of: netWorth) { _, _ in recordSnapshot() }
    }

    // MARK: Net worth hero (green gradient)

    private var netWorthHero: some View {
        let positive = netWorth >= 0
        return Button { selectedTab = .netWorth } label: {
            VStack(alignment: .leading, spacing: Theme.Space.sm) {
                HStack {
                    Text("NET WORTH")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .tracking(1)
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.white.opacity(0.7))
                }
                HStack(spacing: Theme.Space.sm) {
                    Text(money(netWorth))
                        .font(.amount(40))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .layoutPriority(1)
                    if let delta = monthDelta { deltaChip(delta) }
                    Spacer(minLength: 0)
                }
                if hasTrend {
                    Sparkline(values: trendValues, tint: .white)
                        .frame(height: 58)
                        .padding(.top, Theme.Space.xs)
                } else {
                    Text("What you own, minus what you owe")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .premiumCard(gradient: positive ? Self.greenGradient : Self.redGradient,
                         glow: positive ? Self.greenGlow : Self.redGlow,
                         padding: Theme.Space.xl)
        }
        .buttonStyle(.plain)
    }

    private func deltaChip(_ delta: Double) -> some View {
        let up = delta >= 0
        return HStack(spacing: 3) {
            Image(systemName: up ? "arrow.up.right" : "arrow.down.right")
            Text("\(percentText(abs(delta))) this month")
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.vertical, 4)
        .padding(.horizontal, 9)
        .background(.white.opacity(0.22), in: Capsule())
        .fixedSize()
    }

    // MARK: Stat cards (red / gold gradient)

    private func statCard(label: String, value: String, emoji: String,
                          gradient: [Color], glow: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.Space.sm) {
                Text(emoji)
                    .font(.system(size: 22))
                    .frame(width: 42, height: 42)
                    .background(.white.opacity(0.22), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                Spacer(minLength: Theme.Space.sm)
                Text(label.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .tracking(0.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(value)
                    .font(.amount(26))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
            .premiumCard(gradient: gradient, glow: glow)
        }
        .buttonStyle(.plain)
    }

    // MARK: Demo banner + coach tip (kept calm, no gradient)

    private var demoBanner: some View {
        HStack(spacing: Theme.Space.md) {
            Text("👀").font(.title3)
            VStack(alignment: .leading, spacing: 1) {
                Text("Demo data").font(.subheadline.weight(.bold)).foregroundStyle(Theme.ink)
                Text("Exploring an example world. Your real data is safe.")
                    .font(.caption).foregroundStyle(Theme.inkSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Space.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.gold.opacity(0.16),
                    in: RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous))
    }

    private var coachTip: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            SectionHeader(title: "Coach tip", actionTitle: "See all") { selectedTab = .coach }
            InsightCard(insight: headline)
        }
    }

    // MARK: History (same behaviour as the real Home)

    private func syncHistory() {
        guard !accounts.isEmpty else { return }
        if snapshots.count < 2 {
            snapshots.forEach { context.delete($0) }
            NetWorthSnapshot.seedHistory(current: netWorth, into: context)
        } else {
            recordSnapshot()
        }
    }

    private func recordSnapshot() {
        guard !accounts.isEmpty else { return }
        if let today = snapshots.last(where: { $0.date.isSameDay(as: .now) }) {
            if today.value != netWorth { today.value = netWorth }
        } else {
            context.insert(NetWorthSnapshot(date: .now, value: netWorth))
        }
    }

    // MARK: Gradient palettes

    static let greenGradient = [Color(hex: 0x21C36B), Color(hex: 0x0C8F4E)]
    static let redGradient = [Color(hex: 0xFF5E62), Color(hex: 0xE23B41)]
    static let goldGradient = [Color(hex: 0xE9B84A), Color(hex: 0xC2902A)]
    static let greenGlow = Color(hex: 0x12A150)
    static let redGlow = Color(hex: 0xE5333A)
    static let goldGlow = Color(hex: 0xC2902A)
}

// MARK: - Premium gradient card styling

private extension View {
    func premiumCard(gradient: [Color], glow: Color, padding: CGFloat = Theme.Space.lg) -> some View {
        self
            .padding(padding)
            .background(
                LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0.08)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1
                    )
            )
            .shadow(color: glow.opacity(0.35), radius: 16, x: 0, y: 10)
    }
}
