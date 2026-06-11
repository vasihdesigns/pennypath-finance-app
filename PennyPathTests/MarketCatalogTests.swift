//
//  MarketCatalogTests.swift
//  PennyPathTests
//
//  Market scoping and instrument labels for the investments flow.
//

import XCTest
@testable import PennyPath

final class MarketCatalogTests: XCTestCase {

    private func market(_ id: String) -> Market {
        Markets.all.first { $0.id == id }!
    }

    func testSuffixScopesMarket() {
        let india = market("in")
        let reliance = SymbolMatch(symbol: "RELIANCE.NS", name: "Reliance", exchange: "", type: "EQUITY")
        let apple = SymbolMatch(symbol: "AAPL", name: "Apple", exchange: "NASDAQ", type: "EQUITY")
        XCTAssertTrue(india.accepts(reliance))
        XCTAssertFalse(india.accepts(apple))
    }

    func testExchangeKeywordScopesMarket() {
        let us = market("us")
        let apple = SymbolMatch(symbol: "AAPL", name: "Apple", exchange: "NASDAQ", type: "EQUITY")
        XCTAssertTrue(us.accepts(apple))
    }

    func testAllMarketAcceptsEverything() {
        let all = market("all")
        let anything = SymbolMatch(symbol: "XYZ.ZZ", name: "?", exchange: "?", type: "")
        XCTAssertTrue(all.accepts(anything))
    }

    func testMarketSearchFindsByRegion() {
        XCTAssertTrue(Markets.search("india").contains { $0.id == "in" })
        XCTAssertTrue(Markets.search("").contains { $0.isAll })
        XCTAssertFalse(Markets.search("nonexistent-market").contains { $0.isAll })
    }

    func testInstrumentTypeLabels() {
        XCTAssertEqual(InstrumentType.friendly("EQUITY"), "Stock")
        XCTAssertEqual(InstrumentType.friendly("MUTUALFUND"), "Mutual Fund")
        XCTAssertEqual(InstrumentType.unitNoun("MUTUALFUND"), "units")
        XCTAssertEqual(InstrumentType.unitNoun("EQUITY"), "shares")
    }
}
