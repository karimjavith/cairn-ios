//
//  BudgetRecordTests.swift
//  CairnTests
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import SwiftData
import Testing
@testable import Cairn

struct BudgetRecordTests {

    @Test func budgetToRecordPreservesPersistedValues() throws {
        let id = BudgetID(rawValue: try #require(UUID(uuidString: "748C4BA3-E8BE-434A-8CDB-30B781761694")))
        let categoryID = CategoryID(rawValue: try #require(UUID(uuidString: "B14F7964-7FF1-4671-A460-88D4B393C98A")))
        let limitAmount = try #require(Decimal(string: "1234567890.123456789"))
        let startDate = Date(timeIntervalSince1970: 1_786_080_000)
        let endDate = Date(timeIntervalSince1970: 1_788_672_000)
        let budget = try Budget(
            id: id,
            categoryID: categoryID,
            limit: Money(amount: limitAmount, currencyCode: "gbp"),
            period: BudgetPeriod(startDate: startDate, endDate: endDate)
        )

        let record = BudgetRecord(budget: budget)

        #expect(record.id == id.rawValue)
        #expect(record.categoryID == categoryID.rawValue)
        #expect(record.limitAmount == "1234567890.123456789")
        #expect(record.currencyCode == "GBP")
        #expect(record.startDate == startDate)
        #expect(record.endDate == endDate)
    }

    @Test func recordToBudgetReconstructsEquivalentDomainBudget() throws {
        let id = try #require(UUID(uuidString: "4E4AAAC1-0127-4C78-A02E-EA1F47CCB5B1"))
        let categoryID = try #require(UUID(uuidString: "F82163F3-E6C7-474A-BF6D-E1017E6E5C67"))
        let limitAmount = try #require(Decimal(string: "42.01"))
        let startDate = Date(timeIntervalSince1970: 1_786_080_000)
        let endDate = Date(timeIntervalSince1970: 1_788_672_000)
        let record = BudgetRecord(
            id: id,
            categoryID: categoryID,
            limitAmount: "42.01",
            currencyCode: "EUR",
            startDate: startDate,
            endDate: endDate
        )

        let budget = try record.budget()
        let expectedBudget = try Budget(
            id: BudgetID(rawValue: id),
            categoryID: CategoryID(rawValue: categoryID),
            limit: Money(amount: limitAmount, currencyCode: "EUR"),
            period: BudgetPeriod(startDate: startDate, endDate: endDate)
        )

        #expect(budget == expectedBudget)
    }

    @Test func budgetIDSurvivesCompleteMappingRoundTrip() throws {
        let id = BudgetID(rawValue: try #require(UUID(uuidString: "8E5F8228-0FBC-40E2-A720-01D82F44728D")))
        let budget = try makeBudget(id: id)

        let roundTrippedBudget = try BudgetRecord(budget: budget).budget()

        #expect(roundTrippedBudget.id == id)
    }

    @Test func categoryIDSurvivesCompleteMappingRoundTrip() throws {
        let categoryID = CategoryID(rawValue: try #require(UUID(uuidString: "7BAE537C-D634-4882-8476-2E4C54101B04")))
        let budget = try makeBudget(categoryID: categoryID)

        let roundTrippedBudget = try BudgetRecord(budget: budget).budget()

        #expect(roundTrippedBudget.categoryID == categoryID)
    }

    @Test func highPrecisionDecimalLimitSurvivesMappingRoundTrip() throws {
        let amount = try #require(Decimal(string: "1234567890.123456789012345678"))
        let budget = try makeBudget(
            limit: Money(amount: amount, currencyCode: "GBP")
        )

        let roundTrippedBudget = try BudgetRecord(budget: budget).budget()

        #expect(roundTrippedBudget.limit.amount == amount)
    }

    @Test func currencySurvivesMappingRoundTrip() throws {
        let budget = try makeBudget(
            limit: Money(amount: 12, currencyCode: "eur")
        )

        let roundTrippedBudget = try BudgetRecord(budget: budget).budget()

        #expect(roundTrippedBudget.limit.currencyCode == "EUR")
    }

    @Test func startDateSurvivesMappingRoundTrip() throws {
        let startDate = Date(timeIntervalSince1970: 1_785_993_600)
        let period = try BudgetPeriod(
            startDate: startDate,
            endDate: Date(timeIntervalSince1970: 1_788_672_000)
        )
        let budget = try makeBudget(period: period)

        let roundTrippedBudget = try BudgetRecord(budget: budget).budget()

        #expect(roundTrippedBudget.period.startDate == startDate)
    }

    @Test func endDateSurvivesMappingRoundTrip() throws {
        let endDate = Date(timeIntervalSince1970: 1_789_536_000)
        let period = try BudgetPeriod(
            startDate: Date(timeIntervalSince1970: 1_786_080_000),
            endDate: endDate
        )
        let budget = try makeBudget(period: period)

        let roundTrippedBudget = try BudgetRecord(budget: budget).budget()

        #expect(roundTrippedBudget.period.endDate == endDate)
    }

    @Test func zeroLimitSurvivesMappingRoundTrip() throws {
        let budget = try makeBudget(
            limit: Money(amount: 0, currencyCode: "GBP")
        )

        let roundTrippedBudget = try BudgetRecord(budget: budget).budget()

        #expect(roundTrippedBudget.limit.amount == 0)
    }

    @Test func invalidPersistedDecimalFailsReconstruction() {
        let record = makeRecord(limitAmount: "not-a-decimal")

        #expect(throws: BudgetRecordMappingError.invalidLimitAmount("not-a-decimal")) {
            try record.budget()
        }
    }

    @Test func dotDecimalPersistedLimitReconstructsExactly() throws {
        let record = makeRecord(limitAmount: "42.01")
        let expectedAmount = try #require(
            Decimal(string: "42.01", locale: Locale(identifier: "en_US_POSIX"))
        )

        let budget = try record.budget()

        #expect(budget.limit.amount == expectedAmount)
    }

    @Test func exponentPersistedLimitReconstructsExactly() throws {
        let record = makeRecord(limitAmount: "1.23e2")
        let expectedAmount = try #require(
            Decimal(string: "123", locale: Locale(identifier: "en_US_POSIX"))
        )

        let budget = try record.budget()

        #expect(budget.limit.amount == expectedAmount)
    }

    @Test func partiallyParsedPersistedDecimalFailsReconstruction() {
        let record = makeRecord(limitAmount: "12abc")

        #expect(throws: BudgetRecordMappingError.invalidLimitAmount("12abc")) {
            try record.budget()
        }
    }

    @Test func localeStylePersistedDecimalFailsReconstruction() {
        let record = makeRecord(limitAmount: "1,23")

        #expect(throws: BudgetRecordMappingError.invalidLimitAmount("1,23")) {
            try record.budget()
        }
    }

    @Test func negativePersistedLimitFailsThroughBudgetValidation() {
        let record = makeRecord(limitAmount: "-1")

        #expect(throws: Budget.ValidationError.negativeLimit) {
            try record.budget()
        }
    }

    @Test func invalidEqualStartAndEndDatesFailThroughBudgetPeriodValidation() {
        let date = Date(timeIntervalSince1970: 1_786_080_000)
        let record = makeRecord(startDate: date, endDate: date)

        #expect(throws: BudgetPeriod.ValidationError.invalidDateRange) {
            try record.budget()
        }
    }

    @Test func invalidEndBeforeStartFailsThroughBudgetPeriodValidation() {
        let startDate = Date(timeIntervalSince1970: 1_788_672_000)
        let endDate = Date(timeIntervalSince1970: 1_786_080_000)
        let record = makeRecord(startDate: startDate, endDate: endDate)

        #expect(throws: BudgetPeriod.ValidationError.invalidDateRange) {
            try record.budget()
        }
    }

    @Test func swiftDataPersistenceRoundTripPreservesBudgetValues() throws {
        let id = BudgetID(rawValue: try #require(UUID(uuidString: "BDE30E88-71A6-40E8-95E6-E529614A92F3")))
        let categoryID = CategoryID(rawValue: try #require(UUID(uuidString: "3A8D42D7-56B1-4039-8DC1-80F0AD3374D7")))
        let amount = try #require(Decimal(string: "1234567890.123456789012345678"))
        let startDate = Date(timeIntervalSince1970: 1_786_080_000)
        let endDate = Date(timeIntervalSince1970: 1_788_672_000)
        let budget = try Budget(
            id: id,
            categoryID: categoryID,
            limit: Money(amount: amount, currencyCode: "gbp"),
            period: BudgetPeriod(startDate: startDate, endDate: endDate)
        )
        let container = try makeInMemoryModelContainer()
        let insertContext = ModelContext(container)

        insertContext.insert(BudgetRecord(budget: budget))
        try insertContext.save()

        let fetchContext = ModelContext(container)
        let descriptor = FetchDescriptor<BudgetRecord>()
        let fetchedRecord = try #require(try fetchContext.fetch(descriptor).first)
        let fetchedBudget = try fetchedRecord.budget()

        #expect(fetchedBudget.id == id)
        #expect(fetchedBudget.categoryID == categoryID)
        #expect(fetchedBudget.limit.amount == amount)
        #expect(fetchedBudget.limit.currencyCode == "GBP")
        #expect(fetchedBudget.period.startDate == startDate)
        #expect(fetchedBudget.period.endDate == endDate)
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

    private func makeRecord(
        limitAmount: String = "12.34",
        startDate: Date = Date(timeIntervalSince1970: 1_786_080_000),
        endDate: Date = Date(timeIntervalSince1970: 1_788_672_000)
    ) -> BudgetRecord {
        BudgetRecord(
            id: UUID(),
            categoryID: UUID(),
            limitAmount: limitAmount,
            currencyCode: "GBP",
            startDate: startDate,
            endDate: endDate
        )
    }

    private func makePeriod() throws -> BudgetPeriod {
        try BudgetPeriod(
            startDate: Date(timeIntervalSince1970: 1_786_080_000),
            endDate: Date(timeIntervalSince1970: 1_788_672_000)
        )
    }

    private func makeInMemoryModelContainer() throws -> ModelContainer {
        let schema = Schema([
            BudgetRecord.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
