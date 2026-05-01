//
//  CurrencyRepository.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

protocol CurrencyRepository {
    func availableCurrencies() async -> CurrencyListSnapshot
}

