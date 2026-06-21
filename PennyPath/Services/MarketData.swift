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
    /// Synthetic quoteType for curated precious-metal holdings. They're priced
    /// from commodity-futures symbols (GC=F, SI=F, …) but valued per troy ounce.
    static let preciousMetal = "PRECIOUSMETAL"

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
        case "PRECIOUSMETAL": return "Precious Metal"
        case "": return ""
        default: return raw.capitalized
        }
    }

    static func isFund(_ raw: String) -> Bool {
        raw.uppercased().contains("MUTUAL") || raw.uppercased() == "FUND"
    }

    static func isMetal(_ raw: String) -> Bool {
        raw.uppercased().replacingOccurrences(of: " ", with: "") == preciousMetal
    }

    /// "ounces" for metals, "units" for mutual funds, "shares" otherwise.
    static func unitNoun(_ raw: String) -> String {
        if isMetal(raw) { return "ounces" }
        return isFund(raw) ? "units" : "shares"
    }
    static func unitAbbrev(_ raw: String) -> String {
        if isMetal(raw) { return "oz" }
        return isFund(raw) ? "units" : "sh"
    }
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
    /// All rates for `base` (base → code), in one call. The robust source for
    /// converting every account and holding into the user's currency.
    func fxRates(base: String) async throws -> [String: Double]
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

    func fxRates(base: String) async throws -> [String: Double] {
        // open.er-api.com: keyless, one call returns every currency for `base`.
        let url = "https://open.er-api.com/v6/latest/\(base.uppercased())"
        let response: ERApiResponse = try await get(url)
        guard response.result == "success", !response.rates.isEmpty else {
            throw MarketError.noData
        }
        return response.rates
    }

    func fxRate(from: String, to: String) async throws -> Double {
        if from == to { return 1 }
        // Prefer the bulk table; it's the same source the whole app converts with.
        if let rates = try? await fxRates(base: to), let units = rates[from], units > 0 {
            return 1 / units
        }
        // Fallback: Yahoo's per-pair FX symbol (e.g. INRUSD=X).
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

    private struct ERApiResponse: Decodable {
        let result: String
        let rates: [String: Double]
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

    /// Refresh exchange rates, every holding's price, and every account's
    /// converted value, then roll investments into the Net Worth account.
    func refresh(holdings: [Holding], displayCurrency: String, in context: ModelContext) async {
        isRefreshing = true
        lastError = nil
        defer { isRefreshing = false }

        // 0. One FX call covers every currency the app needs — accounts *and*
        //    holdings convert from the same shared, persisted table.
        await MarketService.refreshRates(base: displayCurrency, provider: provider)
        refreshAccountFX(displayCurrency: displayCurrency, in: context)

        guard !holdings.isEmpty else {
            Investments.rebuild(holdings: holdings, in: context)
            return
        }

        // 1. Prices — a few at a time: fast for big portfolios while staying
        //    gentle on the public API.
        var quotes: [String: Quote] = [:]
        let symbols = Array(Set(holdings.map(\.symbol)))
        let provider = self.provider
        for batch in stride(from: 0, to: symbols.count, by: 4).map({ Array(symbols[$0..<min($0 + 4, symbols.count)]) }) {
            await withTaskGroup(of: (String, Quote?).self) { group in
                for symbol in batch {
                    group.addTask { (symbol, try? await provider.quote(symbol)) }
                }
                for await (symbol, quote) in group {
                    if let quote { quotes[symbol] = quote }
                }
            }
        }

        // 2. Apply prices, converting each holding's currency with the shared table.
        for holding in holdings {
            guard let quote = quotes[holding.symbol] else { continue }
            // Today's move is a ratio, so the quote's unit cancels out.
            if let prev = quote.previousClose, prev > 0 {
                holding.cachedChangePercent = (quote.price - prev) / prev
            }
            // Some exchanges quote a security in a currency's MINOR unit — London
            // in pence (GBp), Tel Aviv in agorot (ILA), Johannesburg in cents
            // (ZAc). FX tables only know the major unit (GBP/ILS/ZAR), so map the
            // currency to its major and scale the price into that unit before
            // converting; otherwise a £25 holding quoted as 2500 GBp would be
            // counted as 2500, not 25.
            let (currency, priceFactor) = MarketService.normalizedQuoteCurrency(quote.currency)
            holding.quoteCurrency = currency
            holding.cachedPrice = quote.price * priceFactor

            // Keep curated names for metals — the futures quote name is the
            // contract month (e.g. "Gold Aug 26"), not a useful label.
            if let name = quote.name, !name.isEmpty, !InstrumentType.isMetal(holding.assetType) {
                holding.companyName = name
            }

            // Convert with the shared rate. Never fabricate 1:1 for a foreign
            // currency: prefer the live rate, then a real rate cached from a prior
            // refresh, otherwise leave the value pending (0) until a refresh fills
            // it in — exactly how foreign accounts behave, so net worth is never
            // silently wrong (a brand-new holding's cachedFXRate is 1 by default,
            // which must not be mistaken for a real foreign rate).
            if let rate = FXRates.rateToBase(currency, base: displayCurrency) {
                holding.cachedFXRate = rate
                holding.cachedValueInBase = holding.shares * holding.cachedPrice * rate
            } else if currency == displayCurrency {
                holding.cachedFXRate = 1
                holding.cachedValueInBase = holding.shares * holding.cachedPrice
            } else if holding.cachedFXRate > 0, holding.cachedFXRate != 1 {
                holding.cachedValueInBase = holding.shares * holding.cachedPrice * holding.cachedFXRate
            } else {
                holding.cachedValueInBase = 0
            }
            holding.lastUpdated = .now
        }

        Investments.rebuild(holdings: holdings, in: context)

        if quotes.isEmpty {
            lastError = "Couldn't reach the market just now. Showing last known values."
        } else {
            lastUpdated = .now
        }
    }

    /// Fetch and persist the full rate table for `base`. Shared so the add form
    /// can warm the cache before saving a foreign account.
    @discardableResult
    static func refreshRates(base: String, provider: MarketDataProvider) async -> Bool {
        guard let rates = try? await provider.fxRates(base: base), !rates.isEmpty else {
            return false
        }
        FXRates.update(base: base, rates: rates)
        return true
    }

    /// Map a quote currency to the major ISO unit the FX table understands, plus a
    /// factor to scale the price into that unit. Some exchanges quote in a minor
    /// unit (pence, agorot, cents) that no FX source lists. Unknown codes pass
    /// through unchanged with a factor of 1.
    nonisolated static func normalizedQuoteCurrency(_ code: String) -> (code: String, priceFactor: Double) {
        switch code {
        case "GBp", "GBX": return ("GBP", 0.01)   // London — pence
        case "ILA", "ILa": return ("ILS", 0.01)   // Tel Aviv — agorot
        case "ZAc", "ZAX": return ("ZAR", 0.01)   // Johannesburg — cents
        default:           return (code, 1)
        }
    }

    /// Snap each manual account's cached rate to the shared table. Base-currency
    /// accounts pin to 1; foreign ones with no known rate keep their last value.
    private func refreshAccountFX(displayCurrency: String, in context: ModelContext) {
        let accounts = ((try? context.fetch(FetchDescriptor<Account>())) ?? [])
            .filter { !$0.isMarketLinked }
        for account in accounts {
            let code = account.currencyCode
            if code.isEmpty || code == displayCurrency {
                account.cachedFXRate = 1
                account.cachedFXBase = displayCurrency
            } else if let rate = FXRates.rateToBase(code, base: displayCurrency) {
                account.cachedFXRate = rate
                account.cachedFXBase = displayCurrency
            }
            // A foreign account with no known rate keeps its old cache; because
            // its `cachedFXBase` no longer matches the (possibly changed) base,
            // `baseBalance` treats it as pending instead of converting wrongly.
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
            // No holdings left → remove the auto-account rather than leaving a
            // stray $0 "Investments" entry lingering in the store.
            if holdings.isEmpty { context.delete(account) }
            else { account.balance = total }
        } else if !holdings.isEmpty {
            context.insert(Account(name: "Investments", category: .investment,
                                   balance: total, isMarketLinked: true))
        }
    }
}
