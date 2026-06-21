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
    @FocusState private var sharesFocused: Bool

    private var isEditing: Bool { holding != nil }
    private var symbol: String { holding?.symbol ?? match?.symbol ?? "" }
    private var name: String { holding?.companyName ?? match?.name ?? "" }
    private var exchange: String { match?.exchange ?? "" }
    private var assetType: String { holding?.assetType ?? match?.type ?? "" }
    private var unitNoun: String { InstrumentType.unitNoun(assetType) }
    private var canSave: Bool { shares > 0 }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text(symbol)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Spectrum.accent)
                    if !name.isEmpty {
                        Text(name)
                            .font(.subheadline)
                            .foregroundStyle(Spectrum.onCanvasSoft)
                            .multilineTextAlignment(.center)
                    }
                    if !exchange.isEmpty {
                        Text(exchange)
                            .font(.caption)
                            .foregroundStyle(Spectrum.onCanvasSoft.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 26)
                .spectrumPanel(padding: 0)

                labeled("How many \(unitNoun)?") {
                    TextField("0", value: $shares, format: .number.precision(.fractionLength(0...4)))
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Spectrum.onCanvas)
                        .keyboardType(.decimalPad)
                        .focused($sharesFocused)
                }

                if isEditing { removeButton }
                saveButton
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .background(Spectrum.canvas.ignoresSafeArea())
        .navigationTitle(isEditing ? "Edit investment" : "Add investment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsCancel {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { finish() } }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { sharesFocused = false }.bold()
            }
        }
        .tint(Spectrum.accent)
        .onAppear { if let holding { shares = holding.shares } }
    }

    private var removeButton: some View {
        Button(role: .destructive) { remove() } label: {
            Text("Remove investment")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Spectrum.spend)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Spectrum.spend.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var saveButton: some View {
        Button { save() } label: {
            Text(isEditing ? "Save changes" : "Add investment")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Spectrum.plusInk)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(canSave ? Spectrum.plus : Spectrum.plus.opacity(0.4), in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
    }

    // MARK: Titled smoked-glass panel (matches Add Item / Add Account)

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
