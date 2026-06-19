//
//  NetWorthView.swift
//  PennyPath
//
//  The GREEN pillar. One honest number: everything you own minus everything you owe.
//  Investments are valued from live market data and roll into the total.
//

import SwiftUI
import SwiftData

struct NetWorthView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Account.balance, order: .reverse) private var accounts: [Account]
    @Query private var holdings: [Holding]
    @AppStorage(AppSettings.currencyKey) private var currencyCode = "USD"

    @State private var market = MarketService()
    @State private var showingAdd = false
    @State private var editing: Account?
    @State private var showingSearch = false
    @State private var editingHolding: Holding?

    /// Editable asset rows exclude the auto-managed investments account.
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

    var body: some View {
        ScrollView {
            if accounts.isEmpty && holdings.isEmpty {
                EmptyState(
                    emoji: "💰",
                    title: "Add your first account",
                    message: "Put in your cash, savings, investments, or anything you owe. We'll show you the one number that matters: your net worth.",
                    actionTitle: "Add an account",
                    tint: Theme.green
                ) { showingAdd = true }
            } else {
                VStack(spacing: Theme.Space.lg) {
                    hero
                    if !displayedAssets.isEmpty {
                        accountGroup(title: "What you own", accounts: displayedAssets, tint: Theme.green)
                    }
                    investmentsSection
                    if !debts.isEmpty {
                        accountGroup(title: "What you owe", accounts: debts, tint: Theme.red)
                    }
                }
                .padding(Theme.Space.lg)
            }
        }
        .background(Theme.background)
        .navigationTitle("Net Worth")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAdd) { AccountFormView() }
        .sheet(item: $editing) { AccountFormView(account: $0) }
        .sheet(isPresented: $showingSearch) { HoldingSearchView(service: market) }
        .sheet(item: $editingHolding) { holding in
            NavigationStack { HoldingFormView(holding: holding) }
        }
        .refreshable { await refresh() }
        .task { await refresh() }
        .onChange(of: holdings.count) { _, _ in Task { await refresh() } }
        .onChange(of: currencyCode) { _, _ in Task { await refresh() } }
        .tint(Theme.green)
    }

    private func refresh() async {
        await market.refresh(holdings: holdings, displayCurrency: currencyCode, in: context)
    }

    // MARK: Hero

    private var hero: some View {
        VStack(spacing: Theme.Space.lg) {
            VStack(spacing: 4) {
                Text("NET WORTH")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.inkSecondary)
                    .tracking(1)
                Text(money(netWorth))
                    .font(.amount(46))
                    .foregroundStyle(netWorth >= 0 ? Theme.green : Theme.red)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text("What you own, minus what you owe")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkTertiary)
            }

            SplitBar(leading: assetTotal, trailing: debtTotal)

            HStack {
                legend(color: Theme.green, label: "Own", value: assetTotal)
                Spacer()
                legend(color: Theme.red, label: "Owe", value: debtTotal)
            }
        }
        .card(padding: Theme.Space.xl)
    }

    private func legend(color: Color, label: String, value: Double) -> some View {
        HStack(spacing: Theme.Space.sm) {
            Circle().fill(color).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 0) {
                Text(label).font(.caption).foregroundStyle(Theme.inkSecondary)
                Text(money(value)).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.ink)
            }
        }
    }

    // MARK: Investments (live)

    private var investmentsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            HStack(alignment: .firstTextBaseline) {
                Text("Investments")
                    .font(.display(20))
                    .foregroundStyle(Theme.ink)
                if market.isRefreshing {
                    ProgressView().controlSize(.small).padding(.leading, 4)
                }
                Spacer()
                if !holdings.isEmpty {
                    Text(money(investmentsValue))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.green)
                }
            }

            if !holdings.isEmpty {
                VStack(spacing: Theme.Space.sm) {
                    ForEach(holdings.sorted { $0.cachedValueInBase > $1.cachedValueInBase }) { holding in
                        Button { editingHolding = holding } label: {
                            HoldingRow(holding: holding, currency: currencyCode)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Edit") { editingHolding = holding }
                            Button("Delete", role: .destructive) { deleteHolding(holding) }
                        }
                    }
                }
            }

            Button { showingSearch = true } label: {
                Label(holdings.isEmpty ? "Add an investment" : "Add another", systemImage: "plus")
            }
            .buttonStyle(SoftButtonStyle(tint: Theme.green))

            footnote
        }
    }

    private var footnote: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let error = market.lastError {
                Text(error).font(.caption2).foregroundStyle(Theme.red)
            }
            Text(updatedText).font(.caption2).foregroundStyle(Theme.inkTertiary)
        }
        .padding(.top, 2)
    }

    private var updatedText: String {
        let source = "Prices may be delayed"
        if let date = market.lastUpdated {
            return "Updated \(date.formatted(.relative(presentation: .named))) · \(source)"
        }
        return source
    }

    // MARK: Account group

    private func accountGroup(title: String, accounts: [Account], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            SectionHeader(title: title)
            VStack(spacing: Theme.Space.sm) {
                ForEach(accounts) { account in
                    Button { editing = account } label: {
                        AccountRow(account: account)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Edit") { editing = account }
                        Button("Delete", role: .destructive) { delete(account) }
                    }
                }
            }
        }
    }

    private func delete(_ account: Account) {
        context.delete(account)
    }

    private func deleteHolding(_ holding: Holding) {
        let remaining = holdings.filter { $0.persistentModelID != holding.persistentModelID }
        context.delete(holding)
        Investments.rebuild(holdings: remaining, in: context)
    }
}

private struct AccountRow: View {
    let account: Account

    var body: some View {
        let tint = account.category.isAsset ? Theme.green : Theme.red
        return HStack(spacing: Theme.Space.md) {
            EmojiBadge(emoji: account.category.emoji, tint: tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text(account.category.title)
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer(minLength: Theme.Space.sm)
            Text(money(account.balance))
                .font(.amount(18))
                .foregroundStyle(tint)
        }
        .card()
    }
}

private struct HoldingRow: View {
    let holding: Holding
    let currency: String

    private var sharesText: String {
        holding.shares.formatted(.number.precision(.fractionLength(0...2)))
    }

    var body: some View {
        let up = holding.cachedChangePercent >= 0
        let changeColor = up ? Theme.green : Theme.red
        return HStack(spacing: Theme.Space.md) {
            Text(String(holding.symbol.prefix(4)))
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.green)
                .frame(width: 44, height: 44)
                .background(Theme.green.opacity(0.14),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(holding.symbol)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text(holding.companyName.isEmpty ? "—" : holding.companyName)
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: Theme.Space.sm)
            VStack(alignment: .trailing, spacing: 2) {
                Text(money(holding.cachedValueInBase, code: currency))
                    .font(.amount(17))
                    .foregroundStyle(Theme.ink)
                HStack(spacing: 4) {
                    Text("\(sharesText) \(InstrumentType.unitAbbrev(holding.assetType))")
                        .foregroundStyle(Theme.inkTertiary)
                    Text((up ? "▲ " : "▼ ") + percentText(abs(holding.cachedChangePercent)))
                        .foregroundStyle(changeColor)
                }
                .font(.caption2)
            }
        }
        .card()
    }
}
