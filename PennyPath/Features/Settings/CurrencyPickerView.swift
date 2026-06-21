//
//  CurrencyPickerView.swift
//  PennyPath
//
//  A searchable list of every world currency (ISO 4217). Picks one and stores
//  its code; the whole app formats money in it.
//

import SwiftUI

struct CurrencyOption: Identifiable {
    let code: String
    let name: String
    let symbol: String?

    var id: String { code }

    init(_ code: String) {
        self.code = code
        self.name = Locale.current.localizedString(forCurrencyCode: code) ?? code
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        let candidate = formatter.currencySymbol ?? code
        // Only keep a symbol when it's actually distinct from the code.
        self.symbol = (candidate == code) ? nil : candidate
    }
}

struct CurrencyPickerView: View {
    static let defaultFooter = "Picking a currency changes how amounts are written, not their value — existing numbers aren't converted."

    @Binding var selection: String
    private let footer: String
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private let all: [CurrencyOption]

    init(selection: Binding<String>, footer: String = CurrencyPickerView.defaultFooter) {
        _selection = selection
        self.footer = footer
        all = Locale.commonISOCurrencyCodes
            .map(CurrencyOption.init)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var filtered: [CurrencyOption] {
        let query = search.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return all }
        return all.filter {
            $0.code.localizedCaseInsensitiveContains(query)
                || $0.name.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        List {
            Section {
            } footer: {
                Text(footer)
                    .foregroundStyle(Spectrum.onCanvasSoft)
            }
            .listRowBackground(Color.clear)
            ForEach(filtered) { option in
                Button {
                    selection = option.code
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.code)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Spectrum.onCanvas)
                            Text(option.name)
                                .font(.caption)
                                .foregroundStyle(Spectrum.onCanvasSoft)
                        }
                        Spacer()
                        if let symbol = option.symbol {
                            Text(symbol)
                                .font(.body)
                                .foregroundStyle(Spectrum.onCanvasSoft)
                        }
                        if option.code == selection {
                            Image(systemName: "checkmark")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Spectrum.accent)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Spectrum.canvas.ignoresSafeArea())
        .tint(Spectrum.accent)
        .searchable(text: $search, prompt: "Search currencies")
        .autocorrectionDisabled()
        .navigationTitle("Currency")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if filtered.isEmpty {
                ContentUnavailableView.search(text: search)
            }
        }
    }
}
