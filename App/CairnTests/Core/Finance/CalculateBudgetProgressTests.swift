//
//  CalculateBudgetProgressTests.swift
//  CairnTests
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import Testing
@testable import Cairn

struct CalculateBudgetProgressTests {

    @Test func noTransactionsReturnsZeroSpentAndFullRemaining() async throws {
        let budget = try makeBudget(limit: Money(amount: 250, currencyCode: "GBP"))
        let progress = try await makeCalculator(budget: budget)(budgetID: budget.id)

        #expect(progress.budget == budget)
        try expectMoney(progress.spent, amount: 0, currencyCode: "GBP")
        #expect(progress.remaining == budget.limit)
    }

    @Test func singleQualifyingOutflowContributesToSpent() async throws {
        let budget = try makeBudget(limit: Money(amount: 100, currencyCode: "GBP"))
        let transaction = try makeTransaction(
            direction: .outflow,
            amount: Money(amount: 30, currencyCode: "GBP"),
            occurredAt: date(1_500),
            categoryID: budget.categoryID
        )

        let progress = try await makeCalculator(budget: budget, transactions: [transaction])(budgetID: budget.id)

        try expectMoney(progress.spent, amount: 30, currencyCode: "GBP")
        try expectMoney(progress.remaining, amount: 70, currencyCode: "GBP")
    }

    @Test func multipleQualifyingOutflowsAggregate() async throws {
        let budget = try makeBudget(limit: Money(amount: 100, currencyCode: "GBP"))
        let transactions = try [
            makeTransaction(amount: Money(amount: 12.30, currencyCode: "GBP"), categoryID: budget.categoryID),
            makeTransaction(amount: Money(amount: 7.70, currencyCode: "GBP"), categoryID: budget.categoryID),
            makeTransaction(amount: Money(amount: 10, currencyCode: "GBP"), categoryID: budget.categoryID)
        ]

        let progress = try await makeCalculator(budget: budget, transactions: transactions)(budgetID: budget.id)

        try expectMoney(progress.spent, amount: 30, currencyCode: "GBP")
        try expectMoney(progress.remaining, amount: 70, currencyCode: "GBP")
    }

    @Test func exactDecimalPrecisionIsPreserved() async throws {
        let limit = try Money(amount: decimal("1.000000000000000006"), currencyCode: "GBP")
        let budget = try makeBudget(limit: limit)
        let transactions = try [
            makeTransaction(amount: Money(amount: decimal("0.000000000000000001"), currencyCode: "GBP"), categoryID: budget.categoryID),
            makeTransaction(amount: Money(amount: decimal("0.000000000000000002"), currencyCode: "GBP"), categoryID: budget.categoryID),
            makeTransaction(amount: Money(amount: decimal("0.000000000000000003"), currencyCode: "GBP"), categoryID: budget.categoryID)
        ]

        let progress = try await makeCalculator(budget: budget, transactions: transactions)(budgetID: budget.id)

        try expectMoney(progress.spent, amount: decimal("0.000000000000000006"), currencyCode: "GBP")
        try expectMoney(progress.remaining, amount: decimal("1.000000000000000000"), currencyCode: "GBP")
    }

    @Test func matchingCategoryInflowDoesNotContribute() async throws {
        let budget = try makeBudget(limit: Money(amount: 100, currencyCode: "GBP"))
        let inflow = try makeTransaction(
            direction: .inflow,
            amount: Money(amount: 40, currencyCode: "GBP"),
            categoryID: budget.categoryID
        )

        let progress = try await makeCalculator(budget: budget, transactions: [inflow])(budgetID: budget.id)

        try expectMoney(progress.spent, amount: 0, currencyCode: "GBP")
        try expectMoney(progress.remaining, amount: 100, currencyCode: "GBP")
    }

    @Test func fetchesTransactionsForBudgetCategory() async throws {
        let budget = try makeBudget()
        let transactionRepository = InMemoryBudgetProgressTransactionRepository()
        let calculator = CalculateBudgetProgress(
            budgetRepository: InMemoryBudgetProgressBudgetRepository(budgets: [budget]),
            transactionRepository: transactionRepository
        )

        _ = try await calculator(budgetID: budget.id)

        #expect(await transactionRepository.fetchedCategoryIDs() == [budget.categoryID])
    }

    @Test func repositoryCategoryFilteringYieldsOnlyMatchingCategoryTransactions() async throws {
        let budget = try makeBudget(limit: Money(amount: 100, currencyCode: "GBP"))
        let otherCategoryID = CategoryID()
        let matching = try makeTransaction(amount: Money(amount: 20, currencyCode: "GBP"), categoryID: budget.categoryID)
        let nonMatching = try makeTransaction(amount: Money(amount: 90, currencyCode: "GBP"), categoryID: otherCategoryID)
        let repository = InMemoryBudgetProgressTransactionRepository(transactions: [matching, nonMatching])

        let progress = try await CalculateBudgetProgress(
            budgetRepository: InMemoryBudgetProgressBudgetRepository(budgets: [budget]),
            transactionRepository: repository
        )(budgetID: budget.id)

        try expectMoney(progress.spent, amount: 20, currencyCode: "GBP")
    }

    @Test func defensivelyIgnoresNonMatchingCategoryTransactionReturnedByRepository() async throws {
        let budget = try makeBudget(limit: Money(amount: 100, currencyCode: "GBP"))
        let nonMatching = try makeTransaction(amount: Money(amount: 90, currencyCode: "GBP"), categoryID: CategoryID())

        let progress = try await makeCalculator(
            budget: budget,
            transactions: [nonMatching],
            filtersByCategory: false
        )(budgetID: budget.id)

        try expectMoney(progress.spent, amount: 0, currencyCode: "GBP")
        try expectMoney(progress.remaining, amount: 100, currencyCode: "GBP")
    }

    @Test func uncategorizedTransactionDoesNotContribute() async throws {
        let budget = try makeBudget(limit: Money(amount: 100, currencyCode: "GBP"))
        let transaction = try makeTransaction(amount: Money(amount: 50, currencyCode: "GBP"), categoryID: nil)

        let progress = try await makeCalculator(
            budget: budget,
            transactions: [transaction],
            filtersByCategory: false
        )(budgetID: budget.id)

        try expectMoney(progress.spent, amount: 0, currencyCode: "GBP")
    }

    @Test func beforeStartDoesNotContribute() async throws {
        let budget = try makeBudget(limit: Money(amount: 100, currencyCode: "GBP"))
        let transaction = try makeTransaction(
            amount: Money(amount: 10, currencyCode: "GBP"),
            occurredAt: date(999),
            categoryID: budget.categoryID
        )

        let progress = try await makeCalculator(budget: budget, transactions: [transaction])(budgetID: budget.id)

        try expectMoney(progress.spent, amount: 0, currencyCode: "GBP")
    }

    @Test func exactlyStartContributes() async throws {
        let budget = try makeBudget(limit: Money(amount: 100, currencyCode: "GBP"))
        let transaction = try makeTransaction(
            amount: Money(amount: 10, currencyCode: "GBP"),
            occurredAt: budget.period.startDate,
            categoryID: budget.categoryID
        )

        let progress = try await makeCalculator(budget: budget, transactions: [transaction])(budgetID: budget.id)

        try expectMoney(progress.spent, amount: 10, currencyCode: "GBP")
    }

    @Test func insidePeriodContributes() async throws {
        let budget = try makeBudget(limit: Money(amount: 100, currencyCode: "GBP"))
        let transaction = try makeTransaction(
            amount: Money(amount: 10, currencyCode: "GBP"),
            occurredAt: date(1_500),
            categoryID: budget.categoryID
        )

        let progress = try await makeCalculator(budget: budget, transactions: [transaction])(budgetID: budget.id)

        try expectMoney(progress.spent, amount: 10, currencyCode: "GBP")
    }

    @Test func exactlyEndDoesNotContribute() async throws {
        let budget = try makeBudget(limit: Money(amount: 100, currencyCode: "GBP"))
        let transaction = try makeTransaction(
            amount: Money(amount: 10, currencyCode: "GBP"),
            occurredAt: budget.period.endDate,
            categoryID: budget.categoryID
        )

        let progress = try await makeCalculator(budget: budget, transactions: [transaction])(budgetID: budget.id)

        try expectMoney(progress.spent, amount: 0, currencyCode: "GBP")
    }

    @Test func afterEndDoesNotContribute() async throws {
        let budget = try makeBudget(limit: Money(amount: 100, currencyCode: "GBP"))
        let transaction = try makeTransaction(
            amount: Money(amount: 10, currencyCode: "GBP"),
            occurredAt: date(2_001),
            categoryID: budget.categoryID
        )

        let progress = try await makeCalculator(budget: budget, transactions: [transaction])(budgetID: budget.id)

        try expectMoney(progress.spent, amount: 0, currencyCode: "GBP")
    }

    @Test func qualifyingMatchingCurrencySucceeds() async throws {
        let budget = try makeBudget(limit: Money(amount: 100, currencyCode: "gbp"))
        let transaction = try makeTransaction(
            amount: Money(amount: 10, currencyCode: " GBP\n"),
            categoryID: budget.categoryID
        )

        let progress = try await makeCalculator(budget: budget, transactions: [transaction])(budgetID: budget.id)

        try expectMoney(progress.spent, amount: 10, currencyCode: "GBP")
    }

    @Test func qualifyingMismatchedCurrencyFailsExplicitly() async throws {
        let budget = try makeBudget(limit: Money(amount: 100, currencyCode: "GBP"))
        let transactions = try [
            makeTransaction(amount: Money(amount: 10, currencyCode: "GBP"), categoryID: budget.categoryID),
            makeTransaction(amount: Money(amount: 5, currencyCode: "EUR"), categoryID: budget.categoryID)
        ]

        do {
            _ = try await makeCalculator(budget: budget, transactions: transactions)(budgetID: budget.id)
            Issue.record("Expected qualifying mismatched transaction currency to fail.")
        } catch let error as CalculateBudgetProgress.Error {
            #expect(
                error == .transactionCurrencyMismatch(
                    budgetCurrencyCode: "GBP",
                    transactionCurrencyCode: "EUR"
                )
            )
        }
    }

    @Test func nonQualifyingMismatchedCurrencyDoesNotFail() async throws {
        let budget = try makeBudget(limit: Money(amount: 100, currencyCode: "GBP"))
        let transactions = try [
            makeTransaction(direction: .inflow, amount: Money(amount: 5, currencyCode: "EUR"), categoryID: budget.categoryID),
            makeTransaction(amount: Money(amount: 5, currencyCode: "EUR"), occurredAt: date(999), categoryID: budget.categoryID),
            makeTransaction(amount: Money(amount: 5, currencyCode: "EUR"), categoryID: CategoryID()),
            makeTransaction(amount: Money(amount: 20, currencyCode: "GBP"), categoryID: budget.categoryID)
        ]

        let progress = try await makeCalculator(
            budget: budget,
            transactions: transactions,
            filtersByCategory: false
        )(budgetID: budget.id)

        try expectMoney(progress.spent, amount: 20, currencyCode: "GBP")
        try expectMoney(progress.remaining, amount: 80, currencyCode: "GBP")
    }

    @Test func mismatchedCurrencyReturnsNoPartialResult() async throws {
        let budget = try makeBudget(limit: Money(amount: 100, currencyCode: "GBP"))
        let transactions = try [
            makeTransaction(amount: Money(amount: 10, currencyCode: "GBP"), categoryID: budget.categoryID),
            makeTransaction(amount: Money(amount: 5, currencyCode: "EUR"), categoryID: budget.categoryID),
            makeTransaction(amount: Money(amount: 20, currencyCode: "GBP"), categoryID: budget.categoryID)
        ]

        do {
            _ = try await makeCalculator(budget: budget, transactions: transactions)(budgetID: budget.id)
            Issue.record("Expected mismatched transaction currency to fail before returning progress.")
        } catch let error as CalculateBudgetProgress.Error {
            #expect(
                error == .transactionCurrencyMismatch(
                    budgetCurrencyCode: "GBP",
                    transactionCurrencyCode: "EUR"
                )
            )
        }
    }

    @Test func partialSpendProducesCorrectRemaining() async throws {
        let budget = try makeBudget(limit: Money(amount: 75, currencyCode: "GBP"))
        let transaction = try makeTransaction(amount: Money(amount: 25, currencyCode: "GBP"), categoryID: budget.categoryID)

        let progress = try await makeCalculator(budget: budget, transactions: [transaction])(budgetID: budget.id)

        try expectMoney(progress.remaining, amount: 50, currencyCode: "GBP")
    }

    @Test func exactLimitSpendProducesZeroRemaining() async throws {
        let budget = try makeBudget(limit: Money(amount: 75, currencyCode: "GBP"))
        let transaction = try makeTransaction(amount: Money(amount: 75, currencyCode: "GBP"), categoryID: budget.categoryID)

        let progress = try await makeCalculator(budget: budget, transactions: [transaction])(budgetID: budget.id)

        try expectMoney(progress.spent, amount: 75, currencyCode: "GBP")
        try expectMoney(progress.remaining, amount: 0, currencyCode: "GBP")
    }

    @Test func overspendProducesNegativeRemaining() async throws {
        let budget = try makeBudget(limit: Money(amount: 75, currencyCode: "GBP"))
        let transaction = try makeTransaction(amount: Money(amount: 100, currencyCode: "GBP"), categoryID: budget.categoryID)

        let progress = try await makeCalculator(budget: budget, transactions: [transaction])(budgetID: budget.id)

        try expectMoney(progress.spent, amount: 100, currencyCode: "GBP")
        try expectMoney(progress.remaining, amount: -25, currencyCode: "GBP")
    }

    @Test func missingBudgetFailsExplicitly() async throws {
        let missingBudgetID = BudgetID(rawValue: try #require(UUID(uuidString: "62DCD8C9-B1CF-4301-9359-A52067591D2E")))
        let transactionRepository = InMemoryBudgetProgressTransactionRepository()
        let calculator = CalculateBudgetProgress(
            budgetRepository: InMemoryBudgetProgressBudgetRepository(),
            transactionRepository: transactionRepository
        )

        do {
            _ = try await calculator(budgetID: missingBudgetID)
            Issue.record("Expected missing budget to fail.")
        } catch let error as CalculateBudgetProgress.Error {
            #expect(error == .budgetNotFound(missingBudgetID))
        }

        #expect(await transactionRepository.fetchTransactionsCallCount() == 0)
    }

    @Test func budgetRepositoryFailurePropagatesUnchanged() async throws {
        let transactionRepository = InMemoryBudgetProgressTransactionRepository()
        let calculator = CalculateBudgetProgress(
            budgetRepository: InMemoryBudgetProgressBudgetRepository(fetchError: BudgetProgressRepositoryError.fetchFailed),
            transactionRepository: transactionRepository
        )

        do {
            _ = try await calculator(budgetID: BudgetID())
            Issue.record("Expected budget repository failure to propagate.")
        } catch let error as BudgetProgressRepositoryError {
            #expect(error == .fetchFailed)
        }

        #expect(await transactionRepository.fetchTransactionsCallCount() == 0)
    }

    @Test func transactionRepositoryFailurePropagatesUnchanged() async throws {
        let budget = try makeBudget()
        let calculator = CalculateBudgetProgress(
            budgetRepository: InMemoryBudgetProgressBudgetRepository(budgets: [budget]),
            transactionRepository: InMemoryBudgetProgressTransactionRepository(fetchError: BudgetProgressRepositoryError.fetchFailed)
        )

        do {
            _ = try await calculator(budgetID: budget.id)
            Issue.record("Expected transaction repository failure to propagate.")
        } catch let error as BudgetProgressRepositoryError {
            #expect(error == .fetchFailed)
        }
    }

    @Test func transactionOrderingDoesNotAffectResult() async throws {
        let budget = try makeBudget(limit: Money(amount: 100, currencyCode: "GBP"))
        let transactions = try [
            makeTransaction(amount: Money(amount: 12.34, currencyCode: "GBP"), categoryID: budget.categoryID),
            makeTransaction(amount: Money(amount: 20, currencyCode: "GBP"), categoryID: budget.categoryID),
            makeTransaction(amount: Money(amount: 7.66, currencyCode: "GBP"), categoryID: budget.categoryID)
        ]
        let forward = try await makeCalculator(budget: budget, transactions: transactions)(budgetID: budget.id)
        let reversed = try await makeCalculator(budget: budget, transactions: Array(transactions.reversed()))(budgetID: budget.id)

        try expectMoney(forward.spent, amount: 40, currencyCode: "GBP")
        #expect(reversed == forward)
    }

    @Test func zeroLimitWithNoQualifyingSpendReturnsZeroSpentAndRemaining() async throws {
        let budget = try makeBudget(limit: Money(amount: 0, currencyCode: "GBP"))

        let progress = try await makeCalculator(budget: budget)(budgetID: budget.id)

        try expectMoney(progress.spent, amount: 0, currencyCode: "GBP")
        try expectMoney(progress.remaining, amount: 0, currencyCode: "GBP")
    }

    @Test func zeroLimitWithQualifyingSpendProducesNegativeRemaining() async throws {
        let budget = try makeBudget(limit: Money(amount: 0, currencyCode: "GBP"))
        let transaction = try makeTransaction(amount: Money(amount: 10, currencyCode: "GBP"), categoryID: budget.categoryID)

        let progress = try await makeCalculator(budget: budget, transactions: [transaction])(budgetID: budget.id)

        try expectMoney(progress.spent, amount: 10, currencyCode: "GBP")
        try expectMoney(progress.remaining, amount: -10, currencyCode: "GBP")
    }

    @Test func budgetProgressResultIsSendable() throws {
        let budget = try makeBudget()
        let progress = BudgetProgress(
            budget: budget,
            spent: try Money(amount: 0, currencyCode: "GBP"),
            remaining: budget.limit
        )

        requireSendable(progress)
    }

    @Test func calculateBudgetProgressIsSendable() throws {
        let calculator = CalculateBudgetProgress(
            budgetRepository: InMemoryBudgetProgressBudgetRepository(),
            transactionRepository: InMemoryBudgetProgressTransactionRepository()
        )

        requireSendable(calculator)
    }

    private func makeCalculator(
        budget: Budget,
        transactions: [Transaction] = [],
        filtersByCategory: Bool = true
    ) -> CalculateBudgetProgress {
        CalculateBudgetProgress(
            budgetRepository: InMemoryBudgetProgressBudgetRepository(budgets: [budget]),
            transactionRepository: InMemoryBudgetProgressTransactionRepository(
                transactions: transactions,
                filtersByCategory: filtersByCategory
            )
        )
    }

    private func makeBudget(
        id: BudgetID? = nil,
        categoryID: CategoryID? = nil,
        limit: Money? = nil,
        period: BudgetPeriod? = nil
    ) throws -> Budget {
        try Budget(
            id: id ?? BudgetID(rawValue: try #require(UUID(uuidString: "EE0827E9-637E-44C3-BAFD-0E411863E665"))),
            categoryID: categoryID ?? CategoryID(rawValue: try #require(UUID(uuidString: "55770C2B-E982-4C41-9F1F-C2628369F8C8"))),
            limit: limit ?? Money(amount: 100, currencyCode: "GBP"),
            period: period ?? BudgetPeriod(startDate: date(1_000), endDate: date(2_000))
        )
    }

    private func makeTransaction(
        direction: TransactionDirection = .outflow,
        amount: Money,
        occurredAt: Date = Date(timeIntervalSince1970: 1_500),
        categoryID: CategoryID?
    ) throws -> Transaction {
        try Transaction(
            accountID: AccountID(),
            direction: direction,
            amount: amount,
            occurredAt: occurredAt,
            categoryID: categoryID
        )
    }

    private func date(_ timeIntervalSince1970: TimeInterval) -> Date {
        Date(timeIntervalSince1970: timeIntervalSince1970)
    }

    private func decimal(_ value: String) throws -> Decimal {
        try #require(Decimal(string: value))
    }

    private func expectMoney(
        _ actual: Money,
        amount: Decimal,
        currencyCode: String,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        let expected = try Money(amount: amount, currencyCode: currencyCode)

        #expect(actual == expected, sourceLocation: sourceLocation)
    }

    private func requireSendable<T: Sendable>(_ value: T) {
        _ = value
    }
}

private enum BudgetProgressRepositoryError: Error, Equatable, Sendable {
    case fetchFailed
}

private actor InMemoryBudgetProgressBudgetRepository: BudgetRepository {
    private var budgets: [BudgetID: Budget]
    private let fetchError: BudgetProgressRepositoryError?

    init(budgets: [Budget] = [], fetchError: BudgetProgressRepositoryError? = nil) {
        self.budgets = Dictionary(uniqueKeysWithValues: budgets.map { ($0.id, $0) })
        self.fetchError = fetchError
    }

    func fetchBudgets() async throws -> [Budget] {
        if let fetchError {
            throw fetchError
        }

        return Array(budgets.values)
    }

    func fetchBudget(id: BudgetID) async throws -> Budget? {
        if let fetchError {
            throw fetchError
        }

        return budgets[id]
    }

    func save(_ budget: Budget) async throws {
        budgets[budget.id] = budget
    }

    func deleteBudget(id: BudgetID) async throws {
        budgets[id] = nil
    }
}

private actor InMemoryBudgetProgressTransactionRepository: TransactionRepository {
    private var transactions: [Transaction]
    private var fetchTransactionsCount = 0
    private var categoryIDs: [CategoryID] = []
    private let fetchError: BudgetProgressRepositoryError?
    private let filtersByCategory: Bool

    init(
        transactions: [Transaction] = [],
        fetchError: BudgetProgressRepositoryError? = nil,
        filtersByCategory: Bool = true
    ) {
        self.transactions = transactions
        self.fetchError = fetchError
        self.filtersByCategory = filtersByCategory
    }

    func fetchTransactions(accountID: AccountID) async throws -> [Transaction] {
        if let fetchError {
            throw fetchError
        }

        return transactions.filter { $0.accountID == accountID }
    }

    func fetchTransactions(categoryID: CategoryID) async throws -> [Transaction] {
        fetchTransactionsCount += 1
        categoryIDs.append(categoryID)

        if let fetchError {
            throw fetchError
        }

        guard filtersByCategory else {
            return transactions
        }

        return transactions.filter { $0.categoryID == categoryID }
    }

    func fetchTransactions(occurredFrom start: Date, occurredBefore end: Date) async throws -> [Transaction] {
        if let fetchError {
            throw fetchError
        }

        guard start < end else {
            throw TransactionRepositoryError.invalidDateRange
        }

        return transactions.filter { start <= $0.occurredAt && $0.occurredAt < end }
    }

    func fetchTransaction(id: TransactionID) async throws -> Transaction? {
        transactions.first { $0.id == id }
    }

    func save(_ transaction: Transaction) async throws {
        transactions.append(transaction)
    }

    func deleteTransaction(id: TransactionID) async throws {
        transactions.removeAll { $0.id == id }
    }

    func fetchTransactionsCallCount() -> Int {
        fetchTransactionsCount
    }

    func fetchedCategoryIDs() -> [CategoryID] {
        categoryIDs
    }
}
