//
//  ExchangeRateRepository.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

protocol ExchangeRateRepository {
    func exchangeRate(for quote: Currency, forceRefresh: Bool) async throws -> ExchangeRateSnapshot
}

