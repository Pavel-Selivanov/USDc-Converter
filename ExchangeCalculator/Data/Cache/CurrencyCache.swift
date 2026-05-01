//
//  CurrencyCache.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

import Foundation

nonisolated struct CachedCurrencyList: Codable, Equatable {
    let currencies: [Currency]
    let updatedAt: Date
}

struct CurrencyCache {
    private let store: JSONFileStore<CachedCurrencyList>

    init(store: JSONFileStore<CachedCurrencyList> = .init(filename: "currencies.json")) {
        self.store = store
    }

    func load() -> CachedCurrencyList? {
        try? store.load()
    }

    func save(_ currencies: [Currency], updatedAt: Date = Date()) {
        try? store.save(CachedCurrencyList(currencies: currencies, updatedAt: updatedAt))
    }
}
