//
//  LiveExchangeRateRepository.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

import Foundation

final class LiveExchangeRateRepository: ExchangeRateRepository {
    private let apiClient: DolarAPIClient
    private let cache: ExchangeRateCache
    private let baseCurrency: Currency
    private let freshnessInterval: TimeInterval
    private let now: () -> Date

    init(
        apiClient: DolarAPIClient,
        cache: ExchangeRateCache = ExchangeRateCache(),
        baseCurrency: Currency = CurrencyCatalog.baseCurrency,
        freshnessInterval: TimeInterval = 60,
        now: @escaping () -> Date = Date.init
    ) {
        self.apiClient = apiClient
        self.cache = cache
        self.baseCurrency = baseCurrency
        self.freshnessInterval = freshnessInterval
        self.now = now
    }

    func exchangeRate(
        for quote: Currency,
        forceRefresh: Bool
    ) async throws -> ExchangeRateSnapshot {
        let cached = cache.rate(base: baseCurrency, quote: quote)

        if !forceRefresh, let cached, isFresh(cached) {
            return snapshot(from: cached, isStale: false)
        }

        do {
            let tickers = try await apiClient.fetchTickers(currencies: [quote.code])
            let matchingTicker = tickers.first {
                $0.quoteCurrencyCode(baseCurrency: baseCurrency) == quote.code.uppercased()
            }

            guard let matchingTicker else {
                throw DolarAPIError.missingTicker(quote.code)
            }

            let cachedRate = CachedExchangeRate(
                rate: try matchingTicker.exchangeRate(
                    base: baseCurrency,
                    quote: quote
                ),
                fetchedAt: now()
            )
            cache.save(cachedRate)

            return snapshot(from: cachedRate, isStale: false)
        } catch {
            if let cached {
                return snapshot(from: cached, isStale: true)
            }
            throw error
        }
    }

    private func isFresh(_ cachedRate: CachedExchangeRate) -> Bool {
        now().timeIntervalSince(cachedRate.fetchedAt) < freshnessInterval
    }

    private func snapshot(
        from cachedRate: CachedExchangeRate,
        isStale: Bool
    ) -> ExchangeRateSnapshot {
        ExchangeRateSnapshot(
            rate: cachedRate.rate,
            fetchedAt: cachedRate.fetchedAt,
            isStale: isStale
        )
    }
}
