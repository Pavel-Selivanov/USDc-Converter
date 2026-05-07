//
//  CurrencyRepositoryProtocol.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

protocol CurrencyRepositoryProtocol {
    func availableCurrencies() async throws -> CurrencyListSnapshot
}
