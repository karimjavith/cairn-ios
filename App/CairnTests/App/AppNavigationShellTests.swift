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
            categoryRepository: ShellCategoryRepository(),
            transactionRepository: ShellTransactionRepository(),
            budgetRepository: ShellBudgetRepository(),
            goalRepository: ShellGoalRepository()
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

private actor ShellCategoryRepository: CategoryRepository {
    func fetchCategories() async throws -> [Cairn.Category] {
        []
    }

    func fetchCategory(id: CategoryID) async throws -> Cairn.Category? {
        nil
    }

    func save(_ category: Cairn.Category) async throws {}

    func deleteCategory(id: CategoryID) async throws {}
}

private actor ShellBudgetRepository: BudgetRepository {
    func fetchBudgets() async throws -> [Budget] {
        []
    }

    func fetchBudget(id: BudgetID) async throws -> Budget? {
        nil
    }

    func save(_ budget: Budget) async throws {}

    func deleteBudget(id: BudgetID) async throws {}
}

private actor ShellGoalRepository: GoalRepository {
    func fetchGoals() async throws -> [Goal] {
        []
    }

    func fetchGoal(id: GoalID) async throws -> Goal? {
        nil
    }

    func save(_ goal: Goal) async throws {}

    func deleteGoal(id: GoalID) async throws {}
}
