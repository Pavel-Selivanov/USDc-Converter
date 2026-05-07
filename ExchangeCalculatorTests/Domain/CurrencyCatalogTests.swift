//
//  CurrencyCatalogTests.swift
//  ExchangeCalculatorTests
//
//  Created by Pavel Selivanov on 5/1/26.
//

import Testing
@testable import ExchangeCalculator

struct CurrencyCatalogTests {

    @Test func fallbackCurrencyListKeepsTheAppFunctional() {
        #expect(CurrencyCatalog.fallbackQuoteCurrencies.map(\.code) == ["MXN", "ARS", "BRL", "COP"])
    }
}
