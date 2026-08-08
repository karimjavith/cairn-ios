//
//  AccountRecordTests.swift
//  CairnTests
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import SwiftData
import Testing
@testable import Cairn

struct AccountRecordTests {

    @Test func accountToRecordPreservesPersistedValues() throws {
        let id = AccountID(rawValue: try #require(UUID(uuidString: "9E849395-8DC9-481A-B56F-1EC9AF46A57D")))
        let openingBalanceAmount = try #require(Decimal(string: "1234567890.123456789"))
        let account = try Account(
            id: id,
            name: "  Everyday\n",
            type: .checking,
            currencyCode: "gbp",
            openingBalance: Money(
                amount: openingBalanceAmount,
                currencyCode: "GBP"
            )
        )

        let record = AccountRecord(account: account)

        #expect(record.id == id.rawValue)
        #expect(record.name == "Everyday")
        #expect(record.type == "checking")
        #expect(record.currencyCode == "GBP")
        #expect(record.openingBalanceAmount == "1234567890.123456789")
    }

    @Test func recordToAccountReconstructsEquivalentDomainAccount() throws {
        let id = try #require(UUID(uuidString: "4E4AAAC1-0127-4C78-A02E-EA1F47CCB5B1"))
        let openingBalanceAmount = try #require(Decimal(string: "42.01"))
        let record = AccountRecord(
            id: id,
            name: "Savings",
            type: "savings",
            currencyCode: "EUR",
            openingBalanceAmount: "42.01"
        )

        let account = try record.account()
        let expectedAccount = try Account(
            id: AccountID(rawValue: id),
            name: "Savings",
            type: .savings,
            currencyCode: "EUR",
            openingBalance: Money(
                amount: openingBalanceAmount,
                currencyCode: "EUR"
            )
        )

        #expect(account == expectedAccount)
    }

    @Test func accountIDSurvivesCompleteMappingRoundTrip() throws {
        let id = AccountID(rawValue: try #require(UUID(uuidString: "F82163F3-E6C7-474A-BF6D-E1017E6E5C67")))
        let account = try Account(
            id: id,
            name: "Wallet",
            type: .cash,
            currencyCode: "USD",
            openingBalance: Money(amount: 10, currencyCode: "USD")
        )

        let roundTrippedAccount = try AccountRecord(account: account).account()

        #expect(roundTrippedAccount.id == id)
    }

    @Test func decimalOpeningBalancePrecisionSurvivesMappingRoundTrip() throws {
        let amount = try #require(Decimal(string: "1234567890.123456789012345678"))
        let account = try Account(
            name: "Precision",
            type: .investment,
            currencyCode: "GBP",
            openingBalance: Money(amount: amount, currencyCode: "GBP")
        )

        let roundTrippedAccount = try AccountRecord(account: account).account()

        #expect(roundTrippedAccount.openingBalance.amount == amount)
    }

    @Test func currencySurvivesMappingRoundTrip() throws {
        let account = try Account(
            name: "Euro Cash",
            type: .cash,
            currencyCode: "eur",
            openingBalance: Money(amount: 12, currencyCode: "EUR")
        )

        let roundTrippedAccount = try AccountRecord(account: account).account()

        #expect(roundTrippedAccount.currencyCode == "EUR")
        #expect(roundTrippedAccount.openingBalance.currencyCode == "EUR")
    }

    @Test func normalizedAccountNameSurvivesMappingRoundTrip() throws {
        let account = try Account(
            name: "  Everyday Account\n",
            type: .checking,
            currencyCode: "GBP",
            openingBalance: Money(amount: 0, currencyCode: "GBP")
        )

        let roundTrippedAccount = try AccountRecord(account: account).account()

        #expect(roundTrippedAccount.name == "Everyday Account")
    }

    @Test func invalidPersistedAccountDataFailsReconstruction() throws {
        let record = AccountRecord(
            id: AccountID().rawValue,
            name: " \n\t ",
            type: "checking",
            currencyCode: "GBP",
            openingBalanceAmount: "0"
        )

        #expect(throws: Account.ValidationError.emptyName) {
            try record.account()
        }
    }

    @Test func invalidPersistedAccountTypeFailsReconstruction() throws {
        let record = AccountRecord(
            id: AccountID().rawValue,
            name: "Savings",
            type: "brokerage",
            currencyCode: "GBP",
            openingBalanceAmount: "0"
        )

        #expect(throws: AccountRecordMappingError.invalidAccountType("brokerage")) {
            try record.account()
        }
    }

    @Test func invalidPersistedOpeningBalanceAmountFailsReconstruction() throws {
        let record = AccountRecord(
            id: AccountID().rawValue,
            name: "Savings",
            type: "savings",
            currencyCode: "GBP",
            openingBalanceAmount: "not-a-decimal"
        )

        #expect(throws: AccountRecordMappingError.invalidOpeningBalanceAmount("not-a-decimal")) {
            try record.account()
        }
    }

    @Test func dotDecimalPersistedOpeningBalanceReconstructsExactly() throws {
        let record = makeRecord(openingBalanceAmount: "42.01")
        let expectedAmount = try #require(
            Decimal(string: "42.01", locale: Locale(identifier: "en_US_POSIX"))
        )

        let account = try record.account()

        #expect(account.openingBalance.amount == expectedAmount)
    }

    @Test func exponentPersistedOpeningBalanceReconstructsExactly() throws {
        let record = makeRecord(openingBalanceAmount: "1.23e2")
        let expectedAmount = try #require(
            Decimal(string: "123", locale: Locale(identifier: "en_US_POSIX"))
        )

        let account = try record.account()

        #expect(account.openingBalance.amount == expectedAmount)
    }

    @Test func partiallyParsedPersistedOpeningBalanceAmountFailsReconstruction() {
        let record = makeRecord(openingBalanceAmount: "12abc")

        #expect(throws: AccountRecordMappingError.invalidOpeningBalanceAmount("12abc")) {
            try record.account()
        }
    }

    @Test func localeStylePersistedOpeningBalanceAmountFailsReconstruction() {
        let record = makeRecord(openingBalanceAmount: "1,23")

        #expect(throws: AccountRecordMappingError.invalidOpeningBalanceAmount("1,23")) {
            try record.account()
        }
    }

    @Test func swiftDataPersistenceRoundTripPreservesAccountValues() throws {
        let id = AccountID(rawValue: try #require(UUID(uuidString: "4A084B67-AF4E-45C9-9FC0-C599E2515A48")))
        let amount = try #require(Decimal(string: "1234567890.123456789012345678"))
        let account = try Account(
            id: id,
            name: "  High Precision Savings\n",
            type: .savings,
            currencyCode: "gbp",
            openingBalance: Money(amount: amount, currencyCode: "GBP")
        )
        let container = try makeInMemoryModelContainer()
        let insertContext = ModelContext(container)

        insertContext.insert(AccountRecord(account: account))
        try insertContext.save()

        let fetchContext = ModelContext(container)
        let descriptor = FetchDescriptor<AccountRecord>()
        let fetchedRecord = try #require(try fetchContext.fetch(descriptor).first)
        let fetchedAccount = try fetchedRecord.account()

        #expect(fetchedAccount.id == id)
        #expect(fetchedAccount.openingBalance.amount == amount)
        #expect(fetchedAccount.currencyCode == "GBP")
        #expect(fetchedAccount.openingBalance.currencyCode == "GBP")
        #expect(fetchedAccount.type == .savings)
        #expect(fetchedAccount.name == "High Precision Savings")
    }

    private func makeRecord(
        openingBalanceAmount: String = "12.34"
    ) -> AccountRecord {
        AccountRecord(
            id: UUID(),
            name: "Savings",
            type: "savings",
            currencyCode: "GBP",
            openingBalanceAmount: openingBalanceAmount
        )
    }

    private func makeInMemoryModelContainer() throws -> ModelContainer {
        let schema = Schema([
            AccountRecord.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
