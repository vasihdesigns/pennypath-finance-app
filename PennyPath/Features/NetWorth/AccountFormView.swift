//
//  AccountFormView.swift
//  PennyPath
//
//  Add or edit one account (something you own or owe).
//

import SwiftUI
import SwiftData

struct AccountFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var account: Account?

    @State private var name = ""
    @State private var isAsset = true
    @State private var category: AccountCategory = .cash
    @State private var balance: Double = 0

    private var isEditing: Bool { account != nil }
    private var tint: Color { isAsset ? Theme.green : Theme.red }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }
    private var categories: [AccountCategory] {
        isAsset ? AccountCategory.assetCases : AccountCategory.debtCases
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Space.lg) {
                    AmountField(title: isAsset ? "How much is it worth?" : "How much do you owe?",
                                amount: $balance, tint: tint)
                        .card(padding: Theme.Space.xl)

                    FieldCard(label: "Name it") {
                        TextField(isAsset ? "e.g. Piggy bank" : "e.g. Phone bill", text: $name)
                            .font(.body)
                            .textInputAutocapitalization(.words)
                    }

                    FieldCard(label: "Is this money you own or owe?") {
                        Picker("", selection: $isAsset) {
                            Text("I own it").tag(true)
                            Text("I owe it").tag(false)
                        }
                        .pickerStyle(.segmented)
                    }

                    FieldCard(label: "What kind?") {
                        ChipGrid(items: categories, selection: $category, tint: tint)
                    }

                    if isEditing {
                        Button("Delete account", role: .destructive) { deleteAccount() }
                            .buttonStyle(SoftButtonStyle(tint: Theme.red))
                    }
                }
                .padding(Theme.Space.lg)
            }
            .background(Theme.background)
            .navigationTitle(isEditing ? "Edit account" : "New account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.bold().disabled(!canSave)
                }
            }
            .tint(tint)
            .onChange(of: isAsset) { _, nowAsset in
                if !categories.contains(category) {
                    category = nowAsset ? .cash : .creditCard
                }
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        guard let account else { return }
        name = account.name
        isAsset = account.category.isAsset
        category = account.category
        balance = account.balance
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let account {
            account.name = trimmed
            account.category = category
            account.balance = abs(balance)
        } else {
            context.insert(Account(name: trimmed, category: category, balance: balance))
        }
        dismiss()
    }

    private func deleteAccount() {
        if let account { context.delete(account) }
        dismiss()
    }
}

// MARK: - Small form helpers (shared by the other forms in this app)

struct FieldCard<Content: View>: View {
    let label: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            Text(label.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkSecondary)
                .tracking(0.5)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}
