//
//  HoldingFormView.swift
//  PennyPath
//
//  Set how many shares of a chosen symbol you hold (or edit/remove one).
//  Designed to be pushed inside a NavigationStack (from search) or wrapped in
//  one (when editing from a sheet).
//

import SwiftUI
import SwiftData

struct HoldingFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var match: SymbolMatch?            // when adding
    var holding: Holding?              // when editing
    var showsCancel: Bool = true
    var onComplete: (() -> Void)?      // overrides dismiss (used from the search flow)

    @State private var shares: Double = 0

    private var isEditing: Bool { holding != nil }
    private var symbol: String { holding?.symbol ?? match?.symbol ?? "" }
    private var name: String { holding?.companyName ?? match?.name ?? "" }
    private var exchange: String { match?.exchange ?? "" }
    private var assetType: String { holding?.assetType ?? match?.type ?? "" }
    private var unitNoun: String { InstrumentType.unitNoun(assetType) }
    private var canSave: Bool { shares > 0 }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Space.lg) {
                VStack(spacing: 4) {
                    Text(symbol)
                        .font(.display(28))
                        .foregroundStyle(Theme.green)
                    if !name.isEmpty {
                        Text(name)
                            .font(.subheadline)
                            .foregroundStyle(Theme.inkSecondary)
                            .multilineTextAlignment(.center)
                    }
                    if !exchange.isEmpty {
                        Text(exchange)
                            .font(.caption)
                            .foregroundStyle(Theme.inkTertiary)
                    }
                }
                .frame(maxWidth: .infinity)
                .card(padding: Theme.Space.xl)

                FieldCard(label: "How many \(unitNoun)?") {
                    TextField("0", value: $shares, format: .number.precision(.fractionLength(0...4)))
                        .font(.amount(34))
                        .foregroundStyle(Theme.ink)
                        .keyboardType(.decimalPad)
                }

                if isEditing {
                    Button("Remove investment", role: .destructive) { remove() }
                        .buttonStyle(SoftButtonStyle(tint: Theme.red))
                }
            }
            .padding(Theme.Space.lg)
        }
        .background(Theme.background)
        .navigationTitle(isEditing ? "Edit investment" : "Add investment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsCancel {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { finish() } }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }.bold().disabled(!canSave)
            }
        }
        .tint(Theme.green)
        .onAppear { if let holding { shares = holding.shares } }
    }

    private func save() {
        if let holding {
            holding.shares = shares
        } else if let match {
            context.insert(Holding(symbol: match.symbol, companyName: match.name,
                                   shares: shares, assetType: match.type))
        }
        Investments.rebuild(holdings: Investments.allHoldings(in: context), in: context)
        finish()
    }

    private func remove() {
        if let holding { context.delete(holding) }
        Investments.rebuild(holdings: Investments.allHoldings(in: context), in: context)
        finish()
    }

    private func finish() { (onComplete ?? { dismiss() })() }
}
