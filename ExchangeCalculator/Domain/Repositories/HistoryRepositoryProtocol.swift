//
//  HistoryRepositoryProtocol.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/19/26.
//

protocol HistoryRepositoryProtocol {
    func cachedHistory() -> [HistoryRecord]
    func create(record: HistoryRecord)
    func delete(record: HistoryRecord)
    func deleteAllRecords()
}
