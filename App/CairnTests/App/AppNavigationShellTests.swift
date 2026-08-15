//
//  AppNavigationShellTests.swift
//  CairnTests
//
//  Created by Codex on 15/08/2026.
//

import Foundation
import Testing
@testable import Cairn

struct AppNavigationShellTests {
    @Test func primaryDestinationsAreDeterministic() {
        #expect(AppTab.allCases.map(\.title) == [
            "Dashboard",
            "Accounts",
            "Transactions",
            "Budgets",
            "More"
        ])
    }

    @Test func moreDestinationsAreDeterministic() {
        #expect(MoreDestination.allCases.map(\.title) == [
            "Goals",
            "Categories",
            "Recurring Transactions"
        ])
    }

    @Test func rootShellCanBeConstructed() {
        _ = RootView(dependencies: AppDependencies(
            accountRepository: ShellAccountRepository(),
            transactionRepository: ShellTransactionRepository()
        ))
    }
}

private actor ShellAccountRepository: AccountRepository {
    func fetchAccounts() async throws -> [Account] {
        []
    }

    func fetchAccount(id: AccountID) async throws -> Account? {
        nil
    }

    func save(_ account: Account) async throws {}

    func deleteAccount(id: AccountID) async throws {}
}

private actor ShellTransactionRepository: TransactionRepository {
    func fetchTransactions(accountID: AccountID) async throws -> [Transaction] {
        []
    }

    func fetchTransactions(categoryID: CategoryID) async throws -> [Transaction] {
        []
    }

    func fetchTransactions(occurredFrom start: Date, occurredBefore end: Date) async throws -> [Transaction] {
        []
    }

    func fetchTransaction(id: TransactionID) async throws -> Transaction? {
        nil
    }

    func save(_ transaction: Transaction) async throws {}

    func deleteTransaction(id: TransactionID) async throws {}
}
