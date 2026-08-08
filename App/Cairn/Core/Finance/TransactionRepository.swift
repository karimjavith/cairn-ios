//
//  TransactionRepository.swift
//  Cairn
//
//  Created by Karim Sheikh on 08/08/2026.
//

import Foundation

protocol TransactionRepository: Sendable {
    func fetchTransactions(accountID: AccountID) async throws -> [Transaction]
    func fetchTransactions(categoryID: CategoryID) async throws -> [Transaction]
    func fetchTransactions(occurredFrom start: Date, occurredBefore end: Date) async throws -> [Transaction]
    func fetchTransaction(id: TransactionID) async throws -> Transaction?
    func save(_ transaction: Transaction) async throws
    func deleteTransaction(id: TransactionID) async throws
}

nonisolated enum TransactionRepositoryError: Error, Equatable, Sendable {
    case invalidDateRange
}
