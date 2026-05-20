//
//  HistoryViewModel.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/19/26.
//

import Foundation

@MainActor
@Observable
final class HistoryViewModel {
    typealias LoadHistoryData = () -> [HistoryRecord]
    typealias OnAllHistoryRecordsDeleted = () -> Void
    
    @ObservationIgnored private let loadHistoryData: LoadHistoryData
    @ObservationIgnored private let deleteAllHistoryRecords: OnAllHistoryRecordsDeleted
    
    private(set) var historyRecords: [HistoryRecord] = []
    
    var showTrashButton: Bool {
        historyRecords.count > 0
    }
    
    init(loadHistoryData: @escaping LoadHistoryData, deleteAllHistoryRecords: @escaping OnAllHistoryRecordsDeleted) {
        self.loadHistoryData = loadHistoryData
        self.deleteAllHistoryRecords = deleteAllHistoryRecords
        self.historyRecords = loadHistoryData()
    }
    
    func reloadHistoryData() {
        historyRecords = loadHistoryData()
    }
    
    func clearRecords() {
        historyRecords = []
        deleteAllHistoryRecords()
    }
}
