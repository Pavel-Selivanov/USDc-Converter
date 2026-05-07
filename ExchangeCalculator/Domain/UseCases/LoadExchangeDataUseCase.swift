//
//  LoadExchangeDataUseCase.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/9/26.
//

/// Outcome of a single load attempt for the exchange screen's data bundle.
///
/// The currency list and exchange rates have different reliability contracts:
/// the catalog has a hard-coded fallback (`CurrencyCatalog.fallbackQuoteCurrencies`)
/// and effectively never fails, while rates depend on a live remote source. We
/// therefore model partial success explicitly so the UI can keep the currency
/// picker usable even when rates are temporarily unavailable.
nonisolated enum ExchangeDataLoadOutcome: Sendable {
    case complete(ExchangeDataSnapshot)
    case ratesUnavailable(CurrencyListSnapshot, underlying: Error)
}

struct LoadExchangeDataUseCase {
    private let loadCurrencies: LoadAvailableCurrenciesUseCase
    private let loadExchangeRates: LoadExchangeRatesUseCase

    init(
        loadCurrencies: LoadAvailableCurrenciesUseCase,
        loadExchangeRates: LoadExchangeRatesUseCase
    ) {
        self.loadCurrencies = loadCurrencies
        self.loadExchangeRates = loadExchangeRates
    }

    /// Loads the currency catalog and the rates that pair with it.
    ///
    /// Throws only for cancellation or when the currency catalog itself cannot
    /// be produced. A rate-loading failure is surfaced as
    /// `.ratesUnavailable`, allowing the caller to keep the catalog visible.
    func callAsFunction() async throws -> ExchangeDataLoadOutcome {
        try Task.checkCancellation()
        let currencyList = try await loadCurrencies()

        try Task.checkCancellation()
        do {
            let rates = try await loadExchangeRates(for: currencyList.currencies)
            try Task.checkCancellation()
            return .complete(
                ExchangeDataSnapshot(
                    currencyList: currencyList,
                    exchangeRatesByQuoteCode: rates
                )
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            if Task.isCancelled {
                throw CancellationError()
            }
            return .ratesUnavailable(currencyList, underlying: error)
        }
    }
}
