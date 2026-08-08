//
//  RecurringTransactionRecordTests.swift
//  CairnTests
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import SwiftData
import Testing
@testable import Cairn

struct RecurringTransactionRecordTests {

    @Test func recurringTransactionToRecordPreservesPersistedValues() throws {
        let id = RecurringTransactionID(rawValue: try #require(UUID(uuidString: "D2863CE6-51E2-4B81-8F62-5138C1F0C40B")))
        let accountID = AccountID(rawValue: try #require(UUID(uuidString: "1ED8AC19-F9B3-46BA-9C18-99A61E10B3C2")))
        let amount = try #require(Decimal(string: "1234567890.123456789"))
        let startDate = Date(timeIntervalSince1970: 1_786_080_000)
        let endDate = Date(timeIntervalSince1970: 1_788_672_000)
        let recurringTransaction = try RecurringTransaction(
            id: id,
            accountID: accountID,
            direction: .outflow,
            amount: Money(amount: amount, currencyCode: "gbp"),
            frequency: .monthly,
            startDate: startDate,
            endDate: endDate,
            memo: "  Rent\n"
        )

        let record = RecurringTransactionRecord(recurringTransaction: recurringTransaction)

        #expect(record.id == id.rawValue)
        #expect(record.accountID == accountID.rawValue)
        #expect(record.direction == "outflow")
        #expect(record.amount == "1234567890.123456789")
        #expect(record.currencyCode == "GBP")
        #expect(record.frequency == "monthly")
        #expect(record.startDate == startDate)
        #expect(record.endDate == endDate)
        #expect(record.memo == "Rent")
    }

    @Test func recordToRecurringTransactionReconstructsEquivalentDomainValue() throws {
        let id = try #require(UUID(uuidString: "4E4AAAC1-0127-4C78-A02E-EA1F47CCB5B1"))
        let accountID = try #require(UUID(uuidString: "F82163F3-E6C7-474A-BF6D-E1017E6E5C67"))
        let amount = try #require(Decimal(string: "42.01"))
        let startDate = Date(timeIntervalSince1970: 1_786_166_400)
        let endDate = Date(timeIntervalSince1970: 1_788_672_000)
        let record = RecurringTransactionRecord(
            id: id,
            accountID: accountID,
            direction: "inflow",
            amount: "42.01",
            currencyCode: "EUR",
            frequency: "weekly",
            startDate: startDate,
            endDate: endDate,
            memo: "Salary"
        )

        let recurringTransaction = try record.recurringTransaction()
        let expectedRecurringTransaction = try RecurringTransaction(
            id: RecurringTransactionID(rawValue: id),
            accountID: AccountID(rawValue: accountID),
            direction: .inflow,
            amount: Money(amount: amount, currencyCode: "EUR"),
            frequency: .weekly,
            startDate: startDate,
            endDate: endDate,
            memo: "Salary"
        )

        #expect(recurringTransaction == expectedRecurringTransaction)
    }

    @Test func recurringTransactionIDSurvivesCompleteMappingRoundTrip() throws {
        let id = RecurringTransactionID(rawValue: try #require(UUID(uuidString: "8E5F8228-0FBC-40E2-A720-01D82F44728D")))
        let recurringTransaction = try makeRecurringTransaction(id: id)

        let roundTrippedRecurringTransaction = try RecurringTransactionRecord(
            recurringTransaction: recurringTransaction
        ).recurringTransaction()

        #expect(roundTrippedRecurringTransaction.id == id)
    }

    @Test func accountIDSurvivesCompleteMappingRoundTrip() throws {
        let accountID = AccountID(rawValue: try #require(UUID(uuidString: "7BAE537C-D634-4882-8476-2E4C54101B04")))
        let recurringTransaction = try makeRecurringTransaction(accountID: accountID)

        let roundTrippedRecurringTransaction = try RecurringTransactionRecord(
            recurringTransaction: recurringTransaction
        ).recurringTransaction()

        #expect(roundTrippedRecurringTransaction.accountID == accountID)
    }

    @Test func highPrecisionDecimalAmountSurvivesMappingRoundTrip() throws {
        let amount = try #require(Decimal(string: "1234567890.123456789012345678"))
        let recurringTransaction = try makeRecurringTransaction(
            amount: Money(amount: amount, currencyCode: "GBP")
        )

        let roundTrippedRecurringTransaction = try RecurringTransactionRecord(
            recurringTransaction: recurringTransaction
        ).recurringTransaction()

        #expect(roundTrippedRecurringTransaction.amount.amount == amount)
    }

    @Test func currencySurvivesMappingRoundTrip() throws {
        let recurringTransaction = try makeRecurringTransaction(
            amount: Money(amount: 12, currencyCode: "eur")
        )

        let roundTrippedRecurringTransaction = try RecurringTransactionRecord(
            recurringTransaction: recurringTransaction
        ).recurringTransaction()

        #expect(roundTrippedRecurringTransaction.amount.currencyCode == "EUR")
    }

    @Test func inflowSurvivesMappingRoundTrip() throws {
        let recurringTransaction = try makeRecurringTransaction(direction: .inflow)

        let roundTrippedRecurringTransaction = try RecurringTransactionRecord(
            recurringTransaction: recurringTransaction
        ).recurringTransaction()

        #expect(roundTrippedRecurringTransaction.direction == .inflow)
    }

    @Test func outflowSurvivesMappingRoundTrip() throws {
        let recurringTransaction = try makeRecurringTransaction(direction: .outflow)

        let roundTrippedRecurringTransaction = try RecurringTransactionRecord(
            recurringTransaction: recurringTransaction
        ).recurringTransaction()

        #expect(roundTrippedRecurringTransaction.direction == .outflow)
    }

    @Test(arguments: [
        RecurrenceFrequency.daily,
        .weekly,
        .monthly,
        .yearly
    ])
    func recurrenceFrequencySurvivesMappingRoundTrip(frequency: RecurrenceFrequency) throws {
        let recurringTransaction = try makeRecurringTransaction(frequency: frequency)

        let roundTrippedRecurringTransaction = try RecurringTransactionRecord(
            recurringTransaction: recurringTransaction
        ).recurringTransaction()

        #expect(roundTrippedRecurringTransaction.frequency == frequency)
    }

    @Test func startDateSurvivesMappingRoundTrip() throws {
        let startDate = Date(timeIntervalSince1970: 1_786_252_800)
        let recurringTransaction = try makeRecurringTransaction(startDate: startDate)

        let roundTrippedRecurringTransaction = try RecurringTransactionRecord(
            recurringTransaction: recurringTransaction
        ).recurringTransaction()

        #expect(roundTrippedRecurringTransaction.startDate == startDate)
    }

    @Test func nilEndDateSurvivesMappingRoundTrip() throws {
        let recurringTransaction = try makeRecurringTransaction(endDate: nil)

        let roundTrippedRecurringTransaction = try RecurringTransactionRecord(
            recurringTransaction: recurringTransaction
        ).recurringTransaction()

        #expect(roundTrippedRecurringTransaction.endDate == nil)
    }

    @Test func nonNilEndDateSurvivesMappingRoundTrip() throws {
        let endDate = Date(timeIntervalSince1970: 1_788_672_000)
        let recurringTransaction = try makeRecurringTransaction(endDate: endDate)

        let roundTrippedRecurringTransaction = try RecurringTransactionRecord(
            recurringTransaction: recurringTransaction
        ).recurringTransaction()

        #expect(roundTrippedRecurringTransaction.endDate == endDate)
    }

    @Test func normalizedMemoSurvivesMappingRoundTrip() throws {
        let recurringTransaction = try makeRecurringTransaction(memo: "  Mortgage\n")

        let roundTrippedRecurringTransaction = try RecurringTransactionRecord(
            recurringTransaction: recurringTransaction
        ).recurringTransaction()

        #expect(roundTrippedRecurringTransaction.memo == "Mortgage")
    }

    @Test func nilMemoSurvivesMappingRoundTrip() throws {
        let recurringTransaction = try makeRecurringTransaction(memo: nil)

        let roundTrippedRecurringTransaction = try RecurringTransactionRecord(
            recurringTransaction: recurringTransaction
        ).recurringTransaction()

        #expect(roundTrippedRecurringTransaction.memo == nil)
    }

    @Test func whitespaceOnlyPersistedMemoResolvesThroughDomainValidation() throws {
        let record = makeRecord(memo: " \n\t ")

        let recurringTransaction = try record.recurringTransaction()

        #expect(recurringTransaction.memo == nil)
    }

    @Test func zeroAmountSurvivesMappingRoundTrip() throws {
        let recurringTransaction = try makeRecurringTransaction(
            amount: Money(amount: 0, currencyCode: "GBP")
        )

        let roundTrippedRecurringTransaction = try RecurringTransactionRecord(
            recurringTransaction: recurringTransaction
        ).recurringTransaction()

        #expect(roundTrippedRecurringTransaction.amount.amount == 0)
    }

    @Test func invalidPersistedDecimalFailsReconstruction() {
        let record = makeRecord(amount: "not-a-decimal")

        #expect(throws: RecurringTransactionRecordMappingError.invalidAmount("not-a-decimal")) {
            try record.recurringTransaction()
        }
    }

    @Test func dotDecimalPersistedTextReconstructsExactly() throws {
        let record = makeRecord(amount: "42.01")
        let expectedAmount = try #require(
            Decimal(string: "42.01", locale: Locale(identifier: "en_US_POSIX"))
        )

        let recurringTransaction = try record.recurringTransaction()

        #expect(recurringTransaction.amount.amount == expectedAmount)
    }

    @Test func highPrecisionDotDecimalPersistedTextReconstructsExactly() throws {
        let amount = "1234567890.123456789012345678"
        let record = makeRecord(amount: amount)
        let expectedAmount = try #require(
            Decimal(string: amount, locale: Locale(identifier: "en_US_POSIX"))
        )

        let recurringTransaction = try record.recurringTransaction()

        #expect(recurringTransaction.amount.amount == expectedAmount)
    }

    @Test func exponentPersistedTextReconstructsExactly() throws {
        let record = makeRecord(amount: "1.23e2")
        let expectedAmount = try #require(
            Decimal(string: "123", locale: Locale(identifier: "en_US_POSIX"))
        )

        let recurringTransaction = try record.recurringTransaction()

        #expect(recurringTransaction.amount.amount == expectedAmount)
    }

    @Test(arguments: ["12abc", "1,23", "not-a-number"])
    func malformedPersistedDecimalFailsReconstruction(value: String) {
        let record = makeRecord(amount: value)

        #expect(throws: RecurringTransactionRecordMappingError.invalidAmount(value)) {
            try record.recurringTransaction()
        }
    }

    @Test func negativePersistedAmountFailsThroughDomainValidation() {
        let record = makeRecord(amount: "-1")

        #expect(throws: RecurringTransaction.ValidationError.negativeAmount) {
            try record.recurringTransaction()
        }
    }

    @Test func invalidPersistedDirectionFailsReconstruction() {
        let record = makeRecord(direction: "credit")

        #expect(throws: RecurringTransactionRecordMappingError.invalidDirection("credit")) {
            try record.recurringTransaction()
        }
    }

    @Test func invalidPersistedRecurrenceFrequencyFailsReconstruction() {
        let record = makeRecord(frequency: "fortnightly")

        #expect(throws: RecurringTransactionRecordMappingError.invalidFrequency("fortnightly")) {
            try record.recurringTransaction()
        }
    }

    @Test func equalStartAndEndDateFailsThroughDomainValidation() {
        let startDate = Date(timeIntervalSince1970: 1_786_080_000)
        let record = makeRecord(startDate: startDate, endDate: startDate)

        #expect(throws: RecurringTransaction.ValidationError.invalidDateRange) {
            try record.recurringTransaction()
        }
    }

    @Test func endDateBeforeStartDateFailsThroughDomainValidation() {
        let startDate = Date(timeIntervalSince1970: 1_786_080_000)
        let endDate = Date(timeIntervalSince1970: 1_785_993_600)
        let record = makeRecord(startDate: startDate, endDate: endDate)

        #expect(throws: RecurringTransaction.ValidationError.invalidDateRange) {
            try record.recurringTransaction()
        }
    }

    @Test func swiftDataPersistenceRoundTripPreservesRecurringTransactionValues() throws {
        let id = RecurringTransactionID(rawValue: try #require(UUID(uuidString: "BDE30E88-71A6-40E8-95E6-E529614A92F3")))
        let accountID = AccountID(rawValue: try #require(UUID(uuidString: "3A8D42D7-56B1-4039-8DC1-80F0AD3374D7")))
        let amount = try #require(Decimal(string: "1234567890.123456789012345678"))
        let startDate = Date(timeIntervalSince1970: 1_786_339_200)
        let endDate = Date(timeIntervalSince1970: 1_788_672_000)
        let recurringTransaction = try RecurringTransaction(
            id: id,
            accountID: accountID,
            direction: .outflow,
            amount: Money(amount: amount, currencyCode: "gbp"),
            frequency: .monthly,
            startDate: startDate,
            endDate: endDate,
            memo: "  Rent\n"
        )
        let container = try makeInMemoryModelContainer()
        let insertContext = ModelContext(container)

        insertContext.insert(RecurringTransactionRecord(recurringTransaction: recurringTransaction))
        try insertContext.save()

        let fetchContext = ModelContext(container)
        let descriptor = FetchDescriptor<RecurringTransactionRecord>()
        let fetchedRecord = try #require(try fetchContext.fetch(descriptor).first)
        let fetchedRecurringTransaction = try fetchedRecord.recurringTransaction()

        #expect(fetchedRecurringTransaction.id == id)
        #expect(fetchedRecurringTransaction.accountID == accountID)
        #expect(fetchedRecurringTransaction.direction == .outflow)
        #expect(fetchedRecurringTransaction.amount.amount == amount)
        #expect(fetchedRecurringTransaction.amount.currencyCode == "GBP")
        #expect(fetchedRecurringTransaction.frequency == .monthly)
        #expect(fetchedRecurringTransaction.startDate == startDate)
        #expect(fetchedRecurringTransaction.endDate == endDate)
        #expect(fetchedRecurringTransaction.memo == "Rent")
    }

    private func makeRecurringTransaction(
        id: RecurringTransactionID? = nil,
        accountID: AccountID? = nil,
        direction: TransactionDirection = .outflow,
        amount: Money? = nil,
        frequency: RecurrenceFrequency = .monthly,
        startDate: Date = Date(timeIntervalSince1970: 1_786_080_000),
        endDate: Date? = Date(timeIntervalSince1970: 1_788_672_000),
        memo: String? = "Rent"
    ) throws -> RecurringTransaction {
        let defaultID = RecurringTransactionID(rawValue: try #require(UUID(uuidString: "D2863CE6-51E2-4B81-8F62-5138C1F0C40B")))
        let defaultAccountID = AccountID(rawValue: try #require(UUID(uuidString: "1ED8AC19-F9B3-46BA-9C18-99A61E10B3C2")))

        return try RecurringTransaction(
            id: id ?? defaultID,
            accountID: accountID ?? defaultAccountID,
            direction: direction,
            amount: amount ?? Money(amount: 12.34, currencyCode: "GBP"),
            frequency: frequency,
            startDate: startDate,
            endDate: endDate,
            memo: memo
        )
    }

    private func makeRecord(
        direction: String = "outflow",
        amount: String = "12.34",
        frequency: String = "monthly",
        startDate: Date = Date(timeIntervalSince1970: 1_786_080_000),
        endDate: Date? = Date(timeIntervalSince1970: 1_788_672_000),
        memo: String? = "Rent"
    ) -> RecurringTransactionRecord {
        RecurringTransactionRecord(
            id: UUID(),
            accountID: UUID(),
            direction: direction,
            amount: amount,
            currencyCode: "GBP",
            frequency: frequency,
            startDate: startDate,
            endDate: endDate,
            memo: memo
        )
    }

    private func makeInMemoryModelContainer() throws -> ModelContainer {
        let schema = Schema([
            RecurringTransactionRecord.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
