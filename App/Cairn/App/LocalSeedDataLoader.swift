//
//  LocalSeedDataLoader.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import Foundation

nonisolated struct LocalSeedDataConfiguration: Equatable, Sendable {
    static let launchArgument = "--cairn-load-local-seed-data"
    static let environmentKey = "CAIRN_LOAD_LOCAL_SEED_DATA"
    static let repositoryRelativePath = "Local/SeedData/cairn-seed.json"

    nonisolated enum State: Equatable, Sendable {
        case enabled(URL)
        case disabled(LocalSeedDataSkipReason)
    }

    let state: State

    static func resolve(
        arguments: [String],
        environment: [String: String],
        isDebugBuild: Bool,
        repositoryRoot: URL
    ) -> LocalSeedDataConfiguration {
        guard isDebugBuild else {
            return LocalSeedDataConfiguration(state: .disabled(.releaseBuild))
        }

        let launchArgumentEnabled = arguments.contains(launchArgument)
        let environmentEnabled = environment[environmentKey] == "1"

        guard launchArgumentEnabled || environmentEnabled else {
            return LocalSeedDataConfiguration(state: .disabled(.optInNotRequested))
        }

        return LocalSeedDataConfiguration(
            state: .enabled(repositoryRoot.appending(path: repositoryRelativePath))
        )
    }
}

nonisolated enum LocalSeedDataSkipReason: Equatable, Sendable {
    case optInNotRequested
    case releaseBuild
}

nonisolated enum LocalSeedDataLoadResult: Equatable, Sendable {
    case skipped(LocalSeedDataSkipReason)
    case seeded(LocalSeedDataSummary)
}

nonisolated struct LocalSeedDataSummary: Equatable, Sendable {
    let accounts: Int
    let categories: Int
    let transactions: Int
    let budgets: Int
    let goals: Int
    let recurringTransactions: Int
}

nonisolated enum LocalSeedDataError: Error, Equatable, Sendable {
    case missingFile(URL)
    case unsupportedVersion(Int)
    case decodeFailed
    case invalidDomainData
    case storeNotEmpty
}

nonisolated struct LocalSeedDataLoader: Sendable {
    private let accountRepository: any AccountRepository
    private let categoryRepository: any CategoryRepository
    private let transactionRepository: any TransactionRepository
    private let budgetRepository: any BudgetRepository
    private let goalRepository: any GoalRepository
    private let recurringTransactionRepository: any RecurringTransactionRepository
    private let readData: @Sendable (URL) throws -> Data

    init(
        accountRepository: any AccountRepository,
        categoryRepository: any CategoryRepository,
        transactionRepository: any TransactionRepository,
        budgetRepository: any BudgetRepository,
        goalRepository: any GoalRepository,
        recurringTransactionRepository: any RecurringTransactionRepository,
        readData: @escaping @Sendable (URL) throws -> Data = { url in
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw LocalSeedDataError.missingFile(url)
            }

            return try Data(contentsOf: url)
        }
    ) {
        self.accountRepository = accountRepository
        self.categoryRepository = categoryRepository
        self.transactionRepository = transactionRepository
        self.budgetRepository = budgetRepository
        self.goalRepository = goalRepository
        self.recurringTransactionRepository = recurringTransactionRepository
        self.readData = readData
    }

    func loadIfNeeded(configuration: LocalSeedDataConfiguration) async throws -> LocalSeedDataLoadResult {
        switch configuration.state {
        case let .disabled(reason):
            return .skipped(reason)
        case let .enabled(url):
            let data = try readData(url)
            let seed = try Self.decode(data)
            return .seeded(try await seedStore(with: seed))
        }
    }

    static func decode(_ data: Data) throws -> LocalSeedData {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let document = try decoder.decode(LocalSeedDataDocument.self, from: data)

            guard document.schemaVersion == 1 else {
                throw LocalSeedDataError.unsupportedVersion(document.schemaVersion)
            }

            return try document.makeSeedData()
        } catch let error as LocalSeedDataError {
            throw error
        } catch is DecodingError {
            throw LocalSeedDataError.decodeFailed
        } catch {
            throw LocalSeedDataError.invalidDomainData
        }
    }

    private func seedStore(with seed: LocalSeedData) async throws -> LocalSeedDataSummary {
        guard try await isStoreEmpty() else {
            throw LocalSeedDataError.storeNotEmpty
        }

        for account in seed.accounts {
            try await accountRepository.save(account)
        }

        for category in seed.categories {
            try await categoryRepository.save(category)
        }

        for transaction in seed.transactions {
            try await transactionRepository.save(transaction)
        }

        for budget in seed.budgets {
            try await budgetRepository.save(budget)
        }

        for goal in seed.goals {
            try await goalRepository.save(goal)
        }

        for recurringTransaction in seed.recurringTransactions {
            try await recurringTransactionRepository.save(recurringTransaction)
        }

        return LocalSeedDataSummary(
            accounts: seed.accounts.count,
            categories: seed.categories.count,
            transactions: seed.transactions.count,
            budgets: seed.budgets.count,
            goals: seed.goals.count,
            recurringTransactions: seed.recurringTransactions.count
        )
    }

    private func isStoreEmpty() async throws -> Bool {
        let transactions = try await transactionRepository.fetchTransactions(
            occurredFrom: .distantPast,
            occurredBefore: .distantFuture
        )
        let accounts = try await accountRepository.fetchAccounts()
        let categories = try await categoryRepository.fetchCategories()
        let budgets = try await budgetRepository.fetchBudgets()
        let goals = try await goalRepository.fetchGoals()
        let recurringTransactions = try await recurringTransactionRepository.fetchRecurringTransactions()

        return accounts.isEmpty
            && categories.isEmpty
            && transactions.isEmpty
            && budgets.isEmpty
            && goals.isEmpty
            && recurringTransactions.isEmpty
    }
}

nonisolated struct LocalSeedData: Equatable, Sendable {
    let accounts: [Account]
    let categories: [Category]
    let transactions: [Transaction]
    let budgets: [Budget]
    let goals: [Goal]
    let recurringTransactions: [RecurringTransaction]
}

private nonisolated struct LocalSeedDataDocument: Decodable {
    let schemaVersion: Int
    let accounts: [SeedAccount]
    let categories: [SeedCategory]
    let transactions: [SeedTransaction]
    let budgets: [SeedBudget]
    let goals: [SeedGoal]
    let recurringTransactions: [SeedRecurringTransaction]

    func makeSeedData() throws -> LocalSeedData {
        let domainAccounts = try accounts.map { try $0.makeAccount() }
        let domainCategories = try categories.map { try $0.makeCategory() }
        let accountIDs = Set(domainAccounts.map(\.id))
        let categoryIDs = Set(domainCategories.map(\.id))

        let domainTransactions = try transactions.map {
            try $0.makeTransaction(accountIDs: accountIDs, categoryIDs: categoryIDs)
        }
        let domainBudgets = try budgets.map {
            try $0.makeBudget(categoryIDs: categoryIDs)
        }
        let domainGoals = try goals.map { try $0.makeGoal() }
        let domainRecurringTransactions = try recurringTransactions.map {
            try $0.makeRecurringTransaction(accountIDs: accountIDs)
        }

        return LocalSeedData(
            accounts: domainAccounts,
            categories: domainCategories,
            transactions: domainTransactions,
            budgets: domainBudgets,
            goals: domainGoals,
            recurringTransactions: domainRecurringTransactions
        )
    }
}

private nonisolated struct SeedAccount: Decodable {
    let id: UUID
    let name: String
    let type: String
    let currencyCode: String
    let openingBalance: Decimal

    func makeAccount() throws -> Account {
        let money = try Money(amount: openingBalance, currencyCode: currencyCode)

        return try Account(
            id: AccountID(rawValue: id),
            name: name,
            type: try AccountType(seedValue: type),
            currencyCode: currencyCode,
            openingBalance: money
        )
    }
}

private nonisolated struct SeedCategory: Decodable {
    let id: UUID
    let name: String
    let kind: String

    func makeCategory() throws -> Category {
        try Category(
            id: CategoryID(rawValue: id),
            name: name,
            kind: try CategoryKind(seedValue: kind)
        )
    }
}

private nonisolated struct SeedTransaction: Decodable {
    let id: UUID
    let accountID: UUID
    let direction: String
    let amount: Decimal
    let currencyCode: String
    let occurredAt: Date
    let categoryID: UUID?
    let memo: String?

    func makeTransaction(accountIDs: Set<AccountID>, categoryIDs: Set<CategoryID>) throws -> Transaction {
        let accountID = AccountID(rawValue: accountID)
        let categoryID = categoryID.map(CategoryID.init(rawValue:))

        guard accountIDs.contains(accountID) else {
            throw LocalSeedDataError.invalidDomainData
        }

        if let categoryID, !categoryIDs.contains(categoryID) {
            throw LocalSeedDataError.invalidDomainData
        }

        return try Transaction(
            id: TransactionID(rawValue: id),
            accountID: accountID,
            direction: try TransactionDirection(seedValue: direction),
            amount: Money(amount: amount, currencyCode: currencyCode),
            occurredAt: occurredAt,
            categoryID: categoryID,
            memo: memo
        )
    }
}

private nonisolated struct SeedBudget: Decodable {
    let id: UUID
    let categoryID: UUID
    let limit: Decimal
    let currencyCode: String
    let period: BudgetPeriod

    func makeBudget(categoryIDs: Set<CategoryID>) throws -> Budget {
        let categoryID = CategoryID(rawValue: categoryID)

        guard categoryIDs.contains(categoryID) else {
            throw LocalSeedDataError.invalidDomainData
        }

        return try Budget(
            id: BudgetID(rawValue: id),
            categoryID: categoryID,
            limit: Money(amount: limit, currencyCode: currencyCode),
            period: period
        )
    }
}

private nonisolated struct SeedGoal: Decodable {
    let id: UUID
    let name: String
    let targetAmount: Decimal
    let targetCurrencyCode: String
    let currentAmount: Decimal
    let currentCurrencyCode: String
    let targetDate: Date?

    func makeGoal() throws -> Goal {
        try Goal(
            id: GoalID(rawValue: id),
            name: name,
            targetAmount: Money(amount: targetAmount, currencyCode: targetCurrencyCode),
            currentAmount: Money(amount: currentAmount, currencyCode: currentCurrencyCode),
            targetDate: targetDate
        )
    }
}

private nonisolated struct SeedRecurringTransaction: Decodable {
    let id: UUID
    let accountID: UUID
    let direction: String
    let amount: Decimal
    let currencyCode: String
    let frequency: String
    let startDate: Date
    let endDate: Date?
    let memo: String?

    func makeRecurringTransaction(accountIDs: Set<AccountID>) throws -> RecurringTransaction {
        let accountID = AccountID(rawValue: accountID)

        guard accountIDs.contains(accountID) else {
            throw LocalSeedDataError.invalidDomainData
        }

        return try RecurringTransaction(
            id: RecurringTransactionID(rawValue: id),
            accountID: accountID,
            direction: try TransactionDirection(seedValue: direction),
            amount: Money(amount: amount, currencyCode: currencyCode),
            frequency: try RecurrenceFrequency(seedValue: frequency),
            startDate: startDate,
            endDate: endDate,
            memo: memo
        )
    }
}

private nonisolated extension AccountType {
    init(seedValue: String) throws {
        switch seedValue {
        case "checking":
            self = .checking
        case "savings":
            self = .savings
        case "creditCard":
            self = .creditCard
        case "cash":
            self = .cash
        case "investment":
            self = .investment
        case "loan":
            self = .loan
        default:
            throw LocalSeedDataError.invalidDomainData
        }
    }
}

private nonisolated extension CategoryKind {
    init(seedValue: String) throws {
        switch seedValue {
        case "income":
            self = .income
        case "expense":
            self = .expense
        default:
            throw LocalSeedDataError.invalidDomainData
        }
    }
}

private nonisolated extension TransactionDirection {
    init(seedValue: String) throws {
        switch seedValue {
        case "inflow":
            self = .inflow
        case "outflow":
            self = .outflow
        default:
            throw LocalSeedDataError.invalidDomainData
        }
    }
}

private nonisolated extension RecurrenceFrequency {
    init(seedValue: String) throws {
        switch seedValue {
        case "daily":
            self = .daily
        case "weekly":
            self = .weekly
        case "monthly":
            self = .monthly
        case "yearly":
            self = .yearly
        default:
            throw LocalSeedDataError.invalidDomainData
        }
    }
}

nonisolated enum LocalSeedDataBootstrap {
    static func configuration(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        isDebugBuild: Bool,
        repositoryRoot: URL = defaultRepositoryRoot()
    ) -> LocalSeedDataConfiguration {
        LocalSeedDataConfiguration.resolve(
            arguments: arguments,
            environment: environment,
            isDebugBuild: isDebugBuild,
            repositoryRoot: repositoryRoot
        )
    }

    static func run(
        loader: LocalSeedDataLoader,
        arguments: [String] = ProcessInfo.processInfo.arguments,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        isDebugBuild: Bool,
        repositoryRoot: URL = defaultRepositoryRoot()
    ) async throws -> LocalSeedDataLoadResult {
        let configuration = configuration(
            arguments: arguments,
            environment: environment,
            isDebugBuild: isDebugBuild,
            repositoryRoot: repositoryRoot
        )

        return try await loader.loadIfNeeded(configuration: configuration)
    }

    static func defaultRepositoryRoot(filePath: String = #filePath) -> URL {
        let url = URL(filePath: filePath)
        let appDirectory = url.deletingLastPathComponent()

        return appDirectory
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
