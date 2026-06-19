//
//  ClarityWorthView.swift
//  PennyPath
//
//  Clarity's Worth screen: the one honest number, its history as a thin
//  ink line, then own / owe / investments as hairline ledgers. Accounts,
//  live prices and every form are the real ones.
//

import SwiftUI
import SwiftData

struct ClarityWorthView: View {
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

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                if accounts.isEmpty && holdings.isEmpty {
                    emptyState
                } else {
                    hero
                    if !displayedAssets.isEmpty {
                        ledger(title: "Own", total: assetTotal,
                               accounts: displayedAssets, tint: Clarity.good)
                    }
                    investmentsLedger
                    if !debts.isEmpty {
                        ledger(title: "Owe", total: debtTotal,
                               accounts: debts, tint: Clarity.rust)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(Clarity.paper)
        .toolbar(.hidden, for: .navigationBar)
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
        .onAppear { NetWorthHistory.record(in: context) }
        .onChange(of: netWorth) { _, _ in NetWorthHistory.record(in: context) }
        .tint(Clarity.cobalt)
    }

    private func refresh() async {
        await market.refresh(holdings: holdings, displayCurrency: currencyCode, in: context)
    }

    // MARK: Header & hero

    private var header: some View {
        HStack {
            ClarityOverline(text: "Net worth")
            Spacer()
            Button { showingAdd = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Clarity.inkSoft)
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(money(netWorth))
                .font(.clarityAmount(48))
                .foregroundStyle(netWorth >= 0 ? Clarity.ink : Clarity.rust)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            if let delta = monthDelta, abs(delta) >= 1 {
                Text("\(delta >= 0 ? "Up" : "Down") \(money(abs(delta))) this month")
                    .font(.subheadline)
                    .foregroundStyle(delta >= 0 ? Clarity.good : Clarity.rust)
            }

            if snapshots.count >= 2 {
                VStack(spacing: 8) {
                    Sparkline(values: snapshots.map(\.value),
                              tint: Clarity.ink, lineWidth: 1.5)
                        .frame(height: 100)
                    HStack {
                        ForEach(monthMarks, id: \.self) { mark in
                            Text(mark)
                                .font(.caption2)
                                .tracking(1)
                                .foregroundStyle(Clarity.inkFaint)
                            if mark != monthMarks.last { Spacer() }
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    private var monthMarks: [String] {
        guard snapshots.count >= 2 else { return [] }
        let idx = [0, snapshots.count / 3, snapshots.count * 2 / 3, snapshots.count - 1]
        return idx.map { snapshots[$0].date.formatted(.dateTime.month(.abbreviated)).uppercased() }
    }

    // MARK: Account ledgers

    private func ledger(title: String, total: Double,
                        accounts: [Account], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                ClarityOverline(text: title)
                Spacer()
                Text(money(total))
                    .font(.clarityAmount(14))
                    .foregroundStyle(tint)
            }
            .padding(.bottom, 6)

            ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                Button { editing = account } label: {
                    accountRow(account)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button("Edit") { editing = account }
                    Button("Delete", role: .destructive) { context.delete(account) }
                }
                if index < accounts.count - 1 { ClarityRule() }
            }
        }
    }

    private func accountRow(_ account: Account) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.subheadline)
                    .foregroundStyle(Clarity.ink)
                Text("\(account.category.emoji)  \(account.category.title)")
                    .font(.caption)
                    .foregroundStyle(Clarity.inkFaint)
            }
            Spacer(minLength: 12)
            Text(money(account.balance))
                .font(.clarityAmount(15))
                .foregroundStyle(Clarity.ink)
        }
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }

    // MARK: Investments

    private var investmentsLedger: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                ClarityOverline(text: "Investments")
                if market.isRefreshing {
                    ProgressView().controlSize(.mini).padding(.leading, 4)
                }
                Spacer()
                if !holdings.isEmpty {
                    Text(money(investmentsValue))
                        .font(.clarityAmount(14))
                        .foregroundStyle(Clarity.good)
                }
            }
            .padding(.bottom, 6)

            if !holdings.isEmpty {
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
                    if index < sorted.count - 1 { ClarityRule() }
                }
            }

            ClarityGhostButton(title: holdings.isEmpty ? "Add an investment" : "Add another",
                               systemImage: "plus", tint: Clarity.cobalt) {
                showingSearch = true
            }
            .padding(.top, 12)

            footnote.padding(.top, 10)
        }
    }

    private func holdingRow(_ holding: Holding) -> some View {
        let up = holding.cachedChangePercent >= 0
        return HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(holding.symbol)
                    .font(.subheadline)
                    .foregroundStyle(Clarity.ink)
                Text(holding.companyName.isEmpty ? "—" : holding.companyName)
                    .font(.caption)
                    .foregroundStyle(Clarity.inkFaint)
                    .lineLimit(1)
            }
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 2) {
                Text(money(holding.cachedValueInBase, code: currencyCode))
                    .font(.clarityAmount(15))
                    .foregroundStyle(Clarity.ink)
                Text((up ? "▲ " : "▼ ") + percentText(abs(holding.cachedChangePercent)))
                    .font(.caption2)
                    .foregroundStyle(up ? Clarity.good : Clarity.rust)
            }
        }
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }

    private var footnote: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let error = market.lastError {
                Text(error).font(.caption2).foregroundStyle(Clarity.rust)
            }
            Text(updatedText).font(.caption2).foregroundStyle(Clarity.inkFaint)
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

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("One number,\nhonestly kept.")
                .font(.clarityDisplay(26))
                .foregroundStyle(Clarity.ink)
                .lineSpacing(3)
            Text("Add your cash, savings, investments, and anything you owe. Own minus owe — that's the whole formula.")
                .font(.callout)
                .foregroundStyle(Clarity.inkSoft)
                .lineSpacing(3)
            ClarityButton(title: "Add an account") { showingAdd = true }
                .padding(.top, 6)
        }
        .padding(.top, 16)
    }
}
