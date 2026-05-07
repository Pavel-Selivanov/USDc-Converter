//
//  LoadAvailableCurrenciesUseCase.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

struct LoadAvailableCurrenciesUseCase {
    private let repository: CurrencyRepositoryProtocol

    init(repository: CurrencyRepositoryProtocol) {
        self.repository = repository
    }

    func callAsFunction() async throws -> CurrencyListSnapshot {
        try await repository.availableCurrencies()
    }
}
