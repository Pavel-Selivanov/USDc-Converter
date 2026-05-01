//
//  ExchangeRateSnapshot.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

import Foundation

struct ExchangeRateSnapshot: Equatable {
    let rate: ExchangeRate
    let fetchedAt: Date
    let isStale: Bool
}

