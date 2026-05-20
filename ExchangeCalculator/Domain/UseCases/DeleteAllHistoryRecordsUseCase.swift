//
//  DeleteAllHistoryRecordsUseCase.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/19/26.
//

import Foundation

struct DeleteAllHistoryRecordsUseCase {
    private let repository: HistoryRepositoryProtocol
    
    init(repository: HistoryRepositoryProtocol) {
        self.repository = repository
    }
    
    func callAsFunction() {
        repository.deleteAllRecords()
    }
}
