//
//  ExchangeRateRepository.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

import Foundation

protocol ExchangeRateRemoteDataSource {
    func fetchTickers(currencies: [String]) async throws -> [TickerDTO]
}

nonisolated final class ExchangeRateRepository: ExchangeRateRepositoryProtocol {
    private let remoteDataSource: ExchangeRateRemoteDataSource
    private let cache: ExchangeRateCache
    private let baseCurrency: Currency
    private let now: () -> Date

    init(
        remoteDataSource: ExchangeRateRemoteDataSource,
        cache: ExchangeRateCache = ExchangeRateCache(),
        baseCurrency: Currency = .usdc,
        now: @escaping () -> Date = Date.init
    ) {
        self.remoteDataSource = remoteDataSource
        self.cache = cache
        self.baseCurrency = baseCurrency
        self.now = now
    }

    func exchangeRates(for quotes: [Currency]) async throws -> [String: ExchangeRateSnapshot] {
        let cachedSnapshots = await cache
            .rates(base: baseCurrency, quotes: quotes)
            .mapValues { snapshot(from: $0, isStale: true) }

        do {
            let tickers = try await remoteDataSource.fetchTickers(currencies: quotes.map(\.code))
            try Task.checkCancellation()

            var snapshots = cachedSnapshots /// to do production ready offline-friendly merge

            for quote in quotes {
                guard let matchingTicker = tickers.first(where: {
                    $0.quoteCurrencyCode(baseCurrency: baseCurrency) == quote.code.uppercased()
                }) else {
                    continue
                }

                do {
                    try Task.checkCancellation()
                    let cachedRate = CachedExchangeRate(
                        rate: try matchingTicker.exchangeRate(
                            base: baseCurrency,
                            quote: quote
                        ),
                        fetchedAt: now()
                    )
                    await cache.save(cachedRate)

                    snapshots[quote.code.uppercased()] = snapshot(
                        from: cachedRate,
                        isStale: false
                    )
                } catch {
                    continue
                }
            }

            guard !snapshots.isEmpty else {
                throw DolarAPIError.missingTicker("all")
            }

            return snapshots
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            if Task.isCancelled {
                throw CancellationError()
            }

            if !cachedSnapshots.isEmpty {
                return cachedSnapshots
            }

            throw error
        }
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
