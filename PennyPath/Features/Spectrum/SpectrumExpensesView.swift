//
//  SpectrumExpensesView.swift
//  PennyPath
//
//  Spectrum's Expenses screen on real data: what you spent this month, where it
//  went, and a running day-by-day list. A Budget toggle drops in the real
//  Budget editor. Every form is the real one.
//

import SwiftUI
import SwiftData

struct SpectrumExpensesView: View {
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var budgets: [CategoryBudget]
    @AppStorage(AppSettings.currencyKey) private var currencyCode = "USD"
    @Environment(\.colorScheme) private var scheme

    @State private var showingAdd = false
    @State private var showingSettings = false
    @State private var mode: Mode = .spent
    @State private var range: Range = .month
    /// Flipped by the floating + when on the Upcoming tab, handled inside it.
    @State private var upcomingAddRequested = false

    enum Mode: String, CaseIterable, Identifiable {
        case spent = "Spending", upcoming = "Upcoming", budget = "Budget"
        var id: String { rawValue }
    }

    /// The time window the Spending view is scoped to.
    enum Range: String, CaseIterable, Identifiable {
        case today = "Today", month = "Month", year = "Year"
        var id: String { rawValue }
        /// The full label for the hero ("SPENT TODAY / THIS MONTH / THIS YEAR").
        var heroSuffix: String {
            switch self {
            case .today: return "TODAY"
            case .month: return "THIS MONTH"
            case .year:  return "THIS YEAR"
            }
        }
    }

    private func inRange(_ date: Date) -> Bool {
        switch range {
        case .today: return date.isSameDay(as: .now)
        case .month: return date.isSameMonth(as: .now)
        case .year:  return date.isSameYear(as: .now)
        }
    }

    /// Monthly budgets are pro-rated to the chosen window so the bars stay
    /// meaningful: a daily slice today, ×12 across the year.
    private var budgetScale: Double {
        switch range {
        case .today:
            let days = Calendar.current.range(of: .day, in: .month, for: .now)?.count ?? 30
            return 1 / Double(days)
        case .month: return 1
        case .year:  return 12
        }
    }

    private var windowTotal: Double {
        expenses.filter { inRange($0.date) }.reduce(0) { $0 + $1.amount }
    }
    private var totalBudget: Double { budgets.reduce(0) { $0 + $1.monthlyLimit } * budgetScale }

    private func spent(_ category: ExpenseCategory) -> Double {
        expenses
            .filter { $0.category == category && inRange($0.date) }
            .reduce(0) { $0 + $1.amount }
    }

    /// Budgeted categories paired with this month's spend, most-burned first so
    /// the categories nearing (or over) their limit float to the top.
    private var budgetBurnRows: [(budget: CategoryBudget, spent: Double)] {
        budgets
            .map { (budget: $0, spent: spent($0.category)) }
            .sorted { ($0.spent / max($0.budget.monthlyLimit, 1)) > ($1.spent / max($1.budget.monthlyLimit, 1)) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                SpectrumHeader(title: "Expenses") { showingSettings = true }
                SpectrumSegmented(items: Mode.allCases, title: \.rawValue, selection: $mode)

                switch mode {
                case .spent:
                    if expenses.isEmpty {
                        // Budgets set but nothing spent yet still show their bars.
                        if !budgets.isEmpty { budgetBurnCard } else { emptyCard }
                    } else {
                        // The spend total sits above the category bars so the two
                        // together fit one screen without scrolling.
                        heroCard
                        if !budgets.isEmpty { budgetBurnCard } else { budgetInviteCard }
                    }
                case .upcoming:
                    SpectrumUpcomingView(addRequested: $upcomingAddRequested)
                case .budget:
                    SpectrumBudgetView()
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 96)   // clear the floating tab bar
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(Spectrum.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .bottomTrailing) {
            if mode != .budget {
                SpectrumPlusButton {
                    if mode == .upcoming { upcomingAddRequested = true }
                    else { showingAdd = true }
                }
                .padding(.trailing, 22)
                .padding(.bottom, 58)   // sit just above the floating tab bar
            }
        }
        .sheet(isPresented: $showingAdd) {
            // One add flow: if the user flips on "Repeats" (or picks a future
            // date) it becomes a subscription / scheduled payment and lands in
            // Upcoming — so jump them there to see it.
            SpectrumAddItemView(onSaved: { landedInUpcoming in
                if landedInUpcoming { withAnimation(.snappy) { mode = .upcoming } }
            })
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
    }

    // MARK: Budget burn (headline)

    private var budgetBurnCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(budgetBurnRows, id: \.budget.id) { row in
                NavigationLink {
                    SpectrumCategoryDetailView(category: row.budget.category)
                } label: {
                    SpectrumBudgetBurnBar(
                        category: row.budget.category,
                        spent: row.spent,
                        budget: row.budget.monthlyLimit * budgetScale,
                        currencyCode: currencyCode
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Shown when there's spending but no budgets yet — invites the feature.
    private var budgetInviteCard: some View {
        Button {
            Haptics.tap()
            withAnimation(.snappy) { mode = .budget }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Spectrum.accentSoft)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Set budgets to watch them fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Spectrum.onCanvas)
                    Text("Each category fills and changes colour as you spend.")
                        .font(.system(size: 12))
                        .foregroundStyle(Spectrum.onCanvasSoft)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Spectrum.onCanvasSoft)
            }
            .spectrumPanel()
        }
        .buttonStyle(.plain)
    }

    // MARK: Hero

    private var heroCard: some View {
        let total = windowTotal
        let over = totalBudget > 0 && total > totalBudget
        let usedRatio = totalBudget > 0 ? total / totalBudget : 0
        let pctLeft = max(0, Int(((totalBudget - total) / max(totalBudget, 1) * 100).rounded()))
        return VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .center) {
                Text("SPENT \(range.heroSuffix)")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(Spectrum.onCanvasSoft)
                Spacer(minLength: 8)
                rangePicker
            }
            Text(money(total, code: currencyCode))
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Spectrum.onCanvas)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            if totalBudget > 0 {
                SpectrumMeter(value: min(1, usedRatio),
                              tint: over ? Spectrum.overBudget : Spectrum.good,
                              height: 7)
                    .padding(.top, 7)
                Text(over
                     ? "\(money(total - totalBudget, code: currencyCode)) over your \(money(totalBudget, code: currencyCode)) budget"
                     : "\(pctLeft)% of \(money(totalBudget, code: currencyCode)) budget left")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(over ? Spectrum.spend : Spectrum.onCanvasSoft)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .spectrumPanel(padding: 14)
    }

    /// Small Today / Month / Year scope toggle that lives in the hero header.
    private var rangePicker: some View {
        HStack(spacing: 2) {
            ForEach(Range.allCases) { r in
                let on = r == range
                Button {
                    Haptics.tap()
                    withAnimation(.snappy) { range = r }
                } label: {
                    Text(r.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(on ? Spectrum.plusInk : Spectrum.onCanvasSoft)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background { if on { Capsule().fill(Spectrum.accentSoft) } }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Spectrum.glassFill(dark: scheme == .dark), in: Capsule())
        .accessibilityLabel("Time range")
    }

    // MARK: Empty

    private var emptyCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "creditcard")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(Spectrum.accentSoft)
            Text("Track your first expense")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Spectrum.onCanvas)
            Text("Every time you spend, jot it down. Soon you'll see exactly where your money goes.")
                .font(.system(size: 14))
                .foregroundStyle(Spectrum.onCanvasSoft)
                .multilineTextAlignment(.center)
            Button {
                Haptics.tap()
                showingAdd = true
            } label: {
                Text("Add an expense")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Spectrum.plusInk)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 26)
                    .background(Spectrum.plus, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .spectrumPanel(padding: 28)
        .padding(.top, 8)
    }
}

// MARK: - Small shared pieces

/// A full-width budget "burn" bar: a dashed track = the monthly limit, a solid
/// block that fills left→right with what's been spent, in the category's own
/// fixed colour. The label flips from dark (over the empty track) to white (over
/// the filled block) exactly at the fill edge.
private struct SpectrumBudgetBurnBar: View {
    let category: ExpenseCategory
    let spent: Double
    let budget: Double
    let currencyCode: String

    private var ratio: Double { budget > 0 ? spent / budget : 0 }
    private var fill: Double { min(1, max(0, ratio)) }
    private var isOver: Bool { spent > budget + 0.005 }
    /// The category's own colour — but a clear red once it's over budget.
    private var color: Color { isOver ? Spectrum.overBudget : Spectrum.categoryColor(category) }

    private let height: CGFloat = 44
    private let radius: CGFloat = 15

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let fillW = fill * w
            ZStack(alignment: .leading) {
                // The unfilled track — a faint wash of the category's own colour,
                // full width standing in for 100% of the budget.
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(color.opacity(0.20))
                // The filled block — what's been spent, in the category colour.
                if fillW > 0.5 {
                    RoundedRectangle(cornerRadius: min(radius, fillW / 2), style: .continuous)
                        .fill(color.gradient)
                        .frame(width: fillW)
                }
                // Label drawn dark (reads over the empty light track) …
                label(primary: Spectrum.onCanvas, secondary: Spectrum.onCanvasSoft)
                // … then white, masked to the filled block (reads over the colour).
                label(primary: .white, secondary: .white.opacity(0.85))
                    .mask(alignment: .leading) { Rectangle().frame(width: fillW) }
            }
        }
        .frame(height: height)
        .animation(.snappy, value: fill)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(a11yLabel)
    }

    private func label(primary: Color, secondary: Color) -> some View {
        HStack(spacing: 9) {
            Text(category.emoji).font(.system(size: 17))
            Text(category.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 8)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(money(spent, code: currencyCode))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(primary)
                // The actionable number: how much room is left, or how far over.
                Text(isOver
                     ? "· \(money(spent - budget, code: currencyCode)) over"
                     : "· \(money(max(0, budget - spent), code: currencyCode)) left")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(secondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: height)
    }

    private var a11yLabel: String {
        let tail = isOver
            ? "\(money(spent - budget, code: currencyCode)) over your \(money(budget, code: currencyCode)) budget"
            : "\(money(max(0, budget - spent), code: currencyCode)) left of \(money(budget, code: currencyCode))"
        return "\(category.title), \(money(spent, code: currencyCode)) spent, \(tail)"
    }
}

// MARK: - Category history page (tap a budget bar)

/// Opens when you tap a budget bar: the spending history for one category, with a
/// spent-vs-budget summary up top. Tap any row to edit it; long-press to delete.
struct SpectrumCategoryDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @Query private var budgets: [CategoryBudget]
    @AppStorage(AppSettings.currencyKey) private var currencyCode = "USD"

    let category: ExpenseCategory
    @State private var editing: Expense?

    private var expenses: [Expense] { allExpenses.filter { $0.category == category } }
    private var budget: CategoryBudget? { budgets.first { $0.categoryRaw == category.rawValue } }
    private var spentThisMonth: Double {
        expenses.filter { $0.date.isSameMonth(as: .now) }.reduce(0) { $0 + $1.amount }
    }
    private var dayGroups: [(day: Date, items: [Expense])] {
        Dictionary(grouping: expenses) { Calendar.current.startOfDay(for: $0.date) }
            .map { (day: $0.key, items: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                summaryCard
                if expenses.isEmpty { emptyCard } else { historyList }
            }
            .padding(.horizontal, 22)
            .padding(.top, 10)
            .padding(.bottom, 96)
        }
        .scrollIndicators(.hidden)
        .background(Spectrum.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $editing) { SpectrumAddItemView(expense: $0) }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                Haptics.tap()
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Spectrum.onCanvas)
                    .frame(width: 42, height: 42)
                    .background(Spectrum.glassFill(dark: scheme == .dark), in: Circle())
                    .overlay(Circle().strokeBorder(Spectrum.glassStroke(dark: scheme == .dark), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            Text("\(category.emoji)  \(category.title)")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Spectrum.onCanvas)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 8)
        }
    }

    private var summaryCard: some View {
        let limit = budget?.monthlyLimit ?? 0
        let ratio = limit > 0 ? spentThisMonth / limit : 0
        let isOver = limit > 0 && spentThisMonth > limit
        return VStack(alignment: .leading, spacing: 10) {
            Text("SPENT THIS MONTH")
                .font(.system(size: 11, weight: .semibold)).tracking(1)
                .foregroundStyle(Spectrum.onCanvasSoft)
            Text(money(spentThisMonth, code: currencyCode))
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Spectrum.onCanvas)
                .lineLimit(1).minimumScaleFactor(0.5)
            if limit > 0 {
                SpectrumMeter(value: min(1, ratio), tint: isOver ? Spectrum.overBudget : Spectrum.categoryColor(category), height: 10)
                Text(isOver
                     ? "\(money(spentThisMonth - limit, code: currencyCode)) over your \(money(limit, code: currencyCode)) budget"
                     : "\(money(limit - spentThisMonth, code: currencyCode)) left of \(money(limit, code: currencyCode))")
                    .font(.system(size: 13))
                    .foregroundStyle(isOver ? Spectrum.spend : Spectrum.onCanvasSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .spectrumPanel(padding: 18)
    }

    private var historyList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("History")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Spectrum.onCanvas)
            ForEach(dayGroups, id: \.day) { group in
                let dayTotal = group.items.reduce(0) { $0 + $1.amount }
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(group.day.friendlyDay)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Spectrum.onCanvasSoft)
                        Spacer()
                        Text(money(dayTotal, code: currencyCode))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Spectrum.onCanvasSoft)
                    }
                    VStack(spacing: 0) {
                        ForEach(Array(group.items.enumerated()), id: \.element.id) { index, expense in
                            Button { editing = expense } label: { row(expense) }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button("Edit") { editing = expense }
                                    Button("Delete", role: .destructive) { context.delete(expense) }
                                }
                            if index < group.items.count - 1 {
                                Rectangle()
                                    .fill(Spectrum.onCanvasSoft.opacity(0.18))
                                    .frame(height: 1)
                                    .padding(.leading, 14)
                            }
                        }
                    }
                    .spectrumPanel(padding: 6)
                }
            }
        }
    }

    private func row(_ expense: Expense) -> some View {
        HStack(spacing: 12) {
            Text(expense.displayTitle)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Spectrum.onCanvas)
                .lineLimit(1)
            Spacer(minLength: 8)
            Text("−" + money(expense.amount, code: currencyCode))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Spectrum.spend)
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
    }

    private var emptyCard: some View {
        VStack(spacing: 10) {
            Text(category.emoji).font(.system(size: 40))
            Text("No \(category.title.lowercased()) spending yet")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Spectrum.onCanvas)
                .multilineTextAlignment(.center)
            Text("Expenses you log in this category will show up here.")
                .font(.system(size: 13))
                .foregroundStyle(Spectrum.onCanvasSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .spectrumPanel(padding: 28)
        .padding(.top, 8)
    }
}

/// Segmented pill control in the Spectrum palette (active = slate accent).
struct SpectrumSegmented<T: Hashable>: View {
    let items: [T]
    let title: (T) -> String
    @Binding var selection: T
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 3) {
            ForEach(items, id: \.self) { item in
                let on = item == selection
                Button {
                    Haptics.tap()
                    withAnimation(.snappy) { selection = item }
                } label: {
                    Text(title(item))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(on ? Spectrum.plusInk : Spectrum.onCanvasSoft)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background { if on { Capsule().fill(Spectrum.accentSoft) } }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Spectrum.glassFill(dark: scheme == .dark), in: Capsule())
    }
}
