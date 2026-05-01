//
//  ExchangeCalculatorTests.swift
//  ExchangeCalculatorTests
//
//  Created by Pavel Selivanov on 5/1/26.
//

import Testing
@testable import ExchangeCalculator

struct ExchangeCalculatorTests {

    @Test func fallbackCurrencyListKeepsTheAppFunctional() {
        #expect(CurrencyCatalog.fallbackCurrencies.map(\.code) == ["MXN", "ARS", "BRL", "COP"])
    }
}
