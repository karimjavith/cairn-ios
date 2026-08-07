//
//  Money.swift
//  Cairn
//
//  Created by Karim Sheikh on 07/08/2026.
//

import Foundation

nonisolated struct Money: Equatable, Hashable, Sendable {
    let amount: Decimal
    let currencyCode: String

    init(amount: Decimal, currencyCode: String) throws {
        let normalizedCurrencyCode = Self.normalizedCurrencyCode(currencyCode)

        guard !amount.isNaN else {
            throw MoneyError.invalidAmount
        }

        guard Self.isValidCurrencyCode(normalizedCurrencyCode) else {
            throw MoneyError.invalidCurrencyCode(currencyCode)
        }

        self.amount = amount
        self.currencyCode = normalizedCurrencyCode
    }

    func adding(_ other: Money) throws -> Money {
        try requireMatchingCurrency(with: other)

        return try Money(
            amount: amount + other.amount,
            currencyCode: currencyCode
        )
    }

    func subtracting(_ other: Money) throws -> Money {
        try requireMatchingCurrency(with: other)

        return try Money(
            amount: amount - other.amount,
            currencyCode: currencyCode
        )
    }

    static prefix func - (money: Money) -> Money {
        Money(
            uncheckedAmount: -money.amount,
            currencyCode: money.currencyCode
        )
    }

    private init(uncheckedAmount amount: Decimal, currencyCode: String) {
        self.amount = amount
        self.currencyCode = currencyCode
    }

    private func requireMatchingCurrency(with other: Money) throws {
        guard currencyCode == other.currencyCode else {
            throw MoneyError.currencyMismatch(
                left: currencyCode,
                right: other.currencyCode
            )
        }
    }

    private static func normalizedCurrencyCode(_ currencyCode: String) -> String {
        currencyCode
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
    }

    private static func isValidCurrencyCode(_ currencyCode: String) -> Bool {
        guard currencyCode.count == 3,
              currencyCode.allSatisfy({ $0 >= "A" && $0 <= "Z" }) else {
            return false
        }

        return Locale.Currency(currencyCode).isISOCurrency
    }
}

nonisolated enum MoneyError: Error, Equatable, Sendable {
    case invalidAmount
    case invalidCurrencyCode(String)
    case currencyMismatch(left: String, right: String)
}
