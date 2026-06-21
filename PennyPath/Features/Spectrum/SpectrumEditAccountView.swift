//
//  SpectrumEditAccountView.swift
//  PennyPath
//
//  Editing an existing account, in the Spectrum brand. Replaces the legacy
//  gold/green AccountFormView that the deck and search used to open — which only
//  exposed name / category / balance and left the per-account currency and the
//  type-specific details (issuer, APR, credit limit, due date, counterparty)
//  unreachable once an account was created. This form surfaces all of them, so
//  anything captured on the Add Account flow can be corrected later.
//
//  The detail fields shown are driven by the account's category, plus any field
//  that already holds a value — so no previously-entered detail is ever hidden,
//  even if the category was changed.
//

import SwiftUI
import SwiftData

struct SpectrumEditAccountView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let account: Account

    @State private var name = ""
    @State private var amount: Double = 0
    @State private var category: AccountCategory = .cash
    @State private var currencyCode = AppSettings.currencyCode
    @State private var date = Date.now
    @State private var notes = ""
    @State private var institution = ""
    @State private var counterparty = ""
    @State private var interestRate: Double = 0
    @State private var creditLimit: Double = 0
    @State private var hasDueDate = false
    @State private var dueDate = Date.now

    @State private var originalCurrency = ""
    @State private var isSaving = false
    @State private var showingCurrency = false
    @FocusState private var amountFocused: Bool

    private var canSave: Bool {
        amount > 0 && !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if account.isMarketLinked {
                    autoManagedNote
                } else {
                    editor
                }
            }
            .scrollIndicators(.hidden)
            .background(Spectrum.canvas.ignoresSafeArea())
            .navigationTitle("Edit account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { amountFocused = false }.bold()
                }
            }
            .sheet(isPresented: $showingCurrency) {
                NavigationStack {
                    CurrencyPickerView(
                        selection: $currencyCode,
                        footer: "Sets the currency for this account. Its value is converted to your main currency for net-worth totals.")
                }
            }
            .tint(Spectrum.accent)
        }
        .onAppear(perform: load)
    }

    // MARK: Editor

    private var editor: some View {
        VStack(spacing: 16) {
            amountHero

            labeled("Account name") {
                TextField("Name", text: $name)
                    .textInputAutocapitalization(.words)
                    .foregroundStyle(Spectrum.onCanvas)
            }

            categoryPanel

            ForEach(visibleDetailFields, id: \.self) { detailField($0) }

            labeled("Date added") {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .labelsHidden()
                    .tint(Spectrum.accent)
            }

            labeled("Notes (optional)") {
                TextField("Add a note", text: $notes, axis: .vertical)
                    .lineLimit(1...4)
                    .foregroundStyle(Spectrum.onCanvas)
            }

            deleteButton
            saveButton
        }
        .padding(20)
    }

    private var amountHero: some View {
        VStack(spacing: 14) {
            Button {
                Haptics.tap()
                amountFocused = false
                showingCurrency = true
            } label: {
                HStack(spacing: 6) {
                    Text(currencyCode)
                        .font(.system(size: 15, weight: .semibold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(Spectrum.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Spectrum.accent.opacity(0.16), in: Capsule())
            }
            .buttonStyle(.plain)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(currencySymbol(for: currencyCode))
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Spectrum.onCanvasSoft)
                TextField("0", value: $amount, format: .number.precision(.fractionLength(0...2)))
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(Spectrum.onCanvas)
                    .keyboardType(.decimalPad)
                    .focused($amountFocused)
                    .fixedSize()
            }
            .fixedSize()
            .frame(maxWidth: .infinity)

            Text(category.isAsset ? "Current value" : "Amount owed")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Spectrum.onCanvasSoft)
        }
        .padding(.vertical, 26)
        .frame(maxWidth: .infinity)
        .spectrumPanel(padding: 0)
    }

    // MARK: Category — a scroll of chips (selected wears the accent)

    private var categoryPanel: some View {
        labeled("Kind") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AccountCategory.allCases) { c in
                        categoryChip(c)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func categoryChip(_ c: AccountCategory) -> some View {
        let selected = category == c
        return Button {
            Haptics.tap()
            withAnimation(.snappy) { category = c }
        } label: {
            HStack(spacing: 6) {
                Text(c.emoji).font(.system(size: 14))
                Text(c.title).font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(selected ? Spectrum.plusInk : Spectrum.onCanvas)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(selected ? Spectrum.accent : Spectrum.accent.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Type-specific detail fields

    /// Fields relevant to the chosen category, plus any that already hold a value
    /// (so a detail captured under the original category is never hidden).
    private var visibleDetailFields: [AccountDetailField] {
        var fields = Self.detailFields(for: category)
        func add(_ f: AccountDetailField, _ present: Bool) {
            if present && !fields.contains(f) { fields.append(f) }
        }
        add(.institution, !institution.isEmpty)
        add(.counterparty, !counterparty.isEmpty)
        add(.interestRate, interestRate > 0)
        add(.creditLimit, creditLimit > 0)
        add(.dueDate, hasDueDate)
        return fields
    }

    private static func detailFields(for category: AccountCategory) -> [AccountDetailField] {
        switch category {
        case .creditCard:            return [.institution, .creditLimit, .interestRate, .dueDate]
        case .loan:                  return [.institution, .interestRate, .dueDate]
        case .otherDebt:             return [.counterparty, .dueDate]
        case .otherAsset:            return [.counterparty, .dueDate]
        case .cash, .savings:        return [.institution]
        case .investment:            return [.institution]
        case .property:              return []
        }
    }

    private func label(for field: AccountDetailField) -> String {
        switch field {
        case .institution:  return category.isAsset ? "Provider / bank" : "Institution"
        case .counterparty: return category.isAsset ? "From / held by" : "Owed to"
        case .interestRate: return "Interest rate"
        case .creditLimit:  return "Credit limit"
        case .dueDate:      return "Due date"
        }
    }

    @ViewBuilder private func detailField(_ field: AccountDetailField) -> some View {
        switch field {
        case .institution:
            labeled(label(for: field)) {
                TextField("Optional", text: $institution)
                    .textInputAutocapitalization(.words)
                    .foregroundStyle(Spectrum.onCanvas)
            }
        case .counterparty:
            labeled(label(for: field)) {
                TextField("Optional", text: $counterparty)
                    .textInputAutocapitalization(.words)
                    .foregroundStyle(Spectrum.onCanvas)
            }
        case .interestRate:
            labeled(label(for: field)) {
                HStack(spacing: 6) {
                    TextField("0", value: $interestRate, format: .number.precision(.fractionLength(0...2)))
                        .keyboardType(.decimalPad)
                        .foregroundStyle(Spectrum.onCanvas)
                    Text("%").foregroundStyle(Spectrum.onCanvasSoft)
                }
            }
        case .creditLimit:
            labeled(label(for: field)) {
                HStack(spacing: 6) {
                    Text(currencySymbol(for: currencyCode))
                        .foregroundStyle(Spectrum.onCanvasSoft)
                    TextField("0", value: $creditLimit, format: .number.precision(.fractionLength(0...2)))
                        .keyboardType(.decimalPad)
                        .foregroundStyle(Spectrum.onCanvas)
                }
            }
        case .dueDate:
            optionalDatePanel(label(for: field))
        }
    }

    private func optionalDatePanel(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Spectrum.onCanvasSoft)
                    .tracking(0.5)
                Spacer()
                Toggle("", isOn: $hasDueDate.animation(.snappy))
                    .labelsHidden()
                    .tint(Spectrum.accent)
            }
            if hasDueDate {
                DatePicker("", selection: $dueDate, displayedComponents: .date)
                    .labelsHidden()
                    .tint(Spectrum.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .spectrumPanel(padding: 0)
    }

    // MARK: Buttons

    private var deleteButton: some View {
        Button(role: .destructive) { deleteAccount() } label: {
            Text("Delete account")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Spectrum.spend)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Spectrum.spend.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var saveButton: some View {
        Button { Task { await save() } } label: {
            Text(isSaving ? "Saving…" : "Save changes")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Spectrum.plusInk)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(canSave ? Spectrum.plus : Spectrum.plus.opacity(0.4), in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!canSave || isSaving)
    }

    // MARK: Auto-managed (market-linked) accounts

    private var autoManagedNote: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(Spectrum.accent)
            Text("Managed automatically")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Spectrum.onCanvas)
            Text("This account's value is kept in sync with your live investments, so it isn't edited directly. Add or remove holdings to change it.")
                .font(.system(size: 14))
                .foregroundStyle(Spectrum.onCanvasSoft)
                .multilineTextAlignment(.center)
            Button("Done") { dismiss() }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Spectrum.plusInk)
                .padding(.vertical, 14)
                .padding(.horizontal, 26)
                .background(Spectrum.plus, in: Capsule())
                .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .spectrumPanel(padding: 28)
        .padding(20)
    }

    // MARK: Titled smoked-glass panel (matches the Add Account flow)

    private func labeled<Content: View>(_ title: String,
                                        @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Spectrum.onCanvasSoft)
                .tracking(0.5)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .spectrumPanel(padding: 0)
    }

    // MARK: Load / save

    private func load() {
        name = account.name
        amount = account.balance
        category = account.category
        currencyCode = account.displayCurrencyCode
        originalCurrency = account.currencyCode   // "" for base-currency accounts
        date = account.createdAt
        notes = account.notes
        institution = account.institution
        counterparty = account.counterparty
        interestRate = account.interestRate
        creditLimit = account.creditLimit
        if let due = account.dueDate { hasDueDate = true; dueDate = due }
    }

    @MainActor
    private func save() async {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, amount > 0, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        // Treat "same as base" as the empty sentinel the rest of the app uses, so
        // a base-currency account never converts and never reads as pending.
        let base = AppSettings.currencyCode
        let normalized = (currencyCode == base) ? "" : currencyCode
        let currencyChanged = normalized != originalCurrency

        account.name = trimmed
        account.category = category
        account.balance = abs(amount)
        account.currencyCode = normalized
        account.createdAt = date
        account.notes = notes.trimmingCharacters(in: .whitespaces)
        account.institution = institution.trimmingCharacters(in: .whitespaces)
        account.counterparty = counterparty.trimmingCharacters(in: .whitespaces)
        account.interestRate = interestRate
        account.creditLimit = creditLimit
        account.dueDate = hasDueDate ? dueDate : nil

        // Keep the FX cache honest. Base/empty pins to 1; a foreign currency warms
        // the shared rate table (so the value never counts at 1:1). If the rate is
        // unknown only because we're offline, leave an unchanged currency's good
        // cache intact; a freshly changed currency falls back to "pending" (0).
        if normalized.isEmpty {
            account.cachedFXRate = 1
            account.cachedFXBase = base
        } else {
            if FXRates.rateToBase(normalized, base: base) == nil {
                await MarketService.refreshRates(base: base, provider: YahooMarketDataProvider())
            }
            if let rate = FXRates.rateToBase(normalized, base: base) {
                account.cachedFXRate = rate
                account.cachedFXBase = base
            } else if currencyChanged {
                account.cachedFXRate = 0   // pending until the next refresh re-pins it
                account.cachedFXBase = base
            }
        }

        Haptics.success()
        dismiss()
    }

    private func deleteAccount() {
        context.delete(account)
        Haptics.tap()
        dismiss()
    }
}
