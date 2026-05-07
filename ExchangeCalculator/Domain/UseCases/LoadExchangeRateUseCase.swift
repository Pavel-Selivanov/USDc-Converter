//
//  LoadExchangeRateUseCase.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

struct LoadExchangeRatesUseCase {
    private let repository: ExchangeRateRepositoryProtocol

    init(repository: ExchangeRateRepositoryProtocol) {
        self.repository = repository
    }

    func callAsFunction(for quotes: [Currency]) async throws -> [String: ExchangeRateSnapshot] {
        try await repository.exchangeRates(for: quotes)
    }
}
