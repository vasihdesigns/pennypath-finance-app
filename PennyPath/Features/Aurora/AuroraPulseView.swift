//
//  AuroraPulseView.swift
//  PennyPath
//
//  Aurora reskin of Net Worth: greeting under the stars, the one big
//  number as a glowing gradient hero with a delta chip and trajectory
//  line, then "what you own / owe" as constellation cards. Accounts,
//  live investments and every form are the real ones.
//

import SwiftUI
import SwiftData

struct AuroraPulseView: View {
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

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                header

                if store.isDemo { demoBanner }

                if accounts.isEmpty && holdings.isEmpty {
                    emptyCard
                } else {
                    hero
                    splitCard
                    if !displayedAssets.isEmpty {
                        accountGroup(title: "What you own",
                                     accounts: displayedAssets, tint: Aurora.mint)
                    }
                    investmentsSection
                    if !debts.isEmpty {
                        accountGroup(title: "What you owe",
                                     accounts: debts, tint: Aurora.coral)
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(AuroraSky())
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
        .tint(Aurora.mint)
    }

    private func refresh() async {
        await market.refresh(holdings: holdings, displayCurrency: currencyCode, in: context)
    }

    // MARK: Header

    private var dateLine: String {
        Date.now.formatted(.dateTime.weekday(.wide)) + " · " +
        Date.now.formatted(.dateTime.month(.wide).day())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                AuroraOverline(text: dateLine)
                Spacer()
                HStack(spacing: 16) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Aurora.inkSoft)
                    }
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Aurora.inkSoft)
                    }
                }
            }
            Text(InsightsEngine.greeting() + " ✦")
                .font(.auroraDisplay(28))
                .foregroundStyle(Aurora.ink)
        }
    }

    // MARK: Demo banner

    private var demoBanner: some View {
        HStack(spacing: 10) {
            Text("👀").font(.body)
            VStack(alignment: .leading, spacing: 1) {
                Text("Demo data")
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundStyle(Aurora.ink)
                Text("Exploring an example universe. Your real data is safe.")
                    .font(.caption).foregroundStyle(Aurora.inkSoft)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Aurora.gold.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            AuroraOverline(text: "Net worth")

            Text(money(netWorth))
                .font(.auroraAmount(46))
                .foregroundStyle(netWorth >= 0 ? AnyShapeStyle(Aurora.beam)
                                               : AnyShapeStyle(Aurora.coral))
                .shadow(color: (netWorth >= 0 ? Aurora.mint : Aurora.coral).opacity(0.35),
                        radius: 16)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            if let delta = monthDelta, abs(delta) >= 1 {
                HStack(spacing: 5) {
                    Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                    Text("\(delta >= 0 ? "+" : "−")\(money(abs(delta))) this month")
                        .font(.system(.footnote, design: .rounded).weight(.bold))
                }
                .foregroundStyle(delta >= 0 ? Aurora.mint : Aurora.coral)
                .padding(.vertical, 7)
                .padding(.horizontal, 13)
                .background((delta >= 0 ? Aurora.mint : Aurora.coral).opacity(0.12),
                            in: Capsule())
            }

            if snapshots.count >= 2 {
                trajectory.padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .auroraCard(padding: 22, glow: netWorth >= 0 ? Aurora.mint : Aurora.coral)
    }

    private var trajectory: some View {
        VStack(spacing: 8) {
            Sparkline(values: snapshots.map(\.value), tint: Aurora.mint, lineWidth: 2.5)
                .frame(height: 110)
                .shadow(color: Aurora.mint.opacity(0.5), radius: 8)
            HStack {
                ForEach(monthMarks, id: \.self) { mark in
                    Text(mark)
                        .font(.system(.caption2, design: .rounded).weight(.semibold))
                        .tracking(1.2)
                        .foregroundStyle(Aurora.inkFaint)
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

    // MARK: Own / owe split

    private var splitCard: some View {
        HStack(spacing: 12) {
            splitTile(title: "Own", amount: assetTotal, tint: Aurora.mint,
                      symbol: "sun.max.fill")
            splitTile(title: "Owe", amount: debtTotal, tint: Aurora.coral,
                      symbol: "moon.fill")
        }
    }

    private func splitTile(title: String, amount: Double, tint: Color, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(tint)
                AuroraOverline(text: title, tint: tint)
            }
            Text(money(amount))
                .font(.auroraAmount(21))
                .foregroundStyle(Aurora.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .auroraCard(padding: 18)
    }

    // MARK: Accounts (same behaviour as the real tab)

    private func accountGroup(title: String, accounts: [Account], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            AuroraOverline(text: title)
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
                        Aurora.hairline.frame(height: 1)
                    }
                }
            }
            .auroraCard(padding: 6)
        }
    }

    private func accountRow(_ account: Account, tint: Color) -> some View {
        HStack(spacing: 12) {
            Text(account.category.emoji)
                .font(.body)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Aurora.ink)
                Text(account.category.title)
                    .font(.caption).foregroundStyle(Aurora.inkSoft)
            }
            Spacer(minLength: 8)
            Text(money(account.balance))
                .font(.auroraAmount(16, weight: .semibold))
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    // MARK: Investments (live prices, same as the real tab)

    private var investmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                AuroraOverline(text: "Investments")
                if market.isRefreshing {
                    ProgressView().controlSize(.mini).padding(.leading, 2)
                }
                Spacer()
                if !holdings.isEmpty {
                    Text(money(investmentsValue))
                        .font(.auroraAmount(15, weight: .semibold))
                        .foregroundStyle(Aurora.violet)
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
                            Aurora.hairline.frame(height: 1)
                        }
                    }
                }
                .auroraCard(padding: 6)
            }

            Button { showingSearch = true } label: {
                Label(holdings.isEmpty ? "Add an investment" : "Add another",
                      systemImage: "plus")
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundStyle(Aurora.violet)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background {
                        Capsule().strokeBorder(Aurora.violet.opacity(0.5), lineWidth: 1.2)
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
                .foregroundStyle(Aurora.violet)
                .frame(width: 38, height: 38)
                .background(Aurora.violet.opacity(0.14), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(holding.symbol)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Aurora.ink)
                Text(holding.companyName.isEmpty ? "—" : holding.companyName)
                    .font(.caption).foregroundStyle(Aurora.inkSoft).lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(money(holding.cachedValueInBase, code: currencyCode))
                    .font(.auroraAmount(15, weight: .semibold))
                    .foregroundStyle(Aurora.ink)
                Text((up ? "▲ " : "▼ ") + percentText(abs(holding.cachedChangePercent)))
                    .font(.caption2)
                    .foregroundStyle(up ? Aurora.mint : Aurora.coral)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }

    private var footnote: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let error = market.lastError {
                Text(error).font(.caption2).foregroundStyle(Aurora.coral)
            }
            Text(updatedText).font(.caption2).foregroundStyle(Aurora.inkFaint)
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
            Text("🌌").font(.system(size: 40))
            Text("Light up your universe")
                .font(.auroraDisplay(21))
                .foregroundStyle(Aurora.ink)
            Text("Add your cash, savings, investments, or anything you owe — and watch your one number appear among the stars.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Aurora.inkSoft)
                .multilineTextAlignment(.center)
            AuroraBeamButton(title: "Add an account") { showingAdd = true }
        }
        .frame(maxWidth: .infinity)
        .auroraCard(padding: 28, glow: Aurora.violet)
        .padding(.top, 30)
    }
}
