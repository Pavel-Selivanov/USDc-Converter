//
//  LoadAvailableCurrenciesUseCase.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

struct LoadAvailableCurrenciesUseCase {
    private let repository: CurrencyRepository

    init(repository: CurrencyRepository) {
        self.repository = repository
    }

    func callAsFunction() async -> CurrencyListSnapshot {
        await repository.availableCurrencies()
    }
}

