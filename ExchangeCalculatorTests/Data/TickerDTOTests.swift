//
//  TickerDTOTests.swift
//  ExchangeCalculatorTests
//
//  Created by Pavel Selivanov on 5/7/26.
//

import Foundation
import Testing
@testable import ExchangeCalculator

@Suite("TickerDTO")
struct TickerDTOTests {
    @Test("Decodes API ticker and maps it into an ExchangeRate")
    func mapsTickerToExchangeRate() throws {
        let json = """
        {
          "ask": "18.4105000000",
          "bid": "18.4069700000",
          "book": "usdc_mxn",
          "date": "2025-10-20T20:14:57.361483956"
        }
        """

        let sut = try JSONDecoder().decode(TickerDTO.self, from: Data(json.utf8))
        let rate = try sut.exchangeRate(base: TestFixtures.usdc, quote: TestFixtures.mxn)

        #expect(sut.quoteCurrencyCode(baseCurrency: TestFixtures.usdc) == "MXN")
        #expect(rate.bid == Decimal(string: "18.4069700000")!)
        #expect(rate.ask == Decimal(string: "18.4105000000")!)
        #expect(rate.rate == Decimal(string: "18.4069700000")!)
    }

    @Test("Rejects malformed ticker values")
    func rejectsMalformedTicker() {
        let sut = TickerDTO(
            ask: "not-a-decimal",
            bid: "18.4069700000",
            book: "usdc_mxn",
            date: "2025-10-20T20:14:57.361483956"
        )

        #expect(throws: DolarAPIError.invalidTicker("usdc_mxn")) {
            try sut.exchangeRate(base: TestFixtures.usdc, quote: TestFixtures.mxn)
        }
    }
}
