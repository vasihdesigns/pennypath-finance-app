//
//  StrataWorthView.swift
//  PennyPath
//
//  Strata reskin of Net Worth — the star screen. The one big number with a
//  privacy eye, then net worth drawn as proportional color bands (the
//  signature), then each money kind as a card with a colored proportion
//  edge that expands to the real, editable accounts and live investments.
//

import SwiftUI
import SwiftData

struct StrataWorthView: View {
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
    @State private var showingTrend = false
    @State private var hideAmounts = false
    @State private var expanded: Set<String> = []

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

    private var monthDelta: Double? {
        guard let start = snapshots.first(where: { $0.date.isSameMonth(as: .now) })
                ?? snapshots.last else { return nil }
        return netWorth - start.value
    }

    /// Asset totals by category (investments folded in), biggest first.
    private var assetBuckets: [(category: AccountCategory, value: Double)] {
        var d: [AccountCategory: Double] = [:]
        for a in displayedAssets { d[a.category, default: 0] += a.baseBalance }
        if investmentsValue > 0 { d[.investment, default: 0] += investmentsValue }
        return d.filter { $0.value > 0 }
            .map { (category: $0.key, value: $0.value) }
            .sorted { $0.value > $1.value }
    }
    private var debtBuckets: [(category: AccountCategory, value: Double)] {
        var d: [AccountCategory: Double] = [:]
        for a in debts { d[a.category, default: 0] += a.baseBalance }
        return d.filter { $0.value > 0 }
            .map { (category: $0.key, value: $0.value) }
            .sorted { $0.value > $1.value }
    }

    private var bands: [StrataBand] {
        guard assetTotal > 0 else { return [] }
        var out = assetBuckets.map {
            StrataBand(color: Strata.color(for: $0.category), label: $0.category.title,
                       value: $0.value, share: $0.value / assetTotal, isLiability: false)
        }
        out += debtBuckets.map {
            StrataBand(color: Strata.color(for: $0.category), label: $0.category.title,
                       value: $0.value, share: $0.value / assetTotal, isLiability: true)
        }
        return out
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if store.isDemo { demoBanner }

                if accounts.isEmpty && holdings.isEmpty {
                    emptyCard
                } else {
                    netWorthBlock
                    compositionCard
                    if !assetBuckets.isEmpty {
                        StrataOverline(text: "What you own")
                        ForEach(assetBuckets, id: \.category) { bucket in
                            categoryCard(bucket.category, value: bucket.value)
                        }
                    }
                    if !debtBuckets.isEmpty {
                        StrataOverline(text: "What you owe").padding(.top, 4)
                        ForEach(debtBuckets, id: \.category) { bucket in
                            categoryCard(bucket.category, value: bucket.value)
                        }
                    }
                    footnote
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Strata.bg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAdd) { AccountFormView() }
        .sheet(item: $editing) { AccountFormView(account: $0) }
        .sheet(isPresented: $showingSearch) { HoldingSearchView(service: market) }
        .sheet(item: $editingHolding) { holding in
            NavigationStack { HoldingFormView(holding: holding) }
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .sheet(isPresented: $showingTrend) {
            StrataTrendView(snapshots: snapshots, currencyCode: currencyCode)
        }
        .refreshable { await refresh() }
        .task { await refresh() }
        .onChange(of: holdings.count) { _, _ in Task { await refresh() } }
        .onChange(of: currencyCode) { _, _ in Task { await refresh() } }
        .onAppear { NetWorthHistory.record(in: context) }
        .onChange(of: netWorth) { _, _ in NetWorthHistory.record(in: context) }
        .tint(Strata.bg)
    }

    private func refresh() async {
        await market.refresh(holdings: holdings, displayCurrency: currencyCode, in: context)
    }

    private func mask(_ value: Double) -> String {
        hideAmounts ? "••••••" : money(value, code: currencyCode)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center) {
            Text("Strata")
                .font(.strataDisplay(22))
                .foregroundStyle(Strata.onBrand)
            Spacer()
            Button { showingSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Strata.onBrand)
                    .frame(width: 40, height: 40)
                    .background(Strata.brandSoft.opacity(0.0))
            }
            .accessibilityLabel("Settings")
            StrataPlusButton { showingAdd = true }
        }
    }

    // MARK: Net worth + privacy eye

    private var netWorthBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("NET WORTH (\(currencyCode))")
                    .font(.system(.subheadline).weight(.semibold))
                    .foregroundStyle(Strata.onBrandSoft)
                Button {
                    Haptics.tap()
                    withAnimation(.snappy) { hideAmounts.toggle() }
                } label: {
                    Image(systemName: hideAmounts ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Strata.onBrandSoft)
                }
                .accessibilityLabel(hideAmounts ? "Show amounts" : "Hide amounts")
            }

            Text(mask(netWorth))
                .font(.strataAmount(40, weight: .heavy))
                .foregroundStyle(Strata.onBrand)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Button {
                Haptics.tap()
                showingTrend = true
            } label: {
                HStack(spacing: 6) {
                    if let delta = monthDelta, abs(delta) >= 1 {
                        Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10, weight: .black))
                        Text("\(delta >= 0 ? "+" : "−")\(mask(abs(delta))) this month")
                            .font(.system(.footnote).weight(.bold))
                    } else {
                        Text("View trend")
                            .font(.system(.footnote).weight(.bold))
                    }
                    Image(systemName: "chevron.right").font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(Strata.onBrand)
                .padding(.vertical, 7)
                .padding(.horizontal, 13)
                .background(.white.opacity(0.18), in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Composition (the signature strata)

    private var compositionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                StrataOverline(text: "Composition", tint: Strata.inkSoft)
                Spacer()
                Button { showingTrend = true } label: {
                    Text("Trend ›").font(.system(.footnote).weight(.bold))
                        .foregroundStyle(Strata.bg)
                }
                .buttonStyle(.plain)
            }
            StrataComposition(bands: bands)
        }
        .strataCard(padding: 16)
    }

    // MARK: Category cards (expand to real accounts / holdings)

    @ViewBuilder
    private func categoryCard(_ category: AccountCategory, value: Double) -> some View {
        let isOpen = expanded.contains(category.rawValue)
        let rows = displayedAssets.filter { $0.category == category }
        VStack(spacing: 0) {
            Button {
                Haptics.tap()
                withAnimation(.snappy) {
                    if isOpen { expanded.remove(category.rawValue) }
                    else { expanded.insert(category.rawValue) }
                }
            } label: {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Strata.color(for: category))
                        .frame(width: 5, height: 38)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.title)
                            .font(.system(.subheadline).weight(.bold))
                            .foregroundStyle(Strata.ink)
                        Text(subtitle(for: category, rows: rows))
                            .font(.caption).foregroundStyle(Strata.inkSoft)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    Text((category.isAsset ? "" : "−") + mask(value))
                        .font(.strataAmount(16, weight: .bold))
                        .foregroundStyle(category.isAsset ? Strata.ink : Strata.creditCard)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Strata.inkFaint)
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                }
            }
            .buttonStyle(.plain)

            if isOpen {
                VStack(spacing: 0) {
                    Strata.hairline.frame(height: 1).padding(.top, 12)
                    ForEach(rows) { account in
                        accountRow(account)
                    }
                    if category == .investment {
                        holdingsBlock
                    }
                }
            }
        }
        .strataCard(padding: 16)
    }

    private func subtitle(for category: AccountCategory, rows: [Account]) -> String {
        if category == .investment && !holdings.isEmpty {
            let names = (rows.map(\.name) + holdings.map(\.symbol)).prefix(3)
            return names.joined(separator: ", ")
        }
        if rows.isEmpty { return "Tap to view" }
        return rows.map(\.name).prefix(3).joined(separator: ", ")
    }

    private func accountRow(_ account: Account) -> some View {
        Button { editing = account } label: {
            HStack(spacing: 10) {
                Text(account.category.emoji).font(.footnote)
                Text(account.name)
                    .font(.system(.subheadline)).foregroundStyle(Strata.ink)
                Spacer(minLength: 8)
                Text(mask(account.balance))
                    .font(.strataAmount(14, weight: .semibold))
                    .foregroundStyle(Strata.inkSoft)
            }
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Edit") { editing = account }
            Button("Delete", role: .destructive) { context.delete(account) }
        }
    }

    // MARK: Holdings (live prices, same engine as the real tab)

    private var holdingsBlock: some View {
        VStack(spacing: 0) {
            let sorted = holdings.sorted { $0.cachedValueInBase > $1.cachedValueInBase }
            ForEach(sorted) { holding in
                Button { editingHolding = holding } label: {
                    holdingRow(holding)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button("Edit") { editingHolding = holding }
                    Button("Delete", role: .destructive) { deleteHolding(holding) }
                }
            }
            Button { showingSearch = true } label: {
                Label(holdings.isEmpty ? "Add an investment" : "Add another", systemImage: "plus")
                    .font(.system(.footnote).weight(.bold))
                    .foregroundStyle(Strata.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background { Capsule().strokeBorder(Strata.bg.opacity(0.4), lineWidth: 1.3) }
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            if market.isRefreshing {
                ProgressView().controlSize(.mini).padding(.top, 6)
            }
        }
    }

    private func holdingRow(_ holding: Holding) -> some View {
        let up = holding.cachedChangePercent >= 0
        return HStack(spacing: 10) {
            Text(String(holding.symbol.prefix(4)))
                .font(.system(.caption2).weight(.heavy))
                .foregroundStyle(Strata.investment)
                .frame(width: 34, height: 34)
                .background(Strata.investment.opacity(0.14), in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 1) {
                Text(holding.symbol).font(.system(.subheadline).weight(.semibold)).foregroundStyle(Strata.ink)
                Text(holding.companyName.isEmpty ? "—" : holding.companyName)
                    .font(.caption2).foregroundStyle(Strata.inkSoft).lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 1) {
                Text(mask(holding.cachedValueInBase))
                    .font(.strataAmount(14, weight: .semibold)).foregroundStyle(Strata.ink)
                Text((up ? "▲ " : "▼ ") + percentText(abs(holding.cachedChangePercent)))
                    .font(.caption2).foregroundStyle(up ? Strata.cash : Strata.creditCard)
            }
        }
        .padding(.vertical, 9)
        .contentShape(Rectangle())
    }

    private func deleteHolding(_ holding: Holding) {
        let remaining = holdings.filter { $0.persistentModelID != holding.persistentModelID }
        context.delete(holding)
        Investments.rebuild(holdings: remaining, in: context)
    }

    private var footnote: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let error = market.lastError {
                Text(error).font(.caption2).foregroundStyle(.white.opacity(0.9))
            }
            Text(updatedText).font(.caption2).foregroundStyle(Strata.onBrandSoft)
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

    // MARK: Banners / empty

    private var demoBanner: some View {
        HStack(spacing: 10) {
            Text("👀").font(.body)
            VStack(alignment: .leading, spacing: 1) {
                Text("Demo data").font(.system(.footnote).weight(.bold)).foregroundStyle(Strata.ink)
                Text("Exploring an example world. Your real data is safe.")
                    .font(.caption).foregroundStyle(Strata.inkSoft)
            }
            Spacer(minLength: 0)
        }
        .strataCard(padding: 14)
    }

    private var emptyCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 40)).foregroundStyle(Strata.bg)
            Text("Build your net worth")
                .font(.strataDisplay(21)).foregroundStyle(Strata.ink)
            Text("Add your cash, savings, investments, property, or anything you owe — and see it all break down into clear layers.")
                .font(.subheadline).foregroundStyle(Strata.inkSoft)
                .multilineTextAlignment(.center)
            StrataPrimaryButton(title: "Add an account", systemImage: "plus") { showingAdd = true }
        }
        .frame(maxWidth: .infinity)
        .strataCard(padding: 26)
        .padding(.top, 20)
    }
}
