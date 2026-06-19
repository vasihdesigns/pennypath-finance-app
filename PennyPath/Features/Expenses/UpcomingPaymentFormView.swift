//
//  UpcomingPaymentFormView.swift
//  PennyPath
//
//  Add or edit a subscription or one-off "future payment" — the "New Item"
//  sheet. A type toggle up top, then details, classification, the renewal cycle
//  (subscriptions) or a reminder (future payments), a colour, and a note.
//

import SwiftUI
import SwiftData

struct UpcomingPaymentFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var payment: UpcomingPayment?
    /// Which type the form opens on when adding (set from the active tab).
    var initialIsSubscription: Bool = true

    @State private var name = ""
    @State private var amount: Double = 0
    @State private var category: ExpenseCategory?
    @State private var showingCategoryPicker = false
    @State private var startDate: Date = .now
    @State private var isSubscription = true
    @State private var cycleUnit: CycleUnit = .month
    @State private var cycleInterval = 1
    @State private var autoRenew = true
    @State private var remindMe = false
    @State private var note = ""
    @State private var iconURL = ""
    @State private var suggestions: [AppSuggestion] = []
    @FocusState private var nameFocused: Bool

    private var isEditing: Bool { payment != nil }
    private var canSave: Bool {
        amount > 0 && !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $isSubscription) {
                        Text("Subscription").tag(true)
                        Text("Future Payment").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 6, trailing: 0))
                }

                Section("Details") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                        .focused($nameFocused)
                    if nameFocused && !suggestions.isEmpty {
                        suggestionsRow
                    }
                    HStack {
                        Text(AppSettings.currencySymbol).foregroundStyle(.secondary)
                        TextField("Amount", value: $amount, format: .number.precision(.fractionLength(0...2)))
                            .keyboardType(.decimalPad)
                    }
                    DatePicker("Starts", selection: $startDate, displayedComponents: .date)
                }

                Section("Classification") {
                    Button {
                        showingCategoryPicker = true
                    } label: {
                        HStack(spacing: 10) {
                            Text("Category").foregroundStyle(.primary)
                            Spacer(minLength: 8)
                            Text(category?.title ?? "None").foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                if isSubscription {
                    Section("Cycle") {
                        Toggle("Auto-Renew", isOn: $autoRenew)
                        Picker("Repeats", selection: $cycleUnit) {
                            ForEach(CycleUnit.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        Stepper(value: $cycleInterval, in: 1...365) {
                            Text("Every \(cycleInterval) \(cycleUnit.title.lowercased())\(cycleInterval == 1 ? "" : "s")")
                        }
                    }
                } else {
                    Section("Reminder") {
                        Toggle("Remind Me", isOn: $remindMe)
                    }
                }

                Section("Note") {
                    TextField("Add a note", text: $note, axis: .vertical)
                        .lineLimit(1...4)
                }

                if isEditing {
                    Section {
                        Button("Delete", role: .destructive) { deletePayment() }
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Item" : "New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.bold().disabled(!canSave)
                }
            }
            .tint(Spectrum.accent)
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerView(selection: $category)
            }
            .task(id: name) { await runSearch() }
        }
        .onAppear(perform: load)
    }

    // MARK: App suggestions

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
        guard nameFocused else { return }
        let q = name.trimmingCharacters(in: .whitespaces)
        guard q.count >= 2 else { suggestions = []; return }
        // Debounce — this task is cancelled and restarted as the name changes.
        try? await Task.sleep(nanoseconds: 300_000_000)
        if Task.isCancelled { return }
        let found = await AppStoreSearch.search(q)
        if Task.isCancelled || !nameFocused { return }
        suggestions = found
    }

    private func load() {
        guard let payment else {
            isSubscription = initialIsSubscription
            return
        }
        name = payment.name
        amount = payment.amount
        category = payment.category
        startDate = payment.nextDueDate
        isSubscription = payment.isSubscription
        cycleUnit = payment.cycleUnit
        cycleInterval = payment.cycleInterval
        autoRenew = payment.autoRenew
        remindMe = payment.remindMe
        note = payment.note
        iconURL = payment.iconURL
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let noteTrimmed = note.trimmingCharacters(in: .whitespaces)
        if let payment {
            payment.name = trimmed
            payment.amount = abs(amount)
            payment.category = category
            payment.nextDueDate = startDate
            payment.isSubscription = isSubscription
            payment.cycleUnit = cycleUnit
            payment.cycleInterval = max(1, cycleInterval)
            payment.autoRenew = autoRenew
            payment.remindMe = remindMe
            payment.note = noteTrimmed
            payment.iconURL = iconURL
        } else {
            context.insert(UpcomingPayment(
                name: trimmed, amount: amount, category: category,
                isSubscription: isSubscription, cycleUnit: cycleUnit,
                cycleInterval: max(1, cycleInterval), autoRenew: autoRenew,
                remindMe: remindMe, note: noteTrimmed, iconURL: iconURL,
                nextDueDate: startDate))
        }
        Haptics.success()
        dismiss()
    }

    private func deletePayment() {
        if let payment { context.delete(payment) }
        dismiss()
    }
}

// MARK: - Categories picker

/// The "Categories" screen: pick a category (or None) from the colour-dotted
/// list. Adding custom categories (the +) is a future enhancement.
struct CategoryPickerView: View {
    @Binding var selection: ExpenseCategory?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Button {
                    selection = nil
                    dismiss()
                } label: {
                    row(title: "None", selected: selection == nil)
                }
                .buttonStyle(.plain)
                ForEach(ExpenseCategory.allCases) { category in
                    Button {
                        selection = category
                        dismiss()
                    } label: {
                        row(title: category.title, selected: selection == category)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
            .tint(Spectrum.accent)
        }
    }

    private func row(title: String, selected: Bool) -> some View {
        HStack(spacing: 12) {
            Text(title).foregroundStyle(.primary)
            Spacer(minLength: 8)
            if selected {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Spectrum.accent)
            }
        }
        .contentShape(Rectangle())
    }
}
