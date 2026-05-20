//
//  AppRouterView.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

import SwiftUI

struct AppRouterView: View {

    @Binding private var router: AppRouter
    private let exchangeViewModel: ExchangeViewModel
    private let historyViewModel: HistoryViewModel

    init(router: Binding<AppRouter>, exchangeViewModel: ExchangeViewModel, historyViewModel: HistoryViewModel) {
        self._router = router
        self.exchangeViewModel = exchangeViewModel
        self.historyViewModel = historyViewModel
    }

    var body: some View {
        ExchangeView(
            viewModel: exchangeViewModel,
            routing: router
        )
        .sheet(item: $router.presentedSheet) { sheet in
            sheetContent(for: sheet)
                .adaptiveBottomSheet()
        }
    }

    @ViewBuilder
    private func sheetContent(for sheet: AppSheet) -> some View {
        switch sheet {
        case .currencyPicker:
            currencyPickerSheet
        case .history:
            historyView
        }
    }

    private var currencyPickerSheet: some View {
        BottomSheet(
            title: String(localized: "Choose currency"),
            onClose: router.dismissPresentedSheet
        ) {
            CurrencyPickerList(
                currencies: exchangeViewModel.availableCurrencies,
                selected: exchangeViewModel.targetCurrency,
                onSelect: { picked in
                    Task {
                        await exchangeViewModel.selectQuoteCurrency(picked)
                    }
                    router.dismissPresentedSheet()
                }
            )
        }
    }
    
    private var historyView: some View {
        BottomSheet(
            title: String(localized: "History"),
            onClose: router.dismissPresentedSheet
        ) {
            HistoryView(viewModel: historyViewModel)
        }
    }
}
