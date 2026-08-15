//
//  DashboardStoreTests.swift
//  CairnTests
//
//  Created by Codex on 15/08/2026.
//

import Foundation
import Testing
@testable import Cairn

@MainActor
struct DashboardStoreTests {
    @Test func loadsAccountBalancesAndSingleCurrencyNetWorth() async throws {
        let first = try makeAccount(name: "Checking", currencyCode: "GBP")
        let second = try makeAccount(name: "Savings", currencyCode: "GBP")
        let balanceProvider = DashboardFeatureAccountBalanceProvider(balances: [
            first.id: try money(100, "GBP"),
            second.id: try money(50, "GBP")
        ])
        let store = makeStore(
            accountRepository: DashboardFeatureAccountRepository(accounts: [first, second]),
            accountBalanceProvider: balanceProvider
        )

        await store.loadDashboard()

        let snapshot = try #require(store.snapshot)
        #expect(snapshot.accountBalances.map(\.account) == [first, second])
        #expect(snapshot.currencyTotals == [
            DashboardCurrencyTotal(currencyCode: "GBP", total: try money(150, "GBP"))
        ])
        #expect(snapshot.singleCurrencyNetWorth == (try money(150, "GBP")))
        #expect(balanceProvider.requestedAccountIDs == [first.id, second.id])
    }

    @Test func mixedCurrenciesRemainSeparatedAndDoNotCreateFakeNetWorth() async throws {
        let gbpAccount = try makeAccount(currencyCode: "GBP")
        let eurAccount = try makeAccount(currencyCode: "EUR")
        let store = makeStore(
            accountRepository: DashboardFeatureAccountRepository(accounts: [gbpAccount, eurAccount]),
            accountBalanceProvider: DashboardFeatureAccountBalanceProvider(balances: [
                gbpAccount.id: try money(100, "GBP"),
                eurAccount.id: try money(80, "EUR")
            ])
        )

        await store.loadDashboard()

        let snapshot = try #require(store.snapshot)
        #expect(snapshot.currencyTotals == [
            DashboardCurrencyTotal(currencyCode: "EUR", total: try money(80, "EUR")),
            DashboardCurrencyTotal(currencyCode: "GBP", total: try money(100, "GBP"))
        ])
        #expect(snapshot.singleCurrencyNetWorth == nil)
    }

    @Test func accountBalanceFailureSurfaces() async throws {
        let account = try makeAccount()
        let store = makeStore(
            accountRepository: DashboardFeatureAccountRepository(accounts: [account]),
            accountBalanceProvider: DashboardFeatureAccountBalanceProvider(error: DashboardFeatureError.accountBalanceFailed)
        )

        await store.loadDashboard()

        #expect(store.snapshot == nil)
        #expect(store.errorMessage != nil)
    }

    @Test func cashFlowPeriodIsDeterministicAndSummaryIsLoaded() async throws {
        let account = try makeAccount(currencyCode: "GBP")
        let cashFlowProvider = DashboardFeatureCashFlowProvider(summaries: [
            "GBP": try cashFlowSummary(
                start: utcDate(year: 2026, month: 2, day: 1),
                end: utcDate(year: 2026, month: 2, day: 15),
                currencyCode: "GBP",
                inflows: 250,
                outflows: 40
            )
        ])
        let store = makeStore(
            accountRepository: DashboardFeatureAccountRepository(accounts: [account]),
            accountBalanceProvider: DashboardFeatureAccountBalanceProvider(balances: [
                account.id: try money(100, "GBP")
            ]),
            cashFlowProvider: cashFlowProvider,
            now: { utcDate(year: 2026, month: 2, day: 15) }
        )

        await store.loadDashboard()

        let snapshot = try #require(store.snapshot)
        #expect(snapshot.cashFlowPeriod == (try CashFlowSummaryPeriod(
            start: utcDate(year: 2026, month: 2, day: 1),
            end: utcDate(year: 2026, month: 2, day: 15)
        )))
        #expect(snapshot.cashFlowSummaries.map(\.summary.totalInflows) == [try money(250, "GBP")])
        #expect(snapshot.cashFlowSummaries.map(\.summary.totalOutflows) == [try money(40, "GBP")])
        #expect(snapshot.cashFlowSummaries.map(\.summary.netCashFlow) == [try money(210, "GBP")])
        #expect(cashFlowProvider.requests == [
            DashboardFeatureCashFlowProvider.Request(
                start: utcDate(year: 2026, month: 2, day: 1),
                end: utcDate(year: 2026, month: 2, day: 15),
                currencyCode: "GBP"
            )
        ])
    }

    @Test func cashFlowFailureSurfaces() async throws {
        let account = try makeAccount(currencyCode: "GBP")
        let store = makeStore(
            accountRepository: DashboardFeatureAccountRepository(accounts: [account]),
            accountBalanceProvider: DashboardFeatureAccountBalanceProvider(balances: [
                account.id: try money(100, "GBP")
            ]),
            cashFlowProvider: DashboardFeatureCashFlowProvider(error: DashboardFeatureError.cashFlowFailed)
        )

        await store.loadDashboard()

        #expect(store.snapshot == nil)
        #expect(store.errorMessage != nil)
    }

    @Test func budgetProgressIsDerivedForMultipleBudgets() async throws {
        let groceries = try makeCategory(name: "Groceries")
        let travel = try makeCategory(name: "Travel")
        let first = try makeBudget(categoryID: groceries.id)
        let second = try makeBudget(categoryID: travel.id)
        let firstProgress = BudgetProgress(
            budget: first,
            spent: try money(10, "GBP"),
            remaining: try money(90, "GBP")
        )
        let secondProgress = BudgetProgress(
            budget: second,
            spent: try money(20, "GBP"),
            remaining: try money(80, "GBP")
        )
        let budgetProvider = DashboardFeatureBudgetProgressProvider(progressByID: [
            first.id: firstProgress,
            second.id: secondProgress
        ])
        let store = makeStore(
            budgetRepository: DashboardFeatureBudgetRepository(budgets: [first, second]),
            categoryRepository: DashboardFeatureCategoryRepository(categories: [groceries, travel]),
            budgetProgressProvider: budgetProvider
        )

        await store.loadDashboard()

        let snapshot = try #require(store.snapshot)
        #expect(snapshot.budgetProgress == [
            DashboardBudgetStatus(progress: firstProgress, categoryName: "Groceries"),
            DashboardBudgetStatus(progress: secondProgress, categoryName: "Travel")
        ])
        #expect(budgetProvider.requestedBudgetIDs == [first.id, second.id])
    }

    @Test func budgetProgressFailureSurfaces() async throws {
        let budget = try makeBudget()
        let store = makeStore(
            budgetRepository: DashboardFeatureBudgetRepository(budgets: [budget]),
            budgetProgressProvider: DashboardFeatureBudgetProgressProvider(error: DashboardFeatureError.budgetProgressFailed)
        )

        await store.loadDashboard()

        #expect(store.snapshot == nil)
        #expect(store.errorMessage != nil)
    }

    @Test func goalProgressIncludesCompletedAndInProgressStates() async throws {
        let completed = try makeGoal(name: "Completed", target: 100, current: 100)
        let inProgress = try makeGoal(name: "In Progress", target: 100, current: 40)
        let goalProvider = DashboardFeatureGoalProgressProvider()
        let store = makeStore(
            goalRepository: DashboardFeatureGoalRepository(goals: [completed, inProgress]),
            goalProgressProvider: goalProvider
        )

        await store.loadDashboard()

        let snapshot = try #require(store.snapshot)
        #expect(snapshot.goalProgress.map(\.progress.goal) == [completed, inProgress])
        #expect(snapshot.goalProgress.map(\.progress.isCompleted) == [true, false])
        #expect(goalProvider.requestedGoalIDs == [completed.id, inProgress.id])
    }

    @Test func goalProgressFailureSurfaces() async throws {
        let goal = try makeGoal()
        let store = makeStore(
            goalRepository: DashboardFeatureGoalRepository(goals: [goal]),
            goalProgressProvider: DashboardFeatureGoalProgressProvider(error: DashboardFeatureError.goalProgressFailed)
        )

        await store.loadDashboard()

        #expect(store.snapshot == nil)
        #expect(store.errorMessage != nil)
    }

    @Test func recentTransactionsUseRepositoryOrderingAndPresentationLimit() async throws {
        let account = try makeAccount(name: "Everyday")
        let transactions = try (0..<7).map { index in
            try makeTransaction(
                accountID: account.id,
                occurredAt: utcDate(year: 2026, month: 2, day: 14 - index),
                memo: "Transaction \(index)"
            )
        }
        let store = makeStore(
            accountRepository: DashboardFeatureAccountRepository(accounts: [account]),
            transactionRepository: DashboardFeatureTransactionRepository(transactions: transactions),
            accountBalanceProvider: DashboardFeatureAccountBalanceProvider(balances: [
                account.id: try money(100, "GBP")
            ]),
            recentTransactionLimit: 5
        )

        await store.loadDashboard()

        let snapshot = try #require(store.snapshot)
        #expect(snapshot.recentTransactions.map { $0.transaction } == Array(transactions.prefix(5)))
        #expect(snapshot.recentTransactions.map { $0.accountName } == Array(repeating: "Everyday", count: 5))
    }

    @Test func emptyRepositoriesProduceValidEmptyDashboard() async {
        let store = makeStore()

        await store.loadDashboard()

        let snapshot = store.snapshot
        #expect(snapshot != nil)
        #expect(snapshot?.accountBalances == [])
        #expect(snapshot?.currencyTotals == [])
        #expect(snapshot?.singleCurrencyNetWorth == nil)
        #expect(snapshot?.cashFlowSummaries == [])
        #expect(snapshot?.budgetProgress == [])
        #expect(snapshot?.goalProgress == [])
        #expect(snapshot?.recentTransactions == [])
        #expect(store.errorMessage == nil)
        #expect(store.hasLoadedEmptyDashboard)
    }

    @Test func repositoryFailureDoesNotBecomeFakeZeroData() async {
        let store = makeStore(
            accountRepository: DashboardFeatureAccountRepository(fetchError: DashboardFeatureError.repositoryFailed)
        )

        await store.loadDashboard()

        #expect(store.snapshot == nil)
        #expect(store.errorMessage != nil)
    }

    @Test func dashboardTabRemainsRootDashboardDestination() {
        #expect(AppTab.allCases.first == .dashboard)
        #expect(AppTab.dashboard.title == "Dashboard")
    }

    private func makeStore(
        accountRepository: DashboardFeatureAccountRepository = DashboardFeatureAccountRepository(),
        budgetRepository: DashboardFeatureBudgetRepository = DashboardFeatureBudgetRepository(),
        goalRepository: DashboardFeatureGoalRepository = DashboardFeatureGoalRepository(),
        categoryRepository: DashboardFeatureCategoryRepository = DashboardFeatureCategoryRepository(),
        transactionRepository: DashboardFeatureTransactionRepository = DashboardFeatureTransactionRepository(),
        accountBalanceProvider: DashboardFeatureAccountBalanceProvider = DashboardFeatureAccountBalanceProvider(),
        budgetProgressProvider: DashboardFeatureBudgetProgressProvider = DashboardFeatureBudgetProgressProvider(),
        goalProgressProvider: DashboardFeatureGoalProgressProvider = DashboardFeatureGoalProgressProvider(),
        cashFlowProvider: DashboardFeatureCashFlowProvider = DashboardFeatureCashFlowProvider(),
        now: @escaping @MainActor @Sendable () -> Date = { utcDate(year: 2026, month: 2, day: 15) },
        recentTransactionLimit: Int = 5
    ) -> DashboardStore {
        DashboardStore(
            accountRepository: accountRepository,
            budgetRepository: budgetRepository,
            goalRepository: goalRepository,
            categoryRepository: categoryRepository,
            transactionRepository: transactionRepository,
            calculateAccountBalance: { accountID in
                try await accountBalanceProvider.balance(for: accountID)
            },
            calculateBudgetProgress: { budgetID in
                try await budgetProgressProvider.progress(for: budgetID)
            },
            calculateGoalProgress: { goal in
                try goalProgressProvider.progress(for: goal)
            },
            calculateCashFlowSummary: { start, end, currencyCode in
                try await cashFlowProvider.summary(start: start, end: end, currencyCode: currencyCode)
            },
            calendar: fixedCalendar(),
            now: now,
            recentTransactionLimit: recentTransactionLimit
        )
    }
}

private final class DashboardFeatureAccountBalanceProvider: @unchecked Sendable {
    private let balances: [AccountID: Money]
    private let error: Error?
    private(set) var requestedAccountIDs: [AccountID] = []

    init(balances: [AccountID: Money] = [:], error: Error? = nil) {
        self.balances = balances
        self.error = error
    }

    func balance(for accountID: AccountID) async throws -> Money {
        requestedAccountIDs.append(accountID)

        if let error {
            throw error
        }

        if let balance = balances[accountID] {
            return balance
        }

        return try money(0, "GBP")
    }
}

private final class DashboardFeatureBudgetProgressProvider: @unchecked Sendable {
    private let progressByID: [BudgetID: BudgetProgress]
    private let error: Error?
    private(set) var requestedBudgetIDs: [BudgetID] = []

    init(progressByID: [BudgetID: BudgetProgress] = [:], error: Error? = nil) {
        self.progressByID = progressByID
        self.error = error
    }

    func progress(for budgetID: BudgetID) async throws -> BudgetProgress {
        requestedBudgetIDs.append(budgetID)

        if let error {
            throw error
        }

        if let progress = progressByID[budgetID] {
            return progress
        }

        let budget = try makeBudget(id: budgetID)
        return BudgetProgress(
            budget: budget,
            spent: try money(0, "GBP"),
            remaining: budget.limit
        )
    }
}

private final class DashboardFeatureGoalProgressProvider: @unchecked Sendable {
    private let error: Error?
    private(set) var requestedGoalIDs: [GoalID] = []

    init(error: Error? = nil) {
        self.error = error
    }

    func progress(for goal: Goal) throws -> GoalProgress {
        requestedGoalIDs.append(goal.id)

        if let error {
            throw error
        }

        return try CalculateGoalProgress()(goal: goal)
    }
}

private final class DashboardFeatureCashFlowProvider: @unchecked Sendable {
    struct Request: Equatable {
        let start: Date
        let end: Date
        let currencyCode: String
    }

    private let summaries: [String: CashFlowSummary]
    private let error: Error?
    private(set) var requests: [Request] = []

    init(summaries: [String: CashFlowSummary] = [:], error: Error? = nil) {
        self.summaries = summaries
        self.error = error
    }

    func summary(start: Date, end: Date, currencyCode: String) async throws -> CashFlowSummary {
        requests.append(Request(start: start, end: end, currencyCode: currencyCode))

        if let error {
            throw error
        }

        if let summary = summaries[currencyCode] {
            return summary
        }

        return try cashFlowSummary(
            start: start,
            end: end,
            currencyCode: currencyCode,
            inflows: 0,
            outflows: 0
        )
    }
}

private actor DashboardFeatureAccountRepository: AccountRepository {
    private let accounts: [Account]
    private let fetchError: Error?

    init(accounts: [Account] = [], fetchError: Error? = nil) {
        self.accounts = accounts
        self.fetchError = fetchError
    }

    func fetchAccounts() async throws -> [Account] {
        if let fetchError {
            throw fetchError
        }

        return accounts
    }

    func fetchAccount(id: AccountID) async throws -> Account? {
        accounts.first { $0.id == id }
    }

    func save(_ account: Account) async throws {}

    func deleteAccount(id: AccountID) async throws {}
}

private actor DashboardFeatureBudgetRepository: BudgetRepository {
    private let budgets: [Budget]
    private let fetchError: Error?

    init(budgets: [Budget] = [], fetchError: Error? = nil) {
        self.budgets = budgets
        self.fetchError = fetchError
    }

    func fetchBudgets() async throws -> [Budget] {
        if let fetchError {
            throw fetchError
        }

        return budgets
    }

    func fetchBudget(id: BudgetID) async throws -> Budget? {
        budgets.first { $0.id == id }
    }

    func save(_ budget: Budget) async throws {}

    func deleteBudget(id: BudgetID) async throws {}
}

private actor DashboardFeatureGoalRepository: GoalRepository {
    private let goals: [Goal]
    private let fetchError: Error?

    init(goals: [Goal] = [], fetchError: Error? = nil) {
        self.goals = goals
        self.fetchError = fetchError
    }

    func fetchGoals() async throws -> [Goal] {
        if let fetchError {
            throw fetchError
        }

        return goals
    }

    func fetchGoal(id: GoalID) async throws -> Goal? {
        goals.first { $0.id == id }
    }

    func save(_ goal: Goal) async throws {}

    func deleteGoal(id: GoalID) async throws {}
}

private actor DashboardFeatureCategoryRepository: CategoryRepository {
    private let categories: [Cairn.Category]
    private let fetchError: Error?

    init(categories: [Cairn.Category] = [], fetchError: Error? = nil) {
        self.categories = categories
        self.fetchError = fetchError
    }

    func fetchCategories() async throws -> [Cairn.Category] {
        if let fetchError {
            throw fetchError
        }

        return categories
    }

    func fetchCategory(id: CategoryID) async throws -> Cairn.Category? {
        categories.first { $0.id == id }
    }

    func save(_ category: Cairn.Category) async throws {}

    func deleteCategory(id: CategoryID) async throws {}
}

private actor DashboardFeatureTransactionRepository: TransactionRepository {
    private let transactions: [Transaction]
    private let fetchError: Error?

    init(transactions: [Transaction] = [], fetchError: Error? = nil) {
        self.transactions = transactions
        self.fetchError = fetchError
    }

    func fetchTransactions(accountID: AccountID) async throws -> [Transaction] {
        transactions.filter { $0.accountID == accountID }
    }

    func fetchTransactions(categoryID: CategoryID) async throws -> [Transaction] {
        transactions.filter { $0.categoryID == categoryID }
    }

    func fetchTransactions(occurredFrom start: Date, occurredBefore end: Date) async throws -> [Transaction] {
        if let fetchError {
            throw fetchError
        }

        return transactions
    }

    func fetchTransaction(id: TransactionID) async throws -> Transaction? {
        transactions.first { $0.id == id }
    }

    func save(_ transaction: Transaction) async throws {}

    func deleteTransaction(id: TransactionID) async throws {}
}

private enum DashboardFeatureError: Error {
    case repositoryFailed
    case accountBalanceFailed
    case budgetProgressFailed
    case goalProgressFailed
    case cashFlowFailed
}

private func makeAccount(
    name: String = "Everyday",
    currencyCode: String = "GBP"
) throws -> Account {
    try Account(
        name: name,
        type: .checking,
        currencyCode: currencyCode,
        openingBalance: money(0, currencyCode)
    )
}

private func makeCategory(name: String = "Groceries") throws -> Cairn.Category {
    try Cairn.Category(name: name, kind: .expense)
}

private func makeBudget(
    id: BudgetID = BudgetID(),
    categoryID: CategoryID = CategoryID()
) throws -> Budget {
    try Budget(
        id: id,
        categoryID: categoryID,
        limit: money(100, "GBP"),
        period: BudgetPeriod(
            startDate: utcDate(year: 2026, month: 2, day: 1),
            endDate: utcDate(year: 2026, month: 3, day: 1)
        )
    )
}

private func makeGoal(
    name: String = "Emergency Fund",
    target: Decimal = 100,
    current: Decimal = 10
) throws -> Goal {
    try Goal(
        name: name,
        targetAmount: money(target, "GBP"),
        currentAmount: money(current, "GBP")
    )
}

private func makeTransaction(
    accountID: AccountID = AccountID(),
    direction: TransactionDirection = .outflow,
    amount: Money? = nil,
    occurredAt: Date = utcDate(year: 2026, month: 2, day: 10),
    memo: String? = nil
) throws -> Transaction {
    try Transaction(
        accountID: accountID,
        direction: direction,
        amount: amount ?? money(10, "GBP"),
        occurredAt: occurredAt,
        memo: memo
    )
}

private func cashFlowSummary(
    start: Date,
    end: Date,
    currencyCode: String,
    inflows: Decimal,
    outflows: Decimal
) throws -> CashFlowSummary {
    let inflowMoney = try money(inflows, currencyCode)
    let outflowMoney = try money(outflows, currencyCode)

    return try CashFlowSummary(
        period: CashFlowSummaryPeriod(start: start, end: end),
        totalInflows: inflowMoney,
        totalOutflows: outflowMoney,
        netCashFlow: inflowMoney.subtracting(outflowMoney)
    )
}

private func money(_ amount: Decimal, _ currencyCode: String) throws -> Money {
    try Money(amount: amount, currencyCode: currencyCode)
}

private func utcDate(year: Int, month: Int, day: Int) -> Date {
    var components = DateComponents()
    components.calendar = fixedCalendar()
    components.timeZone = TimeZone(secondsFromGMT: 0)!
    components.year = year
    components.month = month
    components.day = day

    return components.date!
}

private func fixedCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
}
