//
//  Debouncer.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/19/26.
//

import Foundation

final class Debouncer {
    
    private let delayInSeconds: TimeInterval
    var task: Task<Void, Never>?
    
    /// delay: time in seconds
    init(delayInSeconds: TimeInterval) {
        self.delayInSeconds = delayInSeconds
    }
    
    func submit(_ work: @escaping @MainActor @Sendable () -> Void) {
        task?.cancel()
        task = Task {
            do {
                try await Task.sleep(nanoseconds: UInt64(delayInSeconds * 1_000_000_000))
                try Task.checkCancellation()
                work()
            } catch is CancellationError {
                // Expected cancellation
            } catch {
                debugPrint("Task was cancelled.")
            }
        }
    }
    
    func cancel() {
        task?.cancel()
        task = nil
    }
}
