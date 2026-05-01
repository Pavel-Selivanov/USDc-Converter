//
//  AppRouterView.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

import SwiftUI

struct AppRouterView: View {

    @State private var router: AppRouter
    @State private var exchangeViewModel: ExchangeViewModel

    init(
        router: AppRouter = AppRouter(),
        exchangeViewModel: ExchangeViewModel = AppDependencies.makeExchangeViewModel()
    ) {
        self._router = State(initialValue: router)
        self._exchangeViewModel = State(initialValue: exchangeViewModel)
    }

    var body: some View {
        @Bindable var bindableRouter = router

        ExchangeView(
            viewModel: exchangeViewModel,
            routing: router
        )
        .sheet(item: $bindableRouter.presentedSheet) { sheet in
            sheetContent(for: sheet)
                .adaptiveBottomSheet()
        }
    }

    @ViewBuilder
    private func sheetContent(for sheet: AppSheet) -> some View {
        switch sheet {
        case .currencyPicker:
            currencyPickerSheet
        }
    }

    private var currencyPickerSheet: some View {
        BottomSheet(
            title: "Choose currency",
            onClose: router.dismissPresentedSheet
        ) {
            CurrencyPickerList(
                currencies: exchangeViewModel.pickableCurrencies,
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
}
