//
//  AppRouterTests.swift
//  ExchangeCalculatorTests
//
//  Created by Pavel Selivanov on 5/7/26.
//

import Nimble
import Testing
@testable import ExchangeCalculator

@Suite("AppRouter")
@MainActor
struct AppRouterTests {

    @Test("showCurrencyPicker presents the currency picker sheet")
    func showCurrencyPickerPresentsSheet() {
        let sut = AppRouter()

        sut.showCurrencyPicker()

        expect(sut.presentedSheet).to(equal(.currencyPicker))
    }

    @Test("dismissPresentedSheet clears the current sheet")
    func dismissPresentedSheetClearsSheet() {
        let sut = AppRouter()
        sut.showCurrencyPicker()

        sut.dismissPresentedSheet()

        expect(sut.presentedSheet).to(beNil())
    }
}
