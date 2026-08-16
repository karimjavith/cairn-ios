//
//  RecurringTransactionRecord.swift
//  Cairn
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import SwiftData

extension CairnSchemaV1 {
    @Model
    nonisolated final class RecurringTransactionRecord {
        @Attribute(.unique) var id: UUID
        var accountID: UUID
        var direction: String
        var amount: String
        var currencyCode: String
        var frequency: String
        var startDate: Date
        var endDate: Date?
        var memo: String?

        init(
            id: UUID,
            accountID: UUID,
            direction: String,
            amount: String,
            currencyCode: String,
            frequency: String,
            startDate: Date,
            endDate: Date?,
            memo: String?
        ) {
            self.id = id
            self.accountID = accountID
            self.direction = direction
            self.amount = amount
            self.currencyCode = currencyCode
            self.frequency = frequency
            self.startDate = startDate
            self.endDate = endDate
            self.memo = memo
        }
    }
}

typealias RecurringTransactionRecord = CairnSchemaV1.RecurringTransactionRecord

extension RecurringTransactionRecord {
    convenience init(recurringTransaction: RecurringTransaction) {
        self.init(
            id: recurringTransaction.id.rawValue,
            accountID: recurringTransaction.accountID.rawValue,
            direction: recurringTransaction.direction.recurringTransactionPersistenceValue,
            amount: recurringTransaction.amount.amount.recurringTransactionPersistenceValue,
            currencyCode: recurringTransaction.amount.currencyCode,
            frequency: recurringTransaction.frequency.persistenceValue,
            startDate: recurringTransaction.startDate,
            endDate: recurringTransaction.endDate,
            memo: recurringTransaction.memo
        )
    }

    func recurringTransaction() throws -> RecurringTransaction {
        let recurringTransactionDirection = try TransactionDirection(
            recurringTransactionPersistenceValue: direction
        )
        let recurrenceFrequency = try RecurrenceFrequency(persistenceValue: frequency)
        let recurringTransactionAmount = try Decimal(
            recurringTransactionPersistenceValue: amount
        )
        let money = try Money(
            amount: recurringTransactionAmount,
            currencyCode: currencyCode
        )

        return try RecurringTransaction(
            id: RecurringTransactionID(rawValue: id),
            accountID: AccountID(rawValue: accountID),
            direction: recurringTransactionDirection,
            amount: money,
            frequency: recurrenceFrequency,
            startDate: startDate,
            endDate: endDate,
            memo: memo
        )
    }
}

nonisolated enum RecurringTransactionRecordMappingError: Error, Equatable, Sendable {
    case invalidDirection(String)
    case invalidFrequency(String)
    case invalidAmount(String)
}

private extension TransactionDirection {
    nonisolated var recurringTransactionPersistenceValue: String {
        switch self {
        case .inflow:
            "inflow"
        case .outflow:
            "outflow"
        }
    }

    nonisolated init(
        recurringTransactionPersistenceValue: String
    ) throws(RecurringTransactionRecordMappingError) {
        switch recurringTransactionPersistenceValue {
        case "inflow":
            self = .inflow
        case "outflow":
            self = .outflow
        default:
            throw .invalidDirection(recurringTransactionPersistenceValue)
        }
    }
}

private extension RecurrenceFrequency {
    nonisolated var persistenceValue: String {
        switch self {
        case .daily:
            "daily"
        case .weekly:
            "weekly"
        case .monthly:
            "monthly"
        case .yearly:
            "yearly"
        }
    }

    nonisolated init(persistenceValue: String) throws(RecurringTransactionRecordMappingError) {
        switch persistenceValue {
        case "daily":
            self = .daily
        case "weekly":
            self = .weekly
        case "monthly":
            self = .monthly
        case "yearly":
            self = .yearly
        default:
            throw .invalidFrequency(persistenceValue)
        }
    }
}

private extension Decimal {
    private nonisolated static var recurringTransactionPersistenceLocale: Locale {
        Locale(identifier: "en_US_POSIX")
    }

    private nonisolated static var recurringTransactionPersistencePattern: String {
        #"\A[+-]?(?:(?:[0-9]+(?:\.[0-9]*)?)|(?:\.[0-9]+))(?:[eE][+-]?[0-9]+)?\z"#
    }

    nonisolated var recurringTransactionPersistenceValue: String {
        NSDecimalNumber(decimal: self).stringValue
    }

    nonisolated init(
        recurringTransactionPersistenceValue: String
    ) throws(RecurringTransactionRecordMappingError) {
        guard recurringTransactionPersistenceValue.range(
            of: Self.recurringTransactionPersistencePattern,
            options: .regularExpression
        ) != nil,
            let amount = Decimal(
                string: recurringTransactionPersistenceValue,
                locale: Self.recurringTransactionPersistenceLocale
            ) else {
            throw .invalidAmount(recurringTransactionPersistenceValue)
        }

        self = amount
    }
}
