//
//  LocalSeedDataLoaderTests.swift
//  CairnTests
//
//  Created by Codex on 15/08/2026.
//

import Foundation
import Testing
@testable import Cairn

struct LocalSeedDataLoaderTests {
    @Test func validVersionedSeedDecodesAndPreservesIDsAndRelationships() throws {
        let seed = try LocalSeedDataLoader.decode(validSeedData())

        #expect(seed.accounts.map(\.id) == [accountID])
        #expect(seed.categories.map(\.id) == [categoryID])
        #expect(seed.transactions.map(\.id) == [transactionID])
        #expect(seed.budgets.map(\.id) == [budgetID])
        #expect(seed.goals.map(\.id) == [goalID])
        #expect(seed.recurringTransactions.map(\.id) == [recurringTransactionID])
        #expect(seed.transactions.first?.accountID == accountID)
        #expect(seed.transactions.first?.categoryID == categoryID)
        #expect(seed.budgets.first?.categoryID == categoryID)
        #expect(seed.recurringTransactions.first?.accountID == accountID)
    }

    @Test func unsupportedVersionFails() throws {
        #expect(throws: LocalSeedDataError.unsupportedVersion(99)) {
            _ = try LocalSeedDataLoader.decode(validSeedData(schemaVersion: 99))
        }
    }

    @Test func malformedJSONFails() {
        #expect(throws: LocalSeedDataError.decodeFailed) {
            _ = try LocalSeedDataLoader.decode(Data("{".utf8))
        }
    }

    @Test func invalidDomainDataFails() {
        #expect(throws: LocalSeedDataError.invalidDomainData) {
            _ = try LocalSeedDataLoader.decode(validSeedData(accountCurrencyCode: "INVALID"))
        }
    }

    @Test func emptyStoreCanSeedInDependencyOrder() async throws {
        let repository = SeedDataTestRepository()
        let loader = makeLoader(repository: repository)

        let result = try await loader.loadIfNeeded(configuration: enabledConfiguration())

        #expect(result == .seeded(LocalSeedDataSummary(
            accounts: 1,
            categories: 1,
            transactions: 1,
            budgets: 1,
            goals: 1,
            recurringTransactions: 1
        )))
        #expect(await repository.saveOrder() == [
            "account",
            "category",
            "transaction",
            "budget",
            "goal",
            "recurringTransaction"
        ])
        #expect(await repository.transactions().first?.accountID == accountID)
        #expect(await repository.transactions().first?.categoryID == categoryID)
    }

    @Test func nonEmptyStoreRefusesWithoutWrites() async throws {
        let existingAccount = try Account(
            id: AccountID(),
            name: "Existing",
            type: .checking,
            currencyCode: "GBP",
            openingBalance: Money(amount: 0, currencyCode: "GBP")
        )
        let repository = SeedDataTestRepository(accounts: [existingAccount])
        let loader = makeLoader(repository: repository)

        await #expect(throws: LocalSeedDataError.storeNotEmpty) {
            _ = try await loader.loadIfNeeded(configuration: enabledConfiguration())
        }

        #expect(await repository.saveOrder() == [])
    }

    @Test func repeatedSeedAttemptDoesNotDuplicateData() async throws {
        let repository = SeedDataTestRepository()
        let loader = makeLoader(repository: repository)

        _ = try await loader.loadIfNeeded(configuration: enabledConfiguration())

        await #expect(throws: LocalSeedDataError.storeNotEmpty) {
            _ = try await loader.loadIfNeeded(configuration: enabledConfiguration())
        }

        #expect(await repository.accounts().count == 1)
        #expect(await repository.categories().count == 1)
        #expect(await repository.transactions().count == 1)
        #expect(await repository.saveOrder().count == 6)
    }

    @Test func missingLocalFileFailsWhenOptedIn() async {
        let repository = SeedDataTestRepository()
        let loader = LocalSeedDataLoader(
            accountRepository: repository,
            categoryRepository: repository,
            transactionRepository: repository,
            budgetRepository: repository,
            goalRepository: repository,
            recurringTransactionRepository: repository
        )
        let url = URL(filePath: "/tmp/cairn-missing-seed-\(UUID().uuidString).json")

        await #expect(throws: LocalSeedDataError.missingFile(url)) {
            _ = try await loader.loadIfNeeded(configuration: LocalSeedDataConfiguration(state: .enabled(url)))
        }
    }

    @Test func optInDisabledDoesNotReadOrLoad() async throws {
        let repository = SeedDataTestRepository()
        let loader = LocalSeedDataLoader(
            accountRepository: repository,
            categoryRepository: repository,
            transactionRepository: repository,
            budgetRepository: repository,
            goalRepository: repository,
            recurringTransactionRepository: repository,
            readData: { _ in
                Issue.record("Disabled seed loading should not read the local file")
                return Data()
            }
        )

        let result = try await loader.loadIfNeeded(configuration: LocalSeedDataConfiguration(
            state: .disabled(.optInNotRequested)
        ))

        #expect(result == .skipped(LocalSeedDataSkipReason.optInNotRequested))
        #expect(await repository.saveOrder() == [])
    }

    @Test func releaseConfigurationDoesNotSeedEvenWhenOptedIn() async throws {
        let repositoryRoot = URL(filePath: "/tmp/cairn")
        let configuration = LocalSeedDataConfiguration.resolve(
            arguments: [LocalSeedDataConfiguration.launchArgument],
            environment: [LocalSeedDataConfiguration.environmentKey: "1"],
            isDebugBuild: false,
            repositoryRoot: repositoryRoot
        )
        let repository = SeedDataTestRepository()
        let loader = makeLoader(repository: repository)

        let result = try await loader.loadIfNeeded(configuration: configuration)

        #expect(result == .skipped(LocalSeedDataSkipReason.releaseBuild))
        #expect(await repository.saveOrder() == [])
    }

    @Test func debugOptInUsesRepositoryRelativeSeedPath() {
        let repositoryRoot = URL(filePath: "/tmp/cairn")
        let configuration = LocalSeedDataConfiguration.resolve(
            arguments: [LocalSeedDataConfiguration.launchArgument],
            environment: [:],
            isDebugBuild: true,
            repositoryRoot: repositoryRoot
        )

        #expect(configuration == LocalSeedDataConfiguration(
            state: .enabled(repositoryRoot.appending(path: LocalSeedDataConfiguration.repositoryRelativePath))
        ))
    }

    private func makeLoader(repository: SeedDataTestRepository) -> LocalSeedDataLoader {
        LocalSeedDataLoader(
            accountRepository: repository,
            categoryRepository: repository,
            transactionRepository: repository,
            budgetRepository: repository,
            goalRepository: repository,
            recurringTransactionRepository: repository,
            readData: { _ in validSeedData() }
        )
    }
}

private let accountUUID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
private let categoryUUID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
private let transactionUUID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
private let budgetUUID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
private let goalUUID = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
private let recurringTransactionUUID = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!
private let accountID = AccountID(rawValue: accountUUID)
private let categoryID = CategoryID(rawValue: categoryUUID)
private let transactionID = TransactionID(rawValue: transactionUUID)
private let budgetID = BudgetID(rawValue: budgetUUID)
private let goalID = GoalID(rawValue: goalUUID)
private let recurringTransactionID = RecurringTransactionID(rawValue: recurringTransactionUUID)

private func validSeedData(
    schemaVersion: Int = 1,
    accountCurrencyCode: String = "GBP"
) -> Data {
    Data("""
    {
      "schemaVersion": \(schemaVersion),
      "accounts": [
        {
          "id": "\(accountUUID.uuidString)",
          "name": "Everyday",
          "type": "checking",
          "currencyCode": "\(accountCurrencyCode)",
          "openingBalance": 100.25
        }
      ],
      "categories": [
        {
          "id": "\(categoryUUID.uuidString)",
          "name": "Groceries",
          "kind": "expense"
        }
      ],
      "transactions": [
        {
          "id": "\(transactionUUID.uuidString)",
          "accountID": "\(accountUUID.uuidString)",
          "direction": "outflow",
          "amount": 12.34,
          "currencyCode": "GBP",
          "occurredAt": "2026-01-10T12:00:00Z",
          "categoryID": "\(categoryUUID.uuidString)",
          "memo": "Market"
        }
      ],
      "budgets": [
        {
          "id": "\(budgetUUID.uuidString)",
          "categoryID": "\(categoryUUID.uuidString)",
          "limit": 500,
          "currencyCode": "GBP",
          "period": {
            "startDate": "2026-01-01T00:00:00Z",
            "endDate": "2026-02-01T00:00:00Z"
          }
        }
      ],
      "goals": [
        {
          "id": "\(goalUUID.uuidString)",
          "name": "Emergency Fund",
          "targetAmount": 1000,
          "targetCurrencyCode": "GBP",
          "currentAmount": 250,
          "currentCurrencyCode": "GBP",
          "targetDate": "2026-12-31T00:00:00Z"
        }
      ],
      "recurringTransactions": [
        {
          "id": "\(recurringTransactionUUID.uuidString)",
          "accountID": "\(accountUUID.uuidString)",
          "direction": "outflow",
          "amount": 25,
          "currencyCode": "GBP",
          "frequency": "monthly",
          "startDate": "2026-01-01T09:00:00Z",
          "endDate": null,
          "memo": "Subscription"
        }
      ]
    }
    """.utf8)
}

private func enabledConfiguration() -> LocalSeedDataConfiguration {
    LocalSeedDataConfiguration(state: .enabled(URL(filePath: "/tmp/seed.json")))
}

private actor SeedDataTestRepository: AccountRepository,
    CategoryRepository,
    TransactionRepository,
    BudgetRepository,
    GoalRepository,
    RecurringTransactionRepository {
    private var storedAccounts: [Account]
    private var storedCategories: [Cairn.Category]
    private var storedTransactions: [Transaction]
    private var storedBudgets: [Budget]
    private var storedGoals: [Goal]
    private var storedRecurringTransactions: [RecurringTransaction]
    private var storedSaveOrder: [String] = []

    init(
        accounts: [Account] = [],
        categories: [Cairn.Category] = [],
        transactions: [Transaction] = [],
        budgets: [Budget] = [],
        goals: [Goal] = [],
        recurringTransactions: [RecurringTransaction] = []
    ) {
        storedAccounts = accounts
        storedCategories = categories
        storedTransactions = transactions
        storedBudgets = budgets
        storedGoals = goals
        storedRecurringTransactions = recurringTransactions
    }

    func fetchAccounts() async throws -> [Account] {
        storedAccounts
    }

    func fetchAccount(id: AccountID) async throws -> Account? {
        storedAccounts.first { $0.id == id }
    }

    func save(_ account: Account) async throws {
        storedAccounts.append(account)
        storedSaveOrder.append("account")
    }

    func deleteAccount(id: AccountID) async throws {}

    func fetchCategories() async throws -> [Cairn.Category] {
        storedCategories
    }

    func fetchCategory(id: CategoryID) async throws -> Cairn.Category? {
        storedCategories.first { $0.id == id }
    }

    func save(_ category: Cairn.Category) async throws {
        storedCategories.append(category)
        storedSaveOrder.append("category")
    }

    func deleteCategory(id: CategoryID) async throws {}

    func fetchTransactions(accountID: AccountID) async throws -> [Transaction] {
        storedTransactions.filter { $0.accountID == accountID }
    }

    func fetchTransactions(categoryID: CategoryID) async throws -> [Transaction] {
        storedTransactions.filter { $0.categoryID == categoryID }
    }

    func fetchTransactions(occurredFrom start: Date, occurredBefore end: Date) async throws -> [Transaction] {
        storedTransactions.filter { start <= $0.occurredAt && $0.occurredAt < end }
    }

    func fetchTransaction(id: TransactionID) async throws -> Transaction? {
        storedTransactions.first { $0.id == id }
    }

    func save(_ transaction: Transaction) async throws {
        storedTransactions.append(transaction)
        storedSaveOrder.append("transaction")
    }

    func deleteTransaction(id: TransactionID) async throws {}

    func fetchBudgets() async throws -> [Budget] {
        storedBudgets
    }

    func fetchBudget(id: BudgetID) async throws -> Budget? {
        storedBudgets.first { $0.id == id }
    }

    func save(_ budget: Budget) async throws {
        storedBudgets.append(budget)
        storedSaveOrder.append("budget")
    }

    func deleteBudget(id: BudgetID) async throws {}

    func fetchGoals() async throws -> [Goal] {
        storedGoals
    }

    func fetchGoal(id: GoalID) async throws -> Goal? {
        storedGoals.first { $0.id == id }
    }

    func save(_ goal: Goal) async throws {
        storedGoals.append(goal)
        storedSaveOrder.append("goal")
    }

    func deleteGoal(id: GoalID) async throws {}

    func fetchRecurringTransactions() async throws -> [RecurringTransaction] {
        storedRecurringTransactions
    }

    func fetchRecurringTransaction(id: RecurringTransactionID) async throws -> RecurringTransaction? {
        storedRecurringTransactions.first { $0.id == id }
    }

    func save(_ recurringTransaction: RecurringTransaction) async throws {
        storedRecurringTransactions.append(recurringTransaction)
        storedSaveOrder.append("recurringTransaction")
    }

    func deleteRecurringTransaction(id: RecurringTransactionID) async throws {}

    func accounts() -> [Account] {
        storedAccounts
    }

    func categories() -> [Cairn.Category] {
        storedCategories
    }

    func transactions() -> [Transaction] {
        storedTransactions
    }

    func saveOrder() -> [String] {
        storedSaveOrder
    }
}
