//
//  SpectrumAddItemView.swift
//  PennyPath
//
//  The one "money out" add/edit sheet for the shipping app. Instead of forcing
//  the user to pre-sort into Spending vs Upcoming before they've said what the
//  thing is, they just describe it and the app routes it to the right model:
//
//    • Repeats ON                  → a subscription (UpcomingPayment, recurring)
//    • Repeats OFF, future date    → a scheduled future payment (UpcomingPayment)
//    • Repeats OFF, today / past   → a logged expense (Expense, already spent)
//
//  Two natural questions — *does it repeat?* and *when?* — cover all three
//  outcomes, and a live caption says exactly where the item will land. Editing
//  an existing item keeps its original kind (a subscription can flip to a future
//  payment, but an expense stays an expense) so nothing is silently re-modelled.
//

import SwiftUI
import SwiftData

struct SpectrumAddItemView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    // Edit targets — at most one is non-nil. nil/nil = a fresh add.
    var expense: Expense? = nil
    var payment: UpcomingPayment? = nil
    /// Fresh-add defaults, set from the tab the user launched from.
    var initialRepeats: Bool = false
    var initialDate: Date = .now
    /// Called after saving with `true` when the item landed in Upcoming (so the
    /// caller can switch the user there to see it).
    var onSaved: (_ landedInUpcoming: Bool) -> Void = { _ in }

    @State private var amount: Double = 0
    @State private var name = ""
    @State private var category: ExpenseCategory = .other
    @State private var date: Date = .now
    @State private var repeats = false
    @State private var cycleUnit: CycleUnit = .month
    @State private var cycleInterval = 1
    @State private var autoRenew = true
    @State private var remindMe = false
    @State private var note = ""
    @State private var iconURL = ""
    @State private var suggestions: [AppSuggestion] = []
    @FocusState private var nameFocused: Bool

    private var editingExpense: Bool { expense != nil }
    private var editingPayment: Bool { payment != nil }
    private var isEditing: Bool { editingExpense || editingPayment }

    /// Strictly after today (by calendar day) — i.e. it hasn't happened yet.
    private var isFutureDated: Bool {
        Calendar.current.startOfDay(for: date) > Calendar.current.startOfDay(for: .now)
    }

    private enum Outcome { case expense, subscription, futurePayment }
    /// What Save will create/keep. Editing locks to the existing model's family;
    /// only a fresh add is free to route across Expense ↔ UpcomingPayment.
    private var outcome: Outcome {
        if editingExpense { return .expense }
        if editingPayment { return repeats ? .subscription : .futurePayment }
        if repeats { return .subscription }
        return isFutureDated ? .futurePayment : .expense
    }

    private var canSave: Bool {
        guard amount > 0 else { return false }
        // An expense can fall back to its category for a title; anything tracked
        // in Upcoming needs a name to show in the list.
        if outcome == .expense { return true }
        return !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var dateLabel: String {
        switch outcome {
        case .subscription:  return "First payment"
        case .futurePayment: return "Due date"
        case .expense:       return "Date"
        }
    }

    private var outcomeCaption: String {
        switch outcome {
        case .expense:       return "Logged in Spending — money already spent."
        case .subscription:  return "Saved as a subscription in Upcoming — it renews on its own."
        case .futurePayment: return "Scheduled in Upcoming\(remindMe ? " — you'll be reminded" : "") — it hasn't been paid yet."
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(AppSettings.currencySymbol).foregroundStyle(.secondary)
                        TextField("Amount", value: $amount, format: .number.precision(.fractionLength(0...2)))
                            .keyboardType(.decimalPad)
                            .font(.title3.weight(.semibold))
                    }
                    TextField(outcome == .expense ? "Name (optional)" : "Name", text: $name)
                        .textInputAutocapitalization(.words)
                        .focused($nameFocused)
                    if outcome != .expense && nameFocused && !suggestions.isEmpty {
                        suggestionsRow
                    }
                }

                Section {
                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { c in
                            Text("\(c.emoji)  \(c.title)").tag(c)
                        }
                    }
                }

                Section {
                    Toggle("Repeats", isOn: $repeats.animation(.snappy))
                    if repeats {
                        Toggle("Auto-renew", isOn: $autoRenew)
                        Picker("Repeats every", selection: $cycleUnit) {
                            ForEach(CycleUnit.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        Stepper(value: $cycleInterval, in: 1...365) {
                            Text("Every \(cycleInterval) \(cycleUnit.title.lowercased())\(cycleInterval == 1 ? "" : "s")")
                        }
                    }
                } footer: {
                    Text(outcomeCaption)
                }

                Section {
                    DatePicker(dateLabel, selection: $date, displayedComponents: .date)
                    if outcome == .futurePayment {
                        Toggle("Remind me", isOn: $remindMe)
                    }
                }

                if outcome != .expense {
                    Section("Note") {
                        TextField("Add a note", text: $note, axis: .vertical)
                            .lineLimit(1...4)
                    }
                }

                if isEditing {
                    Section {
                        Button(editingExpense ? "Delete expense" : "Delete", role: .destructive) {
                            deleteItem()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.bold().disabled(!canSave)
                }
            }
            .tint(Spectrum.accent)
            .task(id: name) { await runSearch() }
        }
        .onAppear(perform: load)
    }

    private var navTitle: String {
        if editingExpense { return "Edit expense" }
        if editingPayment { return "Edit item" }
        return "Add"
    }

    // MARK: App suggestions (for naming a subscription)

    private var suggestionsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(suggestions) { suggestion in
                    Button { select(suggestion) } label: {
                        VStack(spacing: 5) {
                            AppIconView(url: suggestion.iconURL, size: 52)
                            Text(suggestion.name)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .frame(width: 58)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 6)
        }
        .listRowInsets(EdgeInsets(top: 4, leading: 14, bottom: 4, trailing: 0))
    }

    private func select(_ suggestion: AppSuggestion) {
        name = suggestion.name
        iconURL = suggestion.iconURL?.absoluteString ?? ""
        suggestions = []
        nameFocused = false
    }

    private func runSearch() async {
        guard outcome != .expense, nameFocused else { return }
        let q = name.trimmingCharacters(in: .whitespaces)
        guard q.count >= 2 else { suggestions = []; return }
        try? await Task.sleep(nanoseconds: 300_000_000)   // debounce
        if Task.isCancelled { return }
        let found = await AppStoreSearch.search(q)
        if Task.isCancelled || !nameFocused { return }
        suggestions = found
    }

    // MARK: Load / save

    private func load() {
        if let expense {
            amount = expense.amount
            category = expense.category
            name = expense.note          // expense's single text field is its title
            date = expense.date
            repeats = false
        } else if let payment {
            amount = payment.amount
            name = payment.name
            category = payment.category ?? .subscriptions
            date = payment.nextDueDate
            repeats = payment.isSubscription
            cycleUnit = payment.cycleUnit
            cycleInterval = payment.cycleInterval
            autoRenew = payment.autoRenew
            remindMe = payment.remindMe
            note = payment.note
            iconURL = payment.iconURL
        } else {
            repeats = initialRepeats
            date = initialDate
            category = initialRepeats ? .subscriptions : .other
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedNote = note.trimmingCharacters(in: .whitespaces)

        switch outcome {
        case .expense:
            if let expense {
                expense.amount = abs(amount)
                expense.category = category
                expense.note = trimmedName
                expense.date = date
            } else {
                context.insert(Expense(amount: amount, category: category,
                                       note: trimmedName, date: date))
            }
            onSaved(false)

        case .subscription, .futurePayment:
            let isSub = (outcome == .subscription)
            if let payment {
                payment.name = trimmedName
                payment.amount = abs(amount)
                payment.category = category
                payment.nextDueDate = date
                payment.isSubscription = isSub
                payment.cycleUnit = cycleUnit
                payment.cycleInterval = max(1, cycleInterval)
                payment.autoRenew = autoRenew
                payment.remindMe = isSub ? false : remindMe
                payment.note = trimmedNote
                payment.iconURL = iconURL
            } else {
                context.insert(UpcomingPayment(
                    name: trimmedName, amount: amount, category: category,
                    isSubscription: isSub, cycleUnit: cycleUnit,
                    cycleInterval: max(1, cycleInterval), autoRenew: autoRenew,
                    remindMe: isSub ? false : remindMe, note: trimmedNote,
                    iconURL: iconURL, nextDueDate: date))
            }
            onSaved(true)
        }

        Haptics.success()
        dismiss()
    }

    private func deleteItem() {
        if let expense { context.delete(expense) }
        if let payment { context.delete(payment) }
        dismiss()
    }
}
