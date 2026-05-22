//
//  AppRouterView.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

import SwiftUI

enum Tab: Int {
    case exchange
    case allRates
}

struct AppRouterView: View {
    
    @Binding private var router: AppRouter
    private let exchangeViewModel: ExchangeViewModel

    init(router: Binding<AppRouter>, exchangeViewModel: ExchangeViewModel) {
        self._router = router
        self.exchangeViewModel = exchangeViewModel
    }

    var body: some View {
        TabView(selection: $router.selectedTab) {
            ExchangeView(
                viewModel: exchangeViewModel,
                routing: router
            )
            .tabItem {
                Label("Calculator", systemImage: "dollarsign.circle")
                    .foregroundStyle(Color.primary)
            }
            .tag(Tab.exchange)
            
            AllRatesView(
                viewModel: exchangeViewModel,
                routing: router
            )
            .tabItem {
                Label("All Rates", systemImage: "dollarsign.arrow.trianglehead.counterclockwise.rotate.90")
                    .foregroundStyle(Color.primary)
            }
            .tag(Tab.allRates)
        }
        .tint(Color.contentBrand)
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
}
