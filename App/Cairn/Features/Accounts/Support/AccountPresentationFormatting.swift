//
//  AccountPresentationFormatting.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import Foundation

extension AccountType: CaseIterable {
    static var allCases: [AccountType] {
        [
            .checking,
            .savings,
            .creditCard,
            .cash,
            .investment,
            .loan
        ]
    }

    var displayName: String {
        switch self {
        case .checking:
            "Checking"
        case .savings:
            "Savings"
        case .creditCard:
            "Credit Card"
        case .cash:
            "Cash"
        case .investment:
            "Investment"
        case .loan:
            "Loan"
        }
    }
}

enum AccountMoneyFormatter {
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

nonisolated struct AccountCurrencySummary: Equatable, Sendable {
    let currencyCode: String
    let total: Money
    let accountCount: Int
}

enum AccountListPresentation {
    static func currencySummaries(
        accounts: [Account],
        balances: [AccountID: Money]
    ) -> [AccountCurrencySummary]? {
        guard accounts.isEmpty == false,
              accounts.allSatisfy({ balances[$0.id] != nil }) else {
            return nil
        }

        var summariesByCurrency: [String: (total: Money, count: Int)] = [:]

        for account in accounts {
            guard let balance = balances[account.id] else {
                return nil
            }

            if let existing = summariesByCurrency[balance.currencyCode] {
                do {
                    summariesByCurrency[balance.currencyCode] = (
                        total: try existing.total.adding(balance),
                        count: existing.count + 1
                    )
                } catch {
                    return nil
                }
            } else {
                summariesByCurrency[balance.currencyCode] = (balance, 1)
            }
        }

        return summariesByCurrency
            .map { currencyCode, value in
                AccountCurrencySummary(
                    currencyCode: currencyCode,
                    total: value.total,
                    accountCount: value.count
                )
            }
            .sorted { lhs, rhs in
                if lhs.currencyCode == rhs.currencyCode {
                    return lhs.accountCount < rhs.accountCount
                }

                return lhs.currencyCode < rhs.currencyCode
            }
    }

    static func accountCountText(_ count: Int, currencyCode: String) -> String {
        let accountText = count == 1 ? "1 account" : "\(count) accounts"
        return "\(accountText) in \(currencyCode)"
    }
}

enum AccountMoneyTextParser {
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
