//
//  TestFixtures.swift
//  ExchangeCalculatorTests
//
//  Created by Pavel Selivanov on 5/7/26.
//

import Foundation
@testable import ExchangeCalculator

enum TestFixtures {
    static let date = Date(timeIntervalSince1970: 1_800_000_000)

    static let usdc = Currency(code: "USDc", name: "USD Coin")
    static let mxn = Currency(code: "MXN", name: "Mexican Peso")
    static let ars = Currency(code: "ARS", name: "Argentine Peso")
    static let brl = Currency(code: "BRL", name: "Brazilian Real")

    static func rate(
        quote: Currency = mxn,
        rate: Decimal = Decimal(string: "18.4097")!
    ) -> ExchangeRate {
        ExchangeRate(base: usdc, quote: quote, rate: rate, quotedAt: date)
    }

    static func viewModel(
        exchangeRate: ExchangeRate? = rate(),
        remoteRateForQuote: @escaping (Currency) throws -> ExchangeRate = { quote in
            rate(quote: quote)
        }
    ) -> ExchangeViewModel {
        ExchangeViewModel(
            sourceCurrency: usdc,
            targetCurrency: mxn,
            pickableCurrencies: [mxn, ars, brl],
            exchangeRate: exchangeRate,
            loadCurrencies: {
                CurrencyListSnapshot(
                    currencies: [mxn, ars, brl],
                    source: .fallback,
                    updatedAt: nil
                )
            },
            loadExchangeRate: { quote, _ in
                ExchangeRateSnapshot(
                    rate: try remoteRateForQuote(quote),
                    fetchedAt: date,
                    isStale: false
                )
            }
        )
    }
}

