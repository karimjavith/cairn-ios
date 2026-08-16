//
//  TransactionRecord.swift
//  Cairn
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import SwiftData

extension CairnSchemaV1 {
    @Model
    nonisolated final class TransactionRecord {
        @Attribute(.unique) var id: UUID
        var accountID: UUID
        var direction: String
        var amount: String
        var currencyCode: String
        var occurredAt: Date
        var categoryID: UUID?
        var memo: String?

        init(
            id: UUID,
            accountID: UUID,
            direction: String,
            amount: String,
            currencyCode: String,
            occurredAt: Date,
            categoryID: UUID? = nil,
            memo: String?
        ) {
            self.id = id
            self.accountID = accountID
            self.direction = direction
            self.amount = amount
            self.currencyCode = currencyCode
            self.occurredAt = occurredAt
            self.categoryID = categoryID
            self.memo = memo
        }
    }
}

typealias TransactionRecord = CairnSchemaV1.TransactionRecord

extension TransactionRecord {
    convenience init(transaction: Transaction) {
        self.init(
            id: transaction.id.rawValue,
            accountID: transaction.accountID.rawValue,
            direction: transaction.direction.persistenceValue,
            amount: transaction.amount.amount.persistenceValue,
            currencyCode: transaction.amount.currencyCode,
            occurredAt: transaction.occurredAt,
            categoryID: transaction.categoryID?.rawValue,
            memo: transaction.memo
        )
    }

    func transaction() throws -> Transaction {
        let transactionDirection = try TransactionDirection(persistenceValue: direction)
        let transactionAmount = try Decimal(transactionPersistenceValue: amount)
        let money = try Money(
            amount: transactionAmount,
            currencyCode: currencyCode
        )

        return try Transaction(
            id: TransactionID(rawValue: id),
            accountID: AccountID(rawValue: accountID),
            direction: transactionDirection,
            amount: money,
            occurredAt: occurredAt,
            categoryID: categoryID.map(CategoryID.init(rawValue:)),
            memo: memo
        )
    }
}

nonisolated enum TransactionRecordMappingError: Error, Equatable, Sendable {
    case invalidDirection(String)
    case invalidAmount(String)
}

private extension TransactionDirection {
    nonisolated var persistenceValue: String {
        switch self {
        case .inflow:
            "inflow"
        case .outflow:
            "outflow"
        }
    }

    nonisolated init(persistenceValue: String) throws(TransactionRecordMappingError) {
        switch persistenceValue {
        case "inflow":
            self = .inflow
        case "outflow":
            self = .outflow
        default:
            throw .invalidDirection(persistenceValue)
        }
    }
}

private extension Decimal {
    private nonisolated static var transactionPersistenceLocale: Locale {
        Locale(identifier: "en_US_POSIX")
    }

    private nonisolated static var transactionPersistencePattern: String {
        #"\A[+-]?(?:(?:[0-9]+(?:\.[0-9]*)?)|(?:\.[0-9]+))(?:[eE][+-]?[0-9]+)?\z"#
    }

    nonisolated var persistenceValue: String {
        NSDecimalNumber(decimal: self).stringValue
    }

    nonisolated init(transactionPersistenceValue: String) throws(TransactionRecordMappingError) {
        guard transactionPersistenceValue.range(
            of: Self.transactionPersistencePattern,
            options: .regularExpression
        ) != nil,
            let amount = Decimal(
                string: transactionPersistenceValue,
                locale: Self.transactionPersistenceLocale
            ) else {
            throw .invalidAmount(transactionPersistenceValue)
        }

        self = amount
    }
}
