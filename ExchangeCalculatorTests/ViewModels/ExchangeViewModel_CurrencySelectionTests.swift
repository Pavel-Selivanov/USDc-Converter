//
//  ExchangeViewModel_CurrencySelectionTests.swift
//  ExchangeCalculatorTests
//
//  Created by Pavel Selivanov on 5/4/26.
//

import Foundation
import Testing
@testable import ExchangeCalculator

@Suite("ExchangeViewModel currency selection & swap")
@MainActor
struct ExchangeViewModel_CurrencySelectionTests {

    private let ars = Currency(code: "ARS", name: "Argentine Peso")
    private let brl = Currency(code: "BRL", name: "Brazilian Real")

    // MARK: - selectQuoteCurrency

    @Test("Selecting a new quote preserves source input and fetches the quote's rate")
    func selectingQuotePreservesSourceInputAndFetchesRate() async {
        let sut = TestFixtures.viewModel(remoteRateForQuote:  { quote in
            TestFixtures.rate(quote: quote, rate: 100)
        })
        await sut.loadInitialData()
        sut.onSourceChanged("100")

        await sut.selectQuoteCurrency(ars)

        #expect(sut.sourceText == "100")
        #expect(sut.targetCurrency == ars)
        #expect(sut.exchangeRate?.quote == ars)
        #expect(sut.exchangeRate?.rate == 100)
        #expect(sut.targetText == "10,000.00")
    }

    @Test("When only the target field has input, selecting a quote recomputes the source")
    func selectingQuoteRecomputesFromTargetWhenSourceEmpty() async {
        let sut = TestFixtures.viewModel(remoteRateForQuote:  { quote in
            TestFixtures.rate(quote: quote, rate: 20)
        })
        await sut.loadInitialData()
        sut.onTargetChanged("1840.97")
        #expect(!sut.sourceText.isEmpty)

        await sut.selectQuoteCurrency(brl)

        #expect(sut.targetCurrency == brl)
        #expect(sut.targetText == "1,840.97")
        #expect(sut.sourceText == "92.05")
    }

    @Test("Selecting a quote with both fields empty does not populate either field")
    func selectingQuoteWithEmptyFieldsLeavesFieldsEmpty() async {
        let sut = TestFixtures.viewModel()
        await sut.loadInitialData()

        await sut.selectQuoteCurrency(ars)

        #expect(sut.targetCurrency == ars)
        #expect(sut.sourceText == "")
        #expect(sut.targetText == "")
    }

    @Test("Selecting a quote notifies the persistence hook")
    func selectingQuoteNotifiesPersistenceHook() async {
        var persistedCurrency: Currency?
        let sut = TestFixtures.viewModel(
            onQuoteCurrencySelected: { persistedCurrency = $0 }
        )
        await sut.loadInitialData()

        await sut.selectQuoteCurrency(ars)

        #expect(persistedCurrency == ars)
    }

    // MARK: - swapCurrencies

    @Test("swapCurrencies toggles isSwapped, keeps currency data stable, and recomputes with ask")
    func swapRecomputesWithAskSide() {
        let spreadRate = TestFixtures.rate(bid: 10, ask: 20)
        let sut = TestFixtures.viewModel(exchangeRate: spreadRate)
        sut.onSourceChanged("100")

        let sourceBefore   = sut.sourceCurrency
        let targetBefore   = sut.targetCurrency
        let rateBefore     = sut.exchangeRate
        let sourceTextBefore = sut.sourceText
        #expect(sut.targetText == "1,000.00")

        sut.swapCurrencies()

        #expect(sut.isSwapped)
        #expect(sut.sourceCurrency == sourceBefore)
        #expect(sut.targetCurrency == targetBefore)
        #expect(sut.exchangeRate?.base == rateBefore?.base)
        #expect(sut.exchangeRate?.quote == rateBefore?.quote)
        #expect(sut.exchangeRate?.rate == rateBefore?.rate)
        #expect(sut.sourceText == sourceTextBefore)
        #expect(sut.targetText == "2,000.00")

        sut.swapCurrencies()
        #expect(!sut.isSwapped)
        #expect(sut.targetText == "1,000.00")
    }

    @Test("displayRate switches from bid to ask when swapped without reversing the pair")
    func displayRateFlipsWhenSwapped() {
        let sut = TestFixtures.viewModel(
            exchangeRate: TestFixtures.rate(
                bid: Decimal(string: "18.4069700000")!,
                ask: Decimal(string: "18.4105000000")!
            )
        )
        let rawRate = sut.exchangeRate?.rate

        let beforeSwap = sut.displayRate
        sut.swapCurrencies()
        let afterSwap = sut.displayRate

        #expect(beforeSwap != nil)
        #expect(afterSwap != nil)
        #expect(beforeSwap != afterSwap)
        #expect(beforeSwap?.hasPrefix("1 USDc = ") == true)
        #expect(afterSwap?.hasPrefix("1 USDc = ") == true)
        #expect(beforeSwap?.hasSuffix(" MXN") == true)
        #expect(afterSwap?.hasSuffix(" MXN") == true)
        #expect(beforeSwap?.contains("407") == true)
        #expect(afterSwap?.contains("4105") == true)
        #expect(sut.exchangeRate?.rate == rawRate)
    }
}
