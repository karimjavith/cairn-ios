//
//  TransactionRecordTests.swift
//  CairnTests
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import SwiftData
import Testing
@testable import Cairn

struct TransactionRecordTests {

    @Test func transactionToRecordPreservesPersistedValues() throws {
        let id = TransactionID(rawValue: try #require(UUID(uuidString: "36C6C328-4227-4CBA-8F29-16B5EC114286")))
        let accountID = AccountID(rawValue: try #require(UUID(uuidString: "9E849395-8DC9-481A-B56F-1EC9AF46A57D")))
        let amount = try #require(Decimal(string: "1234567890.123456789"))
        let occurredAt = Date(timeIntervalSince1970: 1_786_080_000)
        let transaction = try Transaction(
            id: id,
            accountID: accountID,
            direction: .outflow,
            amount: Money(amount: amount, currencyCode: "gbp"),
            occurredAt: occurredAt,
            memo: "  Lunch\n"
        )

        let record = TransactionRecord(transaction: transaction)

        #expect(record.id == id.rawValue)
        #expect(record.accountID == accountID.rawValue)
        #expect(record.direction == "outflow")
        #expect(record.amount == "1234567890.123456789")
        #expect(record.currencyCode == "GBP")
        #expect(record.occurredAt == occurredAt)
        #expect(record.memo == "Lunch")
    }

    @Test func recordToTransactionReconstructsEquivalentDomainTransaction() throws {
        let id = try #require(UUID(uuidString: "4E4AAAC1-0127-4C78-A02E-EA1F47CCB5B1"))
        let accountID = try #require(UUID(uuidString: "F82163F3-E6C7-474A-BF6D-E1017E6E5C67"))
        let amount = try #require(Decimal(string: "42.01"))
        let occurredAt = Date(timeIntervalSince1970: 1_786_166_400)
        let record = TransactionRecord(
            id: id,
            accountID: accountID,
            direction: "inflow",
            amount: "42.01",
            currencyCode: "EUR",
            occurredAt: occurredAt,
            memo: "Salary"
        )

        let transaction = try record.transaction()
        let expectedTransaction = try Transaction(
            id: TransactionID(rawValue: id),
            accountID: AccountID(rawValue: accountID),
            direction: .inflow,
            amount: Money(amount: amount, currencyCode: "EUR"),
            occurredAt: occurredAt,
            memo: "Salary"
        )

        #expect(transaction == expectedTransaction)
    }

    @Test func transactionIDSurvivesCompleteMappingRoundTrip() throws {
        let id = TransactionID(rawValue: try #require(UUID(uuidString: "8E5F8228-0FBC-40E2-A720-01D82F44728D")))
        let transaction = try makeTransaction(id: id)

        let roundTrippedTransaction = try TransactionRecord(transaction: transaction).transaction()

        #expect(roundTrippedTransaction.id == id)
    }

    @Test func accountIDSurvivesCompleteMappingRoundTrip() throws {
        let accountID = AccountID(rawValue: try #require(UUID(uuidString: "7BAE537C-D634-4882-8476-2E4C54101B04")))
        let transaction = try makeTransaction(accountID: accountID)

        let roundTrippedTransaction = try TransactionRecord(transaction: transaction).transaction()

        #expect(roundTrippedTransaction.accountID == accountID)
    }

    @Test func highPrecisionDecimalAmountSurvivesMappingRoundTrip() throws {
        let amount = try #require(Decimal(string: "1234567890.123456789012345678"))
        let transaction = try makeTransaction(
            amount: Money(amount: amount, currencyCode: "GBP")
        )

        let roundTrippedTransaction = try TransactionRecord(transaction: transaction).transaction()

        #expect(roundTrippedTransaction.amount.amount == amount)
    }

    @Test func currencySurvivesMappingRoundTrip() throws {
        let transaction = try makeTransaction(
            amount: Money(amount: 12, currencyCode: "eur")
        )

        let roundTrippedTransaction = try TransactionRecord(transaction: transaction).transaction()

        #expect(roundTrippedTransaction.amount.currencyCode == "EUR")
    }

    @Test func inflowSurvivesMappingRoundTrip() throws {
        let transaction = try makeTransaction(direction: .inflow)

        let roundTrippedTransaction = try TransactionRecord(transaction: transaction).transaction()

        #expect(roundTrippedTransaction.direction == .inflow)
    }

    @Test func outflowSurvivesMappingRoundTrip() throws {
        let transaction = try makeTransaction(direction: .outflow)

        let roundTrippedTransaction = try TransactionRecord(transaction: transaction).transaction()

        #expect(roundTrippedTransaction.direction == .outflow)
    }

    @Test func occurredAtSurvivesMappingRoundTrip() throws {
        let occurredAt = Date(timeIntervalSince1970: 1_786_252_800)
        let transaction = try makeTransaction(occurredAt: occurredAt)

        let roundTrippedTransaction = try TransactionRecord(transaction: transaction).transaction()

        #expect(roundTrippedTransaction.occurredAt == occurredAt)
    }

    @Test func memoSurvivesNormalizedMappingRoundTrip() throws {
        let transaction = try makeTransaction(memo: "  Coffee\n")

        let roundTrippedTransaction = try TransactionRecord(transaction: transaction).transaction()

        #expect(roundTrippedTransaction.memo == "Coffee")
    }

    @Test func nilMemoSurvivesMappingRoundTrip() throws {
        let transaction = try makeTransaction(memo: nil)

        let roundTrippedTransaction = try TransactionRecord(transaction: transaction).transaction()

        #expect(roundTrippedTransaction.memo == nil)
    }

    @Test func invalidPersistedDirectionFailsReconstruction() {
        let record = makeRecord(direction: "credit")

        #expect(throws: TransactionRecordMappingError.invalidDirection("credit")) {
            try record.transaction()
        }
    }

    @Test func invalidPersistedDecimalFailsReconstruction() {
        let record = makeRecord(amount: "not-a-decimal")

        #expect(throws: TransactionRecordMappingError.invalidAmount("not-a-decimal")) {
            try record.transaction()
        }
    }

    @Test func dotDecimalPersistedTextReconstructsExactly() throws {
        let record = makeRecord(amount: "42.01")
        let expectedAmount = try #require(
            Decimal(string: "42.01", locale: Locale(identifier: "en_US_POSIX"))
        )

        let transaction = try record.transaction()

        #expect(transaction.amount.amount == expectedAmount)
    }

    @Test func exponentPersistedTextReconstructsExactly() throws {
        let record = makeRecord(amount: "1.23e2")
        let expectedAmount = try #require(
            Decimal(string: "123", locale: Locale(identifier: "en_US_POSIX"))
        )

        let transaction = try record.transaction()

        #expect(transaction.amount.amount == expectedAmount)
    }

    @Test func partiallyParsedPersistedDecimalFailsReconstruction() {
        let record = makeRecord(amount: "12abc")

        #expect(throws: TransactionRecordMappingError.invalidAmount("12abc")) {
            try record.transaction()
        }
    }

    @Test func localeStylePersistedDecimalFailsReconstruction() {
        let record = makeRecord(amount: "1,23")

        #expect(throws: TransactionRecordMappingError.invalidAmount("1,23")) {
            try record.transaction()
        }
    }

    @Test func negativePersistedAmountFailsThroughDomainValidation() {
        let record = makeRecord(amount: "-1")

        #expect(throws: Transaction.ValidationError.negativeAmount) {
            try record.transaction()
        }
    }

    @Test func swiftDataPersistenceRoundTripPreservesTransactionValues() throws {
        let id = TransactionID(rawValue: try #require(UUID(uuidString: "BDE30E88-71A6-40E8-95E6-E529614A92F3")))
        let accountID = AccountID(rawValue: try #require(UUID(uuidString: "3A8D42D7-56B1-4039-8DC1-80F0AD3374D7")))
        let amount = try #require(Decimal(string: "1234567890.123456789012345678"))
        let occurredAt = Date(timeIntervalSince1970: 1_786_339_200)
        let transaction = try Transaction(
            id: id,
            accountID: accountID,
            direction: .outflow,
            amount: Money(amount: amount, currencyCode: "gbp"),
            occurredAt: occurredAt,
            memo: "  Rent\n"
        )
        let container = try makeInMemoryModelContainer()
        let insertContext = ModelContext(container)

        insertContext.insert(TransactionRecord(transaction: transaction))
        try insertContext.save()

        let fetchContext = ModelContext(container)
        let descriptor = FetchDescriptor<TransactionRecord>()
        let fetchedRecord = try #require(try fetchContext.fetch(descriptor).first)
        let fetchedTransaction = try fetchedRecord.transaction()

        #expect(fetchedTransaction.id == id)
        #expect(fetchedTransaction.accountID == accountID)
        #expect(fetchedTransaction.direction == .outflow)
        #expect(fetchedTransaction.amount.amount == amount)
        #expect(fetchedTransaction.amount.currencyCode == "GBP")
        #expect(fetchedTransaction.occurredAt == occurredAt)
        #expect(fetchedTransaction.memo == "Rent")
    }

    private func makeTransaction(
        id: TransactionID? = nil,
        accountID: AccountID? = nil,
        direction: TransactionDirection = .outflow,
        amount: Money? = nil,
        occurredAt: Date = Date(timeIntervalSince1970: 1_786_080_000),
        memo: String? = "Lunch"
    ) throws -> Transaction {
        let defaultID = TransactionID(rawValue: try #require(UUID(uuidString: "36C6C328-4227-4CBA-8F29-16B5EC114286")))
        let defaultAccountID = AccountID(rawValue: try #require(UUID(uuidString: "9E849395-8DC9-481A-B56F-1EC9AF46A57D")))

        return try Transaction(
            id: id ?? defaultID,
            accountID: accountID ?? defaultAccountID,
            direction: direction,
            amount: amount ?? Money(amount: 12.34, currencyCode: "GBP"),
            occurredAt: occurredAt,
            memo: memo
        )
    }

    private func makeRecord(
        direction: String = "outflow",
        amount: String = "12.34"
    ) -> TransactionRecord {
        TransactionRecord(
            id: UUID(),
            accountID: UUID(),
            direction: direction,
            amount: amount,
            currencyCode: "GBP",
            occurredAt: Date(timeIntervalSince1970: 1_786_080_000),
            memo: "Lunch"
        )
    }

    private func makeInMemoryModelContainer() throws -> ModelContainer {
        let schema = Schema([
            TransactionRecord.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
