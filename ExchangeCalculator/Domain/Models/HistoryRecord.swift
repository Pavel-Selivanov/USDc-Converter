//
//  HistoryRecord.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/19/26.
//

import Foundation

struct HistoryRecord: Codable, Equatable, Identifiable {
    let id: UUID
    let sourceCurrency: Currency
    let sourceValue: String
    let targetCurrency: Currency
    let targetValue: String
}
