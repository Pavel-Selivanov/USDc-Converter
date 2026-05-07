//
//  QuoteCurrencySelectionStoreTests.swift
//  ExchangeCalculatorTests
//
//  Created by Pavel Selivanov on 5/10/26.
//

import Foundation
import Testing
@testable import ExchangeCalculator

struct QuoteCurrencySelectionStoreTests {

    @Test func savesAndLoadsSelectedQuoteCurrency() {
        let suiteName = "QuoteCurrencySelectionStoreTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let sut = QuoteCurrencySelectionStore(userDefaults: userDefaults)

        sut.save(.ars)

        #expect(sut.loadCurrency() == .ars)
    }
}
