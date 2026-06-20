//
//  MarketListView.swift
//  PennyPath
//
//  Step 1 of adding an investment: pick a market (searchable). Tapping one
//  pushes the instrument search scoped to that market. Styled to the Spectrum
//  brand so the Add Account → investment flow stays on-brand throughout.
//

import SwiftUI

struct MarketListView: View {
    @Environment(\.dismiss) private var dismiss
    let service: MarketService

    @State private var query = ""

    private var markets: [Market] { Markets.search(query) }

    var body: some View {
        List {
            ForEach(markets) { market in
                NavigationLink(value: market) {
                    HStack(spacing: 12) {
                        Text(market.flag).font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(market.name)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Spectrum.onCanvas)
                            Text(market.subtitle)
                                .font(.caption)
                                .foregroundStyle(Spectrum.onCanvasSoft)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Spectrum.canvas.ignoresSafeArea())
        .navigationTitle("Choose a market")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
        }
        .searchable(text: $query, prompt: "Search markets or countries")
        .autocorrectionDisabled()
        .overlay {
            if markets.isEmpty {
                ContentUnavailableView.search(text: query)
            }
        }
        .tint(Spectrum.accent)
    }
}
