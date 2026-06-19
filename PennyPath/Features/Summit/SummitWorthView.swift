//
//  SummitWorthView.swift
//  PennyPath
//
//  Summit's Net Worth screen: the net-worth number up top, then each category
//  as a full-width colored card lapping over the next into a deck — finished
//  with Apple's Liquid Glass material (`.glassEffect`, iOS 26+). Tap a card to
//  expand its real, editable accounts and live investments.
//
//  NOTE: per-account native currency + rate, true "updated" dates and
//  sub-category icons need fields the shared Account model doesn't have yet, so
//  the expanded rows approximate them (date = when added) pending a decision.
//

import SwiftUI
import SwiftData

struct SummitWorthView: View {
    /// Deep-links to the Goals tab's Milestones segment.
    var onShowMilestones: () -> Void

    @Environment(AppStore.self) private var store
    @Environment(\.modelContext) private var context
    @Query(sort: \Account.balance, order: .reverse) private var accounts: [Account]
    @Query private var holdings: [Holding]
    @Query(sort: \NetWorthSnapshot.date, order: .forward) private var snapshots: [NetWorthSnapshot]
    @AppStorage(AppSettings.currencyKey) private var currencyCode = "USD"

    @State private var market = MarketService()
    @State private var showingAddAccount = false
    @State private var editingAccount: Account?
    @State private var showingSearch = false
    @State private var editingHolding: Holding?
    @State private var showingSettings = false
    @State private var expandedKind: SummitAccountKind?
    @AppStorage("summitHideAmounts") private var hideAmounts = false

    /// How much each card laps over the one above it.
    private let deckOverlap: CGFloat = 58

    // MARK: Numbers

    private var netWorth: Double { accounts.reduce(0) { $0 + $1.signedBalance } }
    private var investmentsValue: Double { holdings.reduce(0) { $0 + $1.cachedValueInBase } }

    private func accountsIn(_ kind: SummitAccountKind) -> [Account] {
        accounts.filter { !$0.isMarketLinked && SummitAccountKind.of($0.category) == kind }
    }
    private func total(for kind: SummitAccountKind) -> Double {
        var sum = accountsIn(kind).reduce(0) { $0 + $1.signedBalance }
        if kind == .investment { sum += investmentsValue }
        return sum
    }
    private var activeKinds: [SummitAccountKind] {
        SummitAccountKind.allCases.filter { kind in
            !accountsIn(kind).isEmpty || (kind == .investment && !holdings.isEmpty)
        }
    }

    // MARK: Number formatting (no currency symbol — the header label carries it)

    private func maskInt(_ value: Double) -> String {
        hideAmounts ? "••••" : value.rounded().formatted(.number.precision(.fractionLength(0)))
    }
    private func split(_ value: Double) -> (whole: String, cents: String) {
        let negative = value < 0
        let magnitude = abs(value)
        var whole = magnitude.rounded(.towardZero)
        var cents = Int(((magnitude - whole) * 100).rounded())
        if cents >= 100 { cents -= 100; whole += 1 }
        return ((negative ? "−" : "") + whole.formatted(.number.precision(.fractionLength(0))),
                String(format: ".%02d", cents))
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header

                if store.isDemo { demoBanner }

                if accounts.isEmpty && holdings.isEmpty {
                    emptyCard
                } else {
                    categoryDeck
                    nextMilestoneChip.padding(.top, 8)
                    footnote
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(Color.adaptive(light: 0xEBEBF1, dark: 0x0F1012).ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAddAccount) { SummitAddAccountView() }
        .sheet(item: $editingAccount) { AccountFormView(account: $0) }
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
        .tint(Summit.accent)
    }

    private func refresh() async {
        await market.refresh(holdings: holdings, displayCurrency: currencyCode, in: context)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 7) {
                    Text("Net Worth (\(currencyCode))")
                        .font(.summitText(17, weight: .semibold))
                        .foregroundStyle(Summit.inkSoft)
                    Button {
                        Haptics.tap()
                        withAnimation(.snappy) { hideAmounts.toggle() }
                    } label: {
                        Image(systemName: hideAmounts ? "eye.slash" : "eye")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Summit.inkFaint)
                    }
                    .accessibilityLabel(hideAmounts ? "Show amounts" : "Hide amounts")
                }
                Text(maskInt(netWorth))
                    .font(.summitNumber(40, weight: .heavy))
                    .foregroundStyle(Summit.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            Spacer(minLength: 8)
            HStack(spacing: 10) {
                Button { showingSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Summit.inkSoft)
                        .frame(width: 40, height: 40)
                        .background(Summit.card, in: Circle())
                        .overlay(Circle().strokeBorder(Summit.hairline, lineWidth: 1))
                }
                .accessibilityLabel("Settings")
                Button {
                    Haptics.tap()
                    showingAddAccount = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Summit.accent)
                        .frame(width: 48, height: 48)
                        .background(Summit.accentSoft, in: Circle())
                }
                .accessibilityLabel("Add account")
            }
        }
        .padding(.bottom, 2)
    }

    // MARK: Category deck (overlapping Liquid Glass cards)

    private var categoryDeck: some View {
        VStack(spacing: -deckOverlap) {
            ForEach(activeKinds) { deckCard($0) }
        }
    }

    private func deckCard(_ kind: SummitAccountKind) -> some View {
        cardContent(kind)
            .background(kind.tint, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private func cardContent(_ kind: SummitAccountKind) -> some View {
        let isOpen = expandedKind == kind
        let value = total(for: kind)
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                Haptics.tap()
                withAnimation(.snappy) { expandedKind = isOpen ? nil : kind }
            } label: {
                HStack(spacing: 11) {
                    Image(systemName: kind.symbol)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(kind.onTint)
                        .frame(width: 32, height: 32)
                        .background(kind.onTint.opacity(0.18), in: Circle())
                    Text(kind.title)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(kind.onTint)
                    Spacer(minLength: 8)
                    Text((kind == .liability && value != 0 ? "−" : "") + maskInt(abs(value)))
                        .font(.summitNumber(20, weight: .heavy))
                        .foregroundStyle(kind.onTint)
                    Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(kind.onTint.opacity(0.8))
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isOpen {
                VStack(spacing: 10) {
                    ForEach(accountsIn(kind)) { account in
                        accountCard(account, tint: kind.deepTint)
                    }
                    if kind == .investment {
                        ForEach(holdings.sorted { $0.cachedValueInBase > $1.cachedValueInBase }) { holding in
                            holdingCard(holding, tint: kind.deepTint)
                        }
                        addCard("Add an investment", onColor: kind.onTint) { showingSearch = true }
                    }
                    addCard("Add to \(kind.title)", onColor: kind.onTint) { showingAddAccount = true }
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
            }
        }
        .padding(.bottom, 18 + deckOverlap)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Account / holding rows (white cards on the glass)

    private func accountCard(_ account: Account, tint: Color) -> some View {
        SummitDeletableRow(
            confirmTitle: "Delete \(account.name)?",
            confirmMessage: "This will be removed from your net worth. This can't be undone.",
            onEdit: { editingAccount = account },
            onDelete: { context.delete(account) }
        ) {
            rowCard(tint: tint, icon: SummitAccountKind.of(account.category).symbol,
                    title: account.name,
                    subtitle: "Added \(account.createdAt.formatted(.dateTime.day().month(.abbreviated).year()))",
                    value: account.balance,
                    date: account.createdAt.formatted(.dateTime.day().month(.abbreviated)))
        }
    }

    private func holdingCard(_ holding: Holding, tint: Color) -> some View {
        let up = holding.cachedChangePercent >= 0
        return SummitDeletableRow(
            confirmTitle: "Delete \(holding.symbol)?",
            confirmMessage: "This holding will be removed. This can't be undone.",
            onEdit: { editingHolding = holding },
            onDelete: { deleteHolding(holding) }
        ) {
            rowCard(tint: tint, icon: "chart.line.uptrend.xyaxis",
                    title: holding.symbol,
                    subtitle: (up ? "▲ " : "▼ ") + percentText(abs(holding.cachedChangePercent))
                              + (holding.companyName.isEmpty ? "" : " · \(holding.companyName)"),
                    value: holding.cachedValueInBase,
                    date: holding.lastUpdated?.formatted(.dateTime.day().month(.abbreviated)) ?? "")
        }
    }

    private func rowCard(tint: Color, icon: String, title: String, subtitle: String,
                         value: Double, date: String) -> some View {
        let parts = split(value)
        return HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 46, height: 46)
                .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Summit.ink)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Summit.inkSoft)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Group {
                    if hideAmounts {
                        Text("••••").foregroundStyle(tint)
                    } else {
                        Text(parts.whole).foregroundStyle(tint)
                            + Text(parts.cents).foregroundStyle(tint.opacity(0.5))
                    }
                }
                .font(.summitNumber(18, weight: .bold))
                Text(date)
                    .font(.system(size: 12))
                    .foregroundStyle(Summit.inkFaint)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Summit.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func addCard(_ title: String, onColor: Color, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus").font(.system(size: 14, weight: .bold))
                Text(title).font(.system(size: 15, weight: .semibold))
                Spacer(minLength: 0)
            }
            .foregroundStyle(onColor)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(onColor.opacity(0.5), style: StrokeStyle(lineWidth: 1.4, dash: [6, 5]))
            )
        }
        .buttonStyle(.plain)
    }

    private func deleteHolding(_ holding: Holding) {
        let remaining = holdings.filter { $0.persistentModelID != holding.persistentModelID }
        context.delete(holding)
        Investments.rebuild(holdings: remaining, in: context)
    }

    // MARK: Next milestone (compact chip → Goals · Milestones)

    private var nextMilestoneChip: some View {
        let next = SummitMilestones.next(after: netWorth)
        let progress = SummitMilestones.progress(netWorth)
        return Button {
            Haptics.tap()
            onShowMilestones()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: next == nil ? "mountain.2.fill" : "flag.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Summit.gold)
                    .frame(width: 34, height: 34)
                    .background(Summit.goldSoft, in: Circle())
                VStack(alignment: .leading, spacing: 5) {
                    Text(next == nil ? "All milestones reached 🏔️" : "Next milestone · \(summitCompact(next!))")
                        .font(.summitText(14, weight: .semibold))
                        .foregroundStyle(Summit.ink)
                        .lineLimit(1)
                    if next != nil {
                        SummitMeter(value: progress, tint: Summit.gold, height: 5)
                    }
                }
                Spacer(minLength: 8)
                if next != nil {
                    Text(percentText(progress))
                        .font(.summitNumber(15, weight: .bold))
                        .foregroundStyle(Summit.gold)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Summit.inkFaint)
            }
            .summitCard(padding: 14)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens milestones")
    }

    // MARK: Footnote / banners / empty

    private var footnote: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let error = market.lastError {
                Text(error).font(.summitText(11)).foregroundStyle(Summit.down)
            }
            Text(updatedSource).font(.summitText(11)).foregroundStyle(Summit.inkFaint)
        }
        .padding(.top, 2)
    }
    private var updatedSource: String {
        let source = "Prices may be delayed"
        if let date = market.lastUpdated {
            return "Updated \(date.formatted(.relative(presentation: .named))) · \(source)"
        }
        return source
    }

    private var demoBanner: some View {
        HStack(spacing: 10) {
            Text("👀").font(.body)
            Text("Demo data — your real numbers are safe.")
                .font(.summitText(13, weight: .medium))
                .foregroundStyle(Summit.inkSoft)
            Spacer(minLength: 0)
        }
        .summitCard(padding: 14)
    }

    private var emptyCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(Summit.accent)
            Text("Start your climb")
                .font(.summitSerif(22, weight: .semibold))
                .foregroundStyle(Summit.ink)
            Text("Add what you own and what you owe to see your net worth — and the first milestone to reach for.")
                .font(.summitText(14))
                .foregroundStyle(Summit.inkSoft)
                .multilineTextAlignment(.center)
            SummitPrimaryButton(title: "Add an account", systemImage: "plus") { showingAddAccount = true }
        }
        .frame(maxWidth: .infinity)
        .summitCard(padding: 28)
        .padding(.top, 24)
    }
}
