//
//  VividHomeView.swift
//  PennyPath
//
//  Vivid reskin of Home + Net Worth: a warm greeting with an avatar, the
//  one big number as a split hero on the violet brand card, color-blocked
//  spend/save tiles, the coach's headline surfaced up top, then the same
//  editable accounts and live investments the real Net Worth tab has.
//

import SwiftUI
import SwiftData

struct VividHomeView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.modelContext) private var context
    @Query(sort: \Account.balance, order: .reverse) private var accounts: [Account]
    @Query private var holdings: [Holding]
    @Query(sort: \NetWorthSnapshot.date, order: .forward) private var snapshots: [NetWorthSnapshot]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var goals: [Goal]
    @Query private var budgets: [CategoryBudget]
    @AppStorage(AppSettings.currencyKey) private var currencyCode = "USD"

    @State private var market = MarketService()
    @State private var showingAdd = false
    @State private var editing: Account?
    @State private var showingSearch = false
    @State private var editingHolding: Holding?
    @State private var showingSettings = false

    // MARK: Numbers

    private var displayedAssets: [Account] {
        accounts.filter { $0.category.isAsset && !$0.isMarketLinked }
    }
    private var debts: [Account] { accounts.filter { !$0.category.isAsset } }
    private var assetTotal: Double {
        accounts.filter { $0.category.isAsset }.reduce(0) { $0 + $1.baseBalance }
    }
    private var debtTotal: Double { debts.reduce(0) { $0 + $1.baseBalance } }
    private var netWorth: Double { assetTotal - debtTotal }
    private var investmentsValue: Double { holdings.reduce(0) { $0 + $1.cachedValueInBase } }
    private var monthSpending: Double {
        expenses.filter { $0.date.isSameMonth(as: .now) }.reduce(0) { $0 + $1.amount }
    }
    private var goalsSaved: Double { goals.reduce(0) { $0 + $1.savedAmount } }

    /// Change since the start of this month, from the snapshot history.
    private var monthDelta: Double? {
        guard let start = snapshots.first(where: { $0.date.isSameMonth(as: .now) })
                ?? snapshots.last else { return nil }
        return netWorth - start.value
    }

    private var headline: Insight {
        InsightsEngine.headline(accounts: accounts, expenses: expenses, goals: goals, budgets: budgets)
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                if store.isDemo { demoBanner }

                if accounts.isEmpty && holdings.isEmpty {
                    emptyCard
                } else {
                    hero
                    statRow
                    coachStrip
                    if !displayedAssets.isEmpty {
                        accountGroup(title: "What you own", accounts: displayedAssets, tint: Vivid.green)
                    }
                    investmentsSection
                    if !debts.isEmpty {
                        accountGroup(title: "What you owe", accounts: debts, tint: Vivid.coral)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Vivid.bg)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAdd) { AccountFormView() }
        .sheet(item: $editing) { AccountFormView(account: $0) }
        .sheet(isPresented: $showingSearch) { HoldingSearchView(service: market) }
        .sheet(item: $editingHolding) { holding in
            NavigationStack { HoldingFormView(holding: holding) }
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .refreshable { await refresh() }
        .task { await refresh() }
        .onChange(of: holdings.count) { _, _ in Task { await refresh() } }
        .onChange(of: currencyCode) { _, _ in Task { await refresh() } }
        .onAppear { NetWorthHistory.record(in: context) }
        .onChange(of: netWorth) { _, _ in NetWorthHistory.record(in: context) }
        .tint(Vivid.violet)
    }

    private func refresh() async {
        await market.refresh(holdings: holdings, displayCurrency: currencyCode, in: context)
    }

    // MARK: Header — the warm, human opener

    private var dateLine: String {
        Date.now.formatted(.dateTime.weekday(.wide)) + " · " +
        Date.now.formatted(.dateTime.month(.wide).day())
    }

    private var header: some View {
        HStack(spacing: 14) {
            VividMonogram { showingSettings = true }
            VStack(alignment: .leading, spacing: 2) {
                Text(InsightsEngine.greeting())
                    .font(.vividDisplay(24))
                    .foregroundStyle(Vivid.ink)
                Text(dateLine)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(Vivid.inkSoft)
            }
            Spacer(minLength: 8)
            Button { showingAdd = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Vivid.violet)
                    .frame(width: 38, height: 38)
                    .background(Vivid.violet.opacity(0.12), in: Circle())
            }
            .accessibilityLabel("Add account")
        }
    }

    // MARK: Demo banner

    private var demoBanner: some View {
        HStack(spacing: 10) {
            Text("👀").font(.body)
            VStack(alignment: .leading, spacing: 1) {
                Text("Demo data")
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundStyle(Vivid.ink)
                Text("Exploring an example world. Your real data is safe.")
                    .font(.caption).foregroundStyle(Vivid.inkSoft)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Vivid.gold.opacity(0.14),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: Hero — the signature color-blocked net-worth card

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VividOverline(text: "Net worth", tint: .white.opacity(0.85))
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
            }

            VividAmount(value: netWorth, size: 52, tint: .white, trimOpacity: 0.7)

            if let delta = monthDelta, abs(delta) >= 1 {
                HStack(spacing: 5) {
                    Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .black))
                    Text("\(delta >= 0 ? "+" : "−")\(money(abs(delta))) this month")
                        .font(.system(.footnote, design: .rounded).weight(.bold))
                }
                .foregroundStyle(.white)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(.white.opacity(0.18), in: Capsule())
            }

            if snapshots.count >= 2 {
                Sparkline(values: snapshots.map(\.value), tint: .white, lineWidth: 2.5)
                    .frame(height: 52)
                    .padding(.top, 2)
            } else {
                Text("What you own, minus what you owe")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(Vivid.brandGradient,
                    in: RoundedRectangle(cornerRadius: Vivid.cardRadius, style: .continuous))
        .shadow(color: Vivid.violet.opacity(0.4), radius: 22, y: 12)
    }

    // MARK: Spend / save tiles (lightly color-blocked)

    private var statRow: some View {
        HStack(spacing: 12) {
            statTile(label: "Spent this month", value: monthSpending, tint: Vivid.coral)
            statTile(label: "Saved in goals", value: goalsSaved, tint: Vivid.gold)
        }
    }

    private func statTile(label: String, value: Double, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            VividOverline(text: label, tint: tint)
            VividAmount(value: value, size: 26, tint: tint, trimOpacity: 0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(tint.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: Coach headline (surfaced near the top, not buried)

    private var coachStrip: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(headline.emoji)
                .font(.title3)
                .frame(width: 40, height: 40)
                .background(headline.tint.opacity(0.14), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(headline.title)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(Vivid.ink)
                Text(headline.message)
                    .font(.footnote)
                    .foregroundStyle(Vivid.inkSoft)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .vividCard(padding: 16)
    }

    // MARK: Accounts (same behaviour as the real tab)

    private func accountGroup(title: String, accounts: [Account], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VividOverline(text: title)
            VStack(spacing: 0) {
                ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                    Button { editing = account } label: {
                        accountRow(account, tint: tint)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Edit") { editing = account }
                        Button("Delete", role: .destructive) { context.delete(account) }
                    }
                    if index < accounts.count - 1 {
                        Vivid.hairline.frame(height: 1).padding(.leading, 64)
                    }
                }
            }
            .vividCard(padding: 6)
        }
    }

    private func accountRow(_ account: Account, tint: Color) -> some View {
        HStack(spacing: 12) {
            Text(account.category.emoji)
                .font(.body)
                .frame(width: 42, height: 42)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Vivid.ink)
                Text(account.category.title)
                    .font(.caption).foregroundStyle(Vivid.inkSoft)
            }
            Spacer(minLength: 8)
            Text(money(account.balance))
                .font(.vividAmount(16, weight: .semibold))
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }

    // MARK: Investments (live prices, same as the real tab)

    private var investmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VividOverline(text: "Investments")
                if market.isRefreshing {
                    ProgressView().controlSize(.mini).padding(.leading, 2)
                }
                Spacer()
                if !holdings.isEmpty {
                    Text(money(investmentsValue))
                        .font(.vividAmount(15, weight: .semibold))
                        .foregroundStyle(Vivid.violet)
                }
            }

            if !holdings.isEmpty {
                VStack(spacing: 0) {
                    let sorted = holdings.sorted { $0.cachedValueInBase > $1.cachedValueInBase }
                    ForEach(Array(sorted.enumerated()), id: \.element.id) { index, holding in
                        Button { editingHolding = holding } label: {
                            holdingRow(holding)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Edit") { editingHolding = holding }
                            Button("Delete", role: .destructive) { deleteHolding(holding) }
                        }
                        if index < sorted.count - 1 {
                            Vivid.hairline.frame(height: 1).padding(.leading, 64)
                        }
                    }
                }
                .vividCard(padding: 6)
            }

            Button { showingSearch = true } label: {
                Label(holdings.isEmpty ? "Add an investment" : "Add another",
                      systemImage: "plus")
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundStyle(Vivid.violet)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background {
                        Capsule().strokeBorder(Vivid.violet.opacity(0.5), lineWidth: 1.4)
                    }
            }
            .buttonStyle(.plain)

            footnote
        }
    }

    private func holdingRow(_ holding: Holding) -> some View {
        let up = holding.cachedChangePercent >= 0
        return HStack(spacing: 12) {
            Text(String(holding.symbol.prefix(4)))
                .font(.system(.caption2, design: .rounded).weight(.heavy))
                .foregroundStyle(Vivid.violet)
                .frame(width: 42, height: 42)
                .background(Vivid.violet.opacity(0.14), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(holding.symbol)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Vivid.ink)
                Text(holding.companyName.isEmpty ? "—" : holding.companyName)
                    .font(.caption).foregroundStyle(Vivid.inkSoft).lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(money(holding.cachedValueInBase, code: currencyCode))
                    .font(.vividAmount(15, weight: .semibold))
                    .foregroundStyle(Vivid.ink)
                Text((up ? "▲ " : "▼ ") + percentText(abs(holding.cachedChangePercent)))
                    .font(.caption2)
                    .foregroundStyle(up ? Vivid.green : Vivid.coral)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }

    private var footnote: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let error = market.lastError {
                Text(error).font(.caption2).foregroundStyle(Vivid.coral)
            }
            Text(updatedText).font(.caption2).foregroundStyle(Vivid.inkFaint)
        }
    }

    private var updatedText: String {
        let source = "Prices may be delayed"
        if let date = market.lastUpdated {
            return "Updated \(date.formatted(.relative(presentation: .named))) · \(source)"
        }
        return source
    }

    private func deleteHolding(_ holding: Holding) {
        let remaining = holdings.filter { $0.persistentModelID != holding.persistentModelID }
        context.delete(holding)
        Investments.rebuild(holdings: remaining, in: context)
    }

    // MARK: Empty state

    private var emptyCard: some View {
        VStack(spacing: 16) {
            Text("✨").font(.system(size: 44))
            Text("Let's see your big number")
                .font(.vividDisplay(22))
                .foregroundStyle(Vivid.ink)
            Text("Add your cash, savings, investments, or anything you owe — and watch your net worth come to life.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Vivid.inkSoft)
                .multilineTextAlignment(.center)
            VividPrimaryButton(title: "Add an account", systemImage: "plus") { showingAdd = true }
        }
        .frame(maxWidth: .infinity)
        .vividCard(padding: 28)
        .padding(.top, 24)
    }
}
