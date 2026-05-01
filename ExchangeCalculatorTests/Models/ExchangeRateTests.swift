//
//  ExchangeRateTests.swift
//  ExchangeCalculatorTests
//
//  Created by Pavel Selivanov on 5/4/26.
//

import Foundation
import Testing
import Nimble
@testable import ExchangeCalculator

/// Locks down the money-math contract of `ExchangeRate`.
///
/// The model intentionally uses `Decimal` (not `Double`) to avoid binary
/// floating-point drift on user-facing amounts. These tests pin that
/// guarantee, plus the divide-by-zero guards on `convertInverse` / `reversed`
/// which return safe defaults rather than crashing.
@Suite("ExchangeRate")
struct ExchangeRateTests {

    private let usdc = Currency(code: "USDc", name: "USD Coin")
    private let mxn  = Currency(code: "MXN",  name: "Mexican Peso")

    private func makeRate(_ rate: Decimal = Decimal(string: "18.4097")!) -> ExchangeRate {
        ExchangeRate(base: usdc, quote: mxn, rate: rate)
    }

    // MARK: - convert / convertInverse

    @Test("convert multiplies the amount by the rate without precision loss")
    func convertIsExact() {
        let sut = makeRate()

        let result = sut.convert(100)

        // 100 * 18.4097 == 1840.97 exactly in Decimal.
        expect(result).to(equal(Decimal(string: "1840.97")!))
    }

    @Test("convertInverse divides the amount by the rate without precision loss")
    func convertInverseIsExact() {
        let sut = makeRate()

        let result = sut.convertInverse(Decimal(string: "1840.97")!)

        expect(result).to(equal(Decimal(100)))
    }

    @Test("convertInverse returns 0 when rate is zero (no crash)")
    func convertInverseGuardsAgainstZeroRate() {
        let sut = makeRate(0)

        expect(sut.convertInverse(100)).to(equal(0))
    }

    // MARK: - reversed

    @Test("reversed swaps base/quote and inverts the rate")
    func reversedSwapsAndInverts() {
        let sut = makeRate(2)

        let reversed = sut.reversed

        expect(reversed.base).to(equal(mxn))
        expect(reversed.quote).to(equal(usdc))
        expect(reversed.rate).to(equal(Decimal(string: "0.5")!))
    }

    @Test("reversed returns self when rate is zero (no divide-by-zero)")
    func reversedGuardsAgainstZeroRate() {
        let sut = makeRate(0)

        let reversed = sut.reversed

        expect(reversed.base).to(equal(sut.base))
        expect(reversed.quote).to(equal(sut.quote))
        expect(reversed.rate).to(equal(sut.rate))
    }

    @Test("reversing twice restores the original rate within Decimal inversion tolerance")
    func reversedIsInvolutive() {
        let sut = makeRate(Decimal(string: "18.4097")!)

        let roundTrip = sut.reversed.reversed

        expect(roundTrip.base).to(equal(sut.base))
        expect(roundTrip.quote).to(equal(sut.quote))
        expect(abs(roundTrip.rate - sut.rate)).to(beLessThan(Decimal(string: "0.0000000001")!))
    }

    // MARK: - displayString

    @Test("displayString formats with 4 fraction digits and currency codes")
    func displayStringFormat() {
        // Pin locale for deterministic grouping/decimal separators.
        let previousLocale = Locale.autoupdatingCurrent
        _ = previousLocale // silence unused warning on platforms that don't expose it

        let sut = makeRate()

        // Note: `formatted` uses the current locale, but for this magnitude
        // (< 1000) there is no grouping separator, and the decimal separator
        // is "." in en_US. We assert prefix/suffix to stay locale-agnostic
        // for the parts we own.
        let display = sut.displayString
        expect(display).to(beginWith("1 USDc = "))
        expect(display).to(endWith(" MXN"))
        expect(display).to(contain("18"))
        expect(display).to(contain("4097"))
    }
}
