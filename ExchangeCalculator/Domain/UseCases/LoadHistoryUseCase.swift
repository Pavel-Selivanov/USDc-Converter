//
//  LoadHistoryUseCase.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/19/26.
//

import Foundation

struct LoadHistoryUseCase {
    private let repository: HistoryRepositoryProtocol
    
    init(repository: HistoryRepositoryProtocol) {
        self.repository = repository
    }
    
    func callAsFunction() -> [HistoryRecord] {
        repository.cachedHistory()
    }
}
