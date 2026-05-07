//
//  AppRouter.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

import Observation

protocol AppRouting: AnyObject {
    func showCurrencyPicker()
}

enum AppSheet: String, Identifiable, Equatable {
    case currencyPicker

    var id: String { rawValue }
}

@Observable
final class AppRouter: AppRouting {

    var presentedSheet: AppSheet?

    func showCurrencyPicker() {
        presentedSheet = .currencyPicker
    }

    func dismissPresentedSheet() {
        presentedSheet = nil
    }
}
