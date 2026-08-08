//
//  TransactionRecord.swift
//  Cairn
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import SwiftData

@Model
nonisolated final class TransactionRecord {
    @Attribute(.unique) var id: UUID
    var accountID: UUID
    var direction: String
    var amount: String
    var currencyCode: String
    var occurredAt: Date
    var memo: String?

    init(
        id: UUID,
        accountID: UUID,
        direction: String,
        amount: String,
        currencyCode: String,
        occurredAt: Date,
        memo: String?
    ) {
        self.id = id
        self.accountID = accountID
        self.direction = direction
        self.amount = amount
        self.currencyCode = currencyCode
        self.occurredAt = occurredAt
        self.memo = memo
    }
}

extension TransactionRecord {
    convenience init(transaction: Transaction) {
        self.init(
            id: transaction.id.rawValue,
            accountID: transaction.accountID.rawValue,
            direction: transaction.direction.persistenceValue,
            amount: transaction.amount.amount.persistenceValue,
            currencyCode: transaction.amount.currencyCode,
            occurredAt: transaction.occurredAt,
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
            let amount = Decimal(string: transactionPersistenceValue) else {
            throw .invalidAmount(transactionPersistenceValue)
        }

        self = amount
    }
}
