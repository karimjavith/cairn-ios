//
//  TransactionTests.swift
//  CairnTests
//
//  Created by Karim Sheikh on 07/08/2026.
//

import Foundation
import Testing
@testable import Cairn

struct TransactionTests {

    @Test func initializationStoresValues() throws {
        let id = TransactionID(rawValue: try #require(UUID(uuidString: "36C6C328-4227-4CBA-8F29-16B5EC114286")))
        let accountID = AccountID(rawValue: try #require(UUID(uuidString: "9E849395-8DC9-481A-B56F-1EC9AF46A57D")))
        let categoryID = CategoryID(rawValue: try #require(UUID(uuidString: "4D26CE21-335E-4C27-98DA-164C86E20AD8")))
        let amount = try Money(amount: 12.34, currencyCode: "GBP")
        let occurredAt = Date(timeIntervalSince1970: 1_786_080_000)

        let transaction = try Transaction(
            id: id,
            accountID: accountID,
            direction: .outflow,
            amount: amount,
            occurredAt: occurredAt,
            categoryID: categoryID,
            memo: "Lunch"
        )

        #expect(transaction.id == id)
        #expect(transaction.accountID == accountID)
        #expect(transaction.direction == .outflow)
        #expect(transaction.amount == amount)
        #expect(transaction.occurredAt == occurredAt)
        #expect(transaction.categoryID == categoryID)
        #expect(transaction.memo == "Lunch")
    }

    @Test func initializationAllowsNilCategory() throws {
        let transaction = try makeTransaction(categoryID: nil)

        #expect(transaction.categoryID == nil)
    }

    @Test func initializationPreservesCategoryID() throws {
        let categoryID = CategoryID(rawValue: try #require(UUID(uuidString: "4D26CE21-335E-4C27-98DA-164C86E20AD8")))

        let transaction = try makeTransaction(categoryID: categoryID)

        #expect(transaction.categoryID == categoryID)
    }

    @Test func propertiesAreImmutableAfterInitialization() throws {
        let transaction = try makeTransaction(memo: "Coffee")

        #expect(transaction.memo == "Coffee")
    }

    @Test func inflowIsStoredAsDirectionWithoutNegatingAmount() throws {
        let amount = try Money(amount: 100, currencyCode: "GBP")

        let transaction = try makeTransaction(
            direction: .inflow,
            amount: amount
        )

        #expect(transaction.direction == .inflow)
        #expect(transaction.amount.amount == 100)
    }

    @Test func outflowIsStoredAsDirectionWithoutNegatingAmount() throws {
        let amount = try Money(amount: 45.67, currencyCode: "GBP")

        let transaction = try makeTransaction(
            direction: .outflow,
            amount: amount
        )

        #expect(transaction.direction == .outflow)
        #expect(transaction.amount.amount == 45.67)
    }

    @Test func initializationRejectsNegativeAmount() throws {
        let amount = try Money(amount: -1, currencyCode: "GBP")

        #expect(throws: Transaction.ValidationError.negativeAmount) {
            try makeTransaction(amount: amount)
        }
    }

    @Test func initializationAcceptsZeroAmount() throws {
        let amount = try Money(amount: 0, currencyCode: "GBP")

        let transaction = try makeTransaction(amount: amount)

        #expect(transaction.amount.amount == 0)
    }

    @Test func initializationTrimsMemo() throws {
        let transaction = try makeTransaction(memo: "  Groceries\n")

        #expect(transaction.memo == "Groceries")
    }

    @Test func initializationConvertsEmptyMemoToNil() throws {
        let blankMemo = try makeTransaction(memo: " \n\t ")
        let nilMemo = try makeTransaction(memo: nil)

        #expect(blankMemo.memo == nil)
        #expect(nilMemo.memo == nil)
    }

    @Test func equalityUsesAllStoredValues() throws {
        let id = TransactionID(rawValue: try #require(UUID(uuidString: "36C6C328-4227-4CBA-8F29-16B5EC114286")))
        let accountID = AccountID(rawValue: try #require(UUID(uuidString: "9E849395-8DC9-481A-B56F-1EC9AF46A57D")))
        let amount = try Money(amount: 12.34, currencyCode: "GBP")
        let occurredAt = Date(timeIntervalSince1970: 1_786_080_000)
        let first = try Transaction(
            id: id,
            accountID: accountID,
            direction: .outflow,
            amount: amount,
            occurredAt: occurredAt,
            categoryID: nil,
            memo: "Lunch"
        )
        let same = try Transaction(
            id: id,
            accountID: accountID,
            direction: .outflow,
            amount: amount,
            occurredAt: occurredAt,
            categoryID: nil,
            memo: "Lunch"
        )
        let different = try Transaction(
            id: id,
            accountID: accountID,
            direction: .inflow,
            amount: amount,
            occurredAt: occurredAt,
            categoryID: nil,
            memo: "Lunch"
        )

        #expect(first == same)
        #expect(first != different)
    }

    @Test func hashableUsesStoredValues() throws {
        let transaction = try makeTransaction()
        let same = try makeTransaction(id: transaction.id)

        #expect(Set([transaction, same]).count == 1)
    }

    @Test func transactionIDDefaultsToUniqueUUIDBackedValues() {
        let first = TransactionID()
        let second = TransactionID()

        #expect(first != second)
    }

    @Test func transactionIDIsCodable() throws {
        let id = TransactionID(rawValue: try #require(UUID(uuidString: "36C6C328-4227-4CBA-8F29-16B5EC114286")))

        let encoded = try JSONEncoder().encode(id)
        let decoded = try JSONDecoder().decode(TransactionID.self, from: encoded)

        #expect(decoded == id)
    }

    @Test func transactionDirectionIsCodable() throws {
        let direction = TransactionDirection.outflow

        let encoded = try JSONEncoder().encode(direction)
        let decoded = try JSONDecoder().decode(TransactionDirection.self, from: encoded)

        #expect(decoded == direction)
    }

    @Test func transactionIsCodable() throws {
        let transaction = try makeTransaction(memo: "Salary")

        let encoded = try JSONEncoder().encode(transaction)
        let decoded = try JSONDecoder().decode(Transaction.self, from: encoded)

        #expect(decoded == transaction)
    }

    @Test func transactionCodablePreservesNilCategory() throws {
        let transaction = try makeTransaction(categoryID: nil)

        let encoded = try JSONEncoder().encode(transaction)
        let decoded = try JSONDecoder().decode(Transaction.self, from: encoded)

        #expect(decoded.categoryID == nil)
        #expect(decoded == transaction)
    }

    @Test func transactionCodablePreservesCategoryID() throws {
        let categoryID = CategoryID(rawValue: try #require(UUID(uuidString: "4D26CE21-335E-4C27-98DA-164C86E20AD8")))
        let transaction = try makeTransaction(categoryID: categoryID)

        let encoded = try JSONEncoder().encode(transaction)
        let decoded = try JSONDecoder().decode(Transaction.self, from: encoded)

        #expect(decoded.categoryID == categoryID)
        #expect(decoded == transaction)
    }

    @Test func transactionCodablePreservesDirectionSeparateFromAmountSign() throws {
        let transaction = try makeTransaction(
            direction: .outflow,
            amount: try Money(amount: 25, currencyCode: "GBP")
        )

        let encoded = try JSONEncoder().encode(transaction)
        let decoded = try JSONDecoder().decode(Transaction.self, from: encoded)

        #expect(decoded.direction == .outflow)
        #expect(decoded.amount.amount == 25)
    }

    @Test func transactionCodableAppliesValidationWhenDecoding() throws {
        let transaction = try makeTransaction()
        let encoded = try JSONEncoder().encode(transaction)
        var json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        json["amount"] = -1
        let data = try JSONSerialization.data(withJSONObject: json)

        #expect(throws: Transaction.ValidationError.negativeAmount) {
            try JSONDecoder().decode(Transaction.self, from: data)
        }
    }

    @Test func transactionIsSendable() throws {
        let transaction = try makeTransaction()

        requireSendable(transaction)
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
        let defaultID = TransactionID(rawValue: try #require(UUID(uuidString: "36C6C328-4227-4CBA-8F29-16B5EC114286")))
        let defaultAccountID = AccountID(rawValue: try #require(UUID(uuidString: "9E849395-8DC9-481A-B56F-1EC9AF46A57D")))

        return try Transaction(
            id: id ?? defaultID,
            accountID: accountID ?? defaultAccountID,
            direction: direction,
            amount: amount ?? Money(amount: 12.34, currencyCode: "GBP"),
            occurredAt: occurredAt,
            categoryID: categoryID,
            memo: memo
        )
    }

    private func requireSendable<T: Sendable>(_ value: T) {
        _ = value
    }
}
