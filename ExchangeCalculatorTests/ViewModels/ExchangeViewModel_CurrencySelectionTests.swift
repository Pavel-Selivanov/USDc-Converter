//
//  ExchangeViewModel_CurrencySelectionTests.swift
//  ExchangeCalculatorTests
//
//  Created by Pavel Selivanov on 5/4/26.
//

import Foundation
import Testing
import Nimble
@testable import ExchangeCalculator

/// Locks down the state-machine behavior of `selectQuoteCurrency` and
/// `swapCurrencies`.
///
/// `selectQuoteCurrency` mutates three coupled pieces of state — the quote
/// currency, the rebuilt `ExchangeRate`, and the recomputed displayed amount.
/// Reordering or skipping any of these silently desyncs the UI (e.g. amount
/// shown for currency A while the rate is still for B). `swapCurrencies` is
/// documented to flip view slots only, never data — that contract is asserted
/// here so it can't be quietly broken.
@Suite("ExchangeViewModel currency selection & swap")
@MainActor
struct ExchangeViewModel_CurrencySelectionTests {

    private let ars = Currency(code: "ARS", name: "Argentine Peso")
    private let brl = Currency(code: "BRL", name: "Brazilian Real")

    // MARK: - selectQuoteCurrency

    @Test("Selecting a new quote preserves source input and fetches the quote's rate")
    func selectingQuotePreservesSourceInputAndFetchesRate() async {
        let sut = TestFixtures.viewModel { quote in
            TestFixtures.rate(quote: quote, rate: 100)
        }
        sut.onSourceChanged("100")

        await sut.selectQuoteCurrency(ars)

        expect(sut.sourceText).to(equal("100"))
        expect(sut.targetCurrency).to(equal(ars))
        expect(sut.exchangeRate?.quote).to(equal(ars))
        expect(sut.exchangeRate?.rate).to(equal(100))
        expect(sut.targetText).to(equal("10,000.00"))
    }

    @Test("When only the target field has input, selecting a quote recomputes the source")
    func selectingQuoteRecomputesFromTargetWhenSourceEmpty() async {
        let sut = TestFixtures.viewModel { quote in
            TestFixtures.rate(quote: quote, rate: 20)
        }
        sut.onTargetChanged("1840.97")
        expect(sut.sourceText).toNot(beEmpty()) // sanity

        await sut.selectQuoteCurrency(brl)

        expect(sut.targetCurrency).to(equal(brl))
        expect(sut.targetText).to(equal("1,840.97"))
        expect(sut.sourceText).to(equal("92.05"))
    }

    @Test("Selecting a quote with both fields empty does not populate either field")
    func selectingQuoteWithEmptyFieldsLeavesFieldsEmpty() async {
        let sut = TestFixtures.viewModel()

        await sut.selectQuoteCurrency(ars)

        expect(sut.targetCurrency).to(equal(ars))
        expect(sut.sourceText).to(equal(""))
        expect(sut.targetText).to(equal(""))
    }

    // MARK: - swapCurrencies

    @Test("swapCurrencies toggles isSwapped and never mutates currency or rate data")
    func swapTogglesFlagOnly() {
        let sut = TestFixtures.viewModel()
        sut.onSourceChanged("100")

        let sourceBefore   = sut.sourceCurrency
        let targetBefore   = sut.targetCurrency
        let rateBefore     = sut.exchangeRate
        let sourceTextBefore = sut.sourceText
        let targetTextBefore = sut.targetText

        sut.swapCurrencies()

        expect(sut.isSwapped).to(beTrue())
        expect(sut.sourceCurrency).to(equal(sourceBefore))
        expect(sut.targetCurrency).to(equal(targetBefore))
        expect(sut.exchangeRate?.base).to(equal(rateBefore?.base))
        expect(sut.exchangeRate?.quote).to(equal(rateBefore?.quote))
        expect(sut.exchangeRate?.rate).to(equal(rateBefore?.rate))
        expect(sut.sourceText).to(equal(sourceTextBefore))
        expect(sut.targetText).to(equal(targetTextBefore))

        sut.swapCurrencies()
        expect(sut.isSwapped).to(beFalse())
    }

    @Test("displayRate flips its direction when isSwapped, leaving raw rate intact")
    func displayRateFlipsWhenSwapped() {
        let sut = TestFixtures.viewModel()
        let rawRate = sut.exchangeRate?.rate

        let beforeSwap = sut.displayRate
        sut.swapCurrencies()
        let afterSwap = sut.displayRate

        expect(beforeSwap).toNot(beNil())
        expect(afterSwap).toNot(beNil())
        expect(beforeSwap).toNot(equal(afterSwap))
        // Raw rate magnitude on the model is unchanged — only the display flips.
        expect(sut.exchangeRate?.rate).to(equal(rawRate))
    }
}
