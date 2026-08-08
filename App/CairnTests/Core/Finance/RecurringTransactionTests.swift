//
//  RecurringTransactionTests.swift
//  CairnTests
//
//  Created by Karim Sheikh on 08/08/2026.
//

import Foundation
import Testing
@testable import Cairn

struct RecurringTransactionTests {

    @Test func recurringTransactionIDIsCodable() throws {
        let id = RecurringTransactionID(rawValue: try #require(UUID(uuidString: "8C9F22C9-79A9-4545-8888-A7CB6FE4B8B8")))

        let encoded = try JSONEncoder().encode(id)
        let decoded = try JSONDecoder().decode(RecurringTransactionID.self, from: encoded)

        #expect(decoded == id)
    }

    @Test func initializationStoresValues() throws {
        let id = RecurringTransactionID(rawValue: try #require(UUID(uuidString: "8C9F22C9-79A9-4545-8888-A7CB6FE4B8B8")))
        let accountID = AccountID(rawValue: try #require(UUID(uuidString: "9E849395-8DC9-481A-B56F-1EC9AF46A57D")))
        let amount = try Money(amount: 12.34, currencyCode: "GBP")
        let startDate = Date(timeIntervalSince1970: 1_786_080_000)
        let endDate = Date(timeIntervalSince1970: 1_788_672_000)

        let recurringTransaction = try RecurringTransaction(
            id: id,
            accountID: accountID,
            direction: .outflow,
            amount: amount,
            frequency: .monthly,
            startDate: startDate,
            endDate: endDate,
            memo: "Rent"
        )

        #expect(recurringTransaction.id == id)
        #expect(recurringTransaction.accountID == accountID)
        #expect(recurringTransaction.direction == .outflow)
        #expect(recurringTransaction.amount == amount)
        #expect(recurringTransaction.frequency == .monthly)
        #expect(recurringTransaction.startDate == startDate)
        #expect(recurringTransaction.endDate == endDate)
        #expect(recurringTransaction.memo == "Rent")
    }

    @Test func inflowIsStoredAsDirectionWithoutNegatingAmount() throws {
        let amount = try Money(amount: 100, currencyCode: "GBP")

        let recurringTransaction = try makeRecurringTransaction(
            direction: .inflow,
            amount: amount
        )

        #expect(recurringTransaction.direction == .inflow)
        #expect(recurringTransaction.amount.amount == 100)
    }

    @Test func outflowIsStoredAsDirectionWithoutNegatingAmount() throws {
        let amount = try Money(amount: 45.67, currencyCode: "GBP")

        let recurringTransaction = try makeRecurringTransaction(
            direction: .outflow,
            amount: amount
        )

        #expect(recurringTransaction.direction == .outflow)
        #expect(recurringTransaction.amount.amount == 45.67)
    }

    @Test func initializationRejectsNegativeAmount() throws {
        let amount = try Money(amount: -1, currencyCode: "GBP")

        #expect(throws: RecurringTransaction.ValidationError.negativeAmount) {
            try makeRecurringTransaction(amount: amount)
        }
    }

    @Test func initializationAcceptsZeroAmount() throws {
        let amount = try Money(amount: 0, currencyCode: "GBP")

        let recurringTransaction = try makeRecurringTransaction(amount: amount)

        #expect(recurringTransaction.amount.amount == 0)
    }

    @Test func initializationTrimsMemo() throws {
        let recurringTransaction = try makeRecurringTransaction(memo: "  Mortgage\n")

        #expect(recurringTransaction.memo == "Mortgage")
    }

    @Test func initializationConvertsEmptyMemoToNil() throws {
        let blankMemo = try makeRecurringTransaction(memo: " \n\t ")
        let nilMemo = try makeRecurringTransaction(memo: nil)

        #expect(blankMemo.memo == nil)
        #expect(nilMemo.memo == nil)
    }

    @Test func initializationAcceptsNoEndDate() throws {
        let recurringTransaction = try makeRecurringTransaction(endDate: nil)

        #expect(recurringTransaction.endDate == nil)
    }

    @Test func initializationAcceptsEndDateAfterStartDate() throws {
        let startDate = Date(timeIntervalSince1970: 1_786_080_000)
        let endDate = Date(timeIntervalSince1970: 1_786_166_400)

        let recurringTransaction = try makeRecurringTransaction(
            startDate: startDate,
            endDate: endDate
        )

        #expect(recurringTransaction.startDate == startDate)
        #expect(recurringTransaction.endDate == endDate)
    }

    @Test func initializationRejectsEqualStartAndEndDate() throws {
        let startDate = Date(timeIntervalSince1970: 1_786_080_000)

        #expect(throws: RecurringTransaction.ValidationError.invalidDateRange) {
            try makeRecurringTransaction(
                startDate: startDate,
                endDate: startDate
            )
        }
    }

    @Test func initializationRejectsEndDateBeforeStartDate() throws {
        let startDate = Date(timeIntervalSince1970: 1_786_080_000)
        let endDate = Date(timeIntervalSince1970: 1_785_993_600)

        #expect(throws: RecurringTransaction.ValidationError.invalidDateRange) {
            try makeRecurringTransaction(
                startDate: startDate,
                endDate: endDate
            )
        }
    }

    @Test func equalityUsesAllStoredValues() throws {
        let id = RecurringTransactionID(rawValue: try #require(UUID(uuidString: "8C9F22C9-79A9-4545-8888-A7CB6FE4B8B8")))
        let accountID = AccountID(rawValue: try #require(UUID(uuidString: "9E849395-8DC9-481A-B56F-1EC9AF46A57D")))
        let amount = try Money(amount: 12.34, currencyCode: "GBP")
        let startDate = Date(timeIntervalSince1970: 1_786_080_000)
        let first = try RecurringTransaction(
            id: id,
            accountID: accountID,
            direction: .outflow,
            amount: amount,
            frequency: .monthly,
            startDate: startDate,
            memo: "Rent"
        )
        let same = try RecurringTransaction(
            id: id,
            accountID: accountID,
            direction: .outflow,
            amount: amount,
            frequency: .monthly,
            startDate: startDate,
            memo: "Rent"
        )
        let different = try RecurringTransaction(
            id: id,
            accountID: accountID,
            direction: .outflow,
            amount: amount,
            frequency: .weekly,
            startDate: startDate,
            memo: "Rent"
        )

        #expect(first == same)
        #expect(first != different)
    }

    @Test func hashableUsesStoredValues() throws {
        let recurringTransaction = try makeRecurringTransaction()
        let same = try makeRecurringTransaction(id: recurringTransaction.id)

        #expect(Set([recurringTransaction, same]).count == 1)
    }

    @Test func recurrenceFrequencyIsCodable() throws {
        let frequency = RecurrenceFrequency.yearly

        let encoded = try JSONEncoder().encode(frequency)
        let decoded = try JSONDecoder().decode(RecurrenceFrequency.self, from: encoded)

        #expect(decoded == frequency)
    }

    @Test func recurringTransactionIsCodable() throws {
        let recurringTransaction = try makeRecurringTransaction(memo: "Salary")

        let encoded = try JSONEncoder().encode(recurringTransaction)
        let decoded = try JSONDecoder().decode(RecurringTransaction.self, from: encoded)

        #expect(decoded == recurringTransaction)
    }

    @Test func recurringTransactionCodablePreservesDirectionSeparateFromAmountSign() throws {
        let recurringTransaction = try makeRecurringTransaction(
            direction: .outflow,
            amount: try Money(amount: 25, currencyCode: "GBP")
        )

        let encoded = try JSONEncoder().encode(recurringTransaction)
        let decoded = try JSONDecoder().decode(RecurringTransaction.self, from: encoded)

        #expect(decoded.direction == .outflow)
        #expect(decoded.amount.amount == 25)
    }

    @Test func recurringTransactionCodableAppliesAmountValidationWhenDecoding() throws {
        let recurringTransaction = try makeRecurringTransaction()
        let encoded = try JSONEncoder().encode(recurringTransaction)
        var json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        json["amount"] = -1
        let data = try JSONSerialization.data(withJSONObject: json)

        #expect(throws: RecurringTransaction.ValidationError.negativeAmount) {
            try JSONDecoder().decode(RecurringTransaction.self, from: data)
        }
    }

    @Test func recurringTransactionCodableAppliesDateValidationWhenDecoding() throws {
        let recurringTransaction = try makeRecurringTransaction()
        let encoded = try JSONEncoder().encode(recurringTransaction)
        var json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        json["endDate"] = json["startDate"]
        let data = try JSONSerialization.data(withJSONObject: json)

        #expect(throws: RecurringTransaction.ValidationError.invalidDateRange) {
            try JSONDecoder().decode(RecurringTransaction.self, from: data)
        }
    }

    @Test func recurringTransactionCodableTrimsMemoWhenDecoding() throws {
        let recurringTransaction = try makeRecurringTransaction()
        let encoded = try JSONEncoder().encode(recurringTransaction)
        var json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        json["memo"] = "  Council tax\n"
        let data = try JSONSerialization.data(withJSONObject: json)

        let decoded = try JSONDecoder().decode(RecurringTransaction.self, from: data)

        #expect(decoded.memo == "Council tax")
    }

    @Test func recurringTransactionIsSendable() throws {
        let recurringTransaction = try makeRecurringTransaction()

        requireSendable(recurringTransaction)
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
        let defaultID = RecurringTransactionID(rawValue: try #require(UUID(uuidString: "8C9F22C9-79A9-4545-8888-A7CB6FE4B8B8")))
        let defaultAccountID = AccountID(rawValue: try #require(UUID(uuidString: "9E849395-8DC9-481A-B56F-1EC9AF46A57D")))

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

    private func requireSendable<T: Sendable>(_ value: T) {
        _ = value
    }
}
