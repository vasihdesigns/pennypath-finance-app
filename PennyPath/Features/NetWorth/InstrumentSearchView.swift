//
//  InstrumentSearchView.swift
//  PennyPath
//
//  Step 2: search instruments within the chosen market. Results are filtered to
//  that market; picking one pushes the shares form. Styled to the Spectrum brand
//  so the Add Account → investment flow stays on-brand throughout.
//

import SwiftUI

struct InstrumentSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    let market: Market
    let service: MarketService
    /// Shown when this is the root of its own flow (e.g. the fund search), so the
    /// sheet can be dismissed without a market-picker behind it.
    var showsCancel: Bool = false

    @State private var query = ""
    @State private var results: [SymbolMatch] = []
    @State private var isSearching = false

    private var trimmedQuery: String { query.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        List {
            if trimmedQuery.isEmpty {
                Section {
                    Text(promptText)
                        .font(.footnote)
                        .foregroundStyle(Spectrum.onCanvasSoft)
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(results) { match in
                    NavigationLink(value: match) {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 8) {
                                Text(match.symbol)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Spectrum.onCanvas)
                                let typeLabel = InstrumentType.friendly(match.type)
                                if !typeLabel.isEmpty {
                                    Text(typeLabel)
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(Spectrum.onCanvasSoft)
                                        .padding(.vertical, 2).padding(.horizontal, 6)
                                        .background(Spectrum.glassFill(dark: scheme == .dark), in: Capsule())
                                }
                            }
                            Text(match.name)
                                .font(.caption)
                                .foregroundStyle(Spectrum.onCanvasSoft)
                                .lineLimit(1)
                            if !match.exchange.isEmpty {
                                Text(match.exchange)
                                    .font(.caption2)
                                    .foregroundStyle(Spectrum.onCanvasSoft.opacity(0.7))
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Spectrum.canvas.ignoresSafeArea())
        .navigationTitle(market.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsCancel {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
        .searchable(text: $query, prompt: searchPrompt)
        .autocorrectionDisabled()
        .overlay {
            if isSearching && results.isEmpty {
                ProgressView()
            } else if !trimmedQuery.isEmpty && results.isEmpty && !isSearching {
                ContentUnavailableView.search(text: query)
            }
        }
        .task(id: query) { await runSearch() }
        .tint(Spectrum.accent)
    }

    private var searchPrompt: String {
        market.isAll ? "Search symbols or companies" : "Search \(market.region.isEmpty ? market.name : market.region)"
    }

    private var promptText: String {
        if let hint = market.searchHint { return hint }
        if market.isAll {
            return "Search any stock, ETF, or fund worldwide — try “Apple”, “TSLA”, or “VWRA.L”."
        }
        let suffix = market.suffixes.first.map { " Symbols here end in \($0)." } ?? ""
        return "Search companies and funds on \(market.name).\(suffix)"
    }

    private func runSearch() async {
        let q = trimmedQuery
        guard !q.isEmpty else { results = []; return }
        // Debounce; the task is cancelled and restarted as the query changes.
        try? await Task.sleep(nanoseconds: 350_000_000)
        if Task.isCancelled { return }
        isSearching = true
        defer { isSearching = false }
        let found = (try? await service.provider.search(q)) ?? []
        if Task.isCancelled { return }
        results = found.filter { market.accepts($0) }
    }
}
