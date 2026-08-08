//
//  RecurringTransactionRepository.swift
//  Cairn
//
//  Created by Karim Sheikh on 08/08/2026.
//

protocol RecurringTransactionRepository: Sendable {
    func fetchRecurringTransactions() async throws -> [RecurringTransaction]
    func fetchRecurringTransaction(id: RecurringTransactionID) async throws -> RecurringTransaction?
    func save(_ recurringTransaction: RecurringTransaction) async throws
    func deleteRecurringTransaction(id: RecurringTransactionID) async throws
}
