//
//  SaveHistoryRecordUseCase.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/19/26.
//

import Foundation

struct SaveHistoryRecordUseCase {
    private let repository: HistoryRepositoryProtocol
    
    init(repository: HistoryRepositoryProtocol) {
        self.repository = repository
    }
    
    func callAsFunction(_ record: HistoryRecord) {
        repository.create(record: record)
    }
}
