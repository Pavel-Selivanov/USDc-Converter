//
//  Currency.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/3/26.
//

import Foundation

nonisolated struct Currency: Codable, Equatable, Hashable, Identifiable {
    var id: String { code }

    let code: String
    let name: String
}
