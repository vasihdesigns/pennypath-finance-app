//
//  HoldingSearchView.swift
//  PennyPath
//
//  The "Add investment" flow: a market list → instrument search within the
//  chosen market → the shares form. Saving in the form closes the whole sheet.
//

import SwiftUI

struct HoldingSearchView: View {
    @Environment(\.dismiss) private var dismiss
    let service: MarketService

    var body: some View {
        NavigationStack {
            MarketListView(service: service)
                .navigationDestination(for: Market.self) { market in
                    InstrumentSearchView(market: market, service: service)
                }
                .navigationDestination(for: SymbolMatch.self) { match in
                    HoldingFormView(match: match, showsCancel: false, onComplete: { dismiss() })
                }
        }
    }
}
