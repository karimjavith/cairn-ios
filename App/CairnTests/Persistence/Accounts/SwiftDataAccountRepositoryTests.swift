//
//  SwiftDataAccountRepositoryTests.swift
//  CairnTests
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import SwiftData
import Testing
@testable import Cairn

struct SwiftDataAccountRepositoryTests {

    @Test func fetchAccountsOnEmptyStoreReturnsEmptyArray() async throws {
        let repository = try makeRepository()

        let accounts = try await repository.fetchAccounts()

        #expect(accounts == [])
    }

    @Test func saveInsertsNewAccount() async throws {
        let repository = try makeRepository()
        let account = try makeAccount(name: "Everyday")

        try await repository.save(account)

        let accounts = try await repository.fetchAccounts()
        #expect(accounts == [account])
    }

    @Test func fetchAccountReturnsSavedAccount() async throws {
        let repository = try makeRepository()
        let account = try makeAccount(name: "Everyday")

        try await repository.save(account)

        let fetchedAccount = try await repository.fetchAccount(id: account.id)
        #expect(fetchedAccount == account)
    }

    @Test func fetchAccountReturnsNilWhenMissing() async throws {
        let repository = try makeRepository()

        let fetchedAccount = try await repository.fetchAccount(id: AccountID())

        #expect(fetchedAccount == nil)
    }

    @Test func fetchAccountsReturnsSavedAccountsDeterministically() async throws {
        let repository = try makeRepository()
        let zeta = try makeAccount(
            id: AccountID(rawValue: try #require(UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"))),
            name: "Zeta"
        )
        let alpha = try makeAccount(
            id: AccountID(rawValue: try #require(UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"))),
            name: "Alpha"
        )
        let alphaTieBreaker = try makeAccount(
            id: AccountID(rawValue: try #require(UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"))),
            name: "Alpha"
        )

        try await repository.save(zeta)
        try await repository.save(alpha)
        try await repository.save(alphaTieBreaker)

        let accounts = try await repository.fetchAccounts()
        #expect(accounts == [alphaTieBreaker, alpha, zeta])
    }

    @Test func repeatedSaveWithSameAccountIDUpdatesWithoutCreatingDuplicates() async throws {
        let repository = try makeRepository()
        let id = AccountID()
        let original = try makeAccount(id: id, name: "Everyday")
        let updated = try makeAccount(id: id, name: "Main Account")

        try await repository.save(original)
        try await repository.save(updated)

        let accounts = try await repository.fetchAccounts()
        #expect(accounts == [updated])
    }

    @Test func updatedOpeningBalancePersistsWithDecimalPrecision() async throws {
        let repository = try makeRepository()
        let id = AccountID()
        let original = try makeAccount(id: id, name: "Savings", openingBalanceAmount: 0)
        let preciseAmount = try #require(Decimal(string: "1234567890.123456789012345678"))
        let updated = try makeAccount(
            id: id,
            name: "Savings",
            openingBalanceAmount: preciseAmount
        )

        try await repository.save(original)
        try await repository.save(updated)

        let fetchedAccount = try #require(try await repository.fetchAccount(id: id))
        #expect(fetchedAccount.openingBalance.amount == preciseAmount)
        #expect(fetchedAccount == updated)
    }

    @Test func deleteRemovesExistingAccount() async throws {
        let repository = try makeRepository()
        let account = try makeAccount(name: "Everyday")

        try await repository.save(account)
        try await repository.deleteAccount(id: account.id)

        let fetchedAccount = try await repository.fetchAccount(id: account.id)
        #expect(fetchedAccount == nil)
        #expect(try await repository.fetchAccounts() == [])
    }

    @Test func deleteMissingAccountIsNoOp() async throws {
        let repository = try makeRepository()

        try await repository.deleteAccount(id: AccountID())

        #expect(try await repository.fetchAccounts() == [])
    }

    @Test func repositoryNeverChangesAccountID() async throws {
        let repository = try makeRepository()
        let id = AccountID(rawValue: try #require(UUID(uuidString: "31F0E030-1B36-4FB0-B939-E98832B7B861")))
        let account = try makeAccount(id: id, name: "Everyday")
        let updated = try makeAccount(id: id, name: "Everyday Updated")

        try await repository.save(account)
        try await repository.save(updated)

        let fetchedAccount = try #require(try await repository.fetchAccount(id: id))
        #expect(fetchedAccount.id == id)
    }

    @Test func invalidPersistedAccountRecordFailsMapping() async throws {
        let container = try makeInMemoryModelContainer()
        let insertContext = ModelContext(container)
        insertContext.insert(AccountRecord(
            id: AccountID().rawValue,
            name: " \n\t ",
            type: "checking",
            currencyCode: "GBP",
            openingBalanceAmount: "0"
        ))
        try insertContext.save()

        let repository = SwiftDataAccountRepository(modelContainer: container)

        await #expect(throws: Account.ValidationError.emptyName) {
            try await repository.fetchAccounts()
        }
    }

    private func makeRepository() throws -> SwiftDataAccountRepository {
        try SwiftDataAccountRepository(modelContainer: makeInMemoryModelContainer())
    }

    private func makeInMemoryModelContainer() throws -> ModelContainer {
        let schema = Schema([
            AccountRecord.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func makeAccount(
        id: AccountID = AccountID(),
        name: String,
        type: AccountType = .checking,
        currencyCode: String = "GBP",
        openingBalanceAmount: Decimal = 10
    ) throws -> Account {
        try Account(
            id: id,
            name: name,
            type: type,
            currencyCode: currencyCode,
            openingBalance: Money(
                amount: openingBalanceAmount,
                currencyCode: currencyCode
            )
        )
    }
}
