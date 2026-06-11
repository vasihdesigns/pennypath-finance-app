//
//  HomeViewVerdeLite.swift
//  PennyPath
//
//  Developer-Mode Home #5 — "Verde, palette + type only": keeps PennyPath's
//  current Home structure (net-worth card, two stat tiles, coach tip) but
//  restyles it with the Verde palette, eyebrow labels, light display type and
//  softer cards. The real HomeView and Theme are untouched.
//

import SwiftUI
import SwiftData

struct HomeViewVerdeLite: View {
    @Binding var selectedTab: AppTab

    @Environment(AppStore.self) private var store
    @Query private var accounts: [Account]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var goals: [Goal]
    @Query private var budgets: [CategoryBudget]
    @Query(sort: \NetWorthSnapshot.date, order: .forward) private var snapshots: [NetWorthSnapshot]

    @State private var showingSettings = false

    private var netWorth: Double { accounts.reduce(0) { $0 + $1.signedBalance } }
    private var monthSpending: Double {
        expenses.filter { $0.date.isSameMonth(as: .now) }.reduce(0) { $0 + $1.amount }
    }
    private var goalsSaved: Double { goals.reduce(0) { $0 + $1.savedAmount } }
    private var trendValues: [Double] { Array(snapshots.suffix(60)).map(\.value) }
    private var hasTrend: Bool { trendValues.count >= 2 }
    private var monthDelta: Double? {
        guard hasTrend else { return nil }
        let start = Date.now.startOfMonth
        let base = snapshots.last(where: { $0.date <= start })?.value ?? snapshots.first?.value
        guard let base, base != 0 else { return nil }
        return (netWorth - base) / abs(base)
    }
    private var headline: Insight {
        InsightsEngine.headline(accounts: accounts, expenses: expenses, goals: goals, budgets: budgets)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if store.isDemo { demoBanner }
                netWorthCard
                HStack(spacing: 14) {
                    statTile(label: "Spent this month", value: money(monthSpending), color: Verde.apricot) {
                        selectedTab = .expenses
                    }
                    statTile(label: "Saved in goals", value: money(goalsSaved), color: Verde.mist) {
                        selectedTab = .goals
                    }
                }
                coachTip
            }
            .padding(20)
        }
        .background(Verde.bg.ignoresSafeArea())
        .navigationTitle(InsightsEngine.greeting())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingSettings = true } label: {
                    Image(systemName: "gearshape").foregroundStyle(Verde.faint)
                }
            }
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .tint(Verde.leaf)
    }

    private var netWorthCard: some View {
        Button { selectedTab = .netWorth } label: {
            VerdeCard(padding: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VerdeEyebrow(text: "Net worth")
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(Verde.ghost)
                    }
                    Text(money(netWorth))
                        .font(Verde.display(40, weight: .regular))
                        .tracking(-0.5)
                        .foregroundStyle(Verde.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    if let delta = monthDelta { percentChip(delta) }
                    if hasTrend {
                        Sparkline(values: trendValues, tint: Verde.leaf)
                            .frame(height: 52)
                            .padding(.top, 4)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func statTile(label: String, value: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VerdeCard(padding: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    VerdeEyebrow(text: label)
                    Text(value)
                        .font(Verde.display(24, weight: .regular))
                        .foregroundStyle(color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var coachTip: some View {
        Button { selectedTab = .coach } label: {
            VerdeCard(fill: Verde.leaf.opacity(0.06), border: Verde.leaf.opacity(0.22)) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 7) {
                        Circle().fill(Verde.leaf).frame(width: 7, height: 7)
                        VerdeEyebrow(text: "Coach tip")
                    }
                    Text(headline.title)
                        .font(.system(size: 15.5, weight: .semibold))
                        .foregroundStyle(Verde.ink)
                    Text(headline.message)
                        .font(.system(size: 13.5))
                        .foregroundStyle(Verde.faint)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func percentChip(_ fraction: Double) -> some View {
        let up = fraction >= 0
        let color = up ? Verde.leaf : Verde.apricot
        return HStack(spacing: 4) {
            Image(systemName: up ? "arrow.up.right" : "arrow.down.right").font(.system(size: 9, weight: .bold))
            Text("\(percentText(abs(fraction))) this month").font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(color)
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .background(color.opacity(0.12), in: Capsule())
    }

    private var demoBanner: some View {
        HStack(spacing: 10) {
            Text("👀")
            Text("Demo data — your real numbers are safe")
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(Verde.faint)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Verde.leafSoft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
