//
//  MonoAddAccountView.swift
//  PennyPath
//
//  The "Add Account" picker: the five net-worth groups, each expanding to its
//  specific account sub-types. Picking a sub-type opens a name + amount entry
//  that creates the account under the right asset/debt category — except Stock
//  and Cryptocurrency, which open the live market search to add a real holding.
//
//  Styled to the Mono brand (grayscale accent, smoked-glass panels on the dark
//  canvas) — not the colourful reference it was modelled on.
//

import SwiftUI
import SwiftData

/// A specific account sub-type within one of the five money kinds. Maps onto a
/// real `AccountCategory` so net-worth maths stays correct.
enum MonoAccountSubtype: String, CaseIterable, Identifiable, Hashable {
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

    var kind: MonoMoneyKind {
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

    /// Stocks and crypto are added via the live market search, not a manual amount.
    var usesMarketSearch: Bool { self == .stock || self == .crypto }

    static func subtypes(for kind: MonoMoneyKind) -> [MonoAccountSubtype] {
        allCases.filter { $0.kind == kind }
    }
}

struct MonoAddAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    @State private var expanded: MonoMoneyKind?
    @State private var entrySubtype: MonoAccountSubtype?
    @State private var showingSearch = false
    @State private var market = MarketService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(MonoMoneyKind.allCases) { kind in
                        groupCard(kind)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .background(Mono.canvas.ignoresSafeArea())
            .navigationTitle("Add Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .navigationDestination(item: $entrySubtype) { subtype in
                MonoAddAccountEntryView(subtype: subtype) { dismiss() }
            }
            .sheet(isPresented: $showingSearch) {
                HoldingSearchView(service: market)
            }
            .tint(Mono.accent)
        }
    }

    // MARK: Group card (expandable)

    private func groupCard(_ kind: MonoMoneyKind) -> some View {
        let isOpen = expanded == kind
        return VStack(spacing: 8) {
            Button {
                Haptics.tap()
                withAnimation(.snappy) { expanded = isOpen ? nil : kind }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: kind.symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Mono.accent)
                        .frame(width: 46, height: 46)
                        .background(Mono.accent.opacity(0.16), in: Circle())
                    Text(kind.title)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(Mono.onCanvas)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Mono.onCanvasSoft)
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isOpen {
                VStack(spacing: 8) {
                    ForEach(MonoAccountSubtype.subtypes(for: kind)) { subtype in
                        subtypeRow(subtype)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .monoPanel(padding: 0)
    }

    private func subtypeRow(_ subtype: MonoAccountSubtype) -> some View {
        let innerFill = (scheme == .dark ? Color.white : Color.black).opacity(0.06)
        return Button {
            Haptics.tap()
            if subtype.usesMarketSearch {
                showingSearch = true
            } else {
                entrySubtype = subtype
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: subtype.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Mono.accent)
                    .frame(width: 42, height: 42)
                    .background(Mono.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text(subtype.title)
                    .font(.system(size: 16))
                    .foregroundStyle(Mono.onCanvas)
                Spacer(minLength: 8)
                if subtype.usesMarketSearch {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Mono.onCanvasSoft)
                }
            }
            .padding(12)
            .background(innerFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Entry (name + amount) for a chosen sub-type

struct MonoAddAccountEntryView: View {
    let subtype: MonoAccountSubtype
    /// Called after a successful save to dismiss the whole Add Account flow.
    var onDone: () -> Void

    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var amount: Double = 0
    @FocusState private var amountFocused: Bool

    private var canSave: Bool {
        amount > 0 && !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 0) {
                    TextField(namePrompt, text: $name)
                        .textInputAutocapitalization(.words)
                        .foregroundStyle(Mono.onCanvas)
                        .padding(.vertical, 14)
                    Rectangle().fill(Mono.onCanvasSoft.opacity(0.18)).frame(height: 1)
                    HStack(spacing: 8) {
                        Text(AppSettings.currencySymbol)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Mono.onCanvasSoft)
                        TextField(subtype.kind == .liability ? "Amount owed" : "Amount",
                                  value: $amount, format: .number.precision(.fractionLength(0...2)))
                            .keyboardType(.decimalPad)
                            .focused($amountFocused)
                            .foregroundStyle(Mono.onCanvas)
                    }
                    .padding(.vertical, 14)
                }
                .padding(.horizontal, 16)
                .monoPanel(padding: 0)

                Button {
                    save()
                } label: {
                    Text("Add \(subtype.title)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Mono.plusInk)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(canSave ? Mono.plus : Mono.plus.opacity(0.4), in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .background(Mono.canvas.ignoresSafeArea())
        .navigationTitle("New \(subtype.title)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { amountFocused = false }.bold()
            }
        }
        .tint(Mono.accent)
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

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, amount > 0 else { return }
        context.insert(Account(name: trimmed, category: subtype.underlying, balance: amount))
        Haptics.success()
        onDone()
    }
}
