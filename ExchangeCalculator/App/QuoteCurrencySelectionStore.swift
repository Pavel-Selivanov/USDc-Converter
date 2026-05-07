//
//  QuoteCurrencySelectionStore.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/10/26.
//

import Foundation

struct QuoteCurrencySelectionStore {
    private let userDefaults: UserDefaults
    private let selectedQuoteCurrencyCodeKey = "selected-quote-currency-code"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadCurrency() -> Currency? {
        guard let code = userDefaults.string(forKey: selectedQuoteCurrencyCodeKey) else {
            return nil
        }

        return CurrencyCatalog.currency(for: code)
    }

    func save(_ currency: Currency) {
        userDefaults.set(currency.code.uppercased(), forKey: selectedQuoteCurrencyCodeKey)
    }
}
