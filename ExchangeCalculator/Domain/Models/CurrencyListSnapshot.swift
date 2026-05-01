//
//  CurrencyListSnapshot.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

import Foundation

struct CurrencyListSnapshot: Equatable {
    enum Source: Equatable {
        case remote
        case cache
        case fallback
    }

    let currencies: [Currency]
    let source: Source
    let updatedAt: Date?
}

