//
//  SpectrumBudgetView.swift
//  PennyPath
//
//  Spectrum's Budget planner. Set a total budget (or a monthly income) and the
//  app splits it across your categories automatically; then tap any amount to
//  fine-tune. Add more categories as needed. No sliders — every figure is typed.
//  Each category box wears its own Spectrum colour. Embedded in the Expenses
//  tab's scroll, so it renders content only.
//

import SwiftUI
import SwiftData

struct SpectrumBudgetView: View {
    @Environment(\.modelContext) private var context
    @Query private var budgets: [CategoryBudget]
    @AppStorage(AppSettings.currencyKey) private var currencyCode = "USD"
    @AppStorage("monthlyIncome") private var monthlyIncome: Double = 0

    /// Share of income the app plans by default (the rest is breathing room).
    private let incomePlanShare = 0.8

    private enum Field: Hashable { case income, total, category(ExpenseCategory) }
    @FocusState private var focused: Field?
    /// What the Total field shows; kept in sync with the live sum unless you're
    /// actively editing it (so typing a total doesn't redistribute per keystroke).
    @State private var draftTotal: Double = 0

    // MARK: Limits

    private func limit(_ c: ExpenseCategory) -> Double {
        budgets.first { $0.categoryRaw == c.rawValue }?.monthlyLimit ?? 0
    }
    private func setLimit(_ c: ExpenseCategory, _ value: Double) {
        let v = max(0, value.rounded())
        if let existing = budgets.first(where: { $0.categoryRaw == c.rawValue }) {
            if v == 0 { context.delete(existing) } else { existing.monthlyLimit = v }
        } else if v > 0 {
            context.insert(CategoryBudget(category: c, monthlyLimit: v))
        }
    }
    private func binding(_ c: ExpenseCategory) -> Binding<Double> {
        Binding(get: { limit(c) }, set: { setLimit(c, $0) })
    }

    private var totalBudget: Double { budgets.reduce(0) { $0 + $1.monthlyLimit } }
    private var activeCategories: [ExpenseCategory] {
        ExpenseCategory.allCases.filter { limit($0) > 0 }
    }
    private var inactiveCategories: [ExpenseCategory] {
        ExpenseCategory.allCases.filter { limit($0) == 0 }
    }

    /// Default split weights — roughly how a month tends to divide up.
    private func weight(_ c: ExpenseCategory) -> Double {
        switch c {
        case .rent:          return 0.34
        case .food:          return 0.14
        case .transport:     return 0.10
        case .shopping:      return 0.10
        case .fun:           return 0.10
        case .other:         return 0.10
        case .health:        return 0.06
        case .subscriptions: return 0.06
        }
    }

    // MARK: Allocation

    /// Split a total across the plan's categories by their default weights
    /// (bootstrapping every category if the plan is still empty).
    private func allocate(total: Double) {
        let cats = activeCategories.isEmpty ? ExpenseCategory.allCases : activeCategories
        let wsum = cats.reduce(0) { $0 + weight($1) }
        guard total > 0, wsum > 0 else { return }
        for c in cats { setLimit(c, (total * weight(c) / wsum).rounded()) }
        Haptics.success()
    }

    /// Apply a typed total: scale the existing categories to hit it (keeping their
    /// proportions), or split it fresh if nothing is set yet.
    private func applyTotal(_ newTotal: Double) {
        guard newTotal >= 0 else { return }
        let current = totalBudget
        if current > 0, !activeCategories.isEmpty {
            guard abs(newTotal - current) >= 1 else { return }
            let factor = newTotal / current
            for c in activeCategories { setLimit(c, (limit(c) * factor).rounded()) }
        } else {
            allocate(total: newTotal)
        }
    }

    private func suggestFromIncome() { allocate(total: monthlyIncome * incomePlanShare) }

    private func addCategory(_ c: ExpenseCategory) {
        let suggested = max(25, (totalBudget * weight(c)).rounded())
        setLimit(c, suggested)
        Haptics.tap()
    }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            planCard
            ForEach(activeCategories) { categoryRow($0) }
            addCategoryButton
        }
        .onAppear { draftTotal = totalBudget }
        .onChange(of: totalBudget) { _, new in if focused != .total { draftTotal = new } }
        .onChange(of: focused) { old, _ in
            if old == .total { applyTotal(draftTotal) }
            if old == .income, monthlyIncome > 0, totalBudget == 0 { suggestFromIncome() }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focused = nil }
            }
        }
    }

    // MARK: Plan card

    private var planCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            planRow(label: "MONTHLY INCOME", sub: "optional — for an auto budget",
                    value: $monthlyIncome, field: .income, size: 22)
            Rectangle()
                .fill(Spectrum.onCanvasSoft.opacity(0.16))
                .frame(height: 1)
            planRow(label: "TOTAL BUDGET",
                    sub: monthlyIncome > 0 ? "\(percentText(min(1, totalBudget / monthlyIncome))) of your income"
                                           : "we'll split it across categories",
                    value: $draftTotal, field: .total, size: 26)

            if monthlyIncome > 0 {
                Button {
                    Haptics.tap()
                    focused = nil
                    suggestFromIncome()
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "wand.and.stars").font(.system(size: 14, weight: .bold))
                        Text("Auto-plan from income").font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(Spectrum.accentSoft)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Spectrum.accentSoft.opacity(0.16), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .spectrumPanel(padding: 16)
    }

    private func planRow(label: String, sub: String, value: Binding<Double>,
                         field: Field, size: CGFloat) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold)).tracking(1)
                    .foregroundStyle(Spectrum.onCanvasSoft)
                Text(sub)
                    .font(.system(size: 12))
                    .foregroundStyle(Spectrum.onCanvasSoft)
            }
            Spacer(minLength: 8)
            amountField(value, field: field, size: size)
        }
    }

    // MARK: Category row (colour-coded, tap to edit)

    private func categoryRow(_ c: ExpenseCategory) -> some View {
        let color = Spectrum.categoryColor(c)
        return HStack(spacing: 10) {
            Text(c.emoji)
                .font(.system(size: 16))
                .frame(width: 34, height: 34)
                .background(color.opacity(0.30), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(c.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Spectrum.onCanvas)
            Spacer(minLength: 8)
            amountField(binding(c), field: .category(c), size: 19)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(focused == .category(c) ? color.opacity(0.28) : .clear,
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(12)
        .background(color.opacity(0.16), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(color.opacity(0.32), lineWidth: 1))
    }

    // MARK: Add category

    @ViewBuilder private var addCategoryButton: some View {
        if !inactiveCategories.isEmpty {
            Menu {
                ForEach(inactiveCategories) { c in
                    Button { addCategory(c) } label: { Text("\(c.emoji)  \(c.title)") }
                }
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "plus").font(.system(size: 14, weight: .bold))
                    Text("Add a category").font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(Spectrum.accentSoft)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Spectrum.accentSoft.opacity(0.16), in: Capsule())
            }
            .padding(.top, 2)
        }
    }

    // MARK: Editable amount

    private func amountField(_ value: Binding<Double>, field: Field, size: CGFloat) -> some View {
        HStack(spacing: 2) {
            Text(AppSettings.currencySymbol)
                .font(.system(size: size * 0.62, weight: .bold))
                .foregroundStyle(Spectrum.onCanvas)
            TextField("0", value: value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .font(.system(size: size, weight: .bold))
                .foregroundStyle(Spectrum.onCanvas)
                .focused($focused, equals: field)
                .frame(width: size * 4.4, alignment: .trailing)
        }
    }
}
