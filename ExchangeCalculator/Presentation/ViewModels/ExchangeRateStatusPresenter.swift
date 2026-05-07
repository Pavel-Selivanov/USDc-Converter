//
//  ExchangeRateStatusPresenter.swift
//  ExchangeCalculator
//

import Foundation

enum RateStatusTone: Equatable {
    case hidden
    case warning
}

struct RateStatusPresentation: Equatable {
    let text: String?
    let iconName: String?
    let tone: RateStatusTone

    nonisolated static let hidden = RateStatusPresentation(
        text: nil,
        iconName: nil,
        tone: .hidden
    )
}

nonisolated enum ExchangeRateStatusPresenter {
    static let offlineErrorText = String(localized: "No internet connection. Connect and refresh to load rates.")
    static let unavailableErrorText = String(localized: "Rates unavailable. Refresh when you're online.")
    static let offlineIconName = "icloud.slash"

    static func status(
        for snapshot: ExchangeRateSnapshot,
        showsStaleRateStatus: Bool,
        forcesOfflineStatus: Bool
    ) -> RateStatusPresentation {
        guard forcesOfflineStatus || (showsStaleRateStatus && snapshot.isStale) else {
            return .hidden
        }

        return RateStatusPresentation(
            text: offlineText(for: snapshot.rate.quotedAt),
            iconName: offlineIconName,
            tone: .warning
        )
    }

    static func offlineText(for date: Date) -> String {
        let formattedDate = date.formatted(
            .dateTime
                .month(.abbreviated)
                .day()
                .hour()
                .minute(.twoDigits)
                .second(.twoDigits)
        )

        return String(localized: "Offline. Last updated \(formattedDate)")
    }

    static func rateDisplayText(
        for rate: ExchangeRate,
        usingAsk: Bool
    ) -> String {
        let displayRate = usingAsk ? rate.ask : rate.bid
        let formatted = displayRate.formatted(.number.precision(.fractionLength(4)))
        return "1 \(rate.base.code) = \(formatted) \(rate.quote.code)"
    }
}
