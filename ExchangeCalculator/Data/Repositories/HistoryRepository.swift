//
//  HistoryRepository.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/19/26.
//

import Foundation

final class HistoryRepository: HistoryRepositoryProtocol {
    
    private enum Constants {
        static let suiteName: String = "arq"
        static let key: String = "history"
    }
    
    func cachedHistory() -> [HistoryRecord] {
        guard let data = UserDefaults(suiteName: Constants.suiteName)?.data(forKey: Constants.key) else {
            return []
        }
        
        let array = try? JSONDecoder().decode([HistoryRecord].self, from: data)
        return array ?? []
    }
    
    private func save(_ records: [HistoryRecord]) {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults(suiteName: Constants.suiteName)?.set(data, forKey: Constants.key)
    }
    
    func create(record: HistoryRecord) {
        var cachedHistory = cachedHistory()
        cachedHistory.insert(record, at: 0)
        save(cachedHistory)
    }
    
    func delete(record: HistoryRecord) {
        var cachedHistory = cachedHistory()
        guard let indexToRemoveAt = cachedHistory.firstIndex(where: { $0.id == record.id }) else {
            return
        }
        cachedHistory.remove(at: indexToRemoveAt)
        save(cachedHistory)
    }
    
    func deleteAllRecords() {
        UserDefaults(suiteName: Constants.suiteName)?.removeObject(forKey: Constants.key)
    }
}
