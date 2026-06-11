//
//  HomeViewSophisticated.swift
//  PennyPath
//
//  A second experimental Home (Developer Mode only) with a refined, muted palette:
//  deep emerald, oxblood, and bronze cards with warm cream text and a hairline
//  edge — a quieter, more "luxe" take than the bright gradient version.
//  The real HomeView is untouched.
//

import SwiftUI
import SwiftData

struct HomeViewSophisticated: View {
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
                             emoji: "💸", gradient: Self.oxblood) { selectedTab = .expenses }
                    statCard(label: "Saved in goals", value: money(goalsSaved),
                             emoji: "🎯", gradient: Self.bronze) { selectedTab = .goals }
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
        .onAppear { NetWorthHistory.record(in: context) }
        .onChange(of: netWorth) { _, _ in NetWorthHistory.record(in: context) }
    }

    // MARK: Net worth hero (deep emerald)

    private var netWorthHero: some View {
        let positive = netWorth >= 0
        return Button { selectedTab = .netWorth } label: {
            VStack(alignment: .leading, spacing: Theme.Space.sm) {
                HStack {
                    Text("NET WORTH")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Self.cream.opacity(0.72))
                        .tracking(1.5)
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(Self.cream.opacity(0.55))
                }
                HStack(spacing: Theme.Space.sm) {
                    Text(money(netWorth))
                        .font(.amount(40))
                        .foregroundStyle(Self.cream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .layoutPriority(1)
                    if let delta = monthDelta { deltaChip(delta) }
                    Spacer(minLength: 0)
                }
                if hasTrend {
                    Sparkline(values: trendValues, tint: Self.cream)
                        .frame(height: 58)
                        .padding(.top, Theme.Space.xs)
                } else {
                    Text("What you own, minus what you owe")
                        .font(.footnote)
                        .foregroundStyle(Self.cream.opacity(0.7))
                }
            }
            .luxeCard(gradient: positive ? Self.emerald : Self.oxblood, padding: Theme.Space.xl)
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
        .foregroundStyle(Self.cream)
        .padding(.vertical, 4)
        .padding(.horizontal, 9)
        .background(Self.cream.opacity(0.16), in: Capsule())
        .fixedSize()
    }

    // MARK: Stat cards (oxblood / bronze)

    private func statCard(label: String, value: String, emoji: String,
                          gradient: [Color], action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.Space.sm) {
                Text(emoji)
                    .font(.system(size: 22))
                    .frame(width: 42, height: 42)
                    .background(Self.cream.opacity(0.14), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                Spacer(minLength: Theme.Space.sm)
                Text(label.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Self.cream.opacity(0.72))
                    .tracking(0.8)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(value)
                    .font(.amount(26))
                    .foregroundStyle(Self.cream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
            .luxeCard(gradient: gradient)
        }
        .buttonStyle(.plain)
    }

    // MARK: Demo banner + coach tip (kept calm)

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

    // MARK: History — real points only (NetWorthHistory)

    // MARK: Sophisticated palette (deep, muted, harmonious)

    static let cream = Color(hex: 0xF3EEE3)
    static let emerald = [Color(hex: 0x15604C), Color(hex: 0x0B3A2D)]   // net worth
    static let oxblood = [Color(hex: 0x8C3A42), Color(hex: 0x551E27)]   // spending
    static let bronze  = [Color(hex: 0x9A7836), Color(hex: 0x655024)]   // goals
}

// MARK: - Luxe card styling (deep gradient + soft sheen + hairline edge)

private extension View {
    func luxeCard(gradient: [Color], padding: CGFloat = Theme.Space.lg) -> some View {
        self
            .padding(padding)
            .background(
                LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
            )
            .overlay(
                // Subtle top-down sheen for a glassy, refined finish.
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .fill(LinearGradient(colors: [.white.opacity(0.10), .clear],
                                         startPoint: .top, endPoint: .center))
                    .allowsHitTesting(false)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.30), .white.opacity(0.04)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.22), radius: 16, x: 0, y: 12)
    }
}
