//
//  ExchangeDataSnapshot.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/9/26.
//

nonisolated struct ExchangeDataSnapshot: Equatable, Sendable {
    let currencyList: CurrencyListSnapshot
    let exchangeRatesByQuoteCode: [String: ExchangeRateSnapshot]
}
