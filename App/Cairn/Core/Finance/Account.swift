//
//  Account.swift
//  Cairn
//
//  Created by Karim Sheikh on 07/08/2026.
//

import Foundation

nonisolated struct AccountID: Equatable, Hashable, Codable, Sendable {
    let rawValue: UUID

    init(rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}

nonisolated enum AccountType: Equatable, Hashable, Codable, Sendable {
    case checking
    case savings
    case creditCard
    case cash
    case investment
    case loan
}

nonisolated struct Account: Equatable, Hashable, Sendable {
    let id: AccountID
    let name: String
    let type: AccountType
    let currencyCode: String
    let openingBalance: Money

    init(
        id: AccountID = AccountID(),
        name: String,
        type: AccountType,
        currencyCode: String,
        openingBalance: Money
    ) throws {
        guard !name.isEmpty else {
            throw ValidationError.emptyName
        }

        let normalizedCurrencyCode = try Money(
            amount: openingBalance.amount,
            currencyCode: currencyCode
        ).currencyCode

        guard normalizedCurrencyCode == openingBalance.currencyCode else {
            throw ValidationError.currencyMismatch(
                currencyCode: normalizedCurrencyCode,
                openingBalanceCurrencyCode: openingBalance.currencyCode
            )
        }

        self.id = id
        self.name = name
        self.type = type
        self.currencyCode = normalizedCurrencyCode
        self.openingBalance = openingBalance
    }
}

extension Account {
    nonisolated enum ValidationError: Error, Equatable, Sendable {
        case emptyName
        case currencyMismatch(
            currencyCode: String,
            openingBalanceCurrencyCode: String
        )
    }
}
