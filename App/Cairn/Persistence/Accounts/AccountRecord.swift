//
//  AccountRecord.swift
//  Cairn
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import SwiftData

@Model
nonisolated final class AccountRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var type: String
    var currencyCode: String
    var openingBalanceAmount: String

    init(
        id: UUID,
        name: String,
        type: String,
        currencyCode: String,
        openingBalanceAmount: String
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.currencyCode = currencyCode
        self.openingBalanceAmount = openingBalanceAmount
    }
}

extension AccountRecord {
    convenience init(account: Account) {
        self.init(
            id: account.id.rawValue,
            name: account.name,
            type: account.type.persistenceValue,
            currencyCode: account.currencyCode,
            openingBalanceAmount: account.openingBalance.amount.persistenceValue
        )
    }

    func account() throws -> Account {
        let accountType = try AccountType(persistenceValue: type)
        let openingBalanceAmount = try Decimal(persistenceValue: openingBalanceAmount)

        let openingBalance = try Money(
            amount: openingBalanceAmount,
            currencyCode: currencyCode
        )

        return try Account(
            id: AccountID(rawValue: id),
            name: name,
            type: accountType,
            currencyCode: currencyCode,
            openingBalance: openingBalance
        )
    }
}

nonisolated enum AccountRecordMappingError: Error, Equatable, Sendable {
    case invalidAccountType(String)
    case invalidOpeningBalanceAmount(String)
}

private extension AccountType {
    nonisolated var persistenceValue: String {
        switch self {
        case .checking:
            "checking"
        case .savings:
            "savings"
        case .creditCard:
            "creditCard"
        case .cash:
            "cash"
        case .investment:
            "investment"
        case .loan:
            "loan"
        }
    }

    nonisolated init(persistenceValue: String) throws(AccountRecordMappingError) {
        switch persistenceValue {
        case "checking":
            self = .checking
        case "savings":
            self = .savings
        case "creditCard":
            self = .creditCard
        case "cash":
            self = .cash
        case "investment":
            self = .investment
        case "loan":
            self = .loan
        default:
            throw .invalidAccountType(persistenceValue)
        }
    }
}

private extension Decimal {
    private nonisolated static var accountPersistencePattern: String {
        #"\A[+-]?(?:(?:[0-9]+(?:\.[0-9]*)?)|(?:\.[0-9]+))(?:[eE][+-]?[0-9]+)?\z"#
    }

    nonisolated var persistenceValue: String {
        NSDecimalNumber(decimal: self).stringValue
    }

    nonisolated init(persistenceValue: String) throws(AccountRecordMappingError) {
        guard persistenceValue.range(
            of: Self.accountPersistencePattern,
            options: .regularExpression
        ) != nil,
            let amount = Decimal(string: persistenceValue) else {
            throw .invalidOpeningBalanceAmount(persistenceValue)
        }

        self = amount
    }
}
