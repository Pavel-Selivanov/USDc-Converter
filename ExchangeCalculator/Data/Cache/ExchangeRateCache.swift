//
//  ExchangeRateCache.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

import Foundation

nonisolated struct CachedExchangeRate: Codable, Equatable, Sendable {
    let base: CachedCurrency
    let quote: CachedCurrency
    let bid: Decimal
    let ask: Decimal
    let quotedAt: Date
    let fetchedAt: Date

    init(rate: ExchangeRate, fetchedAt: Date) {
        self.base = CachedCurrency(rate.base)
        self.quote = CachedCurrency(rate.quote)
        self.bid = rate.bid
        self.ask = rate.ask
        self.quotedAt = rate.quotedAt
        self.fetchedAt = fetchedAt
    }

    var rate: ExchangeRate {
        ExchangeRate(
            base: base.currency,
            quote: quote.currency,
            bid: bid,
            ask: ask,
            quotedAt: quotedAt
        )
    }
}

actor ExchangeRateCache {
    private let store: JSONFileStore<[String: CachedExchangeRate]>

    init(store: JSONFileStore<[String: CachedExchangeRate]> = .init(filename: "exchange-rates.json")) {
        self.store = store
    }
    
    func rates(base: Currency, quotes: [Currency]) -> [String: CachedExchangeRate] {
        guard let storedRates = try? store.load() else {
            return [:]
        }

        return quotes.reduce(into: [String: CachedExchangeRate]()) { result, quote in
            let key = cacheKey(base: base, quote: quote)
            if let cachedRate = storedRates[key] {
                result[quote.code.uppercased()] = cachedRate
            }
        }
    }

    func allRates(base: Currency) -> [String: CachedExchangeRate] {
        guard let storedRates = try? store.load() else {
            return [:]
        }

        return storedRates.values.reduce(into: [String: CachedExchangeRate]()) { result, cachedRate in
            let rate = cachedRate.rate
            guard rate.base == base else { return }
            result[rate.quote.code.uppercased()] = cachedRate
        }
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
