//
//  TransactionPresentationFormatting.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import Foundation

extension TransactionDirection: CaseIterable {
    static var allCases: [TransactionDirection] {
        [
            .outflow,
            .inflow
        ]
    }

    var displayName: String {
        switch self {
        case .inflow:
            "Inflow"
        case .outflow:
            "Outflow"
        }
    }
}

enum TransactionMoneyFormatter {
    static func currency(_ money: Money) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = money.currencyCode

        return formatter.string(from: money.amount as NSDecimalNumber)
            ?? "\(money.amount) \(money.currencyCode)"
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

enum TransactionMoneyTextParser {
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

enum TransactionDateFormatter {
    static func dateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        return formatter.string(from: date)
    }
}
