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
    
    init() {
        self.router = AppRouter()
        self.exchangeViewModel = AppDependencies().makeExchangeViewModel()
    }
    
    var body: some Scene {
        WindowGroup {
            AppRouterView(router: $router, exchangeViewModel: exchangeViewModel)
                .preferredColorScheme(.light)
        }
    }
}
