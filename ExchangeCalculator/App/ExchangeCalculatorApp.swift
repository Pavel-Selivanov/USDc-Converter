//
//  ExchangeCalculatorApp.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/1/26.
//

import SwiftUI

@main
struct ExchangeCalculatorApp: App {
    
    @State private var router: AppRouter
    @State private var exchangeViewModel: ExchangeViewModel
    @State private var historyViewModel: HistoryViewModel
    
    init() {
        self.router = AppRouter()
        let dependencies = AppDependencies()
        self.exchangeViewModel = dependencies.makeExchangeViewModel()
        self.historyViewModel = dependencies.makeHistoryViewModel()
    }
    
    var body: some Scene {
        WindowGroup {
            AppRouterView(router: $router, exchangeViewModel: exchangeViewModel, historyViewModel: historyViewModel)
                .preferredColorScheme(.light)
        }
    }
}
