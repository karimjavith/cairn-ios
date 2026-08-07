//
//  MoneyTests.swift
//  CairnTests
//
//  Created by Karim Sheikh on 07/08/2026.
//

import Foundation
import Testing
@testable import Cairn

struct MoneyTests {

    @Test func initializationStoresAmountAndCurrencyCode() throws {
        let amount = try decimal("12.34")
        let money = try Money(amount: amount, currencyCode: "GBP")

        #expect(money.amount == amount)
        #expect(money.currencyCode == "GBP")
    }

    @Test func initializationNormalizesCurrencyCode() throws {
        let money = try Money(amount: 1, currencyCode: " gbp\n")

        #expect(money.currencyCode == "GBP")
    }

    @Test func initializationRejectsObviouslyInvalidCurrencyCodes() {
        #expect(throws: MoneyError.invalidCurrencyCode("")) {
            try Money(amount: 1, currencyCode: "")
        }

        #expect(throws: MoneyError.invalidCurrencyCode("GB")) {
            try Money(amount: 1, currencyCode: "GB")
        }

        #expect(throws: MoneyError.invalidCurrencyCode("GB1")) {
            try Money(amount: 1, currencyCode: "GB1")
        }

        #expect(throws: MoneyError.invalidCurrencyCode("ZZZ")) {
            try Money(amount: 1, currencyCode: "ZZZ")
        }
    }

    @Test func initializationRejectsNanAmount() {
        #expect(throws: MoneyError.invalidAmount) {
            try Money(amount: Decimal.nan, currencyCode: "GBP")
        }
    }

    @Test func equalityUsesAmountAndCurrencyCode() throws {
        let first = try Money(amount: decimal("10.00"), currencyCode: "GBP")
        let same = try Money(amount: decimal("10.00"), currencyCode: "gbp")
        let differentAmount = try Money(amount: decimal("10.01"), currencyCode: "GBP")
        let differentCurrency = try Money(amount: decimal("10.00"), currencyCode: "EUR")

        #expect(first == same)
        #expect(first != differentAmount)
        #expect(first != differentCurrency)
    }

    @Test func hashableUsesAmountAndCurrencyCode() throws {
        let first = try Money(amount: decimal("10.00"), currencyCode: "GBP")
        let same = try Money(amount: decimal("10.00"), currencyCode: "gbp")

        #expect(Set([first, same]).count == 1)
    }

    @Test func additionWithSameCurrencyPreservesCurrencyAndAddsAmounts() throws {
        let left = try Money(amount: decimal("10.25"), currencyCode: "GBP")
        let right = try Money(amount: decimal("5.10"), currencyCode: "GBP")

        let result = try left.adding(right)
        let expected = try Money(amount: decimal("15.35"), currencyCode: "GBP")

        #expect(result == expected)
    }

    @Test func subtractionWithSameCurrencyPreservesCurrencyAndSubtractsAmounts() throws {
        let left = try Money(amount: decimal("10.25"), currencyCode: "GBP")
        let right = try Money(amount: decimal("5.10"), currencyCode: "GBP")

        let result = try left.subtracting(right)
        let expected = try Money(amount: decimal("5.15"), currencyCode: "GBP")

        #expect(result == expected)
    }

    @Test func negativeValuesAreSupported() throws {
        let amount = try decimal("-12.34")
        let money = try Money(amount: amount, currencyCode: "GBP")

        #expect(money.amount == amount)
    }

    @Test func negationPreservesCurrencyAndNegatesAmount() throws {
        let money = try Money(amount: decimal("12.34"), currencyCode: "GBP")
        let expected = try Money(amount: decimal("-12.34"), currencyCode: "GBP")

        #expect(-money == expected)
    }

    @Test func zeroIsSupported() throws {
        let money = try Money(amount: 0, currencyCode: "GBP")

        #expect(money.amount == 0)
        #expect(money.currencyCode == "GBP")
    }

    @Test func mismatchedCurrencyAdditionThrows() throws {
        let sterling = try Money(amount: 10, currencyCode: "GBP")
        let euros = try Money(amount: 10, currencyCode: "EUR")

        #expect(throws: MoneyError.currencyMismatch(left: "GBP", right: "EUR")) {
            try sterling.adding(euros)
        }
    }

    @Test func mismatchedCurrencySubtractionThrows() throws {
        let sterling = try Money(amount: 10, currencyCode: "GBP")
        let euros = try Money(amount: 10, currencyCode: "EUR")

        #expect(throws: MoneyError.currencyMismatch(left: "GBP", right: "EUR")) {
            try sterling.subtracting(euros)
        }
    }

    @Test func decimalPrecisionDoesNotUseBinaryFloatingPoint() throws {
        let first = try Money(amount: decimal("0.1"), currencyCode: "GBP")
        let second = try Money(amount: decimal("0.2"), currencyCode: "GBP")

        let result = try first.adding(second)
        let expectedAmount = try decimal("0.3")

        #expect(result.amount == expectedAmount)
    }

    private func decimal(_ value: String) throws -> Decimal {
        try #require(Decimal(string: value))
    }
}
