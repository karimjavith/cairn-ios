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
            "Income"
        case .outflow:
            "Expense"
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

    static func time(_ date: Date, locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .none
        formatter.timeStyle = .short

        return formatter.string(from: date)
    }
}

nonisolated struct TransactionDaySection: Equatable, Sendable {
    let day: Date
    let title: String
    let transactions: [Transaction]
}

nonisolated struct TransactionRowPresentation: Equatable, Sendable {
    let title: String
    let metadata: String
    let amountText: String
    let timeText: String
    let accessibilityLabel: String
}

enum TransactionListPresentation {
    static func sections(
        transactions: [Transaction],
        calendar: Calendar = .current,
        locale: Locale = .current,
        now: Date = Date()
    ) -> [TransactionDaySection] {
        let sortedTransactions = transactions.sorted { lhs, rhs in
            if lhs.occurredAt == rhs.occurredAt {
                return lhs.id.rawValue.uuidString < rhs.id.rawValue.uuidString
            }

            return lhs.occurredAt > rhs.occurredAt
        }
        let groupedTransactions = Dictionary(grouping: sortedTransactions) { transaction in
            calendar.startOfDay(for: transaction.occurredAt)
        }

        return groupedTransactions
            .map { day, transactions in
                TransactionDaySection(
                    day: day,
                    title: sectionTitle(for: day, calendar: calendar, locale: locale, now: now),
                    transactions: transactions
                )
            }
            .sorted { $0.day > $1.day }
    }

    static func row(
        transaction: Transaction,
        accountName: String,
        categoryName: String,
        locale: Locale = .current
    ) -> TransactionRowPresentation {
        let direction = transaction.direction.displayName
        let amountText = signedAmountText(transaction)
        let timeText = TransactionDateFormatter.time(transaction.occurredAt, locale: locale)
        let title: String

        if let memo = transaction.memo {
            title = "\(categoryName) - \(memo)"
        } else {
            title = categoryName
        }

        let dateTime = TransactionDateFormatter.dateTime(transaction.occurredAt)
        let memoText = transaction.memo.map { ", \($0)" } ?? ""

        return TransactionRowPresentation(
            title: title,
            metadata: accountName,
            amountText: amountText,
            timeText: timeText,
            accessibilityLabel: "\(direction), \(amountText), \(accountName), \(categoryName), \(dateTime)\(memoText)"
        )
    }

    static func signedAmountText(_ transaction: Transaction) -> String {
        let amount = CairnMoneyPresentation.currency(transaction.amount)

        switch transaction.direction {
        case .inflow:
            return "+\(amount)"
        case .outflow:
            return "-\(amount)"
        }
    }

    private static func sectionTitle(
        for day: Date,
        calendar: Calendar,
        locale: Locale,
        now: Date
    ) -> String {
        let today = calendar.startOfDay(for: now)

        if calendar.isDate(day, inSameDayAs: today) {
            return "Today"
        }

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
           calendar.isDate(day, inSameDayAs: yesterday) {
            return "Yesterday"
        }

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("dMMMyyyy")

        return formatter.string(from: day)
    }
}
