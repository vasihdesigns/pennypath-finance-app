//
//  HomeViewVerde.swift
//  PennyPath
//
//  Developer-Mode Home #4 — a full "Verde" reskin: porcelain/pine palette,
//  leaf + apricot + mist accents, eyebrow labels, light-weight display type,
//  generous whitespace, an editorial composition. Wired to real data; the real
//  HomeView and Theme are untouched.
//

import SwiftUI
import SwiftData

struct HomeViewVerde: View {
    @Binding var selectedTab: AppTab

    @Environment(AppStore.self) private var store
    @Query private var accounts: [Account]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var goals: [Goal]
    @Query private var budgets: [CategoryBudget]
    @Query(sort: \NetWorthSnapshot.date, order: .forward) private var snapshots: [NetWorthSnapshot]

    @State private var showingSettings = false

    // MARK: Data

    private var netWorth: Double { accounts.reduce(0) { $0 + $1.signedBalance } }
    private var assetTotal: Double { accounts.filter { $0.category.isAsset }.reduce(0) { $0 + $1.balance } }
    private var debtTotal: Double { accounts.filter { !$0.category.isAsset }.reduce(0) { $0 + $1.balance } }
    private var trendValues: [Double] { Array(snapshots.suffix(60)).map(\.value) }
    private var hasTrend: Bool { trendValues.count >= 2 }
    private var monthChange: Double? {
        guard hasTrend else { return nil }
        let start = Date.now.startOfMonth
        let base = snapshots.last(where: { $0.date <= start })?.value ?? snapshots.first?.value
        guard let base else { return nil }
        return netWorth - base
    }
    private var headline: Insight {
        InsightsEngine.headline(accounts: accounts, expenses: expenses, goals: goals, budgets: budgets)
    }
    private var dateLine: String {
        let now = Date.now
        return "\(now.formatted(.dateTime.weekday(.wide))) · \(now.formatted(.dateTime.month(.wide).day()))"
    }
    private var monthLabels: [String] {
        let vals = Array(snapshots.suffix(60))
        guard vals.count >= 4 else { return [] }
        let idx = [0, vals.count / 3, 2 * vals.count / 3, vals.count - 1]
        return idx.map { vals[$0].date.formatted(.dateTime.month(.abbreviated)).uppercased() }
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                if store.isDemo { demoBanner }
                header
                netWorthBlock
                assetsCard
                insightCard
            }
            .padding(.horizontal, 26)
            .padding(.top, 8)
            .padding(.bottom, 48)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Verde.bg.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
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

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            VerdeEyebrow(text: dateLine)
            Text(InsightsEngine.greeting())
                .font(Verde.display(24, weight: .medium))
                .foregroundStyle(Verde.ink)
        }
    }

    // MARK: Net worth

    private var netWorthBlock: some View {
        Button { selectedTab = .netWorth } label: {
            VStack(alignment: .leading, spacing: 0) {
                VerdeEyebrow(text: "Net worth")
                Text(money(netWorth))
                    .font(Verde.display(50, weight: .regular))
                    .tracking(-1)
                    .foregroundStyle(Verde.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.top, 8)
                if let change = monthChange {
                    VerdeChangePill(amount: change).padding(.top, 12)
                }
                if hasTrend {
                    Sparkline(values: trendValues, tint: Verde.leaf)
                        .frame(height: 86)
                        .padding(.top, 16)
                    if !monthLabels.isEmpty {
                        HStack {
                            ForEach(Array(monthLabels.enumerated()), id: \.offset) { index, label in
                                Text(label)
                                if index < monthLabels.count - 1 { Spacer() }
                            }
                        }
                        .font(.system(size: 10.5, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(Verde.ghost)
                        .padding(.top, 8)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Assets / liabilities

    private var assetsCard: some View {
        Button { selectedTab = .netWorth } label: {
            VerdeCard {
                VStack(spacing: 0) {
                    assetRow(label: "Assets", note: "Cash · Investments · Property",
                             value: money(assetTotal), color: Verde.leaf, topBorder: false)
                    assetRow(label: "Liabilities", note: "Loans · Cards",
                             value: "−" + money(debtTotal), color: Verde.apricot, topBorder: true)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func assetRow(label: String, note: String, value: String, color: Color, topBorder: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(label).font(.system(size: 14.5, weight: .semibold)).foregroundStyle(Verde.ink)
                Text(note).font(.system(size: 12)).foregroundStyle(Verde.ghost)
            }
            Spacer()
            Text(value).font(Verde.display(19, weight: .medium)).foregroundStyle(color)
        }
        .padding(.vertical, 14)
        .overlay(alignment: .top) {
            if topBorder { Rectangle().fill(Verde.line).frame(height: 1) }
        }
    }

    // MARK: Insight

    private var insightCard: some View {
        Button { selectedTab = .coach } label: {
            VerdeCard(fill: Verde.leaf.opacity(0.06), border: Verde.leaf.opacity(0.22)) {
                VStack(alignment: .leading, spacing: 10) {
                    VerdeEyebrow(text: "This week's insight")
                    Text(headline.message)
                        .font(Verde.display(17, weight: .regular))
                        .foregroundStyle(Verde.ink)
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Demo banner

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
