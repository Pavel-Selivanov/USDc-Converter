//
//  AdHocData.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/3/26.
//

import Foundation

extension Currency {
    static let usdc = Currency(code: "USDc", name: "USD Coin")
    static let mxn  = Currency(code: "MXN",  name: "Mexican Peso")
    static let ars  = Currency(code: "ARS",  name: "Argentine Peso")
    static let brl  = Currency(code: "BRL",  name: "Brazilian Real")
    static let cop  = Currency(code: "COP",  name: "Colombian Peso")

    /// Fallback static list used when the currencies API is unavailable.
    static let supported: [Currency] = [.mxn, .ars, .brl, .cop]
}

enum CurrencyCatalog {
    static let baseCurrency = AppCurrencyConfiguration.primaryCurrency
    static let fallbackCurrencies: [Currency] = Currency.supported

    static func currency(for code: String) -> Currency {
        let normalizedCode = code.uppercased()
        return knownCurrencies[normalizedCode] ?? Currency(
            code: normalizedCode,
            name: localizedName(for: normalizedCode)
        )
    }

    private static let knownCurrencies: [String: Currency] = [
        "MXN": .mxn,
        "ARS": .ars,
        "BRL": .brl,
        "COP": .cop,
        "USDC": .usdc,
        "USDc": .usdc,
    ]

    private static func localizedName(for code: String) -> String {
        Locale.current.localizedString(forCurrencyCode: code) ?? code
    }
}

// MARK: - Lookup table

let currencyToCountry: [String: String] = [
    "MXN":  "MX",
    "ARS":  "AR",
    "BRL":  "BR",
    "COP":  "CO",
    "USD":  "US",
    "USDC": "US",
    "EUR":  "EU",   // Not a real ISO country code, but produces 🇪🇺
    "GBP":  "GB",
    "JPY":  "JP",
    "CAD":  "CA",
    "AUD":  "AU",
    "CLP":  "CL",
    "PEN":  "PE",
]

/// Fallback currency data used when the `GET /v1/tickers-currencies` API is
/// unavailable. Exchange rates are intentionally not hardcoded.
enum FallbackCurrencyDataSource {

    static let baseCurrency = CurrencyCatalog.baseCurrency

    /// The quote currencies supported at launch.
    static let supportedCurrencies: [Currency] = CurrencyCatalog.fallbackCurrencies
}

#if DEBUG
import Foundation

extension Currency {
    static let preview_usdc = Currency(code: "USDc", name: "USD Coin")
    static let preview_mxn  = Currency(code: "MXN",  name: "Mexican Peso")
    static let preview_ars  = Currency(code: "ARS",  name: "Argentine Peso")
    static let preview_brl  = Currency(code: "BRL",  name: "Brazilian Real")
    static let preview_cop  = Currency(code: "COP",  name: "Colombian Peso")
}

extension ExchangeRate {
    static let preview_usdcMxn = ExchangeRate(
        base: .preview_usdc,
        quote: .preview_mxn,
        rate: 18.4097
    )
}
#endif
