//
//  EmberNetWorthView.swift
//  PennyPath
//
//  Ember's Net Worth screen on real data: one honest number (everything you own
//  minus everything you owe), then each money kind as a bronze card lapping into
//  a fanned deck. Tap a card to expand its real, editable accounts and live
//  investments. Investments are valued from live market data and roll into the
//  total. Adaptive light/dark.
//

import SwiftUI
import SwiftData

struct EmberNetWorthView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @Query(sort: \Account.balance, order: .reverse) private var accounts: [Account]
    @Query private var holdings: [Holding]
    @Query private var upcomingPayments: [UpcomingPayment]
    @AppStorage(AppSettings.currencyKey) private var currencyCode = "USD"
    /// Set from the Upcoming screen: deduct monthly committed spend from the
    /// displayed net worth.
    @AppStorage("emberIncludeCommitments") private var includeCommitments = false

    @State private var market = MarketService()
    @State private var showingAdd = false
    @State private var editingAccount: Account?
    @State private var showingSearch = false
    @State private var editingHolding: Holding?
    @State private var showingSettings = false
    @State private var showingAllocation = false
    @State private var expandedKind: EmberMoneyKind?

    private let tuck: CGFloat = 72
    private let lapVisible: CGFloat = 12

    // MARK: Numbers

    private var netWorth: Double { accounts.reduce(0) { $0 + $1.signedBalance } }
    private var investmentsValue: Double { holdings.reduce(0) { $0 + $1.cachedValueInBase } }
    /// Monthly-equivalent cost of recurring subscriptions.
    private var committedMonthly: Double {
        upcomingPayments.filter { $0.isSubscription }.reduce(0) { $0 + $1.monthlyEquivalent }
    }
    /// What the hero shows — optionally net of this month's commitments.
    private var displayedNetWorth: Double {
        includeCommitments ? netWorth - committedMonthly : netWorth
    }
    private var liabilityTotal: Double {
        accounts.filter { !$0.category.isAsset }.reduce(0) { $0 + $1.baseBalance }
    }
    private var assetTotal: Double { netWorth + liabilityTotal }

    /// Real, editable accounts of a kind — never the auto-managed investments account.
    private func accountsIn(_ kind: EmberMoneyKind) -> [Account] {
        accounts.filter { !$0.isMarketLinked && EmberMoneyKind.of($0.category) == kind }
    }
    private func total(for kind: EmberMoneyKind) -> Double {
        var sum = accountsIn(kind).reduce(0) { $0 + $1.signedBalance }
        if kind == .investment { sum += investmentsValue }
        return sum
    }
    private var activeKinds: [EmberMoneyKind] {
        EmberMoneyKind.allCases.filter { kind in
            !accountsIn(kind).isEmpty || (kind == .investment && !holdings.isEmpty)
        }
    }

    /// Boxes for the allocation grid — every category (assets and liability)
    /// as a share of the total balance-sheet footprint, largest first.
    private var allocationSlices: [EmberAllocationSlice] {
        let gross = assetTotal + liabilityTotal
        guard gross > 0 else { return [] }
        return activeKinds.compactMap { kind in
            let value = kind.isAsset ? total(for: kind) : liabilityTotal
            guard value > 0 else { return nil }
            return EmberAllocationSlice(kind: kind, value: value, pct: value / gross * 100)
        }
        .sorted { $0.value > $1.value }
    }

    private func subtitle(for kind: EmberMoneyKind) -> String {
        var names = accountsIn(kind).map(\.name)
        if kind == .investment, !holdings.isEmpty {
            names.append("\(holdings.count) holding\(holdings.count == 1 ? "" : "s")")
        }
        if names.count <= 2 { return names.joined(separator: ", ") }
        return "\(names.count) accounts"
    }

    /// Grouped whole number, no currency symbol — the header label carries it.
    private func groupInt(_ value: Double) -> String {
        value.rounded().formatted(.number.precision(.fractionLength(0)))
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                EmberHeader(title: "Net Worth (\(currencyCode))",
                            accessorySymbol: allocationSlices.isEmpty ? nil : "chart.pie.fill",
                            accessoryLabel: "Allocation",
                            onAccessory: { showingAllocation = true }) { showingSettings = true }

                if store.isDemo { demoBanner.padding(.top, 14) }

                Text(money(displayedNetWorth, code: currencyCode))
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(displayedNetWorth >= 0 ? Ember.onCanvas : Ember.spend)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.top, 8)

                HStack(spacing: 14) {
                    EmberGlassPill(label: "Assets", value: money(assetTotal, code: currencyCode))
                    EmberGlassPill(label: "Liabilities", value: money(liabilityTotal, code: currencyCode))
                }
                .padding(.top, 18)

                if accounts.isEmpty && holdings.isEmpty {
                    emptyCard.padding(.top, 26)
                } else {
                    deck.padding(.top, 22)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 10)
            .padding(.bottom, 96)   // clear the floating tab bar
        }
        .scrollIndicators(.hidden)
        .background(Ember.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .bottomTrailing) {
            EmberPlusButton { showingAdd = true }
                .padding(.trailing, 22)
                .padding(.bottom, 58)   // sit just above the floating tab bar
        }
        .sheet(isPresented: $showingAdd) { EmberAddAccountView() }
        .sheet(item: $editingAccount) { AccountFormView(account: $0) }
        .sheet(isPresented: $showingSearch) { HoldingSearchView(service: market) }
        .sheet(item: $editingHolding) { holding in
            NavigationStack { HoldingFormView(holding: holding) }
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .fullScreenCover(isPresented: $showingAllocation) {
            EmberAllocationView(slices: allocationSlices, netWorth: netWorth,
                                currencyCode: currencyCode) { showingAllocation = false }
        }
        .refreshable { await refresh() }
        .task { await refresh() }
        .onChange(of: holdings.count) { _, _ in Task { await refresh() } }
        .onChange(of: currencyCode) { _, _ in Task { await refresh() } }
        .onAppear { NetWorthHistory.record(in: context) }
        .onChange(of: netWorth) { _, _ in NetWorthHistory.record(in: context) }
    }

    private func refresh() async {
        await market.refresh(holdings: holdings, displayCurrency: currencyCode, in: context)
    }

    // MARK: Fanned deck

    private var deck: some View {
        VStack(spacing: -(tuck - lapVisible)) {
            ForEach(Array(activeKinds.enumerated()), id: \.element.id) { index, kind in
                deckCard(kind, isLast: index == activeKinds.count - 1)
                    .zIndex(Double(index))
            }
        }
    }

    private func deckCard(_ kind: EmberMoneyKind, isLast: Bool) -> some View {
        let isExpanded = expandedKind == kind
        let value = total(for: kind)
        let cardIsDark = true   // every deck card is now a dark bronze surface
        let shape = RoundedRectangle(cornerRadius: Ember.cardRadius, style: .continuous)

        return VStack(spacing: 0) {
            Button {
                Haptics.tap()
                withAnimation(.snappy) { expandedKind = isExpanded ? nil : kind }
            } label: {
                cardHeader(kind, value: value, isExpanded: isExpanded)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(accountsIn(kind)) { account in
                        subRow(name: account.name,
                               value: groupInt(account.balance),
                               kind: kind, cardIsDark: cardIsDark,
                               onTap: { editingAccount = account },
                               onDelete: { context.delete(account) })
                    }
                    if kind == .investment {
                        ForEach(holdings.sorted { $0.cachedValueInBase > $1.cachedValueInBase }) { holding in
                            subRow(name: holding.symbol,
                                   value: groupInt(holding.cachedValueInBase),
                                   kind: kind, cardIsDark: cardIsDark,
                                   onTap: { editingHolding = holding },
                                   onDelete: { deleteHolding(holding) })
                        }
                        addRow("Add an investment", kind: kind, cardIsDark: cardIsDark) { showingSearch = true }
                    }
                }
                .padding(.top, 12)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, isLast ? 24 : tuck)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            shape.fill(LinearGradient(colors: [kind.fill, kind.fillBottom],
                                      startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(shape.fill(LinearGradient(
                    colors: [.white.opacity(0.20), .white.opacity(0.04), .clear],
                    startPoint: .topLeading, endPoint: .bottomTrailing)))
        }
        .overlay(
            shape.strokeBorder(LinearGradient(
                colors: [.white.opacity(0.55), .white.opacity(0.14), .white.opacity(0.04)],
                startPoint: .top, endPoint: .bottom), lineWidth: 1.2)
        )
        .shadow(color: .black.opacity(0.18), radius: 7, y: -3)
    }

    private func cardHeader(_ kind: EmberMoneyKind, value: Double, isExpanded: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(kind.title)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(kind.primary)
                Text(subtitle(for: kind))
                    .font(.system(size: 13))
                    .foregroundStyle(kind.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                Text(groupInt(abs(value)))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(kind.primary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(kind.secondary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(kind.title), \(money(abs(value), code: currencyCode)), \(subtitle(for: kind))")
        .accessibilityHint(isExpanded ? "Collapse" : "Expand to see accounts")
    }

    private func subRow(name: String, value: String, kind: EmberMoneyKind,
                        cardIsDark: Bool, onTap: @escaping () -> Void,
                        onDelete: @escaping () -> Void) -> some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        return Button(action: onTap) {
            HStack(spacing: 8) {
                Text(name)
                    .font(.system(size: 16))
                    .foregroundStyle(kind.primary)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(kind.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.white.opacity(cardIsDark ? 0.12 : 0.45), in: shape)
            .overlay(shape.strokeBorder(cardIsDark ? .white.opacity(0.22) : .black.opacity(0.18), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Edit", action: onTap)
            Button("Delete", role: .destructive, action: onDelete)
        }
    }

    private func addRow(_ title: String, kind: EmberMoneyKind, cardIsDark: Bool,
                        action: @escaping () -> Void) -> some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        return Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus").font(.system(size: 14, weight: .bold))
                Text(title).font(.system(size: 15, weight: .semibold))
                Spacer(minLength: 0)
            }
            .foregroundStyle(kind.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(shape.strokeBorder(kind.primary.opacity(cardIsDark ? 0.4 : 0.5),
                                           style: StrokeStyle(lineWidth: 1.4, dash: [6, 5])))
        }
        .buttonStyle(.plain)
    }

    private func deleteHolding(_ holding: Holding) {
        let remaining = holdings.filter { $0.persistentModelID != holding.persistentModelID }
        context.delete(holding)
        Investments.rebuild(holdings: remaining, in: context)
    }

    // MARK: Banner / empty

    private var demoBanner: some View {
        HStack(spacing: 10) {
            Text("👀").font(.body)
            Text("Demo data — your real numbers are safe.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Ember.onCanvas)
            Spacer(minLength: 0)
        }
        .emberPanel(padding: 14)
    }

    private var emptyCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(Ember.accent)
            Text("Add your first account")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Ember.onCanvas)
            Text("Put in your cash, savings, investments, or anything you owe — and watch the one number that matters take shape.")
                .font(.system(size: 14))
                .foregroundStyle(Ember.onCanvasSoft)
                .multilineTextAlignment(.center)
            Button {
                Haptics.tap()
                showingAdd = true
            } label: {
                Text("Add an account")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Ember.plusInk)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 26)
                    .background(Ember.plus, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .emberPanel(padding: 28)
    }
}
