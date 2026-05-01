//
//  LiveCurrencyRepository.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

import Foundation

final class LiveCurrencyRepository: CurrencyRepository {
    private let apiClient: DolarAPIClient
    private let cache: CurrencyCache

    init(
        apiClient: DolarAPIClient,
        cache: CurrencyCache = CurrencyCache()
    ) {
        self.apiClient = apiClient
        self.cache = cache
    }

    func availableCurrencies() async -> CurrencyListSnapshot {
        do {
            let codes = try await apiClient.fetchAvailableCurrencyCodes()
            let currencies = codes
                .map { CurrencyCatalog.currency(for: $0) }
                .filter { $0 != CurrencyCatalog.baseCurrency }

            guard !currencies.isEmpty else {
                return cachedOrFallback()
            }

            let updatedAt = Date()
            cache.save(currencies, updatedAt: updatedAt)

            return CurrencyListSnapshot(
                currencies: currencies,
                source: .remote,
                updatedAt: updatedAt
            )
        } catch {
            return cachedOrFallback()
        }
    }

    private func cachedOrFallback() -> CurrencyListSnapshot {
        if let cached = cache.load(), !cached.currencies.isEmpty {
            return CurrencyListSnapshot(
                currencies: cached.currencies,
                source: .cache,
                updatedAt: cached.updatedAt
            )
        }

        return CurrencyListSnapshot(
            currencies: CurrencyCatalog.fallbackCurrencies,
            source: .fallback,
            updatedAt: nil
        )
    }
}
