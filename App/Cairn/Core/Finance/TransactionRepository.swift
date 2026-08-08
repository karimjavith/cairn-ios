//
//  TransactionRepository.swift
//  Cairn
//
//  Created by Karim Sheikh on 08/08/2026.
//

protocol TransactionRepository: Sendable {
    func fetchTransactions(accountID: AccountID) async throws -> [Transaction]
    func fetchTransaction(id: TransactionID) async throws -> Transaction?
    func save(_ transaction: Transaction) async throws
    func deleteTransaction(id: TransactionID) async throws
}
