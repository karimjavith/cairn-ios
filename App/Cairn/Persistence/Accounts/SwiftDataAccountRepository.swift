//
//  SwiftDataAccountRepository.swift
//  Cairn
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import SwiftData

@ModelActor
actor SwiftDataAccountRepository: AccountRepository {

    func fetchAccounts() async throws -> [Account] {
        var descriptor = FetchDescriptor<AccountRecord>(
            sortBy: [
                SortDescriptor(\.name),
                SortDescriptor(\.id)
            ]
        )
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor).map { try $0.account() }
    }

    func fetchAccount(id: AccountID) async throws -> Account? {
        try fetchRecord(id: id)?.account()
    }

    func save(_ account: Account) async throws {
        if let existingRecord = try fetchRecord(id: account.id) {
            existingRecord.applyPersistedValues(from: account)
        } else {
            modelContext.insert(AccountRecord(account: account))
        }

        try modelContext.save()
    }

    func deleteAccount(id: AccountID) async throws {
        guard let record = try fetchRecord(id: id) else {
            return
        }

        modelContext.delete(record)
        try modelContext.save()
    }

    private func fetchRecord(id: AccountID) throws -> AccountRecord? {
        let rawID = id.rawValue
        var descriptor = FetchDescriptor<AccountRecord>(
            predicate: #Predicate { record in
                record.id == rawID
            }
        )
        descriptor.fetchLimit = 1
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor).first
    }
}

private extension AccountRecord {
    func applyPersistedValues(from account: Account) {
        let updatedRecord = AccountRecord(account: account)

        id = updatedRecord.id
        name = updatedRecord.name
        type = updatedRecord.type
        currencyCode = updatedRecord.currencyCode
        openingBalanceAmount = updatedRecord.openingBalanceAmount
    }
}
