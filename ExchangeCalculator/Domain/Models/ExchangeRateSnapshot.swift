//
//  ExchangeRateSnapshot.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

import Foundation

nonisolated struct ExchangeRateSnapshot: Equatable, Sendable {
    let rate: ExchangeRate
    let fetchedAt: Date
    let isStale: Bool
}
