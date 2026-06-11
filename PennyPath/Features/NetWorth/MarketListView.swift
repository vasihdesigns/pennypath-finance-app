//
//  MarketListView.swift
//  PennyPath
//
//  Step 1 of adding an investment: pick a market (searchable). Tapping one
//  pushes the instrument search scoped to that market.
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
                    HStack(spacing: Theme.Space.md) {
                        Text(market.flag).font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(market.name)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Theme.ink)
                            Text(market.subtitle)
                                .font(.caption)
                                .foregroundStyle(Theme.inkSecondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .listStyle(.plain)
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
        .tint(Theme.green)
    }
}
