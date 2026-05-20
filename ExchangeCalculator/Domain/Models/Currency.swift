//
//  Currency.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/3/26.
//

nonisolated struct Currency: Equatable, Hashable, Identifiable, Sendable, Codable {
    var id: String { code }

    let code: String
    let name: String
}
