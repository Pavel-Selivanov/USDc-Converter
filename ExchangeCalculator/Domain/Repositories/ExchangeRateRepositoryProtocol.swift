//
//  ExchangeRateRepositoryProtocol.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

protocol ExchangeRateRepositoryProtocol {
    func exchangeRates(for quotes: [Currency]) async throws -> [String: ExchangeRateSnapshot]
}
