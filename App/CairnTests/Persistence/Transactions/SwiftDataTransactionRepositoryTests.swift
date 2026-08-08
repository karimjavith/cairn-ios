//
//  SwiftDataTransactionRepositoryTests.swift
//  CairnTests
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import SwiftData
import Testing
@testable import Cairn

struct SwiftDataTransactionRepositoryTests {

    @Test func fetchTransactionsOnEmptyStoreReturnsEmptyArray() async throws {
        let repository = try makeRepository()

        let transactions = try await repository.fetchTransactions(accountID: AccountID())

        #expect(transactions == [])
    }

    @Test func saveInsertsTransaction() async throws {
        let repository = try makeRepository()
        let transaction = try makeTransaction()

        try await repository.save(transaction)

        let transactions = try await repository.fetchTransactions(accountID: transaction.accountID)
        #expect(transactions == [transaction])
    }

    @Test func fetchTransactionReturnsSavedTransaction() async throws {
        let repository = try makeRepository()
        let transaction = try makeTransaction()

        try await repository.save(transaction)

        let fetchedTransaction = try await repository.fetchTransaction(id: transaction.id)
        #expect(fetchedTransaction == transaction)
    }

    @Test func fetchTransactionReturnsNilWhenMissing() async throws {
        let repository = try makeRepository()

        let fetchedTransaction = try await repository.fetchTransaction(id: TransactionID())

        #expect(fetchedTransaction == nil)
    }

    @Test func fetchTransactionsReturnsOnlyRequestedAccountTransactions() async throws {
        let repository = try makeRepository()
        let requestedAccountID = AccountID()
        let otherAccountID = AccountID()
        let requestedTransaction = try makeTransaction(accountID: requestedAccountID, memo: "Requested")
        let otherTransaction = try makeTransaction(accountID: otherAccountID, memo: "Other")

        try await repository.save(otherTransaction)
        try await repository.save(requestedTransaction)

        let transactions = try await repository.fetchTransactions(accountID: requestedAccountID)
        #expect(transactions == [requestedTransaction])
    }

    @Test func fetchTransactionsOrdersByOccurredAtDescending() async throws {
        let repository = try makeRepository()
        let accountID = AccountID()
        let oldest = try makeTransaction(
            accountID: accountID,
            occurredAt: Date(timeIntervalSince1970: 1_786_080_000),
            memo: "Oldest"
        )
        let newest = try makeTransaction(
            accountID: accountID,
            occurredAt: Date(timeIntervalSince1970: 1_786_252_800),
            memo: "Newest"
        )
        let middle = try makeTransaction(
            accountID: accountID,
            occurredAt: Date(timeIntervalSince1970: 1_786_166_400),
            memo: "Middle"
        )

        try await repository.save(oldest)
        try await repository.save(newest)
        try await repository.save(middle)

        let transactions = try await repository.fetchTransactions(accountID: accountID)
        #expect(transactions == [newest, middle, oldest])
    }

    @Test func fetchTransactionsUsesStableTransactionIDOrderingWhenOccurredAtValuesAreEqual() async throws {
        let repository = try makeRepository()
        let accountID = AccountID()
        let occurredAt = Date(timeIntervalSince1970: 1_786_080_000)
        let first = try makeTransaction(
            id: TransactionID(rawValue: try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))),
            accountID: accountID,
            occurredAt: occurredAt,
            memo: "First"
        )
        let second = try makeTransaction(
            id: TransactionID(rawValue: try #require(UUID(uuidString: "22222222-2222-2222-2222-222222222222"))),
            accountID: accountID,
            occurredAt: occurredAt,
            memo: "Second"
        )
        let third = try makeTransaction(
            id: TransactionID(rawValue: try #require(UUID(uuidString: "33333333-3333-3333-3333-333333333333"))),
            accountID: accountID,
            occurredAt: occurredAt,
            memo: "Third"
        )

        try await repository.save(third)
        try await repository.save(first)
        try await repository.save(second)

        let transactions = try await repository.fetchTransactions(accountID: accountID)
        #expect(transactions == [first, second, third])
    }

    @Test func fetchTransactionsByCategoryReturnsOnlyMatchingCategorizedTransactions() async throws {
        let repository = try makeRepository()
        let requestedCategoryID = CategoryID()
        let otherCategoryID = CategoryID()
        let matching = try makeTransaction(categoryID: requestedCategoryID, memo: "Matching")
        let otherCategory = try makeTransaction(categoryID: otherCategoryID, memo: "Other")
        let uncategorized = try makeTransaction(categoryID: nil, memo: "Uncategorized")

        try await repository.save(otherCategory)
        try await repository.save(uncategorized)
        try await repository.save(matching)

        let transactions = try await repository.fetchTransactions(categoryID: requestedCategoryID)
        #expect(transactions == [matching])
    }

    @Test func fetchTransactionsByCategoryOrdersByOccurredAtDescending() async throws {
        let repository = try makeRepository()
        let categoryID = CategoryID()
        let oldest = try makeTransaction(
            occurredAt: Date(timeIntervalSince1970: 1_786_080_000),
            categoryID: categoryID,
            memo: "Oldest"
        )
        let newest = try makeTransaction(
            occurredAt: Date(timeIntervalSince1970: 1_786_252_800),
            categoryID: categoryID,
            memo: "Newest"
        )
        let middle = try makeTransaction(
            occurredAt: Date(timeIntervalSince1970: 1_786_166_400),
            categoryID: categoryID,
            memo: "Middle"
        )

        try await repository.save(oldest)
        try await repository.save(newest)
        try await repository.save(middle)

        let transactions = try await repository.fetchTransactions(categoryID: categoryID)
        #expect(transactions == [newest, middle, oldest])
    }

    @Test func fetchTransactionsByCategoryUsesStableTransactionIDOrderingWhenOccurredAtValuesAreEqual() async throws {
        let repository = try makeRepository()
        let categoryID = CategoryID()
        let occurredAt = Date(timeIntervalSince1970: 1_786_080_000)
        let first = try makeTransaction(
            id: TransactionID(rawValue: try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))),
            occurredAt: occurredAt,
            categoryID: categoryID,
            memo: "First"
        )
        let second = try makeTransaction(
            id: TransactionID(rawValue: try #require(UUID(uuidString: "22222222-2222-2222-2222-222222222222"))),
            occurredAt: occurredAt,
            categoryID: categoryID,
            memo: "Second"
        )
        let third = try makeTransaction(
            id: TransactionID(rawValue: try #require(UUID(uuidString: "33333333-3333-3333-3333-333333333333"))),
            occurredAt: occurredAt,
            categoryID: categoryID,
            memo: "Third"
        )

        try await repository.save(third)
        try await repository.save(first)
        try await repository.save(second)

        let transactions = try await repository.fetchTransactions(categoryID: categoryID)
        #expect(transactions == [first, second, third])
    }

    @Test func repeatedSaveWithSameTransactionIDUpdatesWithoutCreatingDuplicates() async throws {
        let repository = try makeRepository()
        let id = TransactionID()
        let accountID = AccountID()
        let original = try makeTransaction(id: id, accountID: accountID, memo: "Coffee")
        let updated = try makeTransaction(id: id, accountID: accountID, memo: "Groceries")

        try await repository.save(original)
        try await repository.save(updated)

        let transactions = try await repository.fetchTransactions(accountID: accountID)
        #expect(transactions == [updated])
    }

    @Test func savingExistingTransactionWithChangedAccountIDUpdatesPersistence() async throws {
        let repository = try makeRepository()
        let id = TransactionID()
        let originalAccountID = AccountID()
        let updatedAccountID = AccountID()
        let original = try makeTransaction(id: id, accountID: originalAccountID)
        let updated = try makeTransaction(id: id, accountID: updatedAccountID, memo: "Moved")

        try await repository.save(original)
        try await repository.save(updated)

        #expect(try await repository.fetchTransactions(accountID: originalAccountID) == [])
        #expect(try await repository.fetchTransactions(accountID: updatedAccountID) == [updated])
        #expect(try await repository.fetchTransaction(id: id) == updated)
    }

    @Test func savingExistingTransactionWithChangedCategoryIDUpdatesPersistence() async throws {
        let repository = try makeRepository()
        let id = TransactionID()
        let originalCategoryID = CategoryID()
        let updatedCategoryID = CategoryID()
        let original = try makeTransaction(id: id, categoryID: originalCategoryID)
        let updated = try makeTransaction(id: id, categoryID: updatedCategoryID, memo: "Moved")

        try await repository.save(original)
        try await repository.save(updated)

        #expect(try await repository.fetchTransactions(categoryID: originalCategoryID) == [])
        #expect(try await repository.fetchTransactions(categoryID: updatedCategoryID) == [updated])
        #expect(try await repository.fetchTransaction(id: id) == updated)
    }

    @Test func repositoryPreservesNilCategoryID() async throws {
        let repository = try makeRepository()
        let transaction = try makeTransaction(categoryID: nil)

        try await repository.save(transaction)

        let fetchedTransaction = try #require(try await repository.fetchTransaction(id: transaction.id))
        #expect(fetchedTransaction.categoryID == nil)
        #expect(fetchedTransaction == transaction)
    }

    @Test func repositoryPreservesCategoryID() async throws {
        let repository = try makeRepository()
        let categoryID = CategoryID(rawValue: try #require(UUID(uuidString: "4D26CE21-335E-4C27-98DA-164C86E20AD8")))
        let transaction = try makeTransaction(categoryID: categoryID)

        try await repository.save(transaction)

        let fetchedTransaction = try #require(try await repository.fetchTransaction(id: transaction.id))
        #expect(fetchedTransaction.categoryID == categoryID)
        #expect(fetchedTransaction == transaction)
    }

    @Test func updatedAmountPreservesDecimalPrecision() async throws {
        let repository = try makeRepository()
        let id = TransactionID()
        let accountID = AccountID()
        let original = try makeTransaction(id: id, accountID: accountID, amount: Money(amount: 1, currencyCode: "GBP"))
        let preciseAmount = try #require(Decimal(string: "1234567890.123456789012345678"))
        let updated = try makeTransaction(
            id: id,
            accountID: accountID,
            amount: Money(amount: preciseAmount, currencyCode: "GBP")
        )

        try await repository.save(original)
        try await repository.save(updated)

        let fetchedTransaction = try #require(try await repository.fetchTransaction(id: id))
        #expect(fetchedTransaction.amount.amount == preciseAmount)
        #expect(fetchedTransaction == updated)
    }

    @Test func updatedMemoPersists() async throws {
        let repository = try makeRepository()
        let id = TransactionID()
        let accountID = AccountID()
        let original = try makeTransaction(id: id, accountID: accountID, memo: "Coffee")
        let updated = try makeTransaction(id: id, accountID: accountID, memo: "  Groceries\n")

        try await repository.save(original)
        try await repository.save(updated)

        let fetchedTransaction = try #require(try await repository.fetchTransaction(id: id))
        #expect(fetchedTransaction.memo == "Groceries")
        #expect(fetchedTransaction == updated)
    }

    @Test func nilMemoPersists() async throws {
        let repository = try makeRepository()
        let transaction = try makeTransaction(memo: nil)

        try await repository.save(transaction)

        let fetchedTransaction = try #require(try await repository.fetchTransaction(id: transaction.id))
        #expect(fetchedTransaction.memo == nil)
        #expect(fetchedTransaction == transaction)
    }

    @Test func deleteRemovesExistingTransaction() async throws {
        let repository = try makeRepository()
        let transaction = try makeTransaction()

        try await repository.save(transaction)
        try await repository.deleteTransaction(id: transaction.id)

        let fetchedTransaction = try await repository.fetchTransaction(id: transaction.id)
        #expect(fetchedTransaction == nil)
        #expect(try await repository.fetchTransactions(accountID: transaction.accountID) == [])
    }

    @Test func deleteMissingTransactionIsNoOp() async throws {
        let repository = try makeRepository()

        try await repository.deleteTransaction(id: TransactionID())

        #expect(try await repository.fetchTransactions(accountID: AccountID()) == [])
    }

    @Test func repositoryPreservesTransactionID() async throws {
        let repository = try makeRepository()
        let id = TransactionID(rawValue: try #require(UUID(uuidString: "9B9B1F92-3908-441F-B050-18600444B30E")))
        let transaction = try makeTransaction(id: id)

        try await repository.save(transaction)

        let fetchedTransaction = try #require(try await repository.fetchTransaction(id: id))
        #expect(fetchedTransaction.id == id)
    }

    @Test func repositoryPreservesAccountID() async throws {
        let repository = try makeRepository()
        let accountID = AccountID(rawValue: try #require(UUID(uuidString: "CF19E717-8512-40FB-85E5-2857E39CD308")))
        let transaction = try makeTransaction(accountID: accountID)

        try await repository.save(transaction)

        let fetchedTransaction = try #require(try await repository.fetchTransaction(id: transaction.id))
        #expect(fetchedTransaction.accountID == accountID)
    }

    @Test func invalidPersistedTransactionRecordFailsMapping() async throws {
        let accountID = AccountID()
        let container = try makeInMemoryModelContainer()
        let insertContext = ModelContext(container)
        insertContext.insert(TransactionRecord(
            id: TransactionID().rawValue,
            accountID: accountID.rawValue,
            direction: "credit",
            amount: "12.34",
            currencyCode: "GBP",
            occurredAt: Date(timeIntervalSince1970: 1_786_080_000),
            memo: "Lunch"
        ))
        try insertContext.save()

        let repository = await SwiftDataTransactionRepository(modelContainer: container)

        await #expect(throws: TransactionRecordMappingError.invalidDirection("credit")) {
            try await repository.fetchTransactions(accountID: accountID)
        }
    }

    private func makeRepository() throws -> SwiftDataTransactionRepository {
        try SwiftDataTransactionRepository(modelContainer: makeInMemoryModelContainer())
    }

    private func makeInMemoryModelContainer() throws -> ModelContainer {
        let schema = Schema([
            TransactionRecord.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func makeTransaction(
        id: TransactionID = TransactionID(),
        accountID: AccountID = AccountID(),
        direction: TransactionDirection = .outflow,
        amount: Money? = nil,
        occurredAt: Date = Date(timeIntervalSince1970: 1_786_080_000),
        categoryID: CategoryID? = nil,
        memo: String? = "Lunch"
    ) throws -> Transaction {
        try Transaction(
            id: id,
            accountID: accountID,
            direction: direction,
            amount: amount ?? Money(amount: 12.34, currencyCode: "GBP"),
            occurredAt: occurredAt,
            categoryID: categoryID,
            memo: memo
        )
    }
}
