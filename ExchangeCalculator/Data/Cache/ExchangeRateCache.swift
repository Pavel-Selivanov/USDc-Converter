//
//  ExchangeRateCache.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

import Foundation

nonisolated struct CachedExchangeRate: Codable, Equatable {
    let rate: ExchangeRate
    let fetchedAt: Date
}

struct ExchangeRateCache {
    private let store: JSONFileStore<[String: CachedExchangeRate]>

    init(store: JSONFileStore<[String: CachedExchangeRate]> = .init(filename: "exchange-rates.json")) {
        self.store = store
    }

    func rate(base: Currency, quote: Currency) -> CachedExchangeRate? {
        try? store.load()?[cacheKey(base: base, quote: quote)]
    }

    func save(_ cachedRate: CachedExchangeRate) {
        var rates = (try? store.load()) ?? [:]
        rates[cacheKey(base: cachedRate.rate.base, quote: cachedRate.rate.quote)] = cachedRate
        try? store.save(rates)
    }

    private func cacheKey(base: Currency, quote: Currency) -> String {
        "\(base.code.uppercased())_\(quote.code.uppercased())"
    }
}
