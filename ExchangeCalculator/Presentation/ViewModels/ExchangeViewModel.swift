//
//  ExchangeViewModel.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/4/26.
//

import Observation
import Foundation

@MainActor
@Observable
final class ExchangeViewModel {
    typealias LoadCachedExchangeData = () async -> ExchangeDataSnapshot?
    typealias LoadExchangeData = () async throws -> ExchangeDataLoadOutcome
    typealias OnQuoteCurrencySelected = (Currency) -> Void
    typealias NetworkStatusUpdates = () -> AsyncStream<Bool>

    // MARK: - State

    private(set) var sourceCurrency: Currency
    private(set) var targetCurrency: Currency
    private(set) var availableCurrencies: [Currency]

    var sourceText: String = ""
    var targetText: String = ""

    private(set) var exchangeRate: ExchangeRate?
    private(set) var isLoadingRate: Bool = false
    private(set) var rateStatusText: String?
    private(set) var rateStatusIconName: String?
    private(set) var rateStatusTone: RateStatusTone = .hidden
    private(set) var rateErrorText: String?
    private(set) var showsManualRefresh: Bool = false

    /// Toggles each time `swapCurrencies()` is called. Drives the visual field
    /// order while keeping the source and target views stable in the hierarchy.
    private(set) var isSwapped: Bool = false

    // MARK: - Input limits

    /// Maximum source-currency equivalent a user may type.
    nonisolated static let maxInputValue: Decimal = AmountInputFormatter.maxInputValue

    /// Maximum number of digits allowed after the decimal point.
    nonisolated static let maxFractionDigits: Int = AmountInputFormatter.maxFractionDigits

    @ObservationIgnored private var lastValidSourceText: String = ""
    @ObservationIgnored private var lastValidTargetText: String = ""
    @ObservationIgnored private var lastEditedField: FieldFocus?
    @ObservationIgnored private var dataRequestID: Int = 0
    @ObservationIgnored private var dataLoadTask: Task<Result<ExchangeDataLoadOutcome, Error>, Never>?
    @ObservationIgnored private var networkStatusTask: Task<Void, Never>?
    @ObservationIgnored private var exchangeRatesByQuoteCode: [String: ExchangeRateSnapshot] = [:]
    @ObservationIgnored private let loadCachedExchangeData: LoadCachedExchangeData
    @ObservationIgnored private let loadExchangeData: LoadExchangeData
    @ObservationIgnored private let onQuoteCurrencySelected: OnQuoteCurrencySelected
    @ObservationIgnored private let networkStatusUpdates: NetworkStatusUpdates

    // MARK: - Derived

    /// unswapped shows the bid side, swapped shows the ask side.
    var displayRate: String? {
        guard let rate = exchangeRate else { return nil }
        return ExchangeRateStatusPresenter.rateDisplayText(for: rate, usingAsk: isSwapped)
    }

    var canEditAmounts: Bool {
        !availableCurrencies.isEmpty && exchangeRate != nil
    }

    init(
        sourceCurrency: Currency,
        targetCurrency: Currency,
        availableCurrencies: [Currency],
        initialExchangeData: ExchangeDataSnapshot? = nil,
        exchangeRate: ExchangeRate? = nil,
        loadCachedData: @escaping LoadCachedExchangeData = { nil },
        loadData: @escaping LoadExchangeData = {
            throw ExchangeViewModelError.dataUnavailable
        },
        onQuoteCurrencySelected: @escaping OnQuoteCurrencySelected = { _ in },
        networkStatusUpdates: @escaping NetworkStatusUpdates = {
            AsyncStream { continuation in
                continuation.finish()
            }
        }
    ) {
        self.sourceCurrency = sourceCurrency
        self.targetCurrency = targetCurrency
        self.availableCurrencies = availableCurrencies
        self.exchangeRate = exchangeRate
        self.loadCachedExchangeData = loadCachedData
        self.loadExchangeData = loadData
        self.onQuoteCurrencySelected = onQuoteCurrencySelected
        self.networkStatusUpdates = networkStatusUpdates

        if let initialExchangeData {
            self.availableCurrencies = initialExchangeData.currencyList.currencies
            self.exchangeRatesByQuoteCode = initialExchangeData.exchangeRatesByQuoteCode

            if !availableCurrencies.contains(targetCurrency),
               let firstCurrency = availableCurrencies.first {
                self.targetCurrency = firstCurrency
            }

            if initialExchangeData.exchangeRatesByQuoteCode[self.targetCurrency.code.uppercased()] == nil,
               let firstRatedCurrency = availableCurrencies.first(where: {
                   initialExchangeData.exchangeRatesByQuoteCode[$0.code.uppercased()] != nil
               }) {
                self.targetCurrency = firstRatedCurrency
            }

            let key = self.targetCurrency.code.uppercased()
            if let snapshot = initialExchangeData.exchangeRatesByQuoteCode[key] {
                self.exchangeRate = snapshot.rate
            }
        } else if let exchangeRate {
            seedInitialRate(exchangeRate)
        }

        observeNetworkStatus()
    }

    deinit {
        networkStatusTask?.cancel()
    }

    // MARK: - User actions

    func loadInitialData() async {
        if exchangeRatesByQuoteCode.isEmpty,
           let cachedSnapshot = await loadCachedExchangeData() {
            applyDataSnapshot(cachedSnapshot, showsStaleRateStatus: false)
        }

        await refreshData()
    }

    func refreshData() async {
        dataLoadTask?.cancel()
        dataRequestID += 1

        let requestID = dataRequestID
        let task = Task<Result<ExchangeDataLoadOutcome, Error>, Never> { [loadExchangeData] in
            do {
                return .success(try await loadExchangeData())
            } catch {
                return .failure(error)
            }
        }
        dataLoadTask = task
        isLoadingRate = true
        rateErrorText = nil
        showsManualRefresh = false

        let result = await task.value
        guard requestID == dataRequestID else {
            return
        }

        dataLoadTask = nil
        isLoadingRate = false

        switch result {
        case .success(.complete(let snapshot)):
            applyDataSnapshot(snapshot, showsStaleRateStatus: true)
        case .success(.ratesUnavailable(let currencyList, let underlying)):
            applyCurrencyListOnly(currencyList)
            handleRefreshFailure(underlying)
        case .failure(let error) where error is CancellationError:
            break
        case .failure(let error):
            handleRefreshFailure(error)
        }
    }

    /// Called when the user edits the source field.
    func onSourceChanged(_ newValue: String) {
        guard canEditAmounts else {
            sourceText = lastValidSourceText
            return
        }

        lastEditedField = .source
        let raw = AmountInputFormatter.canonicalAmountInput(
            newValue,
            previousFormattedInput: lastValidSourceText
        )

        guard AmountInputFormatter.isWithinLimits(raw) else {
            sourceText = lastValidSourceText
            return
        }

        let formatted = AmountInputFormatter.withGroupingSeparator(raw)
        sourceText = formatted
        lastValidSourceText = formatted

        guard
            !raw.isEmpty,
            let amount = AmountInputFormatter.decimal(from: raw),
            let rate = exchangeRate
        else {
            if raw.isEmpty { targetText = "" }
            return
        }
        
        let convertedAmount = isSwapped
            ? rate.convertUsingAsk(amount)
            : rate.convert(amount)
        setCalculatedTargetText(convertedAmount)
    }

    /// Called when the user edits the target field.
    func onTargetChanged(_ newValue: String) {
        guard canEditAmounts else {
            targetText = lastValidTargetText
            return
        }

        lastEditedField = .target
        let raw = AmountInputFormatter.canonicalAmountInput(
            newValue,
            previousFormattedInput: lastValidTargetText
        )

        guard AmountInputFormatter.isWithinLimits(raw, maxValue: maxTargetInputValue) else {
            targetText = lastValidTargetText
            return
        }

        let formatted = AmountInputFormatter.withGroupingSeparator(raw)
        targetText = formatted
        lastValidTargetText = formatted

        guard
            !raw.isEmpty,
            let amount = AmountInputFormatter.decimal(from: raw),
            let rate = exchangeRate
        else {
            if raw.isEmpty { sourceText = "" }
            return
        }
        setCalculatedSourceText(rate.convertInverse(amount))
    }

    /// Replaces the quote currency and recomputes the visible amount so the
    /// displayed pair stays consistent.
    ///
    /// The base (`sourceCurrency`) is fixed by product configuration, and
    /// `swapCurrencies()` only reorders slots and changes the active spread
    /// side — so the quote is always `targetCurrency`, regardless of
    /// `isSwapped`.
    func selectQuoteCurrency(_ currency: Currency) async {
        guard currency != targetCurrency else { return }

        targetCurrency = currency
        onQuoteCurrencySelected(currency)
        rateErrorText = nil
        applySelectedRate()
    }

    /// Swaps the two fields by toggling visual order and recomputing the paired
    /// amount against the active side of the spread.
    ///
    /// The source/target data stays where it is; only `isSwapped` flips, which
    /// lets the view animate the fields into the opposite visual positions.
    ///
    /// This keeps the currency source-of-truth stable and avoids swapping
    /// multiple paired pieces of state.
    func swapCurrencies(recomputesAmounts: Bool = true) {
        isSwapped.toggle()
        guard recomputesAmounts else { return }
        recomputeAfterRateChange()
    }

    func recomputeAmountsForCurrentState() {
        recomputeAfterRateChange()
    }
}

enum ExchangeViewModelError: Error {
    case dataUnavailable
}

// MARK: - Recalculation

private extension ExchangeViewModel {
    var maxTargetInputValue: Decimal {
        guard let exchangeRate, exchangeRate.ask > 0 else {
            return Self.maxInputValue
        }

        return exchangeRate.convertUsingAsk(Self.maxInputValue)
    }

    func observeNetworkStatus() {
        networkStatusTask?.cancel()
        networkStatusTask = Task { @MainActor [weak self, networkStatusUpdates] in
            for await isConnected in networkStatusUpdates() {
                guard !Task.isCancelled else { return }
                self?.handleNetworkStatusChange(isConnected)
            }
        }
    }

    func handleNetworkStatusChange(_ isConnected: Bool) {
        if isConnected {
            if rateStatusIconName == ExchangeRateStatusPresenter.offlineIconName {
                applyRateStatus(.hidden)
            }
            return
        }

        guard !exchangeRatesByQuoteCode.isEmpty else { return }
        applySelectedRate(forcesOfflineStatus: true)
    }

    func seedInitialRate(_ rate: ExchangeRate) {
        let snapshot = ExchangeRateSnapshot(
            rate: rate,
            fetchedAt: rate.quotedAt,
            isStale: false
        )
        exchangeRate = rate
        exchangeRatesByQuoteCode = [
            rate.quote.code.uppercased(): snapshot
        ]
        applyRateStatus(.hidden)
    }

    /// Applies a currency list without touching rates.
    ///
    /// Used when a refresh produced a usable catalog but failed to fetch rates.
    /// Keeping the catalog visible lets the user open the currency picker even
    /// while the app is offline on a cold start.
    func applyCurrencyListOnly(_ list: CurrencyListSnapshot) {
        availableCurrencies = list.currencies

        if !availableCurrencies.contains(targetCurrency),
           let firstCurrency = availableCurrencies.first {
            targetCurrency = firstCurrency
            clearCalculatedText()
        }
    }

    func applyDataSnapshot(
        _ snapshot: ExchangeDataSnapshot,
        showsStaleRateStatus: Bool
    ) {
        availableCurrencies = snapshot.currencyList.currencies
        exchangeRatesByQuoteCode = snapshot.exchangeRatesByQuoteCode

        if !availableCurrencies.contains(targetCurrency),
           let firstCurrency = availableCurrencies.first {
            targetCurrency = firstCurrency
            clearCalculatedText()
        }

        if exchangeRatesByQuoteCode[targetCurrency.code.uppercased()] == nil,
           let firstRatedCurrency = availableCurrencies.first(where: {
               exchangeRatesByQuoteCode[$0.code.uppercased()] != nil
           }) {
            targetCurrency = firstRatedCurrency
            clearCalculatedText()
        }

        applySelectedRate(showsStaleRateStatus: showsStaleRateStatus)
    }

    func handleRefreshFailure(_ error: Error) {
        showsManualRefresh = exchangeRatesByQuoteCode.isEmpty
        if exchangeRatesByQuoteCode.isEmpty {
            exchangeRate = nil
            applyRateStatus(.hidden)
            if case DolarAPIError.noInternetConnection = error {
                rateErrorText = ExchangeRateStatusPresenter.offlineErrorText
            } else {
                rateErrorText = ExchangeRateStatusPresenter.unavailableErrorText
            }
        } else {
            applySelectedRate(forcesOfflineStatus: true)
        }
    }

    func applySelectedRate(
        showsStaleRateStatus: Bool = false,
        forcesOfflineStatus: Bool = false
    ) {
        let key = targetCurrency.code.uppercased()

        guard let snapshot = exchangeRatesByQuoteCode[key] else {
            exchangeRate = nil
            applyRateStatus(.hidden)
            showsManualRefresh = exchangeRatesByQuoteCode.isEmpty
            if exchangeRatesByQuoteCode.isEmpty {
                rateErrorText = ExchangeRateStatusPresenter.unavailableErrorText
            } else {
                clearCalculatedText()
            }
            return
        }

        exchangeRate = snapshot.rate
        applyRateStatus(
            ExchangeRateStatusPresenter.status(
                for: snapshot,
                showsStaleRateStatus: showsStaleRateStatus,
                forcesOfflineStatus: forcesOfflineStatus
            )
        )
        rateErrorText = nil
        showsManualRefresh = false
        recomputeAfterRateChange()
    }

    func applyRateStatus(_ status: RateStatusPresentation) {
        rateStatusText = status.text
        rateStatusIconName = status.iconName
        rateStatusTone = status.tone
    }

    func recomputeAfterRateChange() {
        switch lastEditedField {
        case .source:
            onSourceChanged(sourceText)
        case .target:
            onTargetChanged(targetText)
        case nil:
            break
        }
    }

    func clearCalculatedText() {
        switch lastEditedField {
        case .source:
            setCalculatedTargetText(nil)
        case .target:
            setCalculatedSourceText(nil)
        case nil:
            setCalculatedSourceText(nil)
            setCalculatedTargetText(nil)
        }
    }

    func setCalculatedSourceText(_ amount: Decimal?) {
        let text = amount.map(AmountInputFormatter.formattedAmount) ?? ""
        sourceText = text
        lastValidSourceText = text
    }

    func setCalculatedTargetText(_ amount: Decimal?) {
        let text = amount.map(AmountInputFormatter.formattedAmount) ?? ""
        targetText = text
        lastValidTargetText = text
    }

    func clearAllAmountText() {
        lastEditedField = nil
        setCalculatedSourceText(nil)
        setCalculatedTargetText(nil)
    }
}
