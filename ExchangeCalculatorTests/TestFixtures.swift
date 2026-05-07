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

    static func rate(
        quote: Currency = mxn,
        bid: Decimal,
        ask: Decimal
    ) -> ExchangeRate {
        ExchangeRate(base: usdc, quote: quote, bid: bid, ask: ask, quotedAt: date)
    }

    @MainActor
    static func viewModel(
        exchangeRate: ExchangeRate? = rate(),
        onQuoteCurrencySelected: @escaping ExchangeViewModel.OnQuoteCurrencySelected = { _ in },
        remoteRateForQuote: @escaping (Currency) throws -> ExchangeRate = { quote in
            rate(quote: quote)
        }
    ) -> ExchangeViewModel {
        ExchangeViewModel(
            sourceCurrency: usdc,
            targetCurrency: mxn,
            availableCurrencies: [mxn, ars, brl],
            exchangeRate: exchangeRate,
            loadData: {
                let currencies = [mxn, ars, brl]
                let rates = try currencies.reduce(into: [String: ExchangeRateSnapshot]()) { result, quote in
                    result[quote.code.uppercased()] = ExchangeRateSnapshot(
                        rate: try remoteRateForQuote(quote),
                        fetchedAt: date,
                        isStale: false
                    )
                }

                return .complete(
                    ExchangeDataSnapshot(
                        currencyList: CurrencyListSnapshot(
                            currencies: currencies,
                            source: .fallback,
                            updatedAt: nil
                        ),
                        exchangeRatesByQuoteCode: rates
                    )
                )
            },
            onQuoteCurrencySelected: onQuoteCurrencySelected
        )
    }

    static func exchangeData(
        currencies: [Currency] = [mxn, ars, brl],
        rates: [ExchangeRate] = [rate()]
    ) -> ExchangeDataSnapshot {
        ExchangeDataSnapshot(
            currencyList: CurrencyListSnapshot(
                currencies: currencies,
                source: .cache,
                updatedAt: date
            ),
            exchangeRatesByQuoteCode: rates.reduce(into: [:]) { result, rate in
                result[rate.quote.code.uppercased()] = ExchangeRateSnapshot(
                    rate: rate,
                    fetchedAt: date,
                    isStale: true
                )
            }
        )
    }
}
