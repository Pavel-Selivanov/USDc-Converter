//
//  ExchangeViewModel_InputValidationTests.swift
//  ExchangeCalculatorTests
//
//  Created by Pavel Selivanov on 5/4/26.
//

import Testing
import Nimble
@testable import ExchangeCalculator

/// Validates the keystroke-level input contract on `ExchangeViewModel`.
///
/// `onSourceChanged` / `onTargetChanged` run on every keystroke, silently
/// rejecting invalid input by reverting to the last accepted value. A
/// regression here means the user sees their typing eaten without feedback —
/// hence the exhaustive matrix.
@Suite("ExchangeViewModel input validation")
@MainActor
struct ExchangeViewModel_InputValidationTests {

    // MARK: - Acceptance

    @Test(
        "Accepts valid input and applies grouping separators",
        arguments: [
            (input: "0",            expected: "0"),
            (input: "9999",         expected: "9,999"),
            (input: "1234567",      expected: "1,234,567"),
            (input: "9999.",        expected: "9,999."),       // mid-typing decimal
            (input: ".5",           expected: ".5"),           // leading decimal
            (input: "1.23",         expected: "1.23"),
            (input: "1234567.50",   expected: "1,234,567.50"), // trailing zero preserved
            (input: "10000000000",  expected: "10,000,000,000"), // boundary: == maxInputValue
        ]
    )
    func acceptsValidSourceInput(input: String, expected: String) {
        let sut = TestFixtures.viewModel()

        sut.onSourceChanged(input)

        expect(sut.sourceText).to(equal(expected))
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

        expect(sut.sourceText).to(equal(lastValid))
    }

    // MARK: - Empty input clears the opposite field

    @Test("Clearing the source field also clears the target field")
    func clearingSourceClearsTarget() {
        let sut = TestFixtures.viewModel()
        sut.onSourceChanged("100")
        expect(sut.targetText).toNot(beEmpty()) // sanity

        sut.onSourceChanged("")

        expect(sut.sourceText).to(equal(""))
        expect(sut.targetText).to(equal(""))
    }

    @Test("Clearing the target field also clears the source field")
    func clearingTargetClearsSource() {
        let sut = TestFixtures.viewModel()
        sut.onTargetChanged("100")
        expect(sut.sourceText).toNot(beEmpty())

        sut.onTargetChanged("")

        expect(sut.targetText).to(equal(""))
        expect(sut.sourceText).to(equal(""))
    }

    // MARK: - Conversion is wired through on accepted input

    @Test("Accepted source input drives the target via the current rate")
    func acceptedInputComputesTarget() {
        let sut = TestFixtures.viewModel()
        sut.onSourceChanged("100")

        // Formatted with 2 fraction digits.
        expect(sut.targetText).to(equal("1,840.97"))
    }

    @Test("Input is ignored when no rate is available")
    func inputIsIgnoredWhenRateUnavailable() {
        let sut = TestFixtures.viewModel(exchangeRate: nil)

        sut.onSourceChanged("100")
        sut.onTargetChanged("200")

        expect(sut.canEditAmounts).to(beFalse())
        expect(sut.sourceText).to(equal(""))
        expect(sut.targetText).to(equal(""))
    }

    @Test("A failed rate refresh clears all amounts")
    func failedRefreshClearsAllAmounts() async {
        let sut = TestFixtures.viewModel { _ in
            throw ExchangeViewModelError.rateUnavailable
        }
        sut.onSourceChanged("100")

        await sut.refreshRate(forceRefresh: true)

        expect(sut.canEditAmounts).to(beFalse())
        expect(sut.sourceText).to(equal(""))
        expect(sut.targetText).to(equal(""))
    }
}
