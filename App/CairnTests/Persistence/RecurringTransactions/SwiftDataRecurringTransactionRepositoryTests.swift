//
//  SwiftDataRecurringTransactionRepositoryTests.swift
//  CairnTests
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import SwiftData
import Testing
@testable import Cairn

struct SwiftDataRecurringTransactionRepositoryTests {

    @Test func fetchRecurringTransactionsOnEmptyStoreReturnsEmptyArray() async throws {
        let repository = try makeRepository()

        let recurringTransactions = try await repository.fetchRecurringTransactions()

        #expect(recurringTransactions == [])
    }

    @Test func saveInsertsRecurringTransaction() async throws {
        let repository = try makeRepository()
        let recurringTransaction = try makeRecurringTransaction()

        try await repository.save(recurringTransaction)

        let recurringTransactions = try await repository.fetchRecurringTransactions()
        #expect(recurringTransactions == [recurringTransaction])
    }

    @Test func fetchRecurringTransactionReturnsSavedValue() async throws {
        let repository = try makeRepository()
        let recurringTransaction = try makeRecurringTransaction()

        try await repository.save(recurringTransaction)

        let fetchedRecurringTransaction = try await repository.fetchRecurringTransaction(
            id: recurringTransaction.id
        )
        #expect(fetchedRecurringTransaction == recurringTransaction)
    }

    @Test func fetchRecurringTransactionReturnsNilWhenMissing() async throws {
        let repository = try makeRepository()

        let fetchedRecurringTransaction = try await repository.fetchRecurringTransaction(
            id: RecurringTransactionID()
        )

        #expect(fetchedRecurringTransaction == nil)
    }

    @Test func fetchRecurringTransactionsReturnsAllSavedValues() async throws {
        let repository = try makeRepository()
        let earlier = try makeRecurringTransaction(
            startDate: Date(timeIntervalSince1970: 1_786_080_000),
            memo: "Earlier"
        )
        let later = try makeRecurringTransaction(
            startDate: Date(timeIntervalSince1970: 1_786_166_400),
            memo: "Later"
        )

        try await repository.save(later)
        try await repository.save(earlier)

        let recurringTransactions = try await repository.fetchRecurringTransactions()
        #expect(recurringTransactions == [earlier, later])
    }

    @Test func fetchRecurringTransactionsOrdersEarlierStartDateFirst() async throws {
        let repository = try makeRepository()
        let earlier = try makeRecurringTransaction(
            startDate: Date(timeIntervalSince1970: 1_786_080_000),
            memo: "Earlier"
        )
        let later = try makeRecurringTransaction(
            startDate: Date(timeIntervalSince1970: 1_786_166_400),
            memo: "Later"
        )

        try await repository.save(later)
        try await repository.save(earlier)

        let recurringTransactions = try await repository.fetchRecurringTransactions()
        #expect(recurringTransactions == [earlier, later])
    }

    @Test func fetchRecurringTransactionsOrdersNonNilEndDateBeforeNilWhenStartDateIsEqual() async throws {
        let repository = try makeRepository()
        let startDate = Date(timeIntervalSince1970: 1_786_080_000)
        let nilEndDate = try makeRecurringTransaction(
            startDate: startDate,
            endDate: nil,
            memo: "No end"
        )
        let nonNilEndDate = try makeRecurringTransaction(
            startDate: startDate,
            endDate: Date(timeIntervalSince1970: 1_788_672_000),
            memo: "Ends"
        )

        try await repository.save(nilEndDate)
        try await repository.save(nonNilEndDate)

        let recurringTransactions = try await repository.fetchRecurringTransactions()
        #expect(recurringTransactions == [nonNilEndDate, nilEndDate])
    }

    @Test func fetchRecurringTransactionsOrdersNonNilEndDateAscendingWhenStartDateIsEqual() async throws {
        let repository = try makeRepository()
        let startDate = Date(timeIntervalSince1970: 1_786_080_000)
        let earlierEndDate = try makeRecurringTransaction(
            startDate: startDate,
            endDate: Date(timeIntervalSince1970: 1_788_672_000),
            memo: "Earlier end"
        )
        let laterEndDate = try makeRecurringTransaction(
            startDate: startDate,
            endDate: Date(timeIntervalSince1970: 1_791_264_000),
            memo: "Later end"
        )

        try await repository.save(laterEndDate)
        try await repository.save(earlierEndDate)

        let recurringTransactions = try await repository.fetchRecurringTransactions()
        #expect(recurringTransactions == [earlierEndDate, laterEndDate])
    }

    @Test func fetchRecurringTransactionsUsesRecurringTransactionIDAsStableFinalOrdering() async throws {
        let repository = try makeRepository()
        let startDate = Date(timeIntervalSince1970: 1_786_080_000)
        let endDate = Date(timeIntervalSince1970: 1_788_672_000)
        let first = try makeRecurringTransaction(
            id: RecurringTransactionID(rawValue: try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))),
            startDate: startDate,
            endDate: endDate,
            memo: "First"
        )
        let second = try makeRecurringTransaction(
            id: RecurringTransactionID(rawValue: try #require(UUID(uuidString: "22222222-2222-2222-2222-222222222222"))),
            startDate: startDate,
            endDate: endDate,
            memo: "Second"
        )
        let third = try makeRecurringTransaction(
            id: RecurringTransactionID(rawValue: try #require(UUID(uuidString: "33333333-3333-3333-3333-333333333333"))),
            startDate: startDate,
            endDate: endDate,
            memo: "Third"
        )

        try await repository.save(third)
        try await repository.save(first)
        try await repository.save(second)

        let recurringTransactions = try await repository.fetchRecurringTransactions()
        #expect(recurringTransactions == [first, second, third])
    }

    @Test func repeatedSaveWithSameRecurringTransactionIDUpdatesWithoutCreatingDuplicates() async throws {
        let repository = try makeRepository()
        let id = RecurringTransactionID()
        let original = try makeRecurringTransaction(id: id, memo: "Rent")
        let updated = try makeRecurringTransaction(id: id, memo: "Mortgage")

        try await repository.save(original)
        try await repository.save(updated)

        let recurringTransactions = try await repository.fetchRecurringTransactions()
        #expect(recurringTransactions == [updated])
    }

    @Test func changingAccountIDPersists() async throws {
        let repository = try makeRepository()
        let id = RecurringTransactionID()
        let originalAccountID = AccountID()
        let updatedAccountID = AccountID()
        let original = try makeRecurringTransaction(id: id, accountID: originalAccountID)
        let updated = try makeRecurringTransaction(id: id, accountID: updatedAccountID)

        try await repository.save(original)
        try await repository.save(updated)

        let fetchedRecurringTransaction = try #require(try await repository.fetchRecurringTransaction(id: id))
        #expect(fetchedRecurringTransaction.accountID == updatedAccountID)
        #expect(fetchedRecurringTransaction == updated)
    }

    @Test func changingDirectionPersists() async throws {
        let repository = try makeRepository()
        let id = RecurringTransactionID()
        let original = try makeRecurringTransaction(id: id, direction: .outflow)
        let updated = try makeRecurringTransaction(id: id, direction: .inflow)

        try await repository.save(original)
        try await repository.save(updated)

        let fetchedRecurringTransaction = try #require(try await repository.fetchRecurringTransaction(id: id))
        #expect(fetchedRecurringTransaction.direction == .inflow)
        #expect(fetchedRecurringTransaction == updated)
    }

    @Test func updatedAmountPreservesDecimalPrecision() async throws {
        let repository = try makeRepository()
        let id = RecurringTransactionID()
        let original = try makeRecurringTransaction(id: id, amount: Money(amount: 1, currencyCode: "GBP"))
        let preciseAmount = try #require(Decimal(string: "1234567890.123456789012345678"))
        let updated = try makeRecurringTransaction(
            id: id,
            amount: Money(amount: preciseAmount, currencyCode: "GBP")
        )

        try await repository.save(original)
        try await repository.save(updated)

        let fetchedRecurringTransaction = try #require(try await repository.fetchRecurringTransaction(id: id))
        #expect(fetchedRecurringTransaction.amount.amount == preciseAmount)
        #expect(fetchedRecurringTransaction == updated)
    }

    @Test func changingCurrencyPersists() async throws {
        let repository = try makeRepository()
        let id = RecurringTransactionID()
        let original = try makeRecurringTransaction(id: id, amount: Money(amount: 12, currencyCode: "GBP"))
        let updated = try makeRecurringTransaction(id: id, amount: Money(amount: 12, currencyCode: "EUR"))

        try await repository.save(original)
        try await repository.save(updated)

        let fetchedRecurringTransaction = try #require(try await repository.fetchRecurringTransaction(id: id))
        #expect(fetchedRecurringTransaction.amount.currencyCode == "EUR")
        #expect(fetchedRecurringTransaction == updated)
    }

    @Test func changingRecurrenceFrequencyPersists() async throws {
        let repository = try makeRepository()
        let id = RecurringTransactionID()
        let original = try makeRecurringTransaction(id: id, frequency: .monthly)
        let updated = try makeRecurringTransaction(id: id, frequency: .weekly)

        try await repository.save(original)
        try await repository.save(updated)

        let fetchedRecurringTransaction = try #require(try await repository.fetchRecurringTransaction(id: id))
        #expect(fetchedRecurringTransaction.frequency == .weekly)
        #expect(fetchedRecurringTransaction == updated)
    }

    @Test func changingStartDatePersists() async throws {
        let repository = try makeRepository()
        let id = RecurringTransactionID()
        let original = try makeRecurringTransaction(
            id: id,
            startDate: Date(timeIntervalSince1970: 1_786_080_000),
            endDate: Date(timeIntervalSince1970: 1_788_672_000)
        )
        let updatedStartDate = Date(timeIntervalSince1970: 1_786_166_400)
        let updated = try makeRecurringTransaction(
            id: id,
            startDate: updatedStartDate,
            endDate: Date(timeIntervalSince1970: 1_788_672_000)
        )

        try await repository.save(original)
        try await repository.save(updated)

        let fetchedRecurringTransaction = try #require(try await repository.fetchRecurringTransaction(id: id))
        #expect(fetchedRecurringTransaction.startDate == updatedStartDate)
        #expect(fetchedRecurringTransaction == updated)
    }

    @Test func endDateCanChangeFromNilToNonNil() async throws {
        let repository = try makeRepository()
        let id = RecurringTransactionID()
        let endDate = Date(timeIntervalSince1970: 1_788_672_000)
        let original = try makeRecurringTransaction(id: id, endDate: nil)
        let updated = try makeRecurringTransaction(id: id, endDate: endDate)

        try await repository.save(original)
        try await repository.save(updated)

        let fetchedRecurringTransaction = try #require(try await repository.fetchRecurringTransaction(id: id))
        #expect(fetchedRecurringTransaction.endDate == endDate)
        #expect(fetchedRecurringTransaction == updated)
    }

    @Test func endDateCanChangeFromNonNilToNil() async throws {
        let repository = try makeRepository()
        let id = RecurringTransactionID()
        let original = try makeRecurringTransaction(
            id: id,
            endDate: Date(timeIntervalSince1970: 1_788_672_000)
        )
        let updated = try makeRecurringTransaction(id: id, endDate: nil)

        try await repository.save(original)
        try await repository.save(updated)

        let fetchedRecurringTransaction = try #require(try await repository.fetchRecurringTransaction(id: id))
        #expect(fetchedRecurringTransaction.endDate == nil)
        #expect(fetchedRecurringTransaction == updated)
    }

    @Test func updatedMemoPersists() async throws {
        let repository = try makeRepository()
        let id = RecurringTransactionID()
        let original = try makeRecurringTransaction(id: id, memo: "Rent")
        let updated = try makeRecurringTransaction(id: id, memo: "  Mortgage\n")

        try await repository.save(original)
        try await repository.save(updated)

        let fetchedRecurringTransaction = try #require(try await repository.fetchRecurringTransaction(id: id))
        #expect(fetchedRecurringTransaction.memo == "Mortgage")
        #expect(fetchedRecurringTransaction == updated)
    }

    @Test func memoCanChangeFromNonNilToNil() async throws {
        let repository = try makeRepository()
        let id = RecurringTransactionID()
        let original = try makeRecurringTransaction(id: id, memo: "Rent")
        let updated = try makeRecurringTransaction(id: id, memo: nil)

        try await repository.save(original)
        try await repository.save(updated)

        let fetchedRecurringTransaction = try #require(try await repository.fetchRecurringTransaction(id: id))
        #expect(fetchedRecurringTransaction.memo == nil)
        #expect(fetchedRecurringTransaction == updated)
    }

    @Test func deleteRemovesExistingRecurringTransaction() async throws {
        let repository = try makeRepository()
        let recurringTransaction = try makeRecurringTransaction()

        try await repository.save(recurringTransaction)
        try await repository.deleteRecurringTransaction(id: recurringTransaction.id)

        let fetchedRecurringTransaction = try await repository.fetchRecurringTransaction(
            id: recurringTransaction.id
        )
        #expect(fetchedRecurringTransaction == nil)
        #expect(try await repository.fetchRecurringTransactions() == [])
    }

    @Test func deleteMissingRecurringTransactionIsNoOp() async throws {
        let repository = try makeRepository()

        try await repository.deleteRecurringTransaction(id: RecurringTransactionID())

        #expect(try await repository.fetchRecurringTransactions() == [])
    }

    @Test func repositoryPreservesRecurringTransactionID() async throws {
        let repository = try makeRepository()
        let id = RecurringTransactionID(rawValue: try #require(UUID(uuidString: "86A05998-7658-4F15-AB03-A8E8C84986A3")))
        let recurringTransaction = try makeRecurringTransaction(id: id)

        try await repository.save(recurringTransaction)

        let fetchedRecurringTransaction = try #require(try await repository.fetchRecurringTransaction(id: id))
        #expect(fetchedRecurringTransaction.id == id)
    }

    @Test func repositoryPreservesAccountID() async throws {
        let repository = try makeRepository()
        let accountID = AccountID(rawValue: try #require(UUID(uuidString: "CF19E717-8512-40FB-85E5-2857E39CD308")))
        let recurringTransaction = try makeRecurringTransaction(accountID: accountID)

        try await repository.save(recurringTransaction)

        let fetchedRecurringTransaction = try #require(
            try await repository.fetchRecurringTransaction(id: recurringTransaction.id)
        )
        #expect(fetchedRecurringTransaction.accountID == accountID)
    }

    @Test func highPrecisionDecimalSurvivesRepositoryPersistence() async throws {
        let repository = try makeRepository()
        let amount = try #require(Decimal(string: "1234567890.123456789012345678"))
        let recurringTransaction = try makeRecurringTransaction(
            amount: Money(amount: amount, currencyCode: "GBP")
        )

        try await repository.save(recurringTransaction)

        let fetchedRecurringTransaction = try #require(
            try await repository.fetchRecurringTransaction(id: recurringTransaction.id)
        )
        #expect(fetchedRecurringTransaction.amount.amount == amount)
        #expect(fetchedRecurringTransaction == recurringTransaction)
    }

    @Test func invalidPersistedRecurringTransactionRecordFailsMapping() async throws {
        let container = try makeInMemoryModelContainer()
        let insertContext = ModelContext(container)
        insertContext.insert(RecurringTransactionRecord(
            id: RecurringTransactionID().rawValue,
            accountID: AccountID().rawValue,
            direction: "outflow",
            amount: "12abc",
            currencyCode: "GBP",
            frequency: "monthly",
            startDate: Date(timeIntervalSince1970: 1_786_080_000),
            endDate: nil,
            memo: "Rent"
        ))
        try insertContext.save()

        let repository = await SwiftDataRecurringTransactionRepository(modelContainer: container)

        await #expect(throws: RecurringTransactionRecordMappingError.invalidAmount("12abc")) {
            try await repository.fetchRecurringTransactions()
        }
    }

    private func makeRepository() throws -> SwiftDataRecurringTransactionRepository {
        try SwiftDataRecurringTransactionRepository(modelContainer: makeInMemoryModelContainer())
    }

    private func makeInMemoryModelContainer() throws -> ModelContainer {
        let schema = Schema([
            RecurringTransactionRecord.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func makeRecurringTransaction(
        id: RecurringTransactionID = RecurringTransactionID(),
        accountID: AccountID = AccountID(),
        direction: TransactionDirection = .outflow,
        amount: Money? = nil,
        frequency: RecurrenceFrequency = .monthly,
        startDate: Date = Date(timeIntervalSince1970: 1_786_080_000),
        endDate: Date? = Date(timeIntervalSince1970: 1_788_672_000),
        memo: String? = "Rent"
    ) throws -> RecurringTransaction {
        try RecurringTransaction(
            id: id,
            accountID: accountID,
            direction: direction,
            amount: amount ?? Money(amount: 12.34, currencyCode: "GBP"),
            frequency: frequency,
            startDate: startDate,
            endDate: endDate,
            memo: memo
        )
    }
}
