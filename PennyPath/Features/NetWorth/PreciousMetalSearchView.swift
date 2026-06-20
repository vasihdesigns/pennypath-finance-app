//
//  PreciousMetalSearchView.swift
//  PennyPath
//
//  The "Precious Metal" flow: a curated list (gold, silver, platinum,
//  palladium), each priced live from its commodity-futures symbol — GC=F, SI=F,
//  PL=F, PA=F, quoted in USD per troy ounce. Picking one opens the quantity
//  form; the holding then refreshes and rolls into Net Worth like any other.
//
//  Metals are a small fixed set, so a curated list beats free-text search:
//  the user never has to guess that "gold" means the futures ticker GC=F.
//

import SwiftUI

/// A tradable precious metal mapped onto a live Yahoo futures symbol.
struct PreciousMetal: Identifiable, Hashable {
    let name: String          // "Gold"
    let symbol: String        // "GC=F"
    let venue: String         // "COMEX"
    let tint: Color

    var id: String { symbol }

    /// A market match the rest of the investment flow already understands.
    var match: SymbolMatch {
        SymbolMatch(symbol: symbol,
                    name: name,
                    exchange: "\(venue) · per troy ounce (USD)",
                    type: InstrumentType.preciousMetal)
    }

    static let all: [PreciousMetal] = [
        PreciousMetal(name: "Gold",      symbol: "GC=F", venue: "COMEX", tint: Color(red: 0.83, green: 0.66, blue: 0.22)),
        PreciousMetal(name: "Silver",    symbol: "SI=F", venue: "COMEX", tint: Color(red: 0.66, green: 0.69, blue: 0.72)),
        PreciousMetal(name: "Platinum",  symbol: "PL=F", venue: "NYMEX", tint: Color(red: 0.58, green: 0.63, blue: 0.68)),
        PreciousMetal(name: "Palladium", symbol: "PA=F", venue: "NYMEX", tint: Color(red: 0.52, green: 0.56, blue: 0.54))
    ]
}

struct PreciousMetalSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    let service: MarketService

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(PreciousMetal.all) { metal in
                        NavigationLink(value: metal.match) {
                            HStack(spacing: 12) {
                                Image(systemName: "circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(metal.tint)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(metal.name)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(Spectrum.onCanvas)
                                    Text("\(metal.symbol) · \(metal.venue)")
                                        .font(.caption)
                                        .foregroundStyle(Spectrum.onCanvasSoft)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .listRowBackground(Spectrum.glassFill(dark: scheme == .dark))
                    }
                } footer: {
                    Text("Live prices, quoted per troy ounce in USD and converted to your currency. Enter how many ounces you hold.")
                        .foregroundStyle(Spectrum.onCanvasSoft)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Spectrum.canvas.ignoresSafeArea())
            .navigationTitle("Precious Metals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .navigationDestination(for: SymbolMatch.self) { match in
                HoldingFormView(match: match, showsCancel: false, onComplete: { dismiss() })
            }
            .tint(Spectrum.accent)
        }
    }
}
