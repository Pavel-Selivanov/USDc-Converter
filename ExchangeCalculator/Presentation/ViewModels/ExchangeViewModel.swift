//
//  ExchangeViewModel.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/4/26.
//

import Observation
import Foundation

@Observable
final class ExchangeViewModel {
    typealias LoadCurrencies = () async -> CurrencyListSnapshot
    typealias LoadExchangeRate = (_ quote: Currency, _ forceRefresh: Bool) async throws -> ExchangeRateSnapshot

    // MARK: - State

    private(set) var sourceCurrency: Currency
    private(set) var targetCurrency: Currency
    private(set) var pickableCurrencies: [Currency]

    var sourceText: String = ""
    var targetText: String = ""

    private(set) var exchangeRate: ExchangeRate?
    private(set) var isLoadingRate: Bool = false
    private(set) var rateStatusText: String?
    private(set) var rateErrorText: String?

    /// Toggles each time `swapCurrencies()` is called. Drives the slot order
    /// in the view so SwiftUI's diff sees the field views move between slots,
    /// producing the matchedGeometryEffect slide animation.
    private(set) var isSwapped: Bool = false

    // MARK: - Input limits

    /// Maximum value a user may type into either field.
    static let maxInputValue: Decimal = 10_000_000_000

    /// Maximum number of digits allowed after the decimal point.
    static let maxFractionDigits: Int = 2

    @ObservationIgnored private var lastValidSourceText: String = ""
    @ObservationIgnored private var lastValidTargetText: String = ""
    @ObservationIgnored private var lastEditedField: FieldFocus?
    @ObservationIgnored private var rateRequestID: Int = 0
    @ObservationIgnored private let loadCurrencies: LoadCurrencies
    @ObservationIgnored private let loadExchangeRate: LoadExchangeRate

    // MARK: - Derived

    /// The rate as it should appear in the header — flipped when `isSwapped`
    /// so the displayed direction always matches the visual top→bottom order
    /// of the fields.
    var displayRate: String? {
        guard let rate = exchangeRate else { return nil }
        return (isSwapped ? rate.reversed : rate).displayString
    }

    var canEditAmounts: Bool {
        exchangeRate != nil
    }

    init(
        sourceCurrency: Currency = CurrencyCatalog.baseCurrency,
        targetCurrency: Currency = CurrencyCatalog.fallbackCurrencies[0],
        pickableCurrencies: [Currency] = CurrencyCatalog.fallbackCurrencies,
        exchangeRate: ExchangeRate? = nil,
        loadCurrencies: @escaping LoadCurrencies = {
            CurrencyListSnapshot(
                currencies: CurrencyCatalog.fallbackCurrencies,
                source: .fallback,
                updatedAt: nil
            )
        },
        loadExchangeRate: @escaping LoadExchangeRate = { _, _ in
            throw ExchangeViewModelError.rateUnavailable
        }
    ) {
        self.sourceCurrency = sourceCurrency
        self.targetCurrency = targetCurrency
        self.pickableCurrencies = pickableCurrencies
        self.exchangeRate = exchangeRate
        self.loadCurrencies = loadCurrencies
        self.loadExchangeRate = loadExchangeRate
        self.rateStatusText = exchangeRate.map { Self.updatedText(for: $0.quotedAt, isStale: false) }
    }

    // MARK: - User actions

    func loadInitialData() async {
        let snapshot = await loadCurrencies()

        pickableCurrencies = snapshot.currencies

        if !snapshot.currencies.contains(targetCurrency),
           let firstCurrency = snapshot.currencies.first {
            targetCurrency = firstCurrency
            clearCalculatedText()
        }

        await refreshRate(forceRefresh: false)
    }

    func refreshRate(forceRefresh: Bool = true) async {
        rateRequestID += 1
        let requestID = rateRequestID
        let requestedCurrency = targetCurrency

        isLoadingRate = true
        rateErrorText = nil

        do {
            let snapshot = try await loadExchangeRate(requestedCurrency, forceRefresh)
            guard requestID == rateRequestID, requestedCurrency == targetCurrency else {
                return
            }

            exchangeRate = snapshot.rate
            rateStatusText = Self.updatedText(
                for: snapshot.rate.quotedAt,
                isStale: snapshot.isStale
            )
            rateErrorText = snapshot.isStale ? "Using the last available rate." : nil
            recomputeAfterRateChange()
        } catch {
            guard requestID == rateRequestID, requestedCurrency == targetCurrency else {
                return
            }

            exchangeRate = nil
            rateStatusText = nil
            rateErrorText = "Rate unavailable. Pull to retry when you're online."
            clearAllAmountText()
        }

        isLoadingRate = false
    }

    /// Called when the user edits the source field.
    func onSourceChanged(_ newValue: String) {
        guard canEditAmounts else {
            sourceText = lastValidSourceText
            return
        }

        lastEditedField = .source
        let raw = newValue.replacingOccurrences(of: ",", with: "")

        guard Self.isWithinLimits(raw) else {
            sourceText = lastValidSourceText   // revert — input not accepted
            return
        }

        let formatted = Self.withGroupingSeparator(raw)
        sourceText = formatted
        lastValidSourceText = formatted

        guard
            !raw.isEmpty,
            let amount = Decimal(string: Self.parseable(raw), locale: .usParsing),
            let rate = exchangeRate
        else {
            if raw.isEmpty { targetText = "" }
            return
        }
        
        setCalculatedTargetText(rate.convert(amount))
    }

    /// Called when the user edits the target field.
    func onTargetChanged(_ newValue: String) {
        guard canEditAmounts else {
            targetText = lastValidTargetText
            return
        }

        lastEditedField = .target
        let raw = newValue.replacingOccurrences(of: ",", with: "")

        guard Self.isWithinLimits(raw) else {
            targetText = lastValidTargetText   // revert — input not accepted
            return
        }

        let formatted = Self.withGroupingSeparator(raw)
        targetText = formatted
        lastValidTargetText = formatted

        guard
            !raw.isEmpty,
            let amount = Decimal(string: Self.parseable(raw), locale: .usParsing),
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
    /// `swapCurrencies()` only reorders slots without mutating data — so the
    /// quote is always `targetCurrency`, regardless of `isSwapped`.
    func selectQuoteCurrency(_ currency: Currency) async {
        guard currency != targetCurrency else { return }

        targetCurrency = currency
        exchangeRate = nil
        rateStatusText = nil
        rateErrorText = nil
        clearCalculatedText()

        await refreshRate(forceRefresh: true)
    }

    /// Swaps the two fields by toggling slot order, not by mutating data.
    ///
    /// The source/target data stays where it is; only `isSwapped` flips, which
    /// reorders the slots in the view. SwiftUI's diff then sees the same view
    /// instance move from one slot to the other, and `matchedGeometryEffect`
    /// interpolates its frame — producing the slide animation.
    ///
    /// This keeps the source-of-truth stable and avoids swapping multiple
    /// paired pieces of state.
    func swapCurrencies() {
        isSwapped.toggle()
    }
}

enum ExchangeViewModelError: Error {
    case rateUnavailable
}

// MARK: - Formatting helpers

private extension ExchangeViewModel {

    /// Inserts thousands-separator commas into the integer part of a numeric
    /// string without touching the decimal portion or trailing zeros.
    ///
    /// Examples:
    ///   "9999"    → "9,999"
    ///   "9999.5"  → "9,999.5"
    ///   "9999.50" → "9,999.50"   (trailing zero preserved)
    ///   "9999."   → "9,999."     (mid-typing decimal preserved)
    ///   ".5"      → ".5"         (no integer part, unchanged)
    static func withGroupingSeparator(_ raw: String) -> String {
        guard !raw.isEmpty else { return raw }

        let parts = raw.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let intPart = String(parts[0])
        let fracPart = parts.count > 1 ? "." + String(parts[1]) : ""

        guard !intPart.isEmpty else { return raw }

        var result = ""
        for (offset, char) in intPart.reversed().enumerated() {
            if offset > 0, offset % 3 == 0 { result = "," + result }
            result = String(char) + result
        }
        return result + fracPart
    }

    /// Strips a trailing "." so `Decimal(string:)` can parse mid-typing input
    /// like "9999." without returning nil.
    static func parseable(_ raw: String) -> String {
        raw.hasSuffix(".") ? String(raw.dropLast()) : raw
    }

    nonisolated static func formattedAmount(_ amount: Decimal) -> String {
        amount.formatted(.number.precision(.fractionLength(2)))
    }

    nonisolated static func updatedText(for date: Date, isStale: Bool) -> String {
        let formattedDate = date.formatted(
            .dateTime
                .month(.abbreviated)
                .day()
                .hour()
                .minute()
        )

        return isStale
            ? "Offline. Last updated \(formattedDate)"
            : "Updated \(formattedDate)"
    }

    /// Returns `true` when `raw` (commas already stripped) satisfies all limits:
    ///   • at most one decimal point
    ///   • parsed value ≤ `maxInputValue`
    ///   • fractional digits ≤ `maxFractionDigits`
    ///
    /// A trailing "." (mid-typing) and an empty string are considered valid so
    /// the user can keep typing.
    static func isWithinLimits(_ raw: String) -> Bool {
        // At most one decimal point.
        if raw.filter({ $0 == "." }).count > 1 {
            return false
        }

        // Check fractional digit count using the raw string — the parser
        // silently accepts unlimited precision, so we must check here.
        let parts = raw.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        if parts.count > 1, String(parts[1]).count > maxFractionDigits {
            return false
        }

        // Check magnitude.
        if let parsed = Decimal(string: parseable(raw), locale: .usParsing),
           parsed > maxInputValue {
            return false
        }

        return true
    }
}

// MARK: - Recalculation

private extension ExchangeViewModel {
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
        let text = amount.map(Self.formattedAmount) ?? ""
        sourceText = text
        lastValidSourceText = text
    }

    func setCalculatedTargetText(_ amount: Decimal?) {
        let text = amount.map(Self.formattedAmount) ?? ""
        targetText = text
        lastValidTargetText = text
    }

    func clearAllAmountText() {
        lastEditedField = nil
        setCalculatedSourceText(nil)
        setCalculatedTargetText(nil)
    }
}

// MARK: - Locale helper

private extension Locale {
    /// Fixed locale for decimal parsing — prevents `Decimal(string:)` from
    /// misinterpreting locale-specific decimal separators.
    static let usParsing = Locale(identifier: "en_US_POSIX")
}
