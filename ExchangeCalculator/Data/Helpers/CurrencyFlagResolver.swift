//
//  CurrencyFlagResolver.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/3/26.
//

import Foundation

/// Maps ISO 4217 currency codes to Unicode country-flag emoji.
enum CurrencyFlagResolver {
    static func assetName(for currency: Currency) -> String? {
        currencyToFlagAsset[currency.code.uppercased()]
    }

    static func flag(for currency: Currency) -> String {
        let currencyCode = currency.code.uppercased()
        guard let countryCode = currencyToCountry[currencyCode] else {
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
