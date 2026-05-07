//
//  CurrencyRepository.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

import Foundation

protocol CurrencyRemoteDataSource {
    func fetchAvailableCurrencyCodes() async throws -> [String]
}

nonisolated final class CurrencyRepository: CurrencyRepositoryProtocol {
    private let remoteDataSource: CurrencyRemoteDataSource
    private let cache: CurrencyCache
    private let baseCurrency: Currency

    init(
        remoteDataSource: CurrencyRemoteDataSource,
        cache: CurrencyCache,
        baseCurrency: Currency
    ) {
        self.remoteDataSource = remoteDataSource
        self.cache = cache
        self.baseCurrency = baseCurrency
    }

    func availableCurrencies() async throws -> CurrencyListSnapshot {
        do {
            let codes = try await remoteDataSource.fetchAvailableCurrencyCodes()
            try Task.checkCancellation()

            let currencies = codes
                .map { CurrencyCatalog.currency(for: $0) }
                .filter { $0 != baseCurrency }

            guard !currencies.isEmpty else {
                return await cachedCurrenciesOrFallback()
            }

            let updatedAt = Date()
            await cache.save(currencies, updatedAt: updatedAt)

            return CurrencyListSnapshot(
                currencies: currencies,
                source: .remote,
                updatedAt: updatedAt
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            if Task.isCancelled {
                throw CancellationError()
            }
            return await cachedCurrenciesOrFallback()
        }
    }

    private func cachedCurrenciesOrFallback() async -> CurrencyListSnapshot {
        if let cachedCurrencies = await cache.load(), !cachedCurrencies.domainCurrencies.isEmpty {
            return CurrencyListSnapshot(
                currencies: cachedCurrencies.domainCurrencies,
                source: .cache,
                updatedAt: cachedCurrencies.updatedAt
            )
        }

        return CurrencyListSnapshot(
            currencies: CurrencyCatalog.fallbackQuoteCurrencies,
            source: .fallback,
            updatedAt: nil
        )
    }
}
