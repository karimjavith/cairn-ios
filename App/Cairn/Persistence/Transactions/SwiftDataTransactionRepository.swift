//
//  SwiftDataTransactionRepository.swift
//  Cairn
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import SwiftData

@ModelActor
actor SwiftDataTransactionRepository: TransactionRepository {

    func fetchTransactions(accountID: AccountID) async throws -> [Transaction] {
        let rawAccountID = accountID.rawValue
        var descriptor = FetchDescriptor<TransactionRecord>(
            predicate: #Predicate { record in
                record.accountID == rawAccountID
            },
            sortBy: [
                SortDescriptor(\.occurredAt, order: .reverse),
                SortDescriptor(\.id)
            ]
        )
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor).map { try $0.transaction() }
    }

    func fetchTransactions(categoryID: CategoryID) async throws -> [Transaction] {
        let rawCategoryID = Optional(categoryID.rawValue)
        var descriptor = FetchDescriptor<TransactionRecord>(
            predicate: #Predicate { record in
                record.categoryID == rawCategoryID
            },
            sortBy: [
                SortDescriptor(\.occurredAt, order: .reverse),
                SortDescriptor(\.id)
            ]
        )
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor).map { try $0.transaction() }
    }

    func fetchTransaction(id: TransactionID) async throws -> Transaction? {
        try fetchRecord(id: id)?.transaction()
    }

    func save(_ transaction: Transaction) async throws {
        if let existingRecord = try fetchRecord(id: transaction.id) {
            existingRecord.applyPersistedValues(from: transaction)
        } else {
            modelContext.insert(TransactionRecord(transaction: transaction))
        }

        try modelContext.save()
    }

    func deleteTransaction(id: TransactionID) async throws {
        guard let record = try fetchRecord(id: id) else {
            return
        }

        modelContext.delete(record)
        try modelContext.save()
    }

    private func fetchRecord(id: TransactionID) throws -> TransactionRecord? {
        let rawID = id.rawValue
        var descriptor = FetchDescriptor<TransactionRecord>(
            predicate: #Predicate { record in
                record.id == rawID
            }
        )
        descriptor.fetchLimit = 1
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor).first
    }
}

private extension TransactionRecord {
    func applyPersistedValues(from transaction: Transaction) {
        let updatedRecord = TransactionRecord(transaction: transaction)

        id = updatedRecord.id
        accountID = updatedRecord.accountID
        direction = updatedRecord.direction
        amount = updatedRecord.amount
        currencyCode = updatedRecord.currencyCode
        occurredAt = updatedRecord.occurredAt
        categoryID = updatedRecord.categoryID
        memo = updatedRecord.memo
    }
}
