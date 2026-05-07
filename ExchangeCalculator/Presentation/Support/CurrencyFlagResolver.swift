//
//  CurrencyFlagResolver.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/3/26.
//

import Foundation

enum CurrencyFlagResolver {
    static func assetName(for currency: Currency) -> String? {
        currencyToFlagAsset[currency.code.uppercased()]
    }

    static func flag(for currency: Currency) -> String {
        let currencyCode = currency.code.uppercased()
        guard let countryCode = currencyToCountryCode[currencyCode] else {
            return "🏳️"
        }
        return countryCode.countryFlagEmoji
    }
}

private let currencyToFlagAsset: [String: String] = [
    "ARS": "Flags/ARG",
    "BRL": "Flags/BRA",
    "COP": "Flags/COL",
    "EUR": "Flags/EU",
    "MXN": "Flags/MEX",
    "USDC": "Flags/USA",
]

private let currencyToCountryCode: [String: String] = [
    "MXN": "MX",
    "ARS": "AR",
    "BRL": "BR",
    "COP": "CO",
    "USD": "US",
    "USDC": "US",
    "EUR": "EU",
]

private extension String {
    /// Converts a 2-letter ISO 3166-1 alpha-2 country code into its flag emoji.
    /// Each letter is shifted to the Unicode Regional Indicator block (U+1F1E6–U+1F1FF).
    var countryFlagEmoji: String {
        unicodeScalars
            .compactMap { Unicode.Scalar(127397 + $0.value) }
            .map(Character.init)
            .map(String.init)
            .joined()
    }
}
