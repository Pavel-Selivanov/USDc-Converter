//
//  AmountInputFormatter.swift
//  ExchangeCalculator
//

import Foundation

/// Presentation-specific formatter for editable currency amount fields.
///
/// This intentionally lives next to `ExchangeViewModel`: it models the app's
/// amount-entry behavior, not general-purpose `String` formatting.
nonisolated enum AmountInputFormatter {
    /// Maximum source-currency equivalent a user may type.
    static let maxInputValue: Decimal = 10_000_000_000

    /// Maximum number of digits allowed after the decimal point.
    static let maxFractionDigits: Int = 2

    /// Inserts thousands-separator commas into the integer part of a numeric
    /// string without touching the decimal portion or trailing zeros.
    ///
    /// Examples:
    ///   "9999"    -> "9,999"
    ///   "9999.5"  -> "9,999.5"
    ///   "9999.50" -> "9,999.50"
    ///   "9999."   -> "9,999."
    ///   ".5"      -> "0.5"
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

    static func decimal(from raw: String) -> Decimal? {
        Decimal(string: parseable(raw), locale: .usParsing)
    }

    /// Normalizes keyboard input into the app's canonical "." decimal format.
    /// iOS decimal pads use the user's region, so some devices type ",".
    static func canonicalAmountInput(
        _ input: String,
        previousFormattedInput: String = ""
    ) -> String {
        let inputWithSupportedCharacters = input.amountInputCharactersOnly
        guard !inputWithSupportedCharacters.isEmpty || input.isEmpty else {
            return previousFormattedInput.replacingOccurrences(of: ",", with: "")
        }

        if previousFormattedInput == "0.", inputWithSupportedCharacters == "0" {
            return ""
        }

        if inputWithSupportedCharacters.contains(".") {
            return inputWithSupportedCharacters
                .replacingOccurrences(of: ",", with: "")
                .prefixedWithZeroForLeadingDecimal
                .normalizedLeadingZeroAmountInput
        }

        guard inputWithSupportedCharacters.contains(",") else {
            return inputWithSupportedCharacters.normalizedLeadingZeroAmountInput
        }

        if !previousFormattedInput.isEmpty,
           inputWithSupportedCharacters.commaCount <= previousFormattedInput.commaCount {
            return inputWithSupportedCharacters
                .replacingOccurrences(of: ",", with: "")
                .normalizedLeadingZeroAmountInput
        }

        if isGroupedInteger(inputWithSupportedCharacters) {
            return inputWithSupportedCharacters
                .replacingOccurrences(of: ",", with: "")
                .normalizedLeadingZeroAmountInput
        }

        guard let decimalSeparatorIndex = inputWithSupportedCharacters.lastIndex(of: ",") else {
            return inputWithSupportedCharacters.normalizedLeadingZeroAmountInput
        }

        let integerPart = String(inputWithSupportedCharacters[..<decimalSeparatorIndex])
            .replacingOccurrences(of: ",", with: "")
        let fractionPart = String(inputWithSupportedCharacters[inputWithSupportedCharacters.index(after: decimalSeparatorIndex)...])
            .replacingOccurrences(of: ",", with: "")

        return (integerPart + "." + fractionPart)
            .prefixedWithZeroForLeadingDecimal
            .normalizedLeadingZeroAmountInput
    }

    static func isGroupedInteger(_ input: String) -> Bool {
        let groups = input.split(separator: ",", omittingEmptySubsequences: false)

        guard
            groups.count > 1,
            (1...3).contains(groups[0].count),
            groups[0].allSatisfy(\.isNumber)
        else {
            return false
        }

        return groups.dropFirst().allSatisfy { group in
            group.count == 3 && group.allSatisfy(\.isNumber)
        }
    }

    /// Returns `true` when `raw` (commas already stripped) satisfies all limits:
    ///   - at most one decimal point
    ///   - parsed value <= `maxValue`
    ///   - fractional digits <= `maxFractionDigits`
    ///
    /// A trailing "." and an empty string are valid so the user can keep typing.
    static func isWithinLimits(
        _ raw: String,
        maxValue: Decimal = maxInputValue
    ) -> Bool {
        if raw.contains(where: { !$0.isASCIIAmountDigit && $0 != "." }) {
            return false
        }

        if raw.filter({ $0 == "." }).count > 1 {
            return false
        }

        let parts = raw.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        if parts.count > 1, String(parts[1]).count > maxFractionDigits {
            return false
        }

        if let parsed = decimal(from: raw), parsed > maxValue {
            return false
        }

        return true
    }

    static func formattedAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .amountPresentation
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = maxFractionDigits
        formatter.maximumFractionDigits = maxFractionDigits

        return formatter.string(from: amount as NSDecimalNumber) ?? ""
    }
}

private extension String {
    nonisolated var amountInputCharactersOnly: String {
        filter { character in
            character.isASCIIAmountDigit || character == "." || character == ","
        }
    }

    nonisolated var commaCount: Int {
        reduce(0) { count, character in
            character == "," ? count + 1 : count
        }
    }

    nonisolated var prefixedWithZeroForLeadingDecimal: String {
        hasPrefix(".") ? "0" + self : self
    }

    nonisolated var normalizedLeadingZeroAmountInput: String {
        guard !isEmpty else { return self }

        let parts = split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let hasDecimalSeparator = contains(".")
        let fractionPart = parts.count > 1 ? String(parts[1]) : ""
        var integerPart = String(parts[0])

        if integerPart.isEmpty {
            integerPart = "0"
        } else if integerPart.allSatisfy({ $0 == "0" }) {
            integerPart = "0"
        } else {
            integerPart = String(integerPart.drop(while: { $0 == "0" }))
        }

        if hasDecimalSeparator {
            return integerPart + "." + fractionPart
        }

        return integerPart == "0" ? "0." : integerPart
    }
}

private extension Character {
    nonisolated var isASCIIAmountDigit: Bool {
        guard unicodeScalars.count == 1, let scalar = unicodeScalars.first else {
            return false
        }

        return (48...57).contains(scalar.value)
    }
}

private extension Locale {
    /// Fixed locale for decimal parsing: prevents `Decimal(string:)` from
    /// misinterpreting locale-specific decimal separators.
    nonisolated static let usParsing = Locale(identifier: "en_US_POSIX")

    /// Fixed presentation locale for amount fields. User locale is accepted at
    /// input time, but both fields should display the same separators.
    nonisolated static let amountPresentation = Locale(identifier: "en_US_POSIX")
}
