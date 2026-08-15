//
//  DashboardStore.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import Foundation
import Observation

typealias DashboardAccountBalanceProvider = @Sendable (AccountID) async throws -> Money
typealias DashboardBudgetProgressProvider = @Sendable (BudgetID) async throws -> BudgetProgress
typealias DashboardGoalProgressProvider = @Sendable (Goal) throws -> GoalProgress
typealias DashboardCashFlowSummaryProvider = @Sendable (Date, Date, String) async throws -> CashFlowSummary

@MainActor
@Observable
final class DashboardStore {
    private let accountRepository: any AccountRepository
    private let budgetRepository: any BudgetRepository
    private let goalRepository: any GoalRepository
    private let categoryRepository: any CategoryRepository
    private let transactionRepository: any TransactionRepository
    private let calculateAccountBalance: DashboardAccountBalanceProvider
    private let calculateBudgetProgress: DashboardBudgetProgressProvider
    private let calculateGoalProgress: DashboardGoalProgressProvider
    private let calculateCashFlowSummary: DashboardCashFlowSummaryProvider
    private let calendar: Calendar
    private let now: @MainActor @Sendable () -> Date
    private let recentTransactionLimit: Int

    private(set) var snapshot: DashboardSnapshot?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    init(
        accountRepository: any AccountRepository,
        budgetRepository: any BudgetRepository,
        goalRepository: any GoalRepository,
        categoryRepository: any CategoryRepository,
        transactionRepository: any TransactionRepository,
        calculateAccountBalance: @escaping DashboardAccountBalanceProvider,
        calculateBudgetProgress: @escaping DashboardBudgetProgressProvider,
        calculateGoalProgress: @escaping DashboardGoalProgressProvider,
        calculateCashFlowSummary: @escaping DashboardCashFlowSummaryProvider,
        calendar: Calendar,
        now: @escaping @MainActor @Sendable () -> Date = { Date() },
        recentTransactionLimit: Int = 5
    ) {
        self.accountRepository = accountRepository
        self.budgetRepository = budgetRepository
        self.goalRepository = goalRepository
        self.categoryRepository = categoryRepository
        self.transactionRepository = transactionRepository
        self.calculateAccountBalance = calculateAccountBalance
        self.calculateBudgetProgress = calculateBudgetProgress
        self.calculateGoalProgress = calculateGoalProgress
        self.calculateCashFlowSummary = calculateCashFlowSummary
        self.calendar = calendar
        self.now = now
        self.recentTransactionLimit = recentTransactionLimit
    }

    var hasLoadedEmptyDashboard: Bool {
        guard let snapshot else {
            return false
        }

        return snapshot.accountBalances.isEmpty
            && snapshot.budgetProgress.isEmpty
            && snapshot.goalProgress.isEmpty
            && snapshot.recentTransactions.isEmpty
    }

    func loadDashboard() async {
        isLoading = true
        errorMessage = nil

        do {
            let referenceDate = now()
            let period = try currentMonthPeriod(containing: referenceDate)
            let accounts = try await accountRepository.fetchAccounts()
            let budgets = try await budgetRepository.fetchBudgets()
            let goals = try await goalRepository.fetchGoals()
            let categories = try await categoryRepository.fetchCategories()
            let categoryNamesByID = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.name) })

            let accountBalances = try await loadAccountBalances(accounts)
            let currencyTotals = try totalsByCurrency(accountBalances)
            let cashFlowSummaries = try await loadCashFlowSummaries(
                period: period,
                currencyCodes: currencyTotals.map(\.currencyCode)
            )
            let transactions = try await transactionRepository.fetchTransactions(
                occurredFrom: period.start,
                occurredBefore: period.end
            )
            let recentTransactions = transactions.prefix(recentTransactionLimit).map { transaction in
                DashboardRecentTransaction(
                    transaction: transaction,
                    accountName: accountName(for: transaction.accountID, accounts: accounts)
                )
            }
            let budgetProgress = try await loadBudgetProgress(
                budgets,
                categoryNamesByID: categoryNamesByID
            )
            let goalProgress = try loadGoalProgress(goals)

            snapshot = DashboardSnapshot(
                accountBalances: accountBalances,
                currencyTotals: currencyTotals,
                singleCurrencyNetWorth: currencyTotals.count == 1 ? currencyTotals.first?.total : nil,
                cashFlowPeriod: period,
                cashFlowSummaries: cashFlowSummaries,
                budgetProgress: budgetProgress,
                goalProgress: goalProgress,
                recentTransactions: recentTransactions
            )
            isLoading = false
        } catch {
            snapshot = nil
            isLoading = false
            errorMessage = "Dashboard could not be loaded."
        }
    }

    private func currentMonthPeriod(containing referenceDate: Date) throws -> CashFlowSummaryPeriod {
        guard let start = calendar.dateInterval(of: .month, for: referenceDate)?.start else {
            throw DashboardStoreError.periodUnavailable
        }

        return try CashFlowSummaryPeriod(start: start, end: referenceDate)
    }

    private func loadAccountBalances(_ accounts: [Account]) async throws -> [DashboardAccountBalance] {
        var balances: [DashboardAccountBalance] = []

        for account in accounts {
            balances.append(DashboardAccountBalance(
                account: account,
                balance: try await calculateAccountBalance(account.id)
            ))
        }

        return balances
    }

    private func totalsByCurrency(_ balances: [DashboardAccountBalance]) throws -> [DashboardCurrencyTotal] {
        var totals: [String: Money] = [:]

        for balance in balances {
            let currencyCode = balance.balance.currencyCode

            if let total = totals[currencyCode] {
                totals[currencyCode] = try total.adding(balance.balance)
            } else {
                totals[currencyCode] = balance.balance
            }
        }

        return totals.keys.sorted().compactMap { currencyCode in
            totals[currencyCode].map {
                DashboardCurrencyTotal(currencyCode: currencyCode, total: $0)
            }
        }
    }

    private func loadCashFlowSummaries(
        period: CashFlowSummaryPeriod,
        currencyCodes: [String]
    ) async throws -> [DashboardCashFlow] {
        var summaries: [DashboardCashFlow] = []

        for currencyCode in currencyCodes.sorted() {
            summaries.append(DashboardCashFlow(
                summary: try await calculateCashFlowSummary(
                    period.start,
                    period.end,
                    currencyCode
                )
            ))
        }

        return summaries
    }

    private func loadBudgetProgress(
        _ budgets: [Budget],
        categoryNamesByID: [CategoryID: String]
    ) async throws -> [DashboardBudgetStatus] {
        var statuses: [DashboardBudgetStatus] = []

        for budget in budgets {
            statuses.append(DashboardBudgetStatus(
                progress: try await calculateBudgetProgress(budget.id),
                categoryName: categoryNamesByID[budget.categoryID] ?? "Unknown Category"
            ))
        }

        return statuses
    }

    private func loadGoalProgress(_ goals: [Goal]) throws -> [DashboardGoalStatus] {
        try goals.map { goal in
            DashboardGoalStatus(progress: try calculateGoalProgress(goal))
        }
    }

    private func accountName(for accountID: AccountID, accounts: [Account]) -> String {
        accounts.first { $0.id == accountID }?.name ?? "Unknown Account"
    }
}

nonisolated struct DashboardSnapshot: Equatable, Sendable {
    let accountBalances: [DashboardAccountBalance]
    let currencyTotals: [DashboardCurrencyTotal]
    let singleCurrencyNetWorth: Money?
    let cashFlowPeriod: CashFlowSummaryPeriod
    let cashFlowSummaries: [DashboardCashFlow]
    let budgetProgress: [DashboardBudgetStatus]
    let goalProgress: [DashboardGoalStatus]
    let recentTransactions: [DashboardRecentTransaction]
}

nonisolated struct DashboardAccountBalance: Equatable, Sendable {
    let account: Account
    let balance: Money
}

nonisolated struct DashboardCurrencyTotal: Equatable, Sendable {
    let currencyCode: String
    let total: Money
}

nonisolated struct DashboardCashFlow: Equatable, Sendable {
    let summary: CashFlowSummary
}

nonisolated struct DashboardBudgetStatus: Equatable, Sendable {
    let progress: BudgetProgress
    let categoryName: String
}

nonisolated struct DashboardGoalStatus: Equatable, Sendable {
    let progress: GoalProgress
}

nonisolated struct DashboardRecentTransaction: Equatable, Sendable {
    let transaction: Transaction
    let accountName: String
}

private enum DashboardStoreError: Error {
    case periodUnavailable
}
