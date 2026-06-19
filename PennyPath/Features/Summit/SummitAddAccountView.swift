//
//  SummitAddAccountView.swift
//  PennyPath
//
//  Summit's own "Add Account" sheet (Developer Mode only): the five net-worth
//  categories as expandable colour cards. Each maps onto a real AccountCategory
//  so net-worth math and the shared store stay correct; sub-categories (added
//  later) will slot into each expanded card to refine the mapping and the
//  suggested name. The real AccountFormView is untouched and still powers
//  editing and the classic app.
//

import SwiftUI
import SwiftData

/// The five net-worth categories Summit organises accounts into.
enum SummitAccountKind: String, CaseIterable, Identifiable {
    case cash, investment, property, receivable, liability
    var id: String { rawValue }

    var title: String {
        switch self {
        case .cash: return "Cash Equivalents"
        case .investment: return "Investment"
        case .property: return "Property"
        case .receivable: return "Receivable"
        case .liability: return "Liability"
        }
    }

    var symbol: String {
        switch self {
        case .cash: return "banknote.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .property: return "house.fill"
        case .receivable: return "person.2.fill"
        case .liability: return "minus.circle.fill"
        }
    }

    /// The card colour — these are the exact reference-deck colours.
    var tint: Color {
        switch self {
        case .cash:       return Color(hex: 0x6CBE70)   // green
        case .investment: return Color(hex: 0x5159C0)   // indigo
        case .property:   return Color(hex: 0x7C88DE)   // periwinkle (not in ref)
        case .receivable: return Color(hex: 0xA6BCEC)   // light blue
        case .liability:  return Color(hex: 0xBFC8D6)   // gray-blue
        }
    }

    /// Text/icon colour that reads on `tint` (white on the dark cards, deep
    /// navy on the light ones).
    var onTint: Color {
        switch self {
        case .cash, .investment, .property: return .white
        case .receivable, .liability:       return Color(hex: 0x1E2742)
        }
    }

    /// A readable accent for this category on a white background (used for
    /// account values and the Add-Account titles).
    var deepTint: Color {
        switch self {
        case .cash:       return Color.adaptive(light: 0x2E9E5E, dark: 0x6CD08B)
        case .investment: return Color.adaptive(light: 0x5159C0, dark: 0x9099EC)
        case .property:   return Color.adaptive(light: 0x5C68D0, dark: 0x9AA4EC)
        case .receivable: return Color.adaptive(light: 0x4E6BB8, dark: 0x9AB2E8)
        case .liability:  return Color.adaptive(light: 0x5E6880, dark: 0x9AA2B6)
        }
    }

    var isAsset: Bool { self != .liability }

    /// Where this is stored in the shared Account model, so net-worth math
    /// (assets add, liabilities subtract) stays correct.
    var underlying: AccountCategory {
        switch self {
        case .cash: return .cash
        case .investment: return .investment
        case .property: return .property
        case .receivable: return .otherAsset
        case .liability: return .otherDebt
        }
    }

    /// Group an existing stored account into one of these five.
    static func of(_ category: AccountCategory) -> SummitAccountKind {
        switch category {
        case .cash, .savings: return .cash
        case .investment: return .investment
        case .property: return .property
        case .otherAsset: return .receivable
        case .creditCard, .loan, .otherDebt: return .liability
        }
    }

    var namePrompt: String {
        switch self {
        case .cash: return "e.g. Emirates NBD"
        case .investment: return "e.g. Brokerage"
        case .property: return "e.g. Apartment"
        case .receivable: return "e.g. Loan to a friend"
        case .liability: return "e.g. Credit card"
        }
    }
}

struct SummitAddAccountView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var expanded: SummitAccountKind?
    @State private var name = ""
    @State private var amount: Double = 0
    @FocusState private var amountFocused: Bool

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && amount > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(SummitAccountKind.allCases) { kind in
                        card(kind)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .background(Summit.canvas.ignoresSafeArea())
            .navigationTitle("Add Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { amountFocused = false }.bold()
                }
            }
            .tint(Summit.accent)
        }
    }

    private func card(_ kind: SummitAccountKind) -> some View {
        let isOpen = expanded == kind
        return VStack(spacing: 0) {
            Button {
                Haptics.tap()
                withAnimation(.snappy) {
                    if isOpen {
                        expanded = nil
                    } else {
                        expanded = kind
                        name = ""
                        amount = 0
                    }
                }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: kind.symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(kind.deepTint)
                        .frame(width: 46, height: 46)
                        .background(kind.deepTint.opacity(0.15), in: Circle())
                    Text(kind.title)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(kind.deepTint)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(kind.deepTint.opacity(0.7))
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isOpen {
                entryForm(kind)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
        .background(kind.tint.opacity(0.10),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func entryForm(_ kind: SummitAccountKind) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Sub-categories will appear here once provided.
            TextField(kind.namePrompt, text: $name)
                .font(.system(size: 16))
                .textInputAutocapitalization(.words)
                .padding(.vertical, 12).padding(.horizontal, 14)
                .background(Summit.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack(spacing: 8) {
                Text(AppSettings.currencySymbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Summit.inkSoft)
                TextField("0", value: $amount, format: .number.precision(.fractionLength(0...2)))
                    .font(.system(size: 18, weight: .semibold).monospacedDigit())
                    .foregroundStyle(Summit.ink)
                    .keyboardType(.decimalPad)
                    .focused($amountFocused)
            }
            .padding(.vertical, 12).padding(.horizontal, 14)
            .background(Summit.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            Button {
                add(kind)
            } label: {
                Text("Add \(kind.title)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(canSave ? kind.deepTint : kind.deepTint.opacity(0.4), in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
        }
    }

    private func add(_ kind: SummitAccountKind) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, amount > 0 else { return }
        context.insert(Account(name: trimmed, category: kind.underlying, balance: amount))
        Haptics.success()
        dismiss()
    }
}
