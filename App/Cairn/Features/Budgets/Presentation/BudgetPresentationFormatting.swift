//
//  BudgetPresentationFormatting.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import Foundation

enum BudgetProgressPresentationStatus: Equatable, Sendable {
    case normal
    case nearLimit
    case fullySpent
    case overspent

    var accessibilityText: String {
        switch self {
        case .normal:
            "in progress"
        case .nearLimit:
            "near limit"
        case .fullySpent:
            "fully spent"
        case .overspent:
            "overspent"
        }
    }
}

enum BudgetProgressColorIntent: Equatable, Sendable {
    case primary
    case warning
    case negative
}

struct BudgetProgressPresentation: Equatable, Sendable {
    static let nearLimitThreshold = Decimal(8) / Decimal(10)

    let categoryName: String
    let status: BudgetProgressPresentationStatus
    let valueText: String
    let detailText: String
    let accessibilityLabel: String
    let visibleFraction: Double
    let valueColorIntent: BudgetProgressColorIntent
    let progressColorIntent: BudgetProgressColorIntent

    static func make(
        categoryName: String,
        progress: BudgetProgress
    ) -> BudgetProgressPresentation {
        let budget = progress.budget
        let spent = progress.spent
        let limit = budget.limit
        let remaining = progress.remaining
        let status = status(spent: spent, limit: limit, remaining: remaining)
        let visibleFraction = visibleFraction(spent: spent, limit: limit)
        let spentText = BudgetMoneyFormatter.currency(spent)
        let limitText = BudgetMoneyFormatter.currency(limit)
        let valueText = valueText(status: status, spent: spent, remaining: remaining)
        let detailText = "\(spentText) spent of \(limitText)"

        return BudgetProgressPresentation(
            categoryName: categoryName,
            status: status,
            valueText: valueText,
            detailText: detailText,
            accessibilityLabel: "\(categoryName), \(status.accessibilityText), \(valueText), \(detailText), \(BudgetDateFormatter.period(budget.period))",
            visibleFraction: visibleFraction,
            valueColorIntent: valueColorIntent(status: status),
            progressColorIntent: progressColorIntent(status: status)
        )
    }

    private static func status(
        spent: Money,
        limit: Money,
        remaining: Money
    ) -> BudgetProgressPresentationStatus {
        if limit.amount == 0 {
            return spent.amount > 0 ? .overspent : .fullySpent
        }

        if remaining.amount < 0 {
            return .overspent
        }

        if remaining.amount == 0 {
            return .fullySpent
        }

        return progressRatio(spent: spent, limit: limit) >= nearLimitThreshold
            ? .nearLimit
            : .normal
    }

    private static func valueText(
        status: BudgetProgressPresentationStatus,
        spent: Money,
        remaining: Money
    ) -> String {
        switch status {
        case .normal, .nearLimit:
            "\(BudgetMoneyFormatter.currency(remaining)) remaining"
        case .fullySpent:
            "Fully spent"
        case .overspent:
            "Overspent by \(BudgetMoneyFormatter.currency(overspentAmount(spent: spent, remaining: remaining)))"
        }
    }

    private static func overspentAmount(spent: Money, remaining: Money) -> Money {
        if remaining.amount < 0 {
            return -remaining
        }

        return spent
    }

    private static func visibleFraction(spent: Money, limit: Money) -> Double {
        if limit.amount == 0 {
            return spent.amount > 0 ? 1 : 0
        }

        let value = NSDecimalNumber(decimal: progressRatio(spent: spent, limit: limit)).doubleValue

        guard value.isFinite else {
            return 0
        }

        return min(max(value, 0), 1)
    }

    private static func progressRatio(spent: Money, limit: Money) -> Decimal {
        guard limit.amount > 0 else {
            return 0
        }

        return spent.amount / limit.amount
    }

    private static func valueColorIntent(status: BudgetProgressPresentationStatus) -> BudgetProgressColorIntent {
        switch status {
        case .normal, .nearLimit:
            .primary
        case .fullySpent:
            .warning
        case .overspent:
            .negative
        }
    }

    private static func progressColorIntent(status: BudgetProgressPresentationStatus) -> BudgetProgressColorIntent {
        switch status {
        case .normal:
            .primary
        case .nearLimit, .fullySpent, .overspent:
            .warning
        }
    }
}

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
