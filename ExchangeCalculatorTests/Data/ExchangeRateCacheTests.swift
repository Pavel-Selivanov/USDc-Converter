//
//  ExchangeRateCacheTests.swift
//  ExchangeCalculatorTests
//
//  Created by Pavel Selivanov on 5/10/26.
//

import Foundation
import Testing
@testable import ExchangeCalculator

@Suite("ExchangeRateCache")
struct ExchangeRateCacheTests {

    @Test("Concurrent saves preserve all cached rates")
    func concurrentSavesPreserveAllRates() async {
        let cache = makeCache()
        let quotedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let fetchedAt = Date(timeIntervalSince1970: 1_800_000_100)
        let cachedRates = [
            cachedRate(quote: .mxn, rate: 18.4, quotedAt: quotedAt, fetchedAt: fetchedAt),
            cachedRate(quote: .ars, rate: 1_000, quotedAt: quotedAt, fetchedAt: fetchedAt),
            cachedRate(quote: .brl, rate: 5.2, quotedAt: quotedAt, fetchedAt: fetchedAt),
            cachedRate(quote: .cop, rate: 4_000, quotedAt: quotedAt, fetchedAt: fetchedAt),
        ]

        await withTaskGroup(of: Void.self) { group in
            for cachedRate in cachedRates {
                group.addTask {
                    await cache.save(cachedRate)
                }
            }
        }

        let storedRates = await cache.rates(
            base: .usdc,
            quotes: cachedRates.map { $0.rate.quote }
        )

        #expect(storedRates.count == cachedRates.count)
        for cachedRate in cachedRates {
            #expect(storedRates[cachedRate.rate.quote.code]?.rate == cachedRate.rate)
        }
    }

    private func makeCache() -> ExchangeRateCache {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = JSONFileStore<[String: CachedExchangeRate]>(
            filename: "exchange-rates.json",
            directory: directory
        )
        return ExchangeRateCache(store: store)
    }

    private func cachedRate(
        quote: Currency,
        rate: Decimal,
        quotedAt: Date,
        fetchedAt: Date
    ) -> CachedExchangeRate {
        CachedExchangeRate(
            rate: ExchangeRate(
                base: .usdc,
                quote: quote,
                rate: rate,
                quotedAt: quotedAt
            ),
            fetchedAt: fetchedAt
        )
    }
}
