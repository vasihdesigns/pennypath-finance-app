//
//  PrismWorthView.swift
//  PennyPath
//
//  Prism reskin of Net Worth — the star screen. One big private number, an
//  Assets / Liabilities split, then every money kind as a muted, hue-coded
//  gradient box that expands to the real, editable accounts and live
//  investments. Flat canvas, colour lives in the boxes.
//

import SwiftUI
import SwiftData

struct PrismWorthView: View {
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
                    splitRow
                    if !assetBuckets.isEmpty {
                        PrismOverline(text: "What you own").padding(.top, 2)
                        ForEach(assetBuckets, id: \.category) { bucket in
                            categoryCard(bucket.category, value: bucket.value)
                        }
                    }
                    if !debtBuckets.isEmpty {
                        PrismOverline(text: "What you owe").padding(.top, 4)
                        ForEach(debtBuckets, id: \.category) { bucket in
                            categoryCard(bucket.category, value: bucket.value)
                        }
                    }
                    footnote
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(Prism.bg.ignoresSafeArea())
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
        .tint(Prism.accent)
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
            Text("Net Worth")
                .font(.prismDisplay(24))
                .foregroundStyle(Prism.ink)
            Spacer()
            PrismIconButton(systemImage: "gearshape.fill",
                            accessibilityLabel: "Settings") { showingSettings = true }
            PrismPlusButton { showingAdd = true }
        }
    }

    // MARK: Net worth + privacy eye

    private var netWorthBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("NET WORTH (\(currencyCode))")
                    .font(.system(.subheadline).weight(.semibold))
                    .foregroundStyle(Prism.inkSoft)
                Button {
                    Haptics.tap()
                    withAnimation(.snappy) { hideAmounts.toggle() }
                } label: {
                    Image(systemName: hideAmounts ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Prism.inkSoft)
                }
                .accessibilityLabel(hideAmounts ? "Show amounts" : "Hide amounts")
            }

            Text(mask(netWorth))
                .font(.prismAmount(42, weight: .heavy))
                .foregroundStyle(Prism.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            if let delta = monthDelta, abs(delta) >= 1 {
                HStack(spacing: 5) {
                    Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .black))
                    Text("\(delta >= 0 ? "+" : "−")\(mask(abs(delta))) this month")
                        .font(.system(.footnote).weight(.bold))
                }
                .foregroundStyle(delta >= 0 ? Prism.accent : Prism.tint(for: .creditCard))
                .padding(.top, 1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Assets / Liabilities split

    private var splitRow: some View {
        HStack(spacing: 12) {
            splitCard(label: "Assets", value: assetTotal, gradient: Prism.gradient(for: .cash))
            splitCard(label: "Liabilities", value: debtTotal, gradient: Prism.gradient(for: .creditCard))
        }
    }

    private func splitCard(label: String, value: Double, gradient: LinearGradient) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            PrismOverline(text: label, tint: .white.opacity(0.92))
            Text(mask(value))
                .font(.prismAmount(20, weight: .heavy))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .prismGradientCard(gradient, padding: 15)
    }

    // MARK: Category cards (gradient boxes that expand)

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
                    Text(category.emoji)
                        .font(.system(size: 17))
                        .frame(width: 40, height: 40)
                        .background(.white.opacity(0.18),
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.title)
                            .font(.system(.subheadline).weight(.bold))
                            .foregroundStyle(.white)
                        Text(subtitle(for: category, rows: rows))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    Text((category.isAsset ? "" : "−") + mask(value))
                        .font(.prismAmount(17, weight: .bold))
                        .foregroundStyle(.white)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                }
            }
            .buttonStyle(.plain)

            if isOpen {
                VStack(spacing: 0) {
                    Rectangle().fill(.white.opacity(0.2)).frame(height: 1).padding(.top, 12)
                    ForEach(rows) { account in
                        accountRow(account)
                    }
                    if category == .investment {
                        holdingsBlock
                    }
                }
            }
        }
        .prismGradientCard(Prism.gradient(for: category), padding: 16)
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
                Text(account.name)
                    .font(.system(.subheadline)).foregroundStyle(.white)
                Spacer(minLength: 8)
                Text(mask(account.balance))
                    .font(.prismAmount(14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
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
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background { Capsule().strokeBorder(.white.opacity(0.6), lineWidth: 1.3) }
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            if market.isRefreshing {
                ProgressView().controlSize(.mini).tint(.white).padding(.top, 6)
            }
        }
    }

    private func holdingRow(_ holding: Holding) -> some View {
        let up = holding.cachedChangePercent >= 0
        return HStack(spacing: 10) {
            Text(String(holding.symbol.prefix(4)))
                .font(.system(.caption2).weight(.heavy))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 1) {
                Text(holding.symbol)
                    .font(.system(.subheadline).weight(.semibold)).foregroundStyle(.white)
                Text(holding.companyName.isEmpty ? "—" : holding.companyName)
                    .font(.caption2).foregroundStyle(.white.opacity(0.75)).lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 1) {
                Text(mask(holding.cachedValueInBase))
                    .font(.prismAmount(14, weight: .semibold)).foregroundStyle(.white)
                Text((up ? "▲ " : "▼ ") + percentText(abs(holding.cachedChangePercent)))
                    .font(.caption2).foregroundStyle(.white.opacity(0.9))
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
                Text(error).font(.caption2).foregroundStyle(Prism.tint(for: .creditCard))
            }
            Text(updatedText).font(.caption2).foregroundStyle(Prism.inkFaint)
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
                Text("Demo data").font(.system(.footnote).weight(.bold)).foregroundStyle(Prism.ink)
                Text("Exploring an example world. Your real data is safe.")
                    .font(.caption).foregroundStyle(Prism.inkSoft)
            }
            Spacer(minLength: 0)
        }
        .prismSurfaceCard(padding: 14)
    }

    private var emptyCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 40)).foregroundStyle(Prism.accent)
            Text("Build your net worth")
                .font(.prismDisplay(21)).foregroundStyle(Prism.ink)
            Text("Add your cash, savings, investments, property, or anything you owe — and see each kind in its own colour.")
                .font(.subheadline).foregroundStyle(Prism.inkSoft)
                .multilineTextAlignment(.center)
            PrismPrimaryButton(title: "Add an account", systemImage: "plus") { showingAdd = true }
        }
        .frame(maxWidth: .infinity)
        .prismSurfaceCard(padding: 26)
        .padding(.top, 20)
    }
}
