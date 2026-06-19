//
//  SageWorthView.swift
//  PennyPath
//
//  Sage reskin of Net Worth: greeting + date up top, the one big number
//  with a monthly delta chip, a soft growth chart, an assets/liabilities
//  summary card — then the same editable accounts, live investments and
//  forms the real Net Worth tab has.
//

import SwiftUI
import SwiftData

struct SageWorthView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.modelContext) private var context
    @Query(sort: \Account.balance, order: .reverse) private var accounts: [Account]
    @Query private var holdings: [Holding]
    @Query(sort: \NetWorthSnapshot.date, order: .forward) private var snapshots: [NetWorthSnapshot]
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

    /// Change since the start of this month, from the snapshot history.
    private var monthDelta: Double? {
        guard let start = snapshots.first(where: { $0.date.isSameMonth(as: .now) })
                ?? snapshots.last else { return nil }
        return netWorth - start.value
    }

    private var assetKinds: String {
        let kinds = Set(accounts.filter { $0.category.isAsset }.map { $0.category.title })
        return kinds.isEmpty ? "Nothing yet" : kinds.sorted().joined(separator: " · ")
    }
    private var debtKinds: String {
        let kinds = Set(debts.map { $0.category.title })
        return kinds.isEmpty ? "Nothing — nice" : kinds.sorted().joined(separator: " · ")
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                if store.isDemo { demoBanner }

                if accounts.isEmpty && holdings.isEmpty {
                    emptyCard
                } else {
                    hero
                    summaryCard
                    if !displayedAssets.isEmpty {
                        accountGroup(title: "What you own", accounts: displayedAssets, tint: Sage.green)
                    }
                    investmentsSection
                    if !debts.isEmpty {
                        accountGroup(title: "What you owe", accounts: debts, tint: Sage.terracotta)
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Sage.bg)
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
        .tint(Sage.green)
    }

    private func refresh() async {
        await market.refresh(holdings: holdings, displayCurrency: currencyCode, in: context)
    }

    // MARK: Demo banner

    private var demoBanner: some View {
        HStack(spacing: 10) {
            Text("👀").font(.body)
            VStack(alignment: .leading, spacing: 1) {
                Text("Demo data").font(.footnote.weight(.bold)).foregroundStyle(Sage.ink)
                Text("Exploring an example world. Your real data is safe.")
                    .font(.caption).foregroundStyle(Sage.inkSoft)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Sage.terracotta.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: Header

    private var dateLine: String {
        Date.now.formatted(.dateTime.weekday(.wide)) + " · " +
        Date.now.formatted(.dateTime.month(.wide).day())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                SageOverline(text: dateLine)
                Spacer()
                HStack(spacing: 14) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Sage.inkSoft)
                    }
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Sage.inkSoft)
                    }
                }
            }
            Text(InsightsEngine.greeting())
                .font(.sageDisplay(28))
                .foregroundStyle(Sage.ink)
        }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            SageOverline(text: "Net worth")
            Text(money(netWorth))
                .font(.sageAmount(44))
                .foregroundStyle(netWorth >= 0 ? Sage.ink : Sage.terracotta)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            if let delta = monthDelta, abs(delta) >= 1 {
                HStack(spacing: 5) {
                    Image(systemName: delta >= 0 ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                        .font(.system(size: 8))
                    Text("\(delta >= 0 ? "+" : "−")\(money(abs(delta))) this month")
                        .font(.footnote.weight(.semibold))
                }
                .foregroundStyle(delta >= 0 ? Sage.green : Sage.terracotta)
                .padding(.vertical, 7)
                .padding(.horizontal, 13)
                .background((delta >= 0 ? Sage.green : Sage.terracotta).opacity(0.12), in: Capsule())
            }

            if snapshots.count >= 2 {
                chart.padding(.top, 6)
            }
        }
    }

    private var chart: some View {
        VStack(spacing: 8) {
            Sparkline(values: snapshots.map(\.value), tint: Sage.green, lineWidth: 2.5)
                .frame(height: 130)
            HStack {
                ForEach(monthMarks, id: \.self) { mark in
                    Text(mark)
                        .font(.caption2.weight(.medium))
                        .tracking(1.2)
                        .foregroundStyle(Sage.inkFaint)
                    if mark != monthMarks.last { Spacer() }
                }
            }
        }
    }

    /// Four evenly spaced month labels under the chart (JUL … JUN).
    private var monthMarks: [String] {
        guard snapshots.count >= 2 else { return [] }
        let idx = [0, snapshots.count / 3, snapshots.count * 2 / 3, snapshots.count - 1]
        return idx.map { snapshots[$0].date.formatted(.dateTime.month(.abbreviated)).uppercased() }
    }

    // MARK: Assets / liabilities summary

    private var summaryCard: some View {
        VStack(spacing: 0) {
            summaryRow(title: "Assets", detail: assetKinds,
                       amount: money(assetTotal), color: Sage.green)
            Sage.hairline.frame(height: 1).padding(.vertical, 14)
            summaryRow(title: "Liabilities", detail: debtKinds,
                       amount: debtTotal > 0 ? "−" + money(debtTotal) : money(0),
                       color: Sage.terracotta)
        }
        .sageCard(padding: 22)
    }

    private func summaryRow(title: String, detail: String, amount: String, color: Color) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline).foregroundStyle(Sage.ink)
                Text(detail).font(.caption).foregroundStyle(Sage.inkSoft).lineLimit(1)
            }
            Spacer(minLength: 12)
            Text(amount)
                .font(.sageAmount(19))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    // MARK: Accounts (same behaviour as the real tab)

    private func accountGroup(title: String, accounts: [Account], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SageOverline(text: title)
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
                        Sage.hairline.frame(height: 1)
                    }
                }
            }
            .sageCard(padding: 6)
        }
    }

    private func accountRow(_ account: Account, tint: Color) -> some View {
        HStack(spacing: 12) {
            Text(account.category.emoji).font(.body)
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name).font(.subheadline.weight(.semibold)).foregroundStyle(Sage.ink)
                Text(account.category.title).font(.caption).foregroundStyle(Sage.inkSoft)
            }
            Spacer(minLength: 8)
            Text(money(account.balance))
                .font(.sageAmount(16))
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }

    // MARK: Investments (live prices, same as the real tab)

    private var investmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                SageOverline(text: "Investments")
                if market.isRefreshing {
                    ProgressView().controlSize(.mini).padding(.leading, 2)
                }
                Spacer()
                if !holdings.isEmpty {
                    Text(money(investmentsValue))
                        .font(.sageAmount(15))
                        .foregroundStyle(Sage.green)
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
                            Sage.hairline.frame(height: 1)
                        }
                    }
                }
                .sageCard(padding: 6)
            }

            Button { showingSearch = true } label: {
                Label(holdings.isEmpty ? "Add an investment" : "Add another",
                      systemImage: "plus")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Sage.green)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background {
                        Capsule().stroke(Sage.green.opacity(0.4), lineWidth: 1.2)
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
                .font(.caption2.weight(.bold))
                .foregroundStyle(Sage.green)
                .frame(width: 38, height: 38)
                .background(Sage.green.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(holding.symbol).font(.subheadline.weight(.semibold)).foregroundStyle(Sage.ink)
                Text(holding.companyName.isEmpty ? "—" : holding.companyName)
                    .font(.caption).foregroundStyle(Sage.inkSoft).lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(money(holding.cachedValueInBase, code: currencyCode))
                    .font(.sageAmount(15))
                    .foregroundStyle(Sage.ink)
                Text((up ? "▲ " : "▼ ") + percentText(abs(holding.cachedChangePercent)))
                    .font(.caption2)
                    .foregroundStyle(up ? Sage.green : Sage.terracotta)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }

    private var footnote: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let error = market.lastError {
                Text(error).font(.caption2).foregroundStyle(Sage.terracotta)
            }
            Text(updatedText).font(.caption2).foregroundStyle(Sage.inkFaint)
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
        VStack(spacing: 14) {
            Text("💰").font(.system(size: 40))
            Text("Add your first account")
                .font(.sageDisplay(20))
                .foregroundStyle(Sage.ink)
            Text("Put in your cash, savings, investments, or anything you owe — and see the one number that matters.")
                .font(.subheadline)
                .foregroundStyle(Sage.inkSoft)
                .multilineTextAlignment(.center)
            Button { showingAdd = true } label: {
                Text("Add an account")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Sage.green, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .sageCard(padding: 28)
        .padding(.top, 30)
    }

}
