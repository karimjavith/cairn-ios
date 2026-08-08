//
//  CreateTransactionTests.swift
//  CairnTests
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import Testing
@testable import Cairn

struct CreateTransactionTests {

    @Test func existingAccountAllowsTransactionCreation() async throws {
        let account = try makeAccount()
        let accountRepository = InMemoryAccountRepository(accounts: [account])
        let transactionRepository = InMemoryTransactionRepository()
        let createTransaction = CreateTransaction(
            accountRepository: accountRepository,
            transactionRepository: transactionRepository
        )
        let transactionID = TransactionID(rawValue: try #require(UUID(uuidString: "36C6C328-4227-4CBA-8F29-16B5EC114286")))
        let amount = try Money(amount: 12.34, currencyCode: "GBP")
        let occurredAt = Date(timeIntervalSince1970: 1_786_080_000)

        let transaction = try await createTransaction(
            id: transactionID,
            accountID: account.id,
            direction: .outflow,
            amount: amount,
            occurredAt: occurredAt,
            memo: "  Lunch\n"
        )

        let savedTransactions = await transactionRepository.savedTransactions()
        #expect(transaction.id == transactionID)
        #expect(transaction.accountID == account.id)
        #expect(transaction.direction == .outflow)
        #expect(transaction.amount == amount)
        #expect(transaction.occurredAt == occurredAt)
        #expect(transaction.categoryID == nil)
        #expect(transaction.memo == "Lunch")
        #expect(savedTransactions == [transaction])
        #expect(savedTransactions.count == 1)
        let savedTransaction = try #require(savedTransactions.first)
        #expect(transaction == savedTransaction)
    }

    @Test func missingAccountFailsWithAccountNotFound() async throws {
        let missingAccountID = AccountID(rawValue: try #require(UUID(uuidString: "9E849395-8DC9-481A-B56F-1EC9AF46A57D")))
        let transactionRepository = InMemoryTransactionRepository()
        let createTransaction = CreateTransaction(
            accountRepository: InMemoryAccountRepository(accounts: []),
            transactionRepository: transactionRepository
        )

        do {
            _ = try await createTransaction(
                id: makeTransactionID(),
                accountID: missingAccountID,
                direction: .outflow,
                amount: Money(amount: 10, currencyCode: "GBP"),
                occurredAt: Date(timeIntervalSince1970: 1_786_080_000)
            )
            Issue.record("Expected missing account to fail.")
        } catch let error as CreateTransaction.Error {
            #expect(error == .accountNotFound(missingAccountID))
        }

        #expect(await transactionRepository.savedTransactions() == [])
    }

    @Test func matchingCurrencySucceedsWithNormalizedCurrencySemantics() async throws {
        let account = try makeAccount(currencyCode: " gbp\n")
        let transactionRepository = InMemoryTransactionRepository()
        let createTransaction = CreateTransaction(
            accountRepository: InMemoryAccountRepository(accounts: [account]),
            transactionRepository: transactionRepository
        )

        let transaction = try await createTransaction(
            id: makeTransactionID(),
            accountID: account.id,
            direction: .inflow,
            amount: Money(amount: 10, currencyCode: "gbp"),
            occurredAt: Date(timeIntervalSince1970: 1_786_080_000)
        )

        #expect(transaction.amount.currencyCode == "GBP")
        #expect(await transactionRepository.savedTransactions() == [transaction])
    }

    @Test func providedCategoryIDIsPreserved() async throws {
        let account = try makeAccount()
        let categoryID = CategoryID(rawValue: try #require(UUID(uuidString: "4D26CE21-335E-4C27-98DA-164C86E20AD8")))
        let transactionRepository = InMemoryTransactionRepository()
        let createTransaction = CreateTransaction(
            accountRepository: InMemoryAccountRepository(accounts: [account]),
            transactionRepository: transactionRepository
        )

        let transaction = try await createTransaction(
            id: makeTransactionID(),
            accountID: account.id,
            direction: .outflow,
            amount: Money(amount: 10, currencyCode: "GBP"),
            occurredAt: Date(timeIntervalSince1970: 1_786_080_000),
            categoryID: categoryID
        )

        #expect(transaction.categoryID == categoryID)
        #expect(await transactionRepository.savedTransactions() == [transaction])
    }

    @Test func nilCategoryIDRemainsNil() async throws {
        let account = try makeAccount()
        let transactionRepository = InMemoryTransactionRepository()
        let createTransaction = CreateTransaction(
            accountRepository: InMemoryAccountRepository(accounts: [account]),
            transactionRepository: transactionRepository
        )

        let transaction = try await createTransaction(
            id: makeTransactionID(),
            accountID: account.id,
            direction: .outflow,
            amount: Money(amount: 10, currencyCode: "GBP"),
            occurredAt: Date(timeIntervalSince1970: 1_786_080_000),
            categoryID: nil
        )

        #expect(transaction.categoryID == nil)
        #expect(await transactionRepository.savedTransactions() == [transaction])
    }

    @Test func mismatchedCurrencyFailsExplicitlyWithoutSaving() async throws {
        let account = try makeAccount(currencyCode: "GBP")
        let transactionRepository = InMemoryTransactionRepository()
        let createTransaction = CreateTransaction(
            accountRepository: InMemoryAccountRepository(accounts: [account]),
            transactionRepository: transactionRepository
        )

        do {
            _ = try await createTransaction(
                id: makeTransactionID(),
                accountID: account.id,
                direction: .outflow,
                amount: Money(amount: 10, currencyCode: "EUR"),
                occurredAt: Date(timeIntervalSince1970: 1_786_080_000)
            )
            Issue.record("Expected currency mismatch to fail.")
        } catch let error as CreateTransaction.Error {
            #expect(
                error == .currencyMismatch(
                    accountCurrencyCode: "GBP",
                    transactionCurrencyCode: "EUR"
                )
            )
        }

        #expect(await transactionRepository.savedTransactions() == [])
    }

    @Test func negativeTransactionAmountFailsThroughTransactionValidation() async throws {
        let account = try makeAccount()
        let transactionRepository = InMemoryTransactionRepository()
        let createTransaction = CreateTransaction(
            accountRepository: InMemoryAccountRepository(accounts: [account]),
            transactionRepository: transactionRepository
        )

        do {
            _ = try await createTransaction(
                id: makeTransactionID(),
                accountID: account.id,
                direction: .outflow,
                amount: Money(amount: -1, currencyCode: "GBP"),
                occurredAt: Date(timeIntervalSince1970: 1_786_080_000)
            )
            Issue.record("Expected negative amount to fail.")
        } catch let error as Transaction.ValidationError {
            #expect(error == .negativeAmount)
        }

        #expect(await transactionRepository.savedTransactions() == [])
    }

    @Test func duplicateTransactionIDFailsExplicitlyWithoutSaving() async throws {
        let account = try makeAccount()
        let transactionID = try makeTransactionID()
        let existingTransaction = try makeTransaction(
            id: transactionID,
            accountID: account.id,
            memo: "Existing"
        )
        let transactionRepository = InMemoryTransactionRepository(transactions: [existingTransaction])
        let createTransaction = CreateTransaction(
            accountRepository: InMemoryAccountRepository(accounts: [account]),
            transactionRepository: transactionRepository
        )

        do {
            _ = try await createTransaction(
                id: transactionID,
                accountID: account.id,
                direction: .inflow,
                amount: Money(amount: 99, currencyCode: "GBP"),
                occurredAt: Date(timeIntervalSince1970: 1_786_252_800),
                memo: "Replacement"
            )
            Issue.record("Expected duplicate transaction ID to fail.")
        } catch let error as CreateTransaction.Error {
            #expect(error == .duplicateTransactionID(transactionID))
        }

        #expect(await transactionRepository.saveCallCount() == 0)
        #expect(await transactionRepository.savedTransactions() == [existingTransaction])
        let fetchedTransaction = try await transactionRepository.fetchTransaction(id: transactionID)
        #expect(fetchedTransaction == existingTransaction)
    }

    @Test func accountRepositoryFetchFailurePropagates() async throws {
        let transactionRepository = InMemoryTransactionRepository()
        let createTransaction = CreateTransaction(
            accountRepository: InMemoryAccountRepository(fetchError: TestRepositoryError.fetchFailed),
            transactionRepository: transactionRepository
        )

        do {
            _ = try await createTransaction(
                id: makeTransactionID(),
                accountID: AccountID(),
                direction: .outflow,
                amount: Money(amount: 10, currencyCode: "GBP"),
                occurredAt: Date(timeIntervalSince1970: 1_786_080_000)
            )
            Issue.record("Expected account repository failure to propagate.")
        } catch let error as TestRepositoryError {
            #expect(error == .fetchFailed)
        }

        #expect(await transactionRepository.savedTransactions() == [])
    }

    @Test func transactionIDFetchFailurePropagates() async throws {
        let account = try makeAccount()
        let transactionRepository = InMemoryTransactionRepository(fetchTransactionError: TestRepositoryError.fetchFailed)
        let createTransaction = CreateTransaction(
            accountRepository: InMemoryAccountRepository(accounts: [account]),
            transactionRepository: transactionRepository
        )

        do {
            _ = try await createTransaction(
                id: makeTransactionID(),
                accountID: account.id,
                direction: .outflow,
                amount: Money(amount: 10, currencyCode: "GBP"),
                occurredAt: Date(timeIntervalSince1970: 1_786_080_000)
            )
            Issue.record("Expected transaction ID fetch failure to propagate.")
        } catch let error as TestRepositoryError {
            #expect(error == .fetchFailed)
        }

        #expect(await transactionRepository.saveCallCount() == 0)
        #expect(await transactionRepository.savedTransactions() == [])
    }

    @Test func transactionRepositorySaveFailurePropagates() async throws {
        let account = try makeAccount()
        let transactionRepository = InMemoryTransactionRepository(saveError: TestRepositoryError.saveFailed)
        let createTransaction = CreateTransaction(
            accountRepository: InMemoryAccountRepository(accounts: [account]),
            transactionRepository: transactionRepository
        )

        do {
            _ = try await createTransaction(
                id: makeTransactionID(),
                accountID: account.id,
                direction: .outflow,
                amount: Money(amount: 10, currencyCode: "GBP"),
                occurredAt: Date(timeIntervalSince1970: 1_786_080_000)
            )
            Issue.record("Expected transaction repository failure to propagate.")
        } catch let error as TestRepositoryError {
            #expect(error == .saveFailed)
        }

        #expect(await transactionRepository.savedTransactions() == [])
    }

    @Test func createTransactionIsSendable() {
        let createTransaction = CreateTransaction(
            accountRepository: InMemoryAccountRepository(accounts: []),
            transactionRepository: InMemoryTransactionRepository()
        )

        requireSendable(createTransaction)
    }

    private func makeAccount(
        id: AccountID? = nil,
        currencyCode: String = "GBP"
    ) throws -> Account {
        let defaultID = AccountID(rawValue: try #require(UUID(uuidString: "9E849395-8DC9-481A-B56F-1EC9AF46A57D")))

        return try Account(
            id: id ?? defaultID,
            name: "Everyday",
            type: .checking,
            currencyCode: currencyCode,
            openingBalance: Money(amount: 100, currencyCode: "GBP")
        )
    }

    private func makeTransaction(
        id: TransactionID? = nil,
        accountID: AccountID? = nil,
        direction: TransactionDirection = .outflow,
        amount: Money? = nil,
        occurredAt: Date = Date(timeIntervalSince1970: 1_786_080_000),
        categoryID: CategoryID? = nil,
        memo: String? = "Lunch"
    ) throws -> Transaction {
        try Transaction(
            id: id ?? makeTransactionID(),
            accountID: accountID ?? makeAccount().id,
            direction: direction,
            amount: amount ?? Money(amount: 12.34, currencyCode: "GBP"),
            occurredAt: occurredAt,
            categoryID: categoryID,
            memo: memo
        )
    }

    private func makeTransactionID() throws -> TransactionID {
        TransactionID(rawValue: try #require(UUID(uuidString: "36C6C328-4227-4CBA-8F29-16B5EC114286")))
    }

    private func requireSendable<T: Sendable>(_ value: T) {
        _ = value
    }
}

private enum TestRepositoryError: Error, Equatable, Sendable {
    case fetchFailed
    case saveFailed
}

private actor InMemoryAccountRepository: AccountRepository {
    private var accounts: [AccountID: Account]
    private let fetchError: TestRepositoryError?

    init(accounts: [Account] = [], fetchError: TestRepositoryError? = nil) {
        self.accounts = Dictionary(uniqueKeysWithValues: accounts.map { ($0.id, $0) })
        self.fetchError = fetchError
    }

    func fetchAccounts() async throws -> [Account] {
        if let fetchError {
            throw fetchError
        }

        return Array(accounts.values)
    }

    func fetchAccount(id: AccountID) async throws -> Account? {
        if let fetchError {
            throw fetchError
        }

        return accounts[id]
    }

    func save(_ account: Account) async throws {
        accounts[account.id] = account
    }

    func deleteAccount(id: AccountID) async throws {
        accounts[id] = nil
    }
}

private actor InMemoryTransactionRepository: TransactionRepository {
    private var transactions: [Transaction] = []
    private var saveCount = 0
    private let fetchTransactionError: TestRepositoryError?
    private let saveError: TestRepositoryError?

    init(
        transactions: [Transaction] = [],
        fetchTransactionError: TestRepositoryError? = nil,
        saveError: TestRepositoryError? = nil
    ) {
        self.transactions = transactions
        self.fetchTransactionError = fetchTransactionError
        self.saveError = saveError
    }

    func fetchTransactions(accountID: AccountID) async throws -> [Transaction] {
        transactions.filter { $0.accountID == accountID }
    }

    func fetchTransactions(categoryID: CategoryID) async throws -> [Transaction] {
        transactions.filter { $0.categoryID == categoryID }
    }

    func fetchTransactions(occurredFrom start: Date, occurredBefore end: Date) async throws -> [Transaction] {
        guard start < end else {
            throw TransactionRepositoryError.invalidDateRange
        }

        return transactions.filter { start <= $0.occurredAt && $0.occurredAt < end }
    }

    func fetchTransaction(id: TransactionID) async throws -> Transaction? {
        if let fetchTransactionError {
            throw fetchTransactionError
        }

        return transactions.first { $0.id == id }
    }

    func save(_ transaction: Transaction) async throws {
        saveCount += 1

        if let saveError {
            throw saveError
        }

        transactions.append(transaction)
    }

    func deleteTransaction(id: TransactionID) async throws {
        transactions.removeAll { $0.id == id }
    }

    func savedTransactions() -> [Transaction] {
        transactions
    }

    func saveCallCount() -> Int {
        saveCount
    }
}
