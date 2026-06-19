//
//  MonoUpcomingView.swift
//  PennyPath
//
//  Mono's "Upcoming" screen — subscriptions and scheduled future payments.
//  A three-stat header (monthly subs · total upcoming · due soon), an optional
//  "include in net worth" toggle that deducts monthly committed spend from the
//  Net Worth headline, then the list split into Subscriptions (recurring) and
//  Future Payments (one-off), with search and a quick stats breakdown.
//
//  Embedded inside the Expenses tab's scroll, so it's content only. The Expenses
//  floating + adds an item here (pre-set to the active tab) via `addRequested`.
//  "Mark paid" logs a real expense and rolls the date forward (auto-renewing
//  subscriptions) or clears it, keeping tracker and spending in sync.
//

import SwiftUI
import SwiftData

struct MonoUpcomingView: View {
    /// Flipped true by the Expenses floating + to open the add form here.
    @Binding var addRequested: Bool

    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @Query(sort: \UpcomingPayment.nextDueDate, order: .forward) private var payments: [UpcomingPayment]
    @AppStorage(AppSettings.currencyKey) private var currencyCode = "USD"
    /// Shared with the Net Worth screen: when on, monthly commitments are
    /// deducted from the displayed net worth.
    @AppStorage("monoIncludeCommitments") private var includeCommitments = false

    enum SubTab: String, CaseIterable { case subscriptions = "Subscriptions", future = "Future Payments" }

    @State private var subTab: SubTab = .subscriptions
    @State private var editing: UpcomingPayment?
    @State private var showingAdd = false
    @State private var searching = false
    @State private var query = ""
    @State private var showingStats = false

    // MARK: Derived numbers

    private var subscriptions: [UpcomingPayment] { payments.filter { $0.isSubscription } }
    private var oneOffs: [UpcomingPayment] { payments.filter { !$0.isSubscription } }
    private var monthlyTotal: Double { subscriptions.reduce(0) { $0 + $1.monthlyEquivalent } }
    private var upcomingTotal: Double { payments.reduce(0) { $0 + $1.amount } }
    private var dueSoonCount: Int {
        let soon = Date.now.adding(days: 7)
        return payments.filter { $0.nextDueDate <= soon }.count
    }

    private var visible: [UpcomingPayment] {
        let base = subTab == .subscriptions ? subscriptions : oneOffs
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if payments.isEmpty {
                emptyCard
            } else {
                statsCard
                controlRow
                if searching { searchField }
                if visible.isEmpty {
                    contextEmpty
                } else {
                    ForEach(visible) { row($0) }
                }
            }
        }
        .onChange(of: addRequested) { _, requested in
            if requested {
                showingAdd = true
                addRequested = false
            }
        }
        .sheet(isPresented: $showingAdd) {
            UpcomingPaymentFormView(initialIsSubscription: subTab == .subscriptions)
        }
        .sheet(item: $editing) { UpcomingPaymentFormView(payment: $0) }
        .sheet(isPresented: $showingStats) {
            MonoSubsStatsSheet(subscriptions: subscriptions, currencyCode: currencyCode)
        }
    }

    // MARK: Stats + toggle card

    private var statsCard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                stat("MONTHLY SUBS", value: compact(monthlyTotal), caption: "\(subscriptions.count) active")
                statDivider
                stat("UPCOMING", value: compact(upcomingTotal), caption: "\(payments.count) pending")
                statDivider
                stat("DUE SOON", value: "\(dueSoonCount)",
                     caption: "needs attention",
                     valueColor: dueSoonCount > 0 ? Mono.spend : Mono.onCanvas)
            }
            Rectangle().fill(Mono.onCanvasSoft.opacity(0.18)).frame(height: 1)
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Include in Net Worth")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Mono.onCanvas)
                    Text("Monthly committed spend deducted from today's net worth")
                        .font(.system(size: 13))
                        .foregroundStyle(Mono.onCanvasSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Toggle("", isOn: $includeCommitments)
                    .labelsHidden()
                    .tint(Mono.accentSoft)
            }
        }
        .monoPanel(padding: 18)
    }

    private func stat(_ overline: String, value: String, caption: String,
                      valueColor: Color = Mono.onCanvas) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(overline)
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.4)
                .foregroundStyle(Mono.onCanvasSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(caption)
                .font(.system(size: 12))
                .foregroundStyle(Mono.onCanvasSoft)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statDivider: some View {
        Rectangle().fill(Mono.onCanvasSoft.opacity(0.18)).frame(width: 1, height: 46)
    }

    // MARK: Control row (Subscriptions / Future Payments + search + stats)

    private var controlRow: some View {
        HStack(spacing: 6) {
            ForEach(SubTab.allCases, id: \.self) { tab in
                pill(tab.rawValue, active: subTab == tab) {
                    withAnimation(.snappy) { subTab = tab }
                }
            }
            Spacer(minLength: 4)
            iconButton("magnifyingglass", active: searching) {
                withAnimation(.snappy) {
                    searching.toggle()
                    if !searching { query = "" }
                }
            }
            iconButton("chart.bar", active: false) { showingStats = true }
        }
    }

    private func pill(_ title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
                .foregroundStyle(active ? Mono.plusInk : Mono.onCanvas)
                .padding(.vertical, 9)
                .padding(.horizontal, 13)
                .background {
                    if active { Capsule().fill(Mono.plus) }
                    else { Capsule().fill(Mono.onCanvasSoft.opacity(0.14)) }
                }
        }
        .buttonStyle(.plain)
    }

    private func iconButton(_ symbol: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(active ? Mono.accentSoft : Mono.onCanvasSoft)
                .frame(width: 34, height: 34)
                .background(Mono.glassFill(dark: scheme == .dark), in: Circle())
                .overlay(Circle().strokeBorder(Mono.glassStroke(dark: scheme == .dark), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Mono.onCanvasSoft)
            TextField("Search payments", text: $query)
                .font(.system(size: 15))
                .foregroundStyle(Mono.onCanvas)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 14)
        .background(Mono.glassFill(dark: scheme == .dark), in: Capsule())
        .overlay(Capsule().strokeBorder(Mono.glassStroke(dark: scheme == .dark), lineWidth: 1))
    }

    // MARK: Row

    private func row(_ payment: UpcomingPayment) -> some View {
        Button { editing = payment } label: {
            HStack(spacing: 12) {
                if !payment.iconURL.isEmpty, let url = URL(string: payment.iconURL) {
                    AppIconView(url: url, size: 40)
                } else {
                    Text(String(payment.name.prefix(1)).uppercased())
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Mono.accentSoft)
                        .frame(width: 40, height: 40)
                        .background(Mono.accentSoft.opacity(0.16),
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text(payment.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Mono.onCanvas)
                            .lineLimit(1)
                        if payment.remindMe {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(Mono.onCanvasSoft)
                        }
                    }
                    Text(dueLabel(payment))
                        .font(.system(size: 12))
                        .foregroundStyle(payment.isOverdue ? Mono.spend : Mono.onCanvasSoft)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(money(payment.amount, code: currencyCode))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Mono.onCanvas)
                    if payment.isSubscription && payment.cycleInterval == 1 {
                        Text("/ \(payment.cycleUnit.short)")
                            .font(.system(size: 11))
                            .foregroundStyle(Mono.onCanvasSoft)
                    }
                }
            }
            .monoPanel(padding: 14)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button { markPaid(payment) } label: { Label("Mark paid", systemImage: "checkmark.circle") }
            Button { editing = payment } label: { Label("Edit", systemImage: "pencil") }
            Button(role: .destructive) { context.delete(payment) } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private func dueLabel(_ payment: UpcomingPayment) -> String {
        let when = payment.isOverdue ? "Overdue · \(payment.nextDueDate.friendlyDay)"
                                     : "Due \(payment.nextDueDate.friendlyDay)"
        return payment.isSubscription ? "\(payment.cycleLabel) · \(when)" : when
    }

    // MARK: Empty states

    private var contextEmpty: some View {
        VStack(spacing: 8) {
            Image(systemName: query.isEmpty ? (subTab == .subscriptions ? "repeat.circle" : "calendar") : "magnifyingglass")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Mono.onCanvasSoft)
            Text(query.isEmpty
                 ? (subTab == .subscriptions ? "No subscriptions yet." : "No future payments scheduled.")
                 : "Nothing matches “\(query)”.")
                .font(.system(size: 14))
                .foregroundStyle(Mono.onCanvasSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .monoPanel(padding: 24)
    }

    private var emptyCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(Mono.accentSoft)
            Text("Track what's coming")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Mono.onCanvas)
            Text("Add your subscriptions and upcoming bills to see what they cost each month — and never be surprised by a renewal.")
                .font(.system(size: 14))
                .foregroundStyle(Mono.onCanvasSoft)
                .multilineTextAlignment(.center)
            Button {
                Haptics.tap()
                showingAdd = true
            } label: {
                Text("Add a payment")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Mono.plusInk)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 26)
                    .background(Mono.plus, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .monoPanel(padding: 28)
        .padding(.top, 8)
    }

    // MARK: Mark paid

    private func markPaid(_ payment: UpcomingPayment) {
        context.insert(Expense(amount: payment.amount,
                               category: payment.paidCategory,
                               note: payment.name, date: .now))
        if let next = payment.dueDateAfterPaying {
            payment.nextDueDate = next          // recurring → roll forward
        } else {
            context.delete(payment)             // one-off / non-renewing → done
        }
        Haptics.success()
    }

    // MARK: Compact money ($327, $7.0K)

    private func compact(_ value: Double) -> String {
        let symbol = AppSettings.currencySymbol
        let n = abs(value)
        func num(_ x: Double, _ frac: Int) -> String {
            x.formatted(.number.precision(.fractionLength(0...frac)))
        }
        if n >= 1_000_000 { return symbol + num(n / 1_000_000, 1) + "M" }
        if n >= 1_000 { return symbol + num(n / 1_000, 1) + "K" }
        return symbol + num(n, 0)
    }
}

// MARK: - Subscription stats sheet

private struct MonoSubsStatsSheet: View {
    let subscriptions: [UpcomingPayment]
    let currencyCode: String
    @Environment(\.dismiss) private var dismiss

    /// Monthly-equivalent spend per category, biggest first.
    private var byCategory: [(category: ExpenseCategory?, monthly: Double)] {
        Dictionary(grouping: subscriptions, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.monthlyEquivalent } }
            .map { (category: $0.key, monthly: $0.value) }
            .sorted { $0.monthly > $1.monthly }
    }
    private var total: Double { subscriptions.reduce(0) { $0 + $1.monthlyEquivalent } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("EVERY MONTH")
                            .font(.system(size: 11, weight: .semibold)).tracking(1)
                            .foregroundStyle(Mono.onCanvasSoft)
                        Text(money(total, code: currencyCode))
                            .font(.system(size: 38, weight: .bold))
                            .foregroundStyle(Mono.onCanvas)
                        Text("across \(subscriptions.count) subscription\(subscriptions.count == 1 ? "" : "s") · \(money(total * 12, code: currencyCode))/yr")
                            .font(.system(size: 13))
                            .foregroundStyle(Mono.onCanvasSoft)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .monoPanel(padding: 20)

                    let maxValue = byCategory.first?.monthly ?? 1
                    VStack(alignment: .leading, spacing: 14) {
                        Text("By category")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Mono.onCanvas)
                        ForEach(byCategory, id: \.category) { item in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(item.category?.title ?? "Uncategorized")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(Mono.onCanvas)
                                    MonoMeter(value: item.monthly / maxValue, tint: Mono.accentSoft, height: 8)
                                }
                                Text(money(item.monthly, code: currencyCode))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Mono.onCanvas)
                                    .frame(width: 80, alignment: .trailing)
                                    .lineLimit(1).minimumScaleFactor(0.7)
                            }
                        }
                    }
                    .monoPanel()
                }
                .padding(20)
            }
            .background(Mono.canvas.ignoresSafeArea())
            .navigationTitle("Subscriptions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .tint(Mono.accentSoft)
        }
    }
}
