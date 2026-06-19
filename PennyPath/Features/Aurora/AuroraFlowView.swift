//
//  AuroraFlowView.swift
//  PennyPath
//
//  Aurora reskin of Spending: the month's total glowing at the center of
//  an orbital ring chart — each category a luminous arc — with the pace
//  line and the running list of expenses below. Budget mode and all the
//  forms are the real ones.
//

import SwiftUI
import SwiftData

struct AuroraFlowView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    @State private var showingAdd = false
    @State private var editing: Expense?
    @State private var mode: Mode = .spent
    @State private var ringRevealed = false

    enum Mode: String, CaseIterable { case spent = "Spent", budget = "Budget" }

    // MARK: Numbers

    private func monthTotal(_ date: Date) -> Double {
        expenses.filter { $0.date.isSameMonth(as: date) }.reduce(0) { $0 + $1.amount }
    }
    private var thisMonth: Double { monthTotal(.now) }
    private var lastMonth: Double { monthTotal(.now.adding(months: -1)) }

    /// Compare against last month's pace at the same point in the month.
    private var paceLine: (text: String, over: Bool)? {
        guard lastMonth > 0 else { return nil }
        let cal = Calendar.current
        let day = cal.component(.day, from: .now)
        let daysInMonth = cal.range(of: .day, in: .month, for: .now)?.count ?? 30
        let usualPace = lastMonth * Double(day) / Double(daysInMonth)
        let diff = usualPace - thisMonth
        if abs(diff) < 1 { return (text: "Right on your usual pace", over: false) }
        return diff > 0
            ? (text: "\(money(diff)) under your usual pace", over: false)
            : (text: "\(money(-diff)) over your usual pace", over: true)
    }

    private var breakdown: [(category: ExpenseCategory, amount: Double)] {
        let monthly = expenses.filter { $0.date.isSameMonth(as: .now) }
        let totals = Dictionary(grouping: monthly, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
        return totals.map { (category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                switch mode {
                case .spent:
                    if expenses.isEmpty {
                        emptyCard
                    } else {
                        orbitCard
                        recentCard
                    }
                case .budget:
                    BudgetView()
                        .padding(.horizontal, -22)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(AuroraSky())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAdd) { ExpenseFormView() }
        .sheet(item: $editing) { ExpenseFormView(expense: $0) }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).delay(0.15)) { ringRevealed = true }
        }
        .tint(Aurora.pink)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center) {
            AuroraOverline(text: Date.now.formatted(.dateTime.month(.wide)) + " flow")
            Spacer()
            modePills
            Button { showingAdd = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Aurora.inkSoft)
            }
            .padding(.leading, 6)
        }
    }

    private var modePills: some View {
        HStack(spacing: 6) {
            ForEach(Mode.allCases, id: \.self) { item in
                Button {
                    withAnimation(.snappy) { mode = item }
                } label: {
                    Text(item.rawValue)
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(mode == item ? Aurora.pink : Aurora.inkSoft)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background {
                            if mode == item {
                                Capsule().fill(Aurora.pink.opacity(0.13))
                                Capsule().strokeBorder(Aurora.pink.opacity(0.5), lineWidth: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Orbit chart (total in the middle, categories as arcs)

    private var orbitCard: some View {
        VStack(spacing: 18) {
            ZStack {
                AuroraOrbitRing(
                    segments: breakdown.map(\.amount),
                    palette: Aurora.chartPalette,
                    revealed: ringRevealed
                )
                .frame(width: 210, height: 210)

                VStack(spacing: 4) {
                    Text("THIS MONTH")
                        .font(.system(.caption2, design: .rounded).weight(.bold))
                        .tracking(1.8)
                        .foregroundStyle(Aurora.inkFaint)
                    Text(money(thisMonth))
                        .font(.auroraAmount(30))
                        .foregroundStyle(Aurora.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: 130)
                }
            }
            // The legend below reads out every category and amount, so the
            // ring itself is decoration for VoiceOver.
            .accessibilityHidden(true)
            .frame(maxWidth: .infinity)

            if let pace = paceLine {
                Text(pace.text)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(pace.over ? Aurora.coral : Aurora.inkSoft)
            } else {
                Text("Your first month — keep it up!")
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(Aurora.inkSoft)
            }

            if !breakdown.isEmpty { legend }
        }
        .auroraCard(padding: 22, glow: Aurora.pink)
    }

    private var legend: some View {
        let columns = [GridItem(.adaptive(minimum: 130), alignment: .leading)]
        return LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(Array(breakdown.enumerated()), id: \.element.category) { index, item in
                HStack(spacing: 6) {
                    Circle()
                        .fill(Aurora.chartPalette[index % Aurora.chartPalette.count])
                        .frame(width: 7, height: 7)
                        .shadow(color: Aurora.chartPalette[index % Aurora.chartPalette.count]
                            .opacity(0.8), radius: 3)
                    Text(item.category.title)
                        .font(.caption)
                        .foregroundStyle(Aurora.ink)
                    Text(money(item.amount))
                        .font(.caption)
                        .foregroundStyle(Aurora.inkSoft)
                }
            }
        }
    }

    // MARK: Recent list (tap to edit, hold to delete — same as the real tab)

    private var recentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            AuroraOverline(text: "Recent")
            VStack(spacing: 0) {
                ForEach(Array(expenses.prefix(30).enumerated()), id: \.element.id) { index, expense in
                    Button { editing = expense } label: {
                        expenseRow(expense)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Edit") { editing = expense }
                        Button("Delete", role: .destructive) { context.delete(expense) }
                    }
                    if index < min(expenses.count, 30) - 1 {
                        Aurora.hairline.frame(height: 1)
                    }
                }
            }
            .auroraCard(padding: 8)
        }
    }

    private func expenseRow(_ expense: Expense) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(expense.category.emoji)
                .font(.body)
                .frame(width: 38, height: 38)
                .background(Aurora.pink.opacity(0.10), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(expense.displayTitle)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Aurora.ink)
                    .lineLimit(1)
                Text("\(expense.category.title) · \(expense.date.friendlyDay)")
                    .font(.caption)
                    .foregroundStyle(Aurora.inkSoft)
            }
            Spacer(minLength: 8)
            Text("−" + money(expense.amount))
                .font(.auroraAmount(16, weight: .semibold))
                .foregroundStyle(Aurora.ink)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }

    // MARK: Empty state

    private var emptyCard: some View {
        VStack(spacing: 14) {
            Text("☄️").font(.system(size: 40))
            Text("Track your first expense")
                .font(.auroraDisplay(21))
                .foregroundStyle(Aurora.ink)
            Text("Every time you spend, jot it down. Soon you'll see exactly where your money flows.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Aurora.inkSoft)
                .multilineTextAlignment(.center)
            AuroraBeamButton(title: "Add an expense") { showingAdd = true }
        }
        .frame(maxWidth: .infinity)
        .auroraCard(padding: 28, glow: Aurora.pink)
        .padding(.top, 30)
    }
}

// MARK: - The orbital ring chart

/// A donut of glowing arcs, one per category, biggest first. A thin faint
/// track ring shows through the small gaps between segments.
private struct AuroraOrbitRing: View {
    let segments: [Double]
    let palette: [Color]
    var revealed: Bool

    private let lineWidth: CGFloat = 16
    /// Fraction of the circle left as breathing room between arcs.
    private let gap = 0.012

    private var total: Double { max(segments.reduce(0, +), 0.0001) }

    /// Start/end fractions for each segment, gaps included.
    private var arcs: [(from: Double, to: Double)] {
        var out: [(Double, Double)] = []
        var cursor = 0.0
        for value in segments {
            let span = value / total
            let from = cursor + gap / 2
            let to = max(from, cursor + span - gap / 2)
            out.append((from, to))
            cursor += span
        }
        return out
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.07), lineWidth: lineWidth)

            ForEach(Array(arcs.enumerated()), id: \.offset) { index, arc in
                let color = palette[index % palette.count]
                Circle()
                    .trim(from: arc.from, to: revealed ? arc.to : arc.from)
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .shadow(color: color.opacity(0.55), radius: 6)
            }
        }
        .rotationEffect(.degrees(-90))
        .padding(lineWidth / 2)
    }
}
