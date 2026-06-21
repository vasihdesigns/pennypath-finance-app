//
//  SpectrumAddAccountView.swift
//  PennyPath
//
//  The "Add Account" picker: the five net-worth groups, each expanding to its
//  specific account sub-types. Picking a sub-type opens a name + amount entry
//  that creates the account under the right asset/debt category — except the
//  four investment instruments (Stock, Cryptocurrency, Investment Fund, Precious
//  Metal), which open live market data to add a real, auto-valued holding.
//
//  Styled to the Spectrum brand (neutral accent, smoked-glass panels on the dark
//  canvas) — not the colourful reference it was modelled on.
//

import SwiftUI
import SwiftData

/// A specific account sub-type within one of the five money kinds. Maps onto a
/// real `AccountCategory` so net-worth maths stays correct.
enum SpectrumAccountSubtype: String, CaseIterable, Identifiable, Hashable {
    // Cash Equivalents
    case cash, digitalWallet, debitCard, cashOther
    // Investment
    case investmentFund, stock, crypto, preciousMetal, investmentOther
    // Property
    case house, car, propertyOther
    // Receivable
    case moneyLent, deposit, receivableOther
    // Liability
    case creditCard, loan, payable, liabilityOther

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cash: return "Cash"
        case .digitalWallet: return "Digital Wallet"
        case .debitCard: return "Debit Card"
        case .cashOther: return "Other"
        case .investmentFund: return "Investment Fund"
        case .stock: return "Stock"
        case .crypto: return "Cryptocurrency"
        case .preciousMetal: return "Precious Metal"
        case .investmentOther: return "Other Investment"
        case .house: return "House"
        case .car: return "Car"
        case .propertyOther: return "Other Property"
        case .moneyLent: return "Money Lent"
        case .deposit: return "Deposit"
        case .receivableOther: return "Other Receivable"
        case .creditCard: return "Credit Card"
        case .loan: return "Loan"
        case .payable: return "Payable"
        case .liabilityOther: return "Other Liability"
        }
    }

    var icon: String {
        switch self {
        case .cash: return "banknote.fill"
        case .digitalWallet: return "wallet.pass.fill"
        case .debitCard: return "creditcard.fill"
        case .cashOther: return "ellipsis.circle.fill"
        case .investmentFund: return "chart.pie.fill"
        case .stock: return "chart.line.uptrend.xyaxis"
        case .crypto: return "bitcoinsign.circle.fill"
        case .preciousMetal: return "crown.fill"
        case .investmentOther: return "dollarsign.circle.fill"
        case .house: return "house.fill"
        case .car: return "car.fill"
        case .propertyOther: return "building.2.fill"
        case .moneyLent: return "person.2.fill"
        case .deposit: return "tray.and.arrow.down.fill"
        case .receivableOther: return "ellipsis.circle.fill"
        case .creditCard: return "creditcard.fill"
        case .loan: return "building.columns.fill"
        case .payable: return "doc.text.fill"
        case .liabilityOther: return "exclamationmark.circle.fill"
        }
    }

    var kind: SpectrumMoneyKind {
        switch self {
        case .cash, .digitalWallet, .debitCard, .cashOther: return .cash
        case .investmentFund, .stock, .crypto, .preciousMetal, .investmentOther: return .investment
        case .house, .car, .propertyOther: return .property
        case .moneyLent, .deposit, .receivableOther: return .receivable
        case .creditCard, .loan, .payable, .liabilityOther: return .liability
        }
    }

    /// Where this is stored so assets add and debts subtract correctly.
    var underlying: AccountCategory {
        switch self {
        case .cash, .digitalWallet, .debitCard, .cashOther: return .cash
        case .investmentFund, .stock, .crypto, .preciousMetal, .investmentOther: return .investment
        case .house, .car, .propertyOther: return .property
        case .moneyLent, .deposit, .receivableOther: return .otherAsset
        case .creditCard: return .creditCard
        case .loan: return .loan
        case .payable, .liabilityOther: return .otherDebt
        }
    }

    /// The investment instruments are added from live market data, not a manual
    /// amount: stocks & crypto via market search, funds via a fund search, and
    /// precious metals from a curated list.
    var usesMarketSearch: Bool {
        switch self {
        case .stock, .crypto, .investmentFund, .preciousMetal: return true
        default: return false
        }
    }

    static func subtypes(for kind: SpectrumMoneyKind) -> [SpectrumAccountSubtype] {
        allCases.filter { $0.kind == kind }
    }
}

// MARK: - Per-sub-type form details

/// A type-specific field shown on the add form and stored on the Account.
enum AccountDetailField: Hashable {
    case institution, counterparty, interestRate, creditLimit, dueDate
}

struct AccountDetailSpec: Identifiable {
    let field: AccountDetailField
    let label: String
    let placeholder: String
    var id: AccountDetailField { field }
}

extension SpectrumAccountSubtype {
    /// Caption under the big amount — frames what the number means.
    var amountLabel: String {
        switch self {
        case .cash, .digitalWallet, .debitCard, .cashOther: return "Balance"
        case .investmentFund, .stock, .crypto, .preciousMetal, .investmentOther,
             .house, .car, .propertyOther: return "Current value"
        case .moneyLent: return "Amount lent"
        case .deposit, .receivableOther: return "Amount"
        case .creditCard: return "Balance owed"
        case .loan, .payable, .liabilityOther: return "Amount owed"
        }
    }

    /// Label for the date field — tuned to the kind of thing.
    var dateLabel: String {
        switch self {
        case .house, .car: return "Purchase date"
        case .moneyLent: return "Date lent"
        case .deposit: return "Date paid"
        case .creditCard: return "Opened"
        case .loan: return "Start date"
        default: return "Date added"
        }
    }

    /// The extra, type-relevant fields this sub-type collects (beyond amount,
    /// name, date and notes). Empty for kinds where a plain amount says it all.
    var detailSpecs: [AccountDetailSpec] {
        switch self {
        case .digitalWallet:
            return [.init(field: .institution, label: "Provider", placeholder: "e.g. PayPal, Apple Cash")]
        case .debitCard:
            return [.init(field: .institution, label: "Bank", placeholder: "e.g. Chase")]
        case .investmentOther:
            return [.init(field: .institution, label: "Held at", placeholder: "e.g. Brokerage or platform")]
        case .moneyLent:
            return [.init(field: .counterparty, label: "Borrower", placeholder: "Who owes you?"),
                    .init(field: .dueDate, label: "Expected back", placeholder: "")]
        case .deposit:
            return [.init(field: .counterparty, label: "Held by", placeholder: "e.g. Landlord, utility"),
                    .init(field: .dueDate, label: "Return date", placeholder: "")]
        case .creditCard:
            return [.init(field: .institution, label: "Issuer", placeholder: "e.g. Visa, Amex"),
                    .init(field: .creditLimit, label: "Credit limit", placeholder: ""),
                    .init(field: .interestRate, label: "APR", placeholder: ""),
                    .init(field: .dueDate, label: "Payment due", placeholder: "")]
        case .loan:
            return [.init(field: .institution, label: "Lender", placeholder: "e.g. Bank or lender"),
                    .init(field: .interestRate, label: "Interest rate", placeholder: ""),
                    .init(field: .dueDate, label: "Payoff date", placeholder: "")]
        case .payable:
            return [.init(field: .counterparty, label: "Owed to", placeholder: "Who do you owe?"),
                    .init(field: .dueDate, label: "Due date", placeholder: "")]
        default:
            return []
        }
    }
}

struct SpectrumAddAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    /// When set, that group opens pre-expanded — e.g. launched from a specific
    /// Net Worth card so its sub-types are right there.
    var initialKind: SpectrumMoneyKind? = nil

    @State private var expanded: SpectrumMoneyKind?
    @State private var entrySubtype: SpectrumAccountSubtype?
    @State private var marketFlow: MarketFlow?
    @State private var market = MarketService()

    /// Which live-market flow a sub-type opens.
    private enum MarketFlow: Int, Identifiable {
        case search   // pick a market, then search (stock, crypto)
        case funds    // global mutual-fund & ETF search
        case metals   // curated precious-metals list
        var id: Int { rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(SpectrumMoneyKind.allCases) { kind in
                        groupCard(kind)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .background(Spectrum.canvas.ignoresSafeArea())
            .navigationTitle("Add Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .navigationDestination(item: $entrySubtype) { subtype in
                SpectrumAddAccountEntryView(subtype: subtype) { dismiss() }
            }
            .sheet(item: $marketFlow) { flow in
                switch flow {
                case .search: HoldingSearchView(service: market)
                case .funds:  HoldingSearchView(service: market, mode: .funds)
                case .metals: PreciousMetalSearchView(service: market)
                }
            }
            .tint(Spectrum.accent)
            .onAppear { if expanded == nil { expanded = initialKind } }
        }
    }

    // MARK: Group card (expandable)

    private func groupCard(_ kind: SpectrumMoneyKind) -> some View {
        let isOpen = expanded == kind
        return VStack(spacing: 8) {
            Button {
                Haptics.tap()
                withAnimation(.snappy) { expanded = isOpen ? nil : kind }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: kind.symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Spectrum.accent)
                        .frame(width: 46, height: 46)
                        .background(Spectrum.accent.opacity(0.16), in: Circle())
                    Text(kind.title)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(Spectrum.onCanvas)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Spectrum.onCanvasSoft)
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isOpen {
                VStack(spacing: 8) {
                    ForEach(SpectrumAccountSubtype.subtypes(for: kind)) { subtype in
                        subtypeRow(subtype)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .spectrumPanel(padding: 0)
    }

    private func subtypeRow(_ subtype: SpectrumAccountSubtype) -> some View {
        let innerFill = (scheme == .dark ? Color.white : Color.black).opacity(0.06)
        return Button {
            Haptics.tap()
            switch subtype {
            case .investmentFund: marketFlow = .funds
            case .preciousMetal:  marketFlow = .metals
            case .stock, .crypto: marketFlow = .search
            default:              entrySubtype = subtype
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: subtype.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Spectrum.accent)
                    .frame(width: 42, height: 42)
                    .background(Spectrum.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text(subtype.title)
                    .font(.system(size: 16))
                    .foregroundStyle(Spectrum.onCanvas)
                Spacer(minLength: 8)
                if subtype.usesMarketSearch {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Spectrum.onCanvasSoft)
                }
            }
            .padding(12)
            .background(innerFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Entry (name + amount) for a chosen sub-type

struct SpectrumAddAccountEntryView: View {
    let subtype: SpectrumAccountSubtype
    /// Called after a successful save to dismiss the whole Add Account flow.
    var onDone: () -> Void

    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var amount: Double = 0
    @State private var currencyCode = AppSettings.currencyCode
    @State private var date = Date.now
    @State private var notes = ""
    // Type-specific details — only those in `subtype.detailSpecs` are shown.
    @State private var institution = ""
    @State private var counterparty = ""
    @State private var interestRate: Double = 0
    @State private var creditLimit: Double = 0
    @State private var hasDueDate = false
    @State private var dueDate = Date.now
    @State private var isSaving = false
    @State private var showingCurrency = false
    @FocusState private var amountFocused: Bool

    private var canSave: Bool {
        amount > 0 && !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                amountHero

                labeled("Account name") {
                    TextField(namePrompt, text: $name)
                        .textInputAutocapitalization(.words)
                        .foregroundStyle(Spectrum.onCanvas)
                }

                ForEach(subtype.detailSpecs) { spec in
                    detailField(spec)
                }

                labeled(subtype.dateLabel) {
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .labelsHidden()
                        .tint(Spectrum.accent)
                }

                labeled("Notes (optional)") {
                    TextField("Add a note", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                        .foregroundStyle(Spectrum.onCanvas)
                }

                Button {
                    Task { await save() }
                } label: {
                    Text(isSaving ? "Adding…" : "Add \(subtype.title)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Spectrum.plusInk)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(canSave ? Spectrum.plus : Spectrum.plus.opacity(0.4), in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!canSave || isSaving)
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .background(Spectrum.canvas.ignoresSafeArea())
        .navigationTitle("New \(subtype.title)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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

    // MARK: Amount hero — big, with a switchable currency

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

            Text(subtype.amountLabel)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Spectrum.onCanvasSoft)
        }
        .padding(.vertical, 26)
        .frame(maxWidth: .infinity)
        .spectrumPanel(padding: 0)
    }

    // MARK: Type-specific detail fields

    @ViewBuilder private func detailField(_ spec: AccountDetailSpec) -> some View {
        switch spec.field {
        case .institution:
            labeled(spec.label) {
                TextField(spec.placeholder, text: $institution)
                    .textInputAutocapitalization(.words)
                    .foregroundStyle(Spectrum.onCanvas)
            }
        case .counterparty:
            labeled(spec.label) {
                TextField(spec.placeholder, text: $counterparty)
                    .textInputAutocapitalization(.words)
                    .foregroundStyle(Spectrum.onCanvas)
            }
        case .interestRate:
            labeled(spec.label) {
                HStack(spacing: 6) {
                    TextField("0", value: $interestRate, format: .number.precision(.fractionLength(0...2)))
                        .keyboardType(.decimalPad)
                        .foregroundStyle(Spectrum.onCanvas)
                    Text("%").foregroundStyle(Spectrum.onCanvasSoft)
                }
            }
        case .creditLimit:
            labeled(spec.label) {
                HStack(spacing: 6) {
                    Text(currencySymbol(for: currencyCode))
                        .foregroundStyle(Spectrum.onCanvasSoft)
                    TextField("0", value: $creditLimit, format: .number.precision(.fractionLength(0...2)))
                        .keyboardType(.decimalPad)
                        .foregroundStyle(Spectrum.onCanvas)
                }
            }
        case .dueDate:
            optionalDatePanel(spec.label)
        }
    }

    /// A date the user can leave unset (e.g. "Expected back", "Payment due").
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

    private var namePrompt: String {
        switch subtype {
        case .cash: return "e.g. Wallet cash"
        case .digitalWallet: return "e.g. Apple Pay"
        case .debitCard: return "e.g. Bank debit card"
        case .house: return "e.g. Apartment"
        case .car: return "e.g. My car"
        case .creditCard: return "e.g. Visa"
        case .loan: return "e.g. Car loan"
        default: return "Name"
        }
    }

    @MainActor
    private func save() async {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, amount > 0, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        // Convert to the app's base currency so net worth stays correct. Warm
        // the shared rate table first if we don't already have this currency, so
        // the value is never counted at 1:1. If we're offline, it saves as
        // "pending" (counts as 0 until a refresh fills the rate in) — never wrong.
        let base = AppSettings.currencyCode
        var rate = 1.0
        if currencyCode != base {
            if FXRates.rateToBase(currencyCode, base: base) == nil {
                await MarketService.refreshRates(base: base, provider: YahooMarketDataProvider())
            }
            rate = FXRates.rateToBase(currencyCode, base: base) ?? 0
        }

        context.insert(Account(name: trimmed, category: subtype.underlying, balance: amount,
                               createdAt: date, currencyCode: currencyCode,
                               cachedFXRate: rate, cachedFXBase: base,
                               notes: notes.trimmingCharacters(in: .whitespaces),
                               institution: institution.trimmingCharacters(in: .whitespaces),
                               counterparty: counterparty.trimmingCharacters(in: .whitespaces),
                               interestRate: interestRate, creditLimit: creditLimit,
                               dueDate: hasDueDate ? dueDate : nil))
        Haptics.success()
        onDone()
    }
}
