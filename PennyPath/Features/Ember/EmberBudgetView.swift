//
//  EmberBudgetView.swift
//  PennyPath
//
//  Ember's Budget screen — the monthly plan you compare against real spending.
//  Embedded inside the Expenses tab's scroll, so it renders content only (no
//  scroll or background of its own). Reuses the real CategoryBudget model and
//  the real BudgetFormView; bars run bronze while under, terracotta when over.
//

import SwiftUI
import SwiftData

struct EmberBudgetView: View {
    @Environment(\.modelContext) private var context
    @Query private var expenses: [Expense]
    @Query private var budgets: [CategoryBudget]
    @AppStorage(AppSettings.currencyKey) private var currencyCode = "USD"

    @State private var editing: CategoryBudget?
    @State private var showingAdd = false

    // MARK: Numbers (same maths as the real BudgetView)

    private func spent(_ category: ExpenseCategory, in date: Date = .now) -> Double {
        expenses
            .filter { $0.category == category && $0.date.isSameMonth(as: date) }
            .reduce(0) { $0 + $1.amount }
    }
    private var totalSpent: Double {
        expenses.filter { $0.date.isSameMonth(as: .now) }.reduce(0) { $0 + $1.amount }
    }
    private var totalBudget: Double { budgets.reduce(0) { $0 + $1.monthlyLimit } }
    private var left: Double { totalBudget - totalSpent }
    private var over: Bool { left < 0 }

    private var sortedBudgets: [CategoryBudget] {
        budgets.sorted { $0.monthlyLimit > $1.monthlyLimit }
    }
    private var unbudgeted: [ExpenseCategory] {
        let taken = Set(budgets.map { $0.categoryRaw })
        return ExpenseCategory.allCases.filter { !taken.contains($0.rawValue) }
    }
    private var suggestableCategories: [ExpenseCategory] {
        unbudgeted.filter { cat in (0..<3).contains { spent(cat, in: .now.adding(months: -$0)) > 0 } }
    }
    private var canSuggest: Bool { !suggestableCategories.isEmpty }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if budgets.isEmpty {
                emptyCard
            } else {
                headline
                categoryList
                footerButtons
            }
        }
        .sheet(isPresented: $showingAdd) {
            BudgetFormView(takenCategories: Set(budgets.map { $0.categoryRaw }))
        }
        .sheet(item: $editing) { BudgetFormView(budget: $0) }
    }

    // MARK: Headline

    private var headline: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(over ? "OVER BUDGET THIS MONTH" : "LEFT TO SPEND THIS MONTH")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Ember.onCanvasSoft)
            Text(money(abs(left), code: currencyCode))
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(over ? Ember.spend : Ember.good)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            EmberMeter(value: totalBudget > 0 ? min(1, totalSpent / totalBudget) : 0,
                       tint: over ? Ember.spend : Ember.good, height: 12)
            Text("\(money(totalSpent, code: currencyCode)) of \(money(totalBudget, code: currencyCode)) budget")
                .font(.system(size: 13))
                .foregroundStyle(Ember.onCanvasSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .emberPanel(padding: 20)
    }

    // MARK: Category list

    private var categoryList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By category")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Ember.onCanvas)
            ForEach(sortedBudgets) { budget in
                Button { editing = budget } label: { categoryRow(budget) }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Edit") { editing = budget }
                        Button("Delete", role: .destructive) { context.delete(budget) }
                    }
            }
        }
    }

    private func categoryRow(_ budget: CategoryBudget) -> some View {
        let spentAmt = spent(budget.category)
        let limit = budget.monthlyLimit
        let isOver = spentAmt > limit
        let tint = isOver ? Ember.spend : Ember.good
        let progress = limit > 0 ? min(1, spentAmt / limit) : 0
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(budget.category.emoji)
                Text(budget.category.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Ember.onCanvas)
                Spacer()
                Text(isOver ? "\(money(spentAmt - limit, code: currencyCode)) over"
                            : "\(money(limit - spentAmt, code: currencyCode)) left")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(tint)
            }
            EmberMeter(value: progress, tint: tint, height: 10)
            Text("\(money(spentAmt, code: currencyCode)) of \(money(limit, code: currencyCode))")
                .font(.system(size: 12))
                .foregroundStyle(Ember.onCanvasSoft)
        }
        .emberPanel()
    }

    // MARK: Footer / empty

    @ViewBuilder private var footerButtons: some View {
        VStack(spacing: 10) {
            if !unbudgeted.isEmpty {
                softButton(title: "Add a budget", systemImage: "plus") { showingAdd = true }
            }
            if canSuggest {
                softButton(title: "Suggest from my spending", systemImage: "wand.and.stars") { suggestBudgets() }
            }
        }
    }

    private var emptyCard: some View {
        VStack(spacing: 14) {
            Text("🧮").font(.system(size: 46))
            Text("Make a spending plan")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Ember.onCanvas)
            Text("Set a monthly budget for the things you spend on. Each bar stays bronze while you're under and turns red if you go over.")
                .font(.system(size: 14))
                .foregroundStyle(Ember.onCanvasSoft)
                .multilineTextAlignment(.center)
            VStack(spacing: 10) {
                if canSuggest {
                    primaryButton("Suggest from my spending") { suggestBudgets() }
                    softButton(title: "Set one myself", systemImage: nil) { showingAdd = true }
                } else {
                    primaryButton("Set a budget") { showingAdd = true }
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .emberPanel(padding: 28)
        .padding(.top, 8)
    }

    // MARK: Buttons

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Ember.plusInk)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Ember.plus, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func softButton(title: String, systemImage: String?, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 7) {
                if let systemImage {
                    Image(systemName: systemImage).font(.system(size: 14, weight: .bold))
                }
                Text(title).font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(Ember.accentSoft)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Ember.accentSoft.opacity(0.16), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Suggest

    private func suggestBudgets() {
        for category in suggestableCategories {
            let monthly = (0..<3)
                .map { spent(category, in: .now.adding(months: -$0)) }
                .filter { $0 > 0 }
            guard !monthly.isEmpty else { continue }
            let average = monthly.reduce(0, +) / Double(monthly.count)
            let rounded = max(10, (average / 10).rounded(.up) * 10)
            context.insert(CategoryBudget(category: category, monthlyLimit: rounded))
        }
        Haptics.success()
    }
}
