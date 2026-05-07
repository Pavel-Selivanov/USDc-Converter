//
//  ExchangeViewModel_InputValidationTests.swift
//  ExchangeCalculatorTests
//
//  Created by Pavel Selivanov on 5/4/26.
//

import Foundation
import Testing
@testable import ExchangeCalculator

@Suite("ExchangeViewModel input validation")
@MainActor
struct ExchangeViewModel_InputValidationTests {

    // MARK: - Acceptance

    @Test(
        "Accepts valid input and applies grouping separators",
        arguments: [
            (input: "0",            expected: "0."),
            (input: "9999",         expected: "9,999"),
            (input: "1234567",      expected: "1,234,567"),
            (input: "9999.",        expected: "9,999."),       // mid-typing decimal
            (input: ".5",           expected: "0.5"),          // leading decimal
            (input: "1.23",         expected: "1.23"),
            (input: ",5",           expected: "0.5"),          // locale decimal separator
            (input: "1,2",          expected: "1.2"),
            (input: "1,234,5",      expected: "1,234.5"),      // grouping + locale decimal
            (input: "1234567.50",   expected: "1,234,567.50"), // trailing zero preserved
            (input: "10000000000",  expected: "10,000,000,000"), // boundary: == maxInputValue
        ]
    )
    func acceptsValidSourceInput(input: String, expected: String) {
        let sut = TestFixtures.viewModel()

        sut.onSourceChanged(input)

        #expect(sut.sourceText == expected)
    }

    @Test(
        "Normalizes leading zero input",
        arguments: [
            (input: "00",     expected: "0."),
            (input: "000.5",  expected: "0.5"),
            (input: "0012",   expected: "12"),
            (input: "0012.3", expected: "12.3"),
        ]
    )
    func normalizesLeadingZeroInput(input: String, expected: String) {
        let sut = TestFixtures.viewModel()

        sut.onSourceChanged(input)

        #expect(sut.sourceText == expected)
    }

    @Test("Treats a leading zero as fractional intent")
    func treatsLeadingZeroAsFractionalIntent() {
        let sut = TestFixtures.viewModel()

        sut.onSourceChanged("0")
        sut.onSourceChanged(sut.sourceText + "5")

        #expect(sut.sourceText == "0.5")
    }

    @Test("Backspace clears an auto-completed leading zero")
    func backspaceClearsAutoCompletedLeadingZero() {
        let sut = TestFixtures.viewModel()

        sut.onSourceChanged("0")
        sut.onSourceChanged("0")

        #expect(sut.sourceText == "")
    }

    @Test("Ignores unsupported simulator or pasted characters")
    func ignoresUnsupportedSimulatorOrPastedCharacters() {
        let sut = TestFixtures.viewModel()
        sut.onSourceChanged("100")

        sut.onSourceChanged(sut.sourceText + "abc$%")

        #expect(sut.sourceText == "100")
    }

    @Test("Rejects unsupported characters from an empty field")
    func rejectsUnsupportedCharactersFromEmptyField() {
        let sut = TestFixtures.viewModel()

        sut.onSourceChanged("abc$%")

        #expect(sut.sourceText == "")
    }

    @Test("Continues accepting digits after grouping separators are inserted")
    func continuesAcceptingDigitsAfterGroupingSeparatorsAreInserted() {
        let sut = TestFixtures.viewModel()

        for digit in "10000000000" {
            sut.onSourceChanged(sut.sourceText + String(digit))
        }

        #expect(sut.sourceText == "10,000,000,000")
    }

    @Test("Allows editing a calculated target amount above the source currency cap")
    func allowsEditingCalculatedTargetAmountAboveSourceCurrencyCap() {
        let sut = TestFixtures.viewModel()
        sut.onSourceChanged("10000000000")
        #expect(sut.targetText == "184,097,000,000.00")

        sut.onTargetChanged("184,097,000,000.0")

        #expect(sut.targetText == "184,097,000,000.0")
    }

    @Test(
        "Prefixes zero when the first typed character is a decimal separator",
        arguments: [".", ","]
    )
    func prefixesZeroForFirstDecimalSeparator(input: String) {
        let sut = TestFixtures.viewModel()

        sut.onSourceChanged(input)

        #expect(sut.sourceText == "0.")
    }

    @Test("Keeps accepting comma as decimal separator after grouping separators are inserted")
    func acceptsLocaleDecimalSeparatorAfterGroupingSeparatorsAreInserted() {
        let sut = TestFixtures.viewModel()
        sut.onSourceChanged("9999")

        sut.onSourceChanged(sut.sourceText + ",")
        sut.onSourceChanged(sut.sourceText + "5")

        #expect(sut.sourceText == "9,999.5")
    }

    // MARK: - Rejection (revert to last valid)

    @Test(
        "Rejects invalid input by reverting to the last accepted value",
        arguments: [
            "10000000001", // > maxInputValue
            "1.234",       // > maxFractionDigits
            "1.2.3",       // multiple decimals
            "1..2",        // multiple decimals adjacent
        ]
    )
    func rejectsInvalidSourceInput(input: String) {
        let sut = TestFixtures.viewModel()
        sut.onSourceChanged("100")
        let lastValid = sut.sourceText

        sut.onSourceChanged(input)

        #expect(sut.sourceText == lastValid)
    }

    // MARK: - Empty input clears the opposite field

    @Test("Clearing the source field also clears the target field")
    func clearingSourceClearsTarget() {
        let sut = TestFixtures.viewModel()
        sut.onSourceChanged("100")
        #expect(!sut.targetText.isEmpty) // sanity

        sut.onSourceChanged("")

        #expect(sut.sourceText == "")
        #expect(sut.targetText == "")
    }

    @Test("Clearing the target field also clears the source field")
    func clearingTargetClearsSource() {
        let sut = TestFixtures.viewModel()
        sut.onTargetChanged("100")
        #expect(!sut.sourceText.isEmpty)

        sut.onTargetChanged("")

        #expect(sut.targetText == "")
        #expect(sut.sourceText == "")
    }

    // MARK: - Conversion is wired through on accepted input

    @Test("Accepted source input drives the target via the current rate")
    func acceptedInputComputesTarget() {
        let sut = TestFixtures.viewModel()
        sut.onSourceChanged("100")

        // Formatted with 2 fraction digits.
        #expect(sut.targetText == "1,840.97")
    }

    @Test("Calculated amounts use the same separators as edited amounts")
    func calculatedAmountsUseProductSeparators() {
        let amount = Decimal(string: "2346419558.65")!

        #expect(AmountInputFormatter.formattedAmount(amount) == "2,346,419,558.65")
    }

    @Test("Input is disabled when currencies are available but no rate is usable")
    func inputIsDisabledWhenRateUnavailable() {
        let sut = TestFixtures.viewModel(exchangeRate: nil)

        sut.onSourceChanged("100")

        #expect(!sut.canEditAmounts)
        #expect(sut.sourceText == "")
        #expect(sut.targetText == "")
    }

    @Test("Cached launch data keeps input enabled before refresh completes")
    func cachedLaunchDataKeepsInputEnabled() {
        let sut = ExchangeViewModel(
            sourceCurrency: TestFixtures.usdc,
            targetCurrency: TestFixtures.mxn,
            availableCurrencies: [],
            initialExchangeData: TestFixtures.exchangeData(),
            loadData: {
                try await Task.sleep(for: .seconds(10))
                throw ExchangeViewModelError.dataUnavailable
            }
        )

        sut.onSourceChanged("100")

        #expect(sut.canEditAmounts)
        #expect(sut.sourceText == "100")
        #expect(sut.targetText == "1,840.97")
        #expect(!sut.showsManualRefresh)
        #expect(sut.rateStatusText == nil)
        #expect(sut.rateStatusTone == .hidden)
    }

    @Test("Initial load applies cached data before remote refresh")
    func initialLoadAppliesCachedDataBeforeRemoteRefresh() async {
        let events = LoadingEventRecorder()
        let sut = ExchangeViewModel(
            sourceCurrency: TestFixtures.usdc,
            targetCurrency: TestFixtures.mxn,
            availableCurrencies: [],
            loadCachedData: {
                await events.record("cache")
                return TestFixtures.exchangeData()
            },
            loadData: {
                await events.record("remote")
                throw ExchangeViewModelError.dataUnavailable
            }
        )

        await sut.loadInitialData()

        #expect(await events.values == ["cache", "remote"])
        #expect(sut.canEditAmounts)
        #expect(sut.exchangeRate == TestFixtures.rate())
        #expect(!sut.showsManualRefresh)
        #expect(sut.rateStatusText?.hasPrefix("Offline. Last updated") == true)
        #expect(sut.rateStatusIconName == "icloud.slash")
        #expect(sut.rateStatusTone == .warning)
    }

    @Test("A successful refresh keeps offline status hidden")
    func successfulRefreshKeepsOfflineStatusHidden() async {
        let sut = TestFixtures.viewModel()

        await sut.refreshData()

        #expect(sut.canEditAmounts)
        #expect(sut.exchangeRate == TestFixtures.rate())
        #expect(!sut.showsManualRefresh)
        #expect(sut.rateErrorText == nil)
        #expect(sut.rateStatusText == nil)
        #expect(sut.rateStatusIconName == nil)
        #expect(sut.rateStatusTone == .hidden)
    }

    @Test("A failed refresh without saved data leaves the app waiting for manual refresh")
    func failedRefreshWithoutSavedDataShowsManualRefresh() async {
        let sut = TestFixtures.viewModel(exchangeRate: nil, remoteRateForQuote:  { _ in
            throw ExchangeViewModelError.dataUnavailable
        })

        await sut.refreshData()

        #expect(!sut.canEditAmounts)
        #expect(sut.sourceText == "")
        #expect(sut.targetText == "")
        #expect(sut.showsManualRefresh)
        #expect(sut.rateErrorText == "Rates unavailable. Refresh when you're online.")
    }

    @Test("A failed refresh keeps saved data usable")
    func failedRefreshKeepsSavedDataUsable() async {
        let sut = TestFixtures.viewModel(remoteRateForQuote:  { _ in
            throw ExchangeViewModelError.dataUnavailable
        })
        sut.onSourceChanged("100")

        await sut.refreshData()

        #expect(sut.canEditAmounts)
        #expect(sut.sourceText == "100")
        #expect(sut.targetText == "1,840.97")
        #expect(!sut.showsManualRefresh)
        #expect(sut.rateStatusText?.hasPrefix("Offline. Last updated") == true)
        #expect(sut.rateStatusIconName == "icloud.slash")
        #expect(sut.rateStatusTone == .warning)
    }
}

private actor LoadingEventRecorder {
    private var recordedValues: [String] = []

    var values: [String] {
        recordedValues
    }

    func record(_ value: String) {
        recordedValues.append(value)
    }
}
