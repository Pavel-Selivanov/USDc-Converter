//
//  ExchangeRate.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/3/26.
//

import Foundation

/// An exchange quote returned by the backend.
nonisolated struct ExchangeRate: Codable, Equatable {
    let base: Currency
    let quote: Currency
    let bid: Decimal
    let ask: Decimal
    let quotedAt: Date

    /// Rate used when converting the base currency into the quote currency.
    var rate: Decimal {
        bid
    }

    init(
        base: Currency,
        quote: Currency,
        bid: Decimal,
        ask: Decimal,
        quotedAt: Date
    ) {
        self.base = base
        self.quote = quote
        self.bid = bid
        self.ask = ask
        self.quotedAt = quotedAt
    }

    init(
        base: Currency,
        quote: Currency,
        rate: Decimal,
        quotedAt: Date = .distantPast
    ) {
        self.init(base: base, quote: quote, bid: rate, ask: rate, quotedAt: quotedAt)
    }

    func convert(_ amount: Decimal) -> Decimal {
        amount * rate
    }

    func convertInverse(_ amount: Decimal) -> Decimal {
        guard ask != 0 else { return 0 }
        return amount / ask
    }

    /// Returns a display-only reversed quote.
    var reversed: ExchangeRate {
        guard bid != 0, ask != 0 else { return self }
        return ExchangeRate(
            base: quote,
            quote: base,
            bid: 1 / ask,
            ask: 1 / bid,
            quotedAt: quotedAt
        )
    }

    var displayString: String {
        let formatted = rate.formatted(.number.precision(.fractionLength(4)))
        return "1 \(base.code) = \(formatted) \(quote.code)"
    }
}
