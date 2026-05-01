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

enum AppSheet: Identifiable, Equatable {
    case currencyPicker

    var id: String {
        switch self {
        case .currencyPicker:
            "currencyPicker"
        }
    }
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
