//
//  AppDependencies.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

enum AppDependencies {
    static func makeExchangeViewModel() -> ExchangeViewModel {
        let apiClient = DolarAPIClient()
        let currencyRepository = LiveCurrencyRepository(apiClient: apiClient)
        let rateRepository = LiveExchangeRateRepository(apiClient: apiClient)
        let loadCurrencies = LoadAvailableCurrenciesUseCase(repository: currencyRepository)
        let loadExchangeRate = LoadExchangeRateUseCase(repository: rateRepository)

        return ExchangeViewModel(
            loadCurrencies: { await loadCurrencies() },
            loadExchangeRate: { quote, forceRefresh in
                try await loadExchangeRate(for: quote, forceRefresh: forceRefresh)
            }
        )
    }
}
