//
//  HoldingSearchView.swift
//  PennyPath
//
//  The "Add investment" flow: a market list → instrument search within the
//  chosen market → the shares form. Saving in the form closes the whole sheet.
//
//  In `.funds` mode it skips the market picker and opens straight into a global
//  search scoped to mutual funds and ETFs (the "Investment Fund" entry point).
//

import SwiftUI

enum HoldingSearchMode {
    case markets   // pick a market, then search instruments on it
    case funds     // global search scoped to mutual funds & ETFs
}

struct HoldingSearchView: View {
    @Environment(\.dismiss) private var dismiss
    let service: MarketService
    var mode: HoldingSearchMode = .markets

    var body: some View {
        NavigationStack {
            root
                .navigationDestination(for: Market.self) { market in
                    InstrumentSearchView(market: market, service: service)
                }
                .navigationDestination(for: SymbolMatch.self) { match in
                    HoldingFormView(match: match, showsCancel: false, onComplete: { dismiss() })
                }
        }
    }

    @ViewBuilder private var root: some View {
        switch mode {
        case .markets:
            MarketListView(service: service)
        case .funds:
            InstrumentSearchView(market: Markets.funds, service: service, showsCancel: true)
        }
    }
}
