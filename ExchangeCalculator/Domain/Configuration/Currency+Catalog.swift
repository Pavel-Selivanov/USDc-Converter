//
//  CurrencyCatalog.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/3/26.
//

import Foundation

extension Currency {
    nonisolated static let usdc = Currency(code: "USDc", name: "USD Coin")
    nonisolated static let mxn  = Currency(code: "MXN",  name: "Mexican Peso")
    nonisolated static let ars  = Currency(code: "ARS",  name: "Argentine Peso")
    nonisolated static let brl  = Currency(code: "BRL",  name: "Brazilian Real")
    nonisolated static let cop  = Currency(code: "COP",  name: "Colombian Peso")
}

nonisolated enum CurrencyCatalog {
    /// Product-supported quote currencies used when remote configuration is unavailable.
    static let fallbackQuoteCurrencies: [Currency] = [.mxn, .ars, .brl, .cop]

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
