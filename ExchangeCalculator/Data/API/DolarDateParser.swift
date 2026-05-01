//
//  DolarDateParser.swift
//  ExchangeCalculator
//
//  Created by Pavel Selivanov on 5/7/26.
//

import Foundation

enum DolarDateParser {
    static func parse(_ value: String) -> Date? {
        let pieces = value.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        guard let wholeSeconds = baseFormatter.date(from: String(pieces[0])) else {
            return nil
        }

        guard pieces.count == 2 else {
            return wholeSeconds
        }

        let digits = pieces[1].prefix { $0.isNumber }
        guard !digits.isEmpty, let fraction = Double("0." + digits) else {
            return wholeSeconds
        }

        return wholeSeconds.addingTimeInterval(fraction)
    }

    private static let baseFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()
}

