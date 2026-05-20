//
//  AppDependencies.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

final class AppDependencies {
    
    private let baseCurrency = AppCurrencyConfiguration.primaryCurrency
    private let defaultQuoteCurrency = AppCurrencyConfiguration.defaultQuoteCurrency
    private let apiClient = DolarAPIClient()
    private let quoteCurrencySelectionStore = QuoteCurrencySelectionStore()
    
    private let currencyCache = CurrencyCache()
    private let exchangeRateCache = ExchangeRateCache()

    private lazy var currencyRepository: CurrencyRepositoryProtocol = CurrencyRepository(
        remoteDataSource: apiClient,
        cache: currencyCache,
        baseCurrency: baseCurrency
    )

    private lazy var rateRepository = ExchangeRateRepository(
        remoteDataSource: apiClient,
        cache: exchangeRateCache,
        baseCurrency: baseCurrency
    )
    
    private lazy var historyRepository = HistoryRepository()

    private lazy var loadCurrencies = LoadAvailableCurrenciesUseCase(repository: currencyRepository)

    private lazy var loadExchangeRates = LoadExchangeRatesUseCase(repository: rateRepository)

    private lazy var loadExchangeData = LoadExchangeDataUseCase(
        loadCurrencies: loadCurrencies,
        loadExchangeRates: loadExchangeRates
    )
    
    private lazy var loadCachedHistory = LoadHistoryUseCase(repository: historyRepository)
    private lazy var saveHistoryRecord = SaveHistoryRecordUseCase(repository: historyRepository)
    private lazy var deleteAllHistoryRecords = DeleteAllHistoryRecordsUseCase(repository: historyRepository)

    func makeExchangeViewModel() -> ExchangeViewModel {
        ExchangeViewModel(
            sourceCurrency: baseCurrency,
            targetCurrency: initialQuoteCurrency(),
            availableCurrencies: [],
            loadCachedData: { await self.cachedExchangeData() },
            loadData: { try await self.loadExchangeData() },
            onQuoteCurrencySelected: { [quoteCurrencySelectionStore] currency in
                quoteCurrencySelectionStore.save(currency)
            },
            onSaveHistoryRecord: { record in self.saveHistoryRecord(record) },
            networkStatusUpdates: {
                InternetConnectionManager.shared.connectionStatusUpdates
            }
        )
    }
    
    func makeHistoryViewModel() -> HistoryViewModel {
        HistoryViewModel(
            loadHistoryData: { self.loadCachedHistory() },
            deleteAllHistoryRecords: { self.deleteAllHistoryRecords() }
        )
    }

    private func initialQuoteCurrency() -> Currency {
        quoteCurrencySelectionStore.loadCurrency() ?? defaultQuoteCurrency
    }

    private func cachedExchangeData() async -> ExchangeDataSnapshot? {
        let cachedCurrencies = await currencyCache.load()
        let cachedCurrencyList = cachedCurrencies?.domainCurrencies ?? []
        let cachedRates = cachedCurrencyList.isEmpty
            ? await exchangeRateCache.allRates(base: baseCurrency)
            : await exchangeRateCache.rates(base: baseCurrency, quotes: cachedCurrencyList)

        guard !cachedRates.isEmpty else {
            return nil
        }

        let rates = cachedRates.mapValues { cachedRate in
            ExchangeRateSnapshot(
                rate: cachedRate.rate,
                fetchedAt: cachedRate.fetchedAt,
                isStale: true
            )
        }
        let currencies = cachedCurrencyList.isEmpty
            ? cachedRates.values.map { $0.rate.quote }.sorted { $0.code < $1.code }
            : cachedCurrencyList

        return ExchangeDataSnapshot(
            currencyList: CurrencyListSnapshot(
                currencies: currencies,
                source: .cache,
                updatedAt: cachedCurrencies?.updatedAt
            ),
            exchangeRatesByQuoteCode: rates
        )
    }
}
