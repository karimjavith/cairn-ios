//
//  CalculateAccountBalanceTests.swift
//  CairnTests
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import Testing
@testable import Cairn

struct CalculateAccountBalanceTests {

    @Test func openingBalanceWithNoTransactionsReturnsOpeningBalance() async throws {
        let account = try makeAccount(openingBalance: Money(amount: 125, currencyCode: "GBP"))
        let calculateBalance = CalculateAccountBalance(
            accountRepository: InMemoryBalanceAccountRepository(accounts: [account]),
            transactionRepository: InMemoryBalanceTransactionRepository()
        )

        let balance = try await calculateBalance(accountID: account.id)

        #expect(balance == account.openingBalance)
    }

    @Test func singleInflowAddsToOpeningBalance() async throws {
        let account = try makeAccount(openingBalance: Money(amount: 100, currencyCode: "GBP"))
        let transaction = try makeTransaction(
            accountID: account.id,
            direction: .inflow,
            amount: Money(amount: 25, currencyCode: "GBP")
        )
        let calculateBalance = CalculateAccountBalance(
            accountRepository: InMemoryBalanceAccountRepository(accounts: [account]),
            transactionRepository: InMemoryBalanceTransactionRepository(transactions: [transaction])
        )

        let balance = try await calculateBalance(accountID: account.id)
        let expectedBalance = try Money(amount: 125, currencyCode: "GBP")

        #expect(balance == expectedBalance)
    }

    @Test func singleOutflowSubtractsFromOpeningBalance() async throws {
        let account = try makeAccount(openingBalance: Money(amount: 100, currencyCode: "GBP"))
        let transaction = try makeTransaction(
            accountID: account.id,
            direction: .outflow,
            amount: Money(amount: 30, currencyCode: "GBP")
        )
        let calculateBalance = CalculateAccountBalance(
            accountRepository: InMemoryBalanceAccountRepository(accounts: [account]),
            transactionRepository: InMemoryBalanceTransactionRepository(transactions: [transaction])
        )

        let balance = try await calculateBalance(accountID: account.id)
        let expectedBalance = try Money(amount: 70, currencyCode: "GBP")

        #expect(balance == expectedBalance)
    }

    @Test func multipleInflowsAndOutflowsAggregateCorrectly() async throws {
        let account = try makeAccount(openingBalance: Money(amount: 100, currencyCode: "GBP"))
        let transactions = try [
            makeTransaction(accountID: account.id, direction: .inflow, amount: Money(amount: 50, currencyCode: "GBP")),
            makeTransaction(accountID: account.id, direction: .outflow, amount: Money(amount: 20, currencyCode: "GBP")),
            makeTransaction(accountID: account.id, direction: .inflow, amount: Money(amount: 5.75, currencyCode: "GBP")),
            makeTransaction(accountID: account.id, direction: .outflow, amount: Money(amount: 10.25, currencyCode: "GBP"))
        ]
        let calculateBalance = CalculateAccountBalance(
            accountRepository: InMemoryBalanceAccountRepository(accounts: [account]),
            transactionRepository: InMemoryBalanceTransactionRepository(transactions: transactions)
        )

        let balance = try await calculateBalance(accountID: account.id)
        let expectedBalance = try Money(amount: 125.50, currencyCode: "GBP")

        #expect(balance == expectedBalance)
    }

    @Test func negativeFinalBalanceIsAllowed() async throws {
        let account = try makeAccount(openingBalance: Money(amount: 10, currencyCode: "GBP"))
        let transaction = try makeTransaction(
            accountID: account.id,
            direction: .outflow,
            amount: Money(amount: 25, currencyCode: "GBP")
        )
        let calculateBalance = CalculateAccountBalance(
            accountRepository: InMemoryBalanceAccountRepository(accounts: [account]),
            transactionRepository: InMemoryBalanceTransactionRepository(transactions: [transaction])
        )

        let balance = try await calculateBalance(accountID: account.id)
        let expectedBalance = try Money(amount: -15, currencyCode: "GBP")

        #expect(balance == expectedBalance)
    }

    @Test func zeroFinalBalanceIsAllowed() async throws {
        let account = try makeAccount(openingBalance: Money(amount: 40, currencyCode: "GBP"))
        let transactions = try [
            makeTransaction(accountID: account.id, direction: .outflow, amount: Money(amount: 15, currencyCode: "GBP")),
            makeTransaction(accountID: account.id, direction: .outflow, amount: Money(amount: 25, currencyCode: "GBP"))
        ]
        let calculateBalance = CalculateAccountBalance(
            accountRepository: InMemoryBalanceAccountRepository(accounts: [account]),
            transactionRepository: InMemoryBalanceTransactionRepository(transactions: transactions)
        )

        let balance = try await calculateBalance(accountID: account.id)
        let expectedBalance = try Money(amount: 0, currencyCode: "GBP")

        #expect(balance == expectedBalance)
    }

    @Test func highPrecisionDecimalValuesArePreserved() async throws {
        let openingAmount = try #require(Decimal(string: "1.000000000000000001"))
        let inflowAmount = try #require(Decimal(string: "0.000000000000000002"))
        let outflowAmount = try #require(Decimal(string: "0.000000000000000003"))
        let expectedAmount = try #require(Decimal(string: "1.000000000000000000"))
        let account = try makeAccount(openingBalance: Money(amount: openingAmount, currencyCode: "GBP"))
        let transactions = try [
            makeTransaction(accountID: account.id, direction: .inflow, amount: Money(amount: inflowAmount, currencyCode: "GBP")),
            makeTransaction(accountID: account.id, direction: .outflow, amount: Money(amount: outflowAmount, currencyCode: "GBP"))
        ]
        let calculateBalance = CalculateAccountBalance(
            accountRepository: InMemoryBalanceAccountRepository(accounts: [account]),
            transactionRepository: InMemoryBalanceTransactionRepository(transactions: transactions)
        )

        let balance = try await calculateBalance(accountID: account.id)
        let expectedBalance = try Money(amount: expectedAmount, currencyCode: "GBP")

        #expect(balance == expectedBalance)
    }

    @Test func transactionOrderingDoesNotChangeResult() async throws {
        let account = try makeAccount(openingBalance: Money(amount: 100, currencyCode: "GBP"))
        let transactions = try [
            makeTransaction(accountID: account.id, direction: .outflow, amount: Money(amount: 12.34, currencyCode: "GBP")),
            makeTransaction(accountID: account.id, direction: .inflow, amount: Money(amount: 50, currencyCode: "GBP")),
            makeTransaction(accountID: account.id, direction: .outflow, amount: Money(amount: 7.66, currencyCode: "GBP"))
        ]
        let forwardBalance = try await CalculateAccountBalance(
            accountRepository: InMemoryBalanceAccountRepository(accounts: [account]),
            transactionRepository: InMemoryBalanceTransactionRepository(transactions: transactions)
        )(accountID: account.id)
        let reversedBalance = try await CalculateAccountBalance(
            accountRepository: InMemoryBalanceAccountRepository(accounts: [account]),
            transactionRepository: InMemoryBalanceTransactionRepository(transactions: Array(transactions.reversed()))
        )(accountID: account.id)
        let expectedBalance = try Money(amount: 130, currencyCode: "GBP")

        #expect(forwardBalance == expectedBalance)
        #expect(reversedBalance == forwardBalance)
    }

    @Test func missingAccountFailsExplicitly() async throws {
        let missingAccountID = AccountID(rawValue: try #require(UUID(uuidString: "5AE1E563-7CC4-4AA8-A318-3A9385D6355B")))
        let transactionRepository = InMemoryBalanceTransactionRepository()
        let calculateBalance = CalculateAccountBalance(
            accountRepository: InMemoryBalanceAccountRepository(accounts: []),
            transactionRepository: transactionRepository
        )

        do {
            _ = try await calculateBalance(accountID: missingAccountID)
            Issue.record("Expected missing account to fail.")
        } catch let error as CalculateAccountBalance.Error {
            #expect(error == .accountNotFound(missingAccountID))
        }

        #expect(await transactionRepository.fetchTransactionsCallCount() == 0)
    }

    @Test func matchingTransactionCurrenciesSucceed() async throws {
        let account = try makeAccount(openingBalance: Money(amount: 10, currencyCode: "gbp"))
        let transaction = try makeTransaction(
            accountID: account.id,
            direction: .inflow,
            amount: Money(amount: 5, currencyCode: " GBP\n")
        )
        let calculateBalance = CalculateAccountBalance(
            accountRepository: InMemoryBalanceAccountRepository(accounts: [account]),
            transactionRepository: InMemoryBalanceTransactionRepository(transactions: [transaction])
        )

        let balance = try await calculateBalance(accountID: account.id)
        let expectedBalance = try Money(amount: 15, currencyCode: "GBP")

        #expect(balance == expectedBalance)
    }

    @Test func mismatchedTransactionCurrencyFailsExplicitly() async throws {
        let account = try makeAccount(openingBalance: Money(amount: 100, currencyCode: "GBP"))
        let transactions = try [
            makeTransaction(accountID: account.id, direction: .inflow, amount: Money(amount: 20, currencyCode: "GBP")),
            makeTransaction(accountID: account.id, direction: .inflow, amount: Money(amount: 5, currencyCode: "EUR"))
        ]
        let calculateBalance = CalculateAccountBalance(
            accountRepository: InMemoryBalanceAccountRepository(accounts: [account]),
            transactionRepository: InMemoryBalanceTransactionRepository(transactions: transactions)
        )

        do {
            _ = try await calculateBalance(accountID: account.id)
            Issue.record("Expected mismatched transaction currency to fail.")
        } catch let error as CalculateAccountBalance.Error {
            #expect(
                error == .transactionCurrencyMismatch(
                    accountCurrencyCode: "GBP",
                    transactionCurrencyCode: "EUR"
                )
            )
        }
    }

    @Test func mismatchedTransactionCurrencyDoesNotConvertOrReturnPartialBalance() async throws {
        let account = try makeAccount(openingBalance: Money(amount: 100, currencyCode: "GBP"))
        let transactions = try [
            makeTransaction(accountID: account.id, direction: .inflow, amount: Money(amount: 200, currencyCode: "EUR")),
            makeTransaction(accountID: account.id, direction: .outflow, amount: Money(amount: 50, currencyCode: "GBP"))
        ]
        let calculateBalance = CalculateAccountBalance(
            accountRepository: InMemoryBalanceAccountRepository(accounts: [account]),
            transactionRepository: InMemoryBalanceTransactionRepository(transactions: transactions)
        )

        do {
            _ = try await calculateBalance(accountID: account.id)
            Issue.record("Expected mismatched transaction currency to fail before returning a balance.")
        } catch let error as CalculateAccountBalance.Error {
            #expect(
                error == .transactionCurrencyMismatch(
                    accountCurrencyCode: "GBP",
                    transactionCurrencyCode: "EUR"
                )
            )
        }
    }

    @Test func accountRepositoryFetchFailurePropagatesUnchanged() async throws {
        let transactionRepository = InMemoryBalanceTransactionRepository()
        let calculateBalance = CalculateAccountBalance(
            accountRepository: InMemoryBalanceAccountRepository(fetchError: BalanceRepositoryError.fetchFailed),
            transactionRepository: transactionRepository
        )

        do {
            _ = try await calculateBalance(accountID: AccountID())
            Issue.record("Expected account repository failure to propagate.")
        } catch let error as BalanceRepositoryError {
            #expect(error == .fetchFailed)
        }

        #expect(await transactionRepository.fetchTransactionsCallCount() == 0)
    }

    @Test func transactionRepositoryFetchFailurePropagatesUnchanged() async throws {
        let account = try makeAccount()
        let calculateBalance = CalculateAccountBalance(
            accountRepository: InMemoryBalanceAccountRepository(accounts: [account]),
            transactionRepository: InMemoryBalanceTransactionRepository(fetchTransactionsError: BalanceRepositoryError.fetchFailed)
        )

        do {
            _ = try await calculateBalance(accountID: account.id)
            Issue.record("Expected transaction repository failure to propagate.")
        } catch let error as BalanceRepositoryError {
            #expect(error == .fetchFailed)
        }
    }

    @Test func returnedMoneyCurrencyEqualsAccountOpeningBalanceCurrency() async throws {
        let account = try makeAccount(openingBalance: Money(amount: 100, currencyCode: "GBP"))
        let transaction = try makeTransaction(
            accountID: account.id,
            direction: .outflow,
            amount: Money(amount: 20, currencyCode: "GBP")
        )
        let calculateBalance = CalculateAccountBalance(
            accountRepository: InMemoryBalanceAccountRepository(accounts: [account]),
            transactionRepository: InMemoryBalanceTransactionRepository(transactions: [transaction])
        )

        let balance = try await calculateBalance(accountID: account.id)

        #expect(balance.currencyCode == account.openingBalance.currencyCode)
    }

    @Test func calculateAccountBalanceIsSendable() {
        let calculateBalance = CalculateAccountBalance(
            accountRepository: InMemoryBalanceAccountRepository(accounts: []),
            transactionRepository: InMemoryBalanceTransactionRepository()
        )

        requireSendable(calculateBalance)
    }

    private func makeAccount(
        id: AccountID? = nil,
        openingBalance providedOpeningBalance: Money? = nil
    ) throws -> Account {
        let defaultID = AccountID(rawValue: try #require(UUID(uuidString: "4CC91F32-C3EF-4D03-A7F1-79FBB339DD28")))
        let openingBalance: Money

        if let providedOpeningBalance {
            openingBalance = providedOpeningBalance
        } else {
            openingBalance = try Money(amount: 100, currencyCode: "GBP")
        }

        return try Account(
            id: id ?? defaultID,
            name: "Everyday",
            type: .checking,
            currencyCode: openingBalance.currencyCode,
            openingBalance: openingBalance
        )
    }

    private func makeTransaction(
        accountID: AccountID,
        direction: TransactionDirection,
        amount: Money,
        occurredAt: Date = Date(timeIntervalSince1970: 1_786_080_000)
    ) throws -> Transaction {
        try Transaction(
            accountID: accountID,
            direction: direction,
            amount: amount,
            occurredAt: occurredAt
        )
    }

    private func requireSendable<T: Sendable>(_ value: T) {
        _ = value
    }
}

private enum BalanceRepositoryError: Error, Equatable, Sendable {
    case fetchFailed
}

private actor InMemoryBalanceAccountRepository: AccountRepository {
    private var accounts: [AccountID: Account]
    private let fetchError: BalanceRepositoryError?

    init(accounts: [Account] = [], fetchError: BalanceRepositoryError? = nil) {
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

private actor InMemoryBalanceTransactionRepository: TransactionRepository {
    private var transactions: [Transaction]
    private var fetchTransactionsCount = 0
    private let fetchTransactionsError: BalanceRepositoryError?

    init(
        transactions: [Transaction] = [],
        fetchTransactionsError: BalanceRepositoryError? = nil
    ) {
        self.transactions = transactions
        self.fetchTransactionsError = fetchTransactionsError
    }

    func fetchTransactions(accountID: AccountID) async throws -> [Transaction] {
        fetchTransactionsCount += 1

        if let fetchTransactionsError {
            throw fetchTransactionsError
        }

        return transactions.filter { $0.accountID == accountID }
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
}
