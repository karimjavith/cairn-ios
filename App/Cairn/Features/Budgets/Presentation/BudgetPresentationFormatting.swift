//
//  BudgetPresentationFormatting.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import Foundation

enum BudgetMoneyFormatter {
    static func currency(_ money: Money) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = money.currencyCode

        return formatter.string(from: money.amount as NSDecimalNumber)
            ?? "\(money.amount) \(money.currencyCode)"
    }

    static func remainingStatusTitle(_ remaining: Money) -> String {
        remaining.amount < 0 ? "Overspent" : "Remaining"
    }

    static func remainingStatusValue(_ remaining: Money) -> String {
        let displayedMoney = remaining.amount < 0 ? -remaining : remaining

        return currency(displayedMoney)
    }

    static func remainingStatusAccessibilityText(_ remaining: Money) -> String {
        let status = remaining.amount < 0 ? "overspent by" : "remaining"

        return "\(status) \(remainingStatusValue(remaining))"
    }

    static func decimalText(_ decimal: Decimal, locale: Locale) -> String {
        let decimalText = NSDecimalNumber(decimal: decimal).stringValue
        let decimalSeparator = locale.decimalSeparator ?? "."

        guard decimalSeparator != "." else {
            return decimalText
        }

        return decimalText.replacingOccurrences(of: ".", with: decimalSeparator)
    }
}

enum BudgetMoneyTextParser {
    enum Error: Swift.Error, Equatable, Sendable {
        case empty
        case malformed
    }

    static func parse(_ text: String, locale: Locale) throws -> Decimal {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else {
            throw Error.empty
        }

        let decimalSeparator = locale.decimalSeparator ?? "."
        let escapedDecimalSeparator = NSRegularExpression.escapedPattern(for: decimalSeparator)
        let pattern = #"^-?(?:\d+|\d+\#(escapedDecimalSeparator)\d+|\#(escapedDecimalSeparator)\d+)$"#

        guard trimmedText.range(of: pattern, options: .regularExpression) != nil,
              let decimal = Decimal(
                string: trimmedText.replacingOccurrences(of: decimalSeparator, with: "."),
                locale: Locale(identifier: "en_US_POSIX")
              ) else {
            throw Error.malformed
        }

        return decimal
    }
}

enum BudgetDateFormatter {
    static func date(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        return formatter.string(from: date)
    }

    static func period(_ period: BudgetPeriod) -> String {
        "\(date(period.startDate)) - \(date(period.endDate))"
    }
}
