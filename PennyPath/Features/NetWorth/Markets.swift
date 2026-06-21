//
//  Markets.swift
//  PennyPath
//
//  A catalog of world stock markets. Pick one, then search instruments that
//  trade on it. Matching uses Yahoo's exchange labels plus symbol suffixes
//  (e.g. .L London, .NS India, .T Tokyo) so results are scoped to the market.
//

import Foundation

struct Market: Identifiable, Hashable {
    let id: String
    let name: String          // e.g. "London Stock Exchange"
    let region: String        // e.g. "United Kingdom"
    let flag: String          // e.g. "🇬🇧"
    let keywords: [String]    // lowercased, matched against a result's exchange label
    let suffixes: [String]    // e.g. [".NS", ".BO"], matched against the symbol
    var isAll: Bool = false
    var allowedTypes: Set<String>? = nil   // if set, only these quoteTypes are kept (e.g. ETF, MUTUALFUND)
    var searchHint: String? = nil          // overrides the instrument-search helper text

    var subtitle: String {
        if isAll { return "Search across every exchange" }
        if let suffix = suffixes.first, !suffix.isEmpty { return "\(region) · \(suffix)" }
        return region
    }

    /// Does a search result belong to this market?
    func accepts(_ match: SymbolMatch) -> Bool {
        if let allowedTypes {
            let type = match.type.uppercased().replacingOccurrences(of: " ", with: "")
            if !allowedTypes.contains(type) { return false }
        }
        if isAll { return true }
        let exchange = match.exchange.lowercased()
        if keywords.contains(where: { !$0.isEmpty && exchange.contains($0) }) { return true }
        let symbol = match.symbol.uppercased()
        if suffixes.contains(where: { !$0.isEmpty && symbol.hasSuffix($0.uppercased()) }) { return true }
        return false
    }
}

enum Markets {
    static let all: [Market] = [
        Market(id: "all", name: "All markets", region: "", flag: "🌐",
               keywords: [], suffixes: [], isAll: true),

        Market(id: "us", name: "United States — NYSE · NASDAQ", region: "United States", flag: "🇺🇸",
               keywords: ["nasdaq", "nyse", "nyse american", "nysearca", "nyse arca", "arca",
                          "amex", "bats", "cboe", "otc", "pink", "nms", "ngm", "ase", "pcx"],
               suffixes: []),
        Market(id: "uk", name: "London Stock Exchange", region: "United Kingdom", flag: "🇬🇧",
               keywords: ["london", "lse", "ftse"], suffixes: [".L"]),
        Market(id: "in", name: "NSE & BSE", region: "India", flag: "🇮🇳",
               keywords: ["nse", "bse", "national stock exchange", "bombay"], suffixes: [".NS", ".BO"]),
        Market(id: "jp", name: "Tokyo Stock Exchange", region: "Japan", flag: "🇯🇵",
               keywords: ["tokyo", "jpx", "jasdaq"], suffixes: [".T"]),
        Market(id: "de", name: "XETRA · Frankfurt", region: "Germany", flag: "🇩🇪",
               keywords: ["xetra", "frankfurt", "stuttgart", "munich", "berlin", "dusseldorf", "hamburg", "ger"],
               suffixes: [".DE", ".F", ".BE", ".MU", ".SG", ".HM", ".DU"]),
        Market(id: "hk", name: "Hong Kong (HKEX)", region: "Hong Kong", flag: "🇭🇰",
               keywords: ["hong kong", "hkse", "hkg"], suffixes: [".HK"]),
        Market(id: "ca", name: "Toronto (TSX)", region: "Canada", flag: "🇨🇦",
               keywords: ["toronto", "tsx", "tsxv", "cse", "neo"], suffixes: [".TO", ".V", ".CN", ".NE"]),
        Market(id: "fr", name: "Euronext Paris", region: "France", flag: "🇫🇷",
               keywords: ["paris"], suffixes: [".PA"]),
        Market(id: "au", name: "ASX", region: "Australia", flag: "🇦🇺",
               keywords: ["asx", "australian"], suffixes: [".AX"]),
        Market(id: "cn", name: "Shanghai & Shenzhen", region: "China", flag: "🇨🇳",
               keywords: ["shanghai", "shenzhen"], suffixes: [".SS", ".SZ"]),
        Market(id: "ch", name: "SIX Swiss Exchange", region: "Switzerland", flag: "🇨🇭",
               keywords: ["swiss", "six", "zurich"], suffixes: [".SW"]),
        Market(id: "nl", name: "Euronext Amsterdam", region: "Netherlands", flag: "🇳🇱",
               keywords: ["amsterdam"], suffixes: [".AS"]),
        Market(id: "es", name: "BME Madrid", region: "Spain", flag: "🇪🇸",
               keywords: ["madrid", "mce", "bolsa de madrid"], suffixes: [".MC"]),
        Market(id: "it", name: "Borsa Italiana", region: "Italy", flag: "🇮🇹",
               keywords: ["milan", "milano"], suffixes: [".MI"]),
        Market(id: "br", name: "B3 — Bovespa", region: "Brazil", flag: "🇧🇷",
               keywords: ["sao paulo", "são paulo", "bovespa", "b3"], suffixes: [".SA"]),
        Market(id: "kr", name: "KRX — KOSPI · KOSDAQ", region: "South Korea", flag: "🇰🇷",
               keywords: ["korea", "kosdaq", "kospi", "kse", "krx"], suffixes: [".KS", ".KQ"]),
        Market(id: "tw", name: "Taiwan Stock Exchange", region: "Taiwan", flag: "🇹🇼",
               keywords: ["taiwan"], suffixes: [".TW", ".TWO"]),
        Market(id: "sg", name: "Singapore Exchange (SGX)", region: "Singapore", flag: "🇸🇬",
               keywords: ["singapore", "sgx"], suffixes: [".SI"]),
        Market(id: "sa", name: "Tadawul", region: "Saudi Arabia", flag: "🇸🇦",
               keywords: ["saudi", "tadawul"], suffixes: [".SR"]),
        Market(id: "za", name: "Johannesburg (JSE)", region: "South Africa", flag: "🇿🇦",
               keywords: ["johannesburg", "jse"], suffixes: [".JO"]),
        Market(id: "mx", name: "Mexican Exchange (BMV)", region: "Mexico", flag: "🇲🇽",
               keywords: ["mexico"], suffixes: [".MX"]),
        Market(id: "se", name: "Nasdaq Stockholm", region: "Sweden", flag: "🇸🇪",
               keywords: ["stockholm"], suffixes: [".ST"]),
        Market(id: "no", name: "Oslo Børs", region: "Norway", flag: "🇳🇴",
               keywords: ["oslo"], suffixes: [".OL"]),
        Market(id: "dk", name: "Nasdaq Copenhagen", region: "Denmark", flag: "🇩🇰",
               keywords: ["copenhagen"], suffixes: [".CO"]),
        Market(id: "fi", name: "Nasdaq Helsinki", region: "Finland", flag: "🇫🇮",
               keywords: ["helsinki"], suffixes: [".HE"]),
        Market(id: "be", name: "Euronext Brussels", region: "Belgium", flag: "🇧🇪",
               keywords: ["brussels"], suffixes: [".BR"]),
        Market(id: "pt", name: "Euronext Lisbon", region: "Portugal", flag: "🇵🇹",
               keywords: ["lisbon"], suffixes: [".LS"]),
        Market(id: "at", name: "Vienna (Wiener Börse)", region: "Austria", flag: "🇦🇹",
               keywords: ["vienna"], suffixes: [".VI"]),
        Market(id: "nz", name: "NZX", region: "New Zealand", flag: "🇳🇿",
               keywords: ["new zealand", "nzx"], suffixes: [".NZ"]),
        Market(id: "id", name: "Indonesia Stock Exchange", region: "Indonesia", flag: "🇮🇩",
               keywords: ["jakarta", "indonesia"], suffixes: [".JK"]),
        Market(id: "th", name: "Stock Exchange of Thailand", region: "Thailand", flag: "🇹🇭",
               keywords: ["thailand", "bangkok"], suffixes: [".BK"]),
        Market(id: "my", name: "Bursa Malaysia", region: "Malaysia", flag: "🇲🇾",
               keywords: ["malaysia", "kuala lumpur"], suffixes: [".KL"]),
        Market(id: "tr", name: "Borsa İstanbul", region: "Türkiye", flag: "🇹🇷",
               keywords: ["istanbul"], suffixes: [".IS"]),
        Market(id: "il", name: "Tel Aviv (TASE)", region: "Israel", flag: "🇮🇱",
               keywords: ["tel aviv", "israel"], suffixes: [".TA"]),
        Market(id: "crypto", name: "Crypto", region: "Bitcoin, Ethereum & more", flag: "🪙",
               keywords: ["ccc", "cryptocurrency", "crypto"], suffixes: ["-USD"])
    ]

    /// Entry point for the "Investment Fund" flow: a global instrument search
    /// scoped to mutual funds and ETFs, so equities and crypto don't clutter it.
    static let funds = Market(
        id: "funds", name: "Funds & ETFs", region: "Mutual funds & ETFs worldwide", flag: "🧺",
        keywords: [], suffixes: [], isAll: true,
        allowedTypes: ["MUTUALFUND", "ETF"],
        searchHint: "Search any mutual fund or ETF worldwide — try “Vanguard”, “VFIAX”, or “VWRA.L”.")

    static func search(_ query: String) -> [Market] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return all }
        return all.filter { market in
            guard !market.isAll else { return false }
            return market.name.lowercased().contains(q)
                || market.region.lowercased().contains(q)
                || market.keywords.contains { $0.contains(q) }
        }
    }
}
