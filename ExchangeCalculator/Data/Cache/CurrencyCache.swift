//
//  CurrencyCache.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

import Foundation

/// nonisolated - to opts out of this target's default actor isolation
nonisolated struct CachedCurrency: Codable, Equatable, Sendable {
    let code: String
    let name: String

    init(_ currency: Currency) {
        self.code = currency.code
        self.name = currency.name
    }

    var currency: Currency {
        Currency(code: code, name: name)
    }
}

nonisolated struct CachedCurrencyList: Codable, Equatable, Sendable {
    let currencies: [CachedCurrency]
    let updatedAt: Date

    init(currencies: [Currency], updatedAt: Date) {
        self.currencies = currencies.map(CachedCurrency.init)
        self.updatedAt = updatedAt
    }

    var domainCurrencies: [Currency] {
        currencies.map(\.currency)
    }
}

actor CurrencyCache {
    private let store: JSONFileStore<CachedCurrencyList>

    init(store: JSONFileStore<CachedCurrencyList> = .init(filename: "currencies.json")) {
        self.store = store
    }

    func load() -> CachedCurrencyList? {
        try? store.load()
    }

    func save(_ currencies: [Currency], updatedAt: Date) async {
        try? store.save(CachedCurrencyList(currencies: currencies, updatedAt: updatedAt))
    }
}
