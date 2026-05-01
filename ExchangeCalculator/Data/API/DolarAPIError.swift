//
//  DolarAPIError.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

import Foundation

enum DolarAPIError: Error, Equatable {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decoding(Error)
    case invalidTicker(String)
    case missingTicker(String)

    static func == (lhs: DolarAPIError, rhs: DolarAPIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.invalidResponse, .invalidResponse):
            true
        case let (.httpStatus(lhsCode), .httpStatus(rhsCode)):
            lhsCode == rhsCode
        case let (.invalidTicker(lhsBook), .invalidTicker(rhsBook)):
            lhsBook == rhsBook
        case let (.missingTicker(lhsCode), .missingTicker(rhsCode)):
            lhsCode == rhsCode
        case (.decoding, .decoding):
            true
        default:
            false
        }
    }
}

