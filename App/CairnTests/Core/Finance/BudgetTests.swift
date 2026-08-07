//
//  BudgetTests.swift
//  CairnTests
//
//  Created by Karim Sheikh on 07/08/2026.
//

import Foundation
import Testing
@testable import Cairn

struct BudgetTests {

    @Test func budgetIDIsCodable() throws {
        let id = BudgetID(rawValue: try #require(UUID(uuidString: "748C4BA3-E8BE-434A-8CDB-30B781761694")))

        let encoded = try JSONEncoder().encode(id)
        let decoded = try JSONDecoder().decode(BudgetID.self, from: encoded)

        #expect(decoded == id)
    }

    @Test func periodInitializationStoresValues() throws {
        let startDate = Date(timeIntervalSince1970: 1_786_080_000)
        let endDate = Date(timeIntervalSince1970: 1_788_672_000)

        let period = try BudgetPeriod(startDate: startDate, endDate: endDate)

        #expect(period.startDate == startDate)
        #expect(period.endDate == endDate)
    }

    @Test func periodInitializationRejectsEqualStartAndEndDates() {
        let date = Date(timeIntervalSince1970: 1_786_080_000)

        #expect(throws: BudgetPeriod.ValidationError.invalidDateRange) {
            try BudgetPeriod(startDate: date, endDate: date)
        }
    }

    @Test func periodInitializationRejectsEndDateBeforeStartDate() {
        let startDate = Date(timeIntervalSince1970: 1_788_672_000)
        let endDate = Date(timeIntervalSince1970: 1_786_080_000)

        #expect(throws: BudgetPeriod.ValidationError.invalidDateRange) {
            try BudgetPeriod(startDate: startDate, endDate: endDate)
        }
    }

    @Test func initializationStoresValues() throws {
        let id = BudgetID(rawValue: try #require(UUID(uuidString: "748C4BA3-E8BE-434A-8CDB-30B781761694")))
        let categoryID = CategoryID(rawValue: try #require(UUID(uuidString: "B14F7964-7FF1-4671-A460-88D4B393C98A")))
        let limit = try Money(amount: 250, currencyCode: "GBP")
        let period = try makePeriod()

        let budget = try Budget(
            id: id,
            categoryID: categoryID,
            limit: limit,
            period: period
        )

        #expect(budget.id == id)
        #expect(budget.categoryID == categoryID)
        #expect(budget.limit == limit)
        #expect(budget.period == period)
    }

    @Test func initializationAcceptsZeroLimit() throws {
        let limit = try Money(amount: 0, currencyCode: "GBP")

        let budget = try makeBudget(limit: limit)

        #expect(budget.limit.amount == 0)
    }

    @Test func initializationRejectsNegativeLimit() throws {
        let limit = try Money(amount: -1, currencyCode: "GBP")

        #expect(throws: Budget.ValidationError.negativeLimit) {
            try makeBudget(limit: limit)
        }
    }

    @Test func equalityUsesAllStoredValues() throws {
        let id = BudgetID(rawValue: try #require(UUID(uuidString: "748C4BA3-E8BE-434A-8CDB-30B781761694")))
        let categoryID = CategoryID(rawValue: try #require(UUID(uuidString: "B14F7964-7FF1-4671-A460-88D4B393C98A")))
        let limit = try Money(amount: 250, currencyCode: "GBP")
        let period = try makePeriod()
        let first = try Budget(id: id, categoryID: categoryID, limit: limit, period: period)
        let same = try Budget(id: id, categoryID: categoryID, limit: limit, period: period)
        let different = try Budget(
            id: id,
            categoryID: categoryID,
            limit: try Money(amount: 300, currencyCode: "GBP"),
            period: period
        )

        #expect(first == same)
        #expect(first != different)
    }

    @Test func hashableUsesStoredValues() throws {
        let budget = try makeBudget()
        let same = try makeBudget(id: budget.id)

        #expect(Set([budget, same]).count == 1)
    }

    @Test func periodIsCodable() throws {
        let period = try makePeriod()

        let encoded = try JSONEncoder().encode(period)
        let decoded = try JSONDecoder().decode(BudgetPeriod.self, from: encoded)

        #expect(decoded == period)
    }

    @Test func budgetIsCodable() throws {
        let budget = try makeBudget()

        let encoded = try JSONEncoder().encode(budget)
        let decoded = try JSONDecoder().decode(Budget.self, from: encoded)

        #expect(decoded == budget)
    }

    @Test func periodCodableAppliesValidationWhenDecodingEqualDates() throws {
        let period = try makePeriod()
        let encoded = try JSONEncoder().encode(period)
        var json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        json["endDate"] = json["startDate"]
        let data = try JSONSerialization.data(withJSONObject: json)

        #expect(throws: BudgetPeriod.ValidationError.invalidDateRange) {
            try JSONDecoder().decode(BudgetPeriod.self, from: data)
        }
    }

    @Test func budgetCodableAppliesLimitValidationWhenDecoding() throws {
        let budget = try makeBudget()
        let encoded = try JSONEncoder().encode(budget)
        var json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        json["limit"] = -1
        let data = try JSONSerialization.data(withJSONObject: json)

        #expect(throws: Budget.ValidationError.negativeLimit) {
            try JSONDecoder().decode(Budget.self, from: data)
        }
    }

    @Test func budgetCodableAppliesPeriodValidationWhenDecoding() throws {
        let budget = try makeBudget()
        let encoded = try JSONEncoder().encode(budget)
        var json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        var periodJSON = try #require(json["period"] as? [String: Any])
        periodJSON["endDate"] = periodJSON["startDate"]
        json["period"] = periodJSON
        let data = try JSONSerialization.data(withJSONObject: json)

        #expect(throws: BudgetPeriod.ValidationError.invalidDateRange) {
            try JSONDecoder().decode(Budget.self, from: data)
        }
    }

    @Test func budgetIsSendable() throws {
        let budget = try makeBudget()

        requireSendable(budget)
    }

    private func makeBudget(
        id: BudgetID? = nil,
        categoryID: CategoryID? = nil,
        limit: Money? = nil,
        period: BudgetPeriod? = nil
    ) throws -> Budget {
        let defaultID = BudgetID(rawValue: try #require(UUID(uuidString: "748C4BA3-E8BE-434A-8CDB-30B781761694")))
        let defaultCategoryID = CategoryID(rawValue: try #require(UUID(uuidString: "B14F7964-7FF1-4671-A460-88D4B393C98A")))

        return try Budget(
            id: id ?? defaultID,
            categoryID: categoryID ?? defaultCategoryID,
            limit: limit ?? Money(amount: 250, currencyCode: "GBP"),
            period: period ?? makePeriod()
        )
    }

    private func makePeriod() throws -> BudgetPeriod {
        try BudgetPeriod(
            startDate: Date(timeIntervalSince1970: 1_786_080_000),
            endDate: Date(timeIntervalSince1970: 1_788_672_000)
        )
    }

    private func requireSendable<T: Sendable>(_ value: T) {
        _ = value
    }
}
