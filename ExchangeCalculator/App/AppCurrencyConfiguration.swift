//
//  AppCurrencyConfiguration.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

enum AppCurrencyConfiguration {
    /// Change this line to switch the app's primary currency.
    static let primaryCurrency: Currency = .usdc

    /// Initial quote currency used when the user has not selected one yet.
    static let defaultQuoteCurrency: Currency = .brl
}
