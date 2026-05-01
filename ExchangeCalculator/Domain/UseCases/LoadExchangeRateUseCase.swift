//
//  LoadExchangeRateUseCase.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

struct LoadExchangeRateUseCase {
    private let repository: ExchangeRateRepository

    init(repository: ExchangeRateRepository) {
        self.repository = repository
    }

    func callAsFunction(
        for quote: Currency,
        forceRefresh: Bool = false
    ) async throws -> ExchangeRateSnapshot {
        try await repository.exchangeRate(for: quote, forceRefresh: forceRefresh)
    }
}

