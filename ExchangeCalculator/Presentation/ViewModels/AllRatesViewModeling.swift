//
//  AllRatesViewModeling.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/21/26.
//

import Foundation
import Observation

protocol AllRatesViewModeling: AnyObject, Observable {
    var availableCurrencies: [Currency] { get }
    func bidAskRates(currency: Currency) -> (bid: Decimal, ask: Decimal)?
    func selectQuoteCurrency(_ currency: Currency) async
    
    func loadAllRatesIfNeeded() async
    func refreshAllRates() async
}
