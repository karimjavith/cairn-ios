//
//  AccountTests.swift
//  CairnTests
//
//  Created by Karim Sheikh on 07/08/2026.
//

import Foundation
import Testing
@testable import Cairn

struct AccountTests {

    @Test func initializationStoresValues() throws {
        let id = AccountID(rawValue: try #require(UUID(uuidString: "9E849395-8DC9-481A-B56F-1EC9AF46A57D")))
        let openingBalance = try Money(amount: 100, currencyCode: "GBP")

        let account = try Account(
            id: id,
            name: "Everyday",
            type: .checking,
            currencyCode: "GBP",
            openingBalance: openingBalance
        )

        #expect(account.id == id)
        #expect(account.name == "Everyday")
        #expect(account.type == .checking)
        #expect(account.currencyCode == "GBP")
        #expect(account.openingBalance == openingBalance)
    }

    @Test func initializationNormalizesLowercaseCurrencyCode() throws {
        let openingBalance = try Money(amount: 100, currencyCode: "GBP")

        let account = try Account(
            name: "Everyday",
            type: .checking,
            currencyCode: "gbp",
            openingBalance: openingBalance
        )

        #expect(account.currencyCode == "GBP")
    }

    @Test func initializationNormalizesWhitespacePaddedCurrencyCode() throws {
        let openingBalance = try Money(amount: 100, currencyCode: "GBP")

        let account = try Account(
            name: "Everyday",
            type: .checking,
            currencyCode: " GBP\n",
            openingBalance: openingBalance
        )

        #expect(account.currencyCode == "GBP")
    }

    @Test func idDefaultsToUniqueUUIDBackedValues() {
        let first = AccountID()
        let second = AccountID()

        #expect(first != second)
    }

    @Test func idIsCodable() throws {
        let id = AccountID(rawValue: try #require(UUID(uuidString: "9E849395-8DC9-481A-B56F-1EC9AF46A57D")))

        let encoded = try JSONEncoder().encode(id)
        let decoded = try JSONDecoder().decode(AccountID.self, from: encoded)

        #expect(decoded == id)
    }

    @Test func accountTypesContainSupportedCases() {
        let types: [AccountType] = [
            .checking,
            .savings,
            .creditCard,
            .cash,
            .investment,
            .loan
        ]

        #expect(types.count == 6)
        #expect(Set(types).count == 6)
    }

    @Test func initializationRejectsEmptyName() throws {
        let openingBalance = try Money(amount: 0, currencyCode: "GBP")

        #expect(throws: Account.ValidationError.emptyName) {
            try Account(
                name: "",
                type: .checking,
                currencyCode: "GBP",
                openingBalance: openingBalance
            )
        }
    }

    @Test func initializationRejectsCurrencyMismatch() throws {
        let openingBalance = try Money(amount: 0, currencyCode: "GBP")

        #expect(
            throws: Account.ValidationError.currencyMismatch(
                currencyCode: "EUR",
                openingBalanceCurrencyCode: "GBP"
            )
        ) {
            try Account(
                name: "Everyday",
                type: .checking,
                currencyCode: "eur",
                openingBalance: openingBalance
            )
        }
    }
}
