//
//  TickerDTO.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

import Foundation

struct TickerDTO: Decodable, Equatable {
    let ask: String
    let bid: String
    let book: String
    let date: String

    func quoteCurrencyCode(baseCurrency: Currency) -> String? {
        let parts = book.split(separator: "_", maxSplits: 1)
        guard
            parts.count == 2,
            parts[0].caseInsensitiveCompare(baseCurrency.code) == .orderedSame
        else {
            return nil
        }
        return parts[1].uppercased()
    }

    func exchangeRate(base: Currency, quote: Currency) throws -> ExchangeRate {
        guard
            let bid = Decimal(string: bid, locale: .apiParsing),
            let ask = Decimal(string: ask, locale: .apiParsing),
            let quotedAt = DolarDateParser.parse(date)
        else {
            throw DolarAPIError.invalidTicker(book)
        }

        return ExchangeRate(
            base: base,
            quote: quote,
            bid: bid,
            ask: ask,
            quotedAt: quotedAt
        )
    }
}

private extension Locale {
    static let apiParsing = Locale(identifier: "en_US_POSIX")
}
