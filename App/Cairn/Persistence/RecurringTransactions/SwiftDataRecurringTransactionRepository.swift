//
//  SwiftDataRecurringTransactionRepository.swift
//  Cairn
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import SwiftData

@ModelActor
actor SwiftDataRecurringTransactionRepository: RecurringTransactionRepository {

    func fetchRecurringTransactions() async throws -> [RecurringTransaction] {
        var descriptor = FetchDescriptor<RecurringTransactionRecord>()
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor)
            .map { try $0.recurringTransaction() }
            .sortedByRecurringTransactionOrdering()
    }

    func fetchRecurringTransaction(id: RecurringTransactionID) async throws -> RecurringTransaction? {
        try fetchRecord(id: id)?.recurringTransaction()
    }

    func save(_ recurringTransaction: RecurringTransaction) async throws {
        if let existingRecord = try fetchRecord(id: recurringTransaction.id) {
            existingRecord.applyPersistedValues(from: recurringTransaction)
        } else {
            modelContext.insert(RecurringTransactionRecord(recurringTransaction: recurringTransaction))
        }

        try modelContext.save()
    }

    func deleteRecurringTransaction(id: RecurringTransactionID) async throws {
        guard let record = try fetchRecord(id: id) else {
            return
        }

        modelContext.delete(record)
        try modelContext.save()
    }

    private func fetchRecord(id: RecurringTransactionID) throws -> RecurringTransactionRecord? {
        let rawID = id.rawValue
        var descriptor = FetchDescriptor<RecurringTransactionRecord>(
            predicate: #Predicate { record in
                record.id == rawID
            }
        )
        descriptor.fetchLimit = 1
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor).first
    }
}

private extension Array where Element == RecurringTransaction {
    func sortedByRecurringTransactionOrdering() -> [RecurringTransaction] {
        sorted { lhs, rhs in
            if lhs.startDate != rhs.startDate {
                return lhs.startDate < rhs.startDate
            }

            switch (lhs.endDate, rhs.endDate) {
            case let (lhsDate?, rhsDate?) where lhsDate != rhsDate:
                return lhsDate < rhsDate
            case (.some, nil):
                return true
            case (nil, .some):
                return false
            default:
                return lhs.id.rawValue.uuidString < rhs.id.rawValue.uuidString
            }
        }
    }
}

private extension RecurringTransactionRecord {
    func applyPersistedValues(from recurringTransaction: RecurringTransaction) {
        let updatedRecord = RecurringTransactionRecord(recurringTransaction: recurringTransaction)

        id = updatedRecord.id
        accountID = updatedRecord.accountID
        direction = updatedRecord.direction
        amount = updatedRecord.amount
        currencyCode = updatedRecord.currencyCode
        frequency = updatedRecord.frequency
        startDate = updatedRecord.startDate
        endDate = updatedRecord.endDate
        memo = updatedRecord.memo
    }
}
