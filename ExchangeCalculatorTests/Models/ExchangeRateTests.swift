//
//  ExchangeRateTests.swift
//  ExchangeCalculatorTests
//
//  Created by Pavel Selivanov on 5/4/26.
//

import Foundation
import Testing
@testable import ExchangeCalculator

@Suite("ExchangeRate")
struct ExchangeRateTests {

    private let usdc = Currency(code: "USDc", name: "USD Coin")
    private let mxn  = Currency(code: "MXN",  name: "Mexican Peso")

    private func makeRate(_ rate: Decimal = Decimal(string: "18.4097")!) -> ExchangeRate {
        ExchangeRate(base: usdc, quote: mxn, rate: rate)
    }

    private func makeSpreadRate(
        bid: Decimal = Decimal(string: "18.4069700000")!,
        ask: Decimal = Decimal(string: "18.4105000000")!
    ) -> ExchangeRate {
        ExchangeRate(base: usdc, quote: mxn, bid: bid, ask: ask, quotedAt: .distantPast)
    }

    // MARK: - convert / convertInverse

    @Test("convert multiplies the amount by the rate without precision loss")
    func convertIsExact() {
        let sut = makeRate()

        let result = sut.convert(100)

        // 100 * 18.4097 == 1840.97 exactly in Decimal.
        #expect(result == Decimal(string: "1840.97")!)
    }

    @Test("convertInverse divides the amount by the rate without precision loss")
    func convertInverseIsExact() {
        let sut = makeSpreadRate()

        let result = sut.convertInverse(Decimal(string: "1841.05")!)

        #expect(result == Decimal(100))
    }

    @Test("convertInverse returns 0 when rate is zero (no crash)")
    func convertInverseGuardsAgainstZeroRate() {
        let sut = makeRate(0)

        #expect(sut.convertInverse(100) == 0)
    }

    // MARK: - reversed

    @Test("reversed swaps base/quote and inverts the rate")
    func reversedSwapsAndInverts() {
        let sut = makeRate(2)

        let reversed = sut.reversed

        #expect(reversed.base == mxn)
        #expect(reversed.quote == usdc)
        #expect(reversed.rate == Decimal(string: "0.5")!)
    }

    @Test("reversed returns self when rate is zero (no divide-by-zero)")
    func reversedGuardsAgainstZeroRate() {
        let sut = makeRate(0)

        let reversed = sut.reversed

        #expect(reversed.base == sut.base)
        #expect(reversed.quote == sut.quote)
        #expect(reversed.rate == sut.rate)
    }

    @Test("reversing twice restores the original rate within Decimal inversion tolerance")
    func reversedIsInvolutive() {
        let sut = makeRate(Decimal(string: "18.4097")!)

        let roundTrip = sut.reversed.reversed

        #expect(roundTrip.base == sut.base)
        #expect(roundTrip.quote == sut.quote)
        #expect(abs(roundTrip.rate - sut.rate) < Decimal(string: "0.0000000001")!)
    }

}
