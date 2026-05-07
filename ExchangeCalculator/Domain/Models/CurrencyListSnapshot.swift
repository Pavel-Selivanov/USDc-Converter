//
//  CurrencyListSnapshot.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

import Foundation

nonisolated struct CurrencyListSnapshot: Equatable, Sendable {
    nonisolated enum Source: Equatable, Sendable {
        case remote
        case cache
        case fallback
    }

    let currencies: [Currency]
    let source: Source
    let updatedAt: Date?
}
