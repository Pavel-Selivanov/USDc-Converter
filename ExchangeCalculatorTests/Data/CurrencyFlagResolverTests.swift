//
//  CurrencyFlagResolverTests.swift
//  ExchangeCalculatorTests
//
//  Created by Pavel Selivanov on 5/7/26.
//

import Testing
import Nimble
@testable import ExchangeCalculator

@Suite("Currency flag resolver")
struct CurrencyFlagResolverTests {

    @Test(
        "Uses bundled asset names for currencies with designed flags",
        arguments: [
            (currency: Currency.mxn, expectedAsset: "Flags/MEX"),
            (currency: Currency.ars, expectedAsset: "Flags/ARG"),
            (currency: Currency.brl, expectedAsset: "Flags/BRA"),
            (currency: Currency.cop, expectedAsset: "Flags/COL"),
            (currency: Currency(code: "EUR", name: "Euro"), expectedAsset: "Flags/EU"),
            (currency: Currency.usdc, expectedAsset: "Flags/USA"),
        ]
    )
    func resolvesBundledFlagAssets(currency: Currency, expectedAsset: String) {
        expect(CurrencyFlagResolver.assetName(for: currency)).to(equal(expectedAsset))
    }

    @Test("Falls back to emoji when no bundled flag asset exists")
    func fallsBackToEmoji() {
        let currency = Currency(code: "GBP", name: "British Pound")

        expect(CurrencyFlagResolver.assetName(for: currency)).to(beNil())
        expect(CurrencyFlagResolver.flag(for: currency)).to(equal("🇬🇧"))
    }
}
