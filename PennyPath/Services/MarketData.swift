//
//  MarketData.swift
//  PennyPath
//
//  Fetches live prices, symbol search, and FX rates. The default provider uses
//  Yahoo Finance's public (keyless) endpoints, which reach most world exchanges
//  via symbol suffixes (e.g. AAPL, BMW.DE, RELIANCE.NS, 7203.T, 0700.HK).
//
//  Everything goes through `MarketDataProvider`, so a paid provider (Finnhub,
//  Polygon, Twelve Data, …) can be dropped in later — just implement the
//  protocol and set `MarketService.provider`.
//
//  This is read-only valuation: prices in, value out. No trading, no advice.
//

import Foundation
import SwiftData

// MARK: - Models

struct Quote {
    let symbol: String
    let name: String?
    let price: Double
    let previousClose: Double?
    let currency: String
}

struct SymbolMatch: Identifiable, Hashable {
    let symbol: String
    let name: String
    let exchange: String
    let type: String          // raw Yahoo quoteType, e.g. "EQUITY", "MUTUALFUND"
    var id: String { symbol }
}

/// Friendly labels and unit nouns for instrument types.
enum InstrumentType {
    static func friendly(_ raw: String) -> String {
        switch raw.uppercased().replacingOccurrences(of: " ", with: "") {
        case "EQUITY", "STOCK", "EQUITIES": return "Stock"
        case "MUTUALFUND", "FUND": return "Mutual Fund"
        case "ETF": return "ETF"
        case "INDEX": return "Index"
        case "CRYPTOCURRENCY", "CRYPTO": return "Crypto"
        case "CURRENCY": return "FX"
        case "FUTURE": return "Future"
        case "OPTION": return "Option"
        case "": return ""
        default: return raw.capitalized
        }
    }

    static func isFund(_ raw: String) -> Bool {
        raw.uppercased().contains("MUTUAL") || raw.uppercased() == "FUND"
    }

    /// "units" for mutual funds, "shares" otherwise.
    static func unitNoun(_ raw: String) -> String { isFund(raw) ? "units" : "shares" }
    static func unitAbbrev(_ raw: String) -> String { isFund(raw) ? "units" : "sh" }
}

enum MarketError: LocalizedError {
    case badURL, badResponse, noData
    var errorDescription: String? {
        switch self {
        case .badURL: return "Bad request."
        case .badResponse: return "The market service didn't respond."
        case .noData: return "No data for that symbol."
        }
    }
}

// MARK: - Provider

protocol MarketDataProvider {
    func quote(_ symbol: String) async throws -> Quote
    func search(_ query: String) async throws -> [SymbolMatch]
    func fxRate(from: String, to: String) async throws -> Double
}

struct YahooMarketDataProvider: MarketDataProvider {
    private let session: URLSession = .shared
    private let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko)"

    func quote(_ symbol: String) async throws -> Quote {
        let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        let url = "https://query1.finance.yahoo.com/v8/finance/chart/\(encoded)?interval=1d&range=1d"
        let response: ChartResponse = try await get(url)
        guard let meta = response.chart.result?.first?.meta, let price = meta.regularMarketPrice else {
            throw MarketError.noData
        }
        return Quote(
            symbol: meta.symbol ?? symbol,
            name: meta.longName ?? meta.shortName,
            price: price,
            previousClose: meta.chartPreviousClose ?? meta.previousClose,
            currency: meta.currency ?? "USD"
        )
    }

    func search(_ query: String) async throws -> [SymbolMatch] {
        var components = URLComponents(string: "https://query2.finance.yahoo.com/v1/finance/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "quotesCount", value: "25"),
            URLQueryItem(name: "newsCount", value: "0")
        ]
        guard let url = components.url else { throw MarketError.badURL }
        let response: SearchResponse = try await get(url.absoluteString)
        return response.quotes.compactMap { item in
            guard let symbol = item.symbol, !symbol.isEmpty else { return nil }
            let name = item.longname ?? item.shortname ?? symbol
            return SymbolMatch(symbol: symbol,
                               name: name,
                               exchange: item.exchDisp ?? item.exchange ?? "",
                               type: item.quoteType ?? item.typeDisp ?? "")
        }
    }

    func fxRate(from: String, to: String) async throws -> Double {
        if from == to { return 1 }
        let quote = try await quote("\(from)\(to)=X")
        return quote.price
    }

    // MARK: Networking

    private func get<T: Decodable>(_ urlString: String) async throws -> T {
        guard let url = URL(string: urlString) else { throw MarketError.badURL }
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 12
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw MarketError.badResponse
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: Decoding

    private struct ChartResponse: Decodable {
        struct Chart: Decodable { let result: [Result]? }
        struct Result: Decodable { let meta: Meta }
        struct Meta: Decodable {
            let currency: String?
            let symbol: String?
            let regularMarketPrice: Double?
            let chartPreviousClose: Double?
            let previousClose: Double?
            let shortName: String?
            let longName: String?
        }
        let chart: Chart
    }

    private struct SearchResponse: Decodable {
        struct Item: Decodable {
            let symbol: String?
            let shortname: String?
            let longname: String?
            let exchDisp: String?
            let exchange: String?
            let quoteType: String?
            let typeDisp: String?
        }
        let quotes: [Item]
    }
}

// MARK: - Refresh service

@MainActor
@Observable
final class MarketService {
    var provider: MarketDataProvider = YahooMarketDataProvider()
    var isRefreshing = false
    var lastError: String?
    var lastUpdated: Date?

    /// Fetch fresh prices + FX for every holding, update the cached values, then
    /// roll the total into the market-linked Net Worth account.
    func refresh(holdings: [Holding], displayCurrency: String, in context: ModelContext) async {
        guard !holdings.isEmpty else {
            Investments.rebuild(holdings: holdings, in: context)
            return
        }
        isRefreshing = true
        lastError = nil
        defer { isRefreshing = false }

        // 1. Prices (one symbol at a time keeps us gentle on the public API).
        var quotes: [String: Quote] = [:]
        for holding in holdings {
            if let quote = try? await provider.quote(holding.symbol) {
                quotes[holding.symbol] = quote
            }
        }

        // 2. FX rates for each currency we actually need.
        var fx: [String: Double] = [:]
        for currency in Set(quotes.values.map(\.currency)) where currency != displayCurrency {
            if let rate = try? await provider.fxRate(from: currency, to: displayCurrency) {
                fx[currency] = rate
            }
        }

        // 3. Apply to holdings.
        for holding in holdings {
            guard let quote = quotes[holding.symbol] else { continue }
            holding.cachedPrice = quote.price
            holding.quoteCurrency = quote.currency
            if let prev = quote.previousClose, prev > 0 {
                holding.cachedChangePercent = (quote.price - prev) / prev
            }
            if let name = quote.name, !name.isEmpty { holding.companyName = name }
            let rate = quote.currency == displayCurrency ? 1 : (fx[quote.currency] ?? holding.cachedFXRate)
            holding.cachedFXRate = rate
            holding.cachedValueInBase = holding.shares * quote.price * rate
            holding.lastUpdated = .now
        }

        Investments.rebuild(holdings: holdings, in: context)

        if quotes.isEmpty {
            lastError = "Couldn't reach the market just now. Showing last known values."
        } else {
            lastUpdated = .now
        }
    }
}

// MARK: - Net Worth integration

/// Keeps a single hidden "Investments" account in sync with the live holdings
/// total, so every Net Worth calculation in the app includes investments
/// without each screen needing to know about market data.
enum Investments {
    static func linkedAccount(in context: ModelContext) -> Account? {
        let descriptor = FetchDescriptor<Account>(predicate: #Predicate<Account> { $0.isMarketLinked })
        return try? context.fetch(descriptor).first
    }

    static func allHoldings(in context: ModelContext) -> [Holding] {
        (try? context.fetch(FetchDescriptor<Holding>())) ?? []
    }

    static func rebuild(holdings: [Holding], in context: ModelContext) {
        let total = holdings.reduce(0) { $0 + $1.cachedValueInBase }
        if let account = linkedAccount(in: context) {
            account.balance = total
        } else if !holdings.isEmpty {
            context.insert(Account(name: "Investments", category: .investment,
                                   balance: total, isMarketLinked: true))
        }
    }
}
