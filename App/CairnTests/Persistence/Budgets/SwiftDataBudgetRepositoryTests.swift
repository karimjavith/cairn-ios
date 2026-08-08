//
//  SwiftDataBudgetRepositoryTests.swift
//  CairnTests
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import SwiftData
import Testing
@testable import Cairn

struct SwiftDataBudgetRepositoryTests {

    @Test func fetchBudgetsOnEmptyStoreReturnsEmptyArray() async throws {
        let repository = try makeRepository()

        let budgets = try await repository.fetchBudgets()

        #expect(budgets == [])
    }

    @Test func saveInsertsBudget() async throws {
        let repository = try makeRepository()
        let budget = try makeBudget()

        try await repository.save(budget)

        let budgets = try await repository.fetchBudgets()
        #expect(budgets == [budget])
    }

    @Test func fetchBudgetReturnsSavedBudget() async throws {
        let repository = try makeRepository()
        let budget = try makeBudget()

        try await repository.save(budget)

        let fetchedBudget = try await repository.fetchBudget(id: budget.id)
        #expect(fetchedBudget == budget)
    }

    @Test func fetchBudgetReturnsNilWhenMissing() async throws {
        let repository = try makeRepository()

        let fetchedBudget = try await repository.fetchBudget(id: BudgetID())

        #expect(fetchedBudget == nil)
    }

    @Test func fetchBudgetsReturnsAllSavedBudgets() async throws {
        let repository = try makeRepository()
        let groceries = try makeBudget(
            period: makePeriod(
                startDate: Date(timeIntervalSince1970: 1_788_672_000),
                endDate: Date(timeIntervalSince1970: 1_791_264_000)
            )
        )
        let transport = try makeBudget(
            period: makePeriod(
                startDate: Date(timeIntervalSince1970: 1_785_993_600),
                endDate: Date(timeIntervalSince1970: 1_788_672_000)
            )
        )

        try await repository.save(transport)
        try await repository.save(groceries)

        let budgets = try await repository.fetchBudgets()
        #expect(budgets == [groceries, transport])
    }

    @Test func fetchBudgetsOrdersByStartDateDescending() async throws {
        let repository = try makeRepository()
        let oldest = try makeBudget(
            period: makePeriod(
                startDate: Date(timeIntervalSince1970: 1_785_993_600),
                endDate: Date(timeIntervalSince1970: 1_788_672_000)
            )
        )
        let newest = try makeBudget(
            period: makePeriod(
                startDate: Date(timeIntervalSince1970: 1_791_264_000),
                endDate: Date(timeIntervalSince1970: 1_793_856_000)
            )
        )
        let middle = try makeBudget(
            period: makePeriod(
                startDate: Date(timeIntervalSince1970: 1_788_672_000),
                endDate: Date(timeIntervalSince1970: 1_791_264_000)
            )
        )

        try await repository.save(oldest)
        try await repository.save(newest)
        try await repository.save(middle)

        let budgets = try await repository.fetchBudgets()
        #expect(budgets == [newest, middle, oldest])
    }

    @Test func fetchBudgetsOrdersByEndDateDescendingWhenStartDatesAreEqual() async throws {
        let repository = try makeRepository()
        let startDate = Date(timeIntervalSince1970: 1_785_993_600)
        let shortest = try makeBudget(
            period: makePeriod(
                startDate: startDate,
                endDate: Date(timeIntervalSince1970: 1_788_672_000)
            )
        )
        let longest = try makeBudget(
            period: makePeriod(
                startDate: startDate,
                endDate: Date(timeIntervalSince1970: 1_793_856_000)
            )
        )
        let middle = try makeBudget(
            period: makePeriod(
                startDate: startDate,
                endDate: Date(timeIntervalSince1970: 1_791_264_000)
            )
        )

        try await repository.save(shortest)
        try await repository.save(longest)
        try await repository.save(middle)

        let budgets = try await repository.fetchBudgets()
        #expect(budgets == [longest, middle, shortest])
    }

    @Test func fetchBudgetsUsesStableBudgetIDOrderingWhenDatesAreEqual() async throws {
        let repository = try makeRepository()
        let period = try makePeriod()
        let first = try makeBudget(
            id: BudgetID(rawValue: try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))),
            period: period
        )
        let second = try makeBudget(
            id: BudgetID(rawValue: try #require(UUID(uuidString: "22222222-2222-2222-2222-222222222222"))),
            period: period
        )
        let third = try makeBudget(
            id: BudgetID(rawValue: try #require(UUID(uuidString: "33333333-3333-3333-3333-333333333333"))),
            period: period
        )

        try await repository.save(third)
        try await repository.save(first)
        try await repository.save(second)

        let budgets = try await repository.fetchBudgets()
        #expect(budgets == [first, second, third])
    }

    @Test func repeatedSaveWithSameBudgetIDUpdatesWithoutCreatingDuplicates() async throws {
        let repository = try makeRepository()
        let id = BudgetID()
        let original = try makeBudget(id: id, limitAmount: 100)
        let updated = try makeBudget(id: id, limitAmount: 200)

        try await repository.save(original)
        try await repository.save(updated)

        let budgets = try await repository.fetchBudgets()
        #expect(budgets == [updated])
    }

    @Test func savingExistingBudgetWithChangedCategoryIDUpdatesPersistence() async throws {
        let repository = try makeRepository()
        let id = BudgetID()
        let originalCategoryID = CategoryID()
        let updatedCategoryID = CategoryID()
        let original = try makeBudget(id: id, categoryID: originalCategoryID)
        let updated = try makeBudget(id: id, categoryID: updatedCategoryID)

        try await repository.save(original)
        try await repository.save(updated)

        let fetchedBudget = try #require(try await repository.fetchBudget(id: id))
        #expect(fetchedBudget.categoryID == updatedCategoryID)
        #expect(fetchedBudget == updated)
        #expect(try await repository.fetchBudgets() == [updated])
    }

    @Test func updatedLimitPreservesDecimalPrecision() async throws {
        let repository = try makeRepository()
        let id = BudgetID()
        let original = try makeBudget(id: id, limitAmount: 0)
        let preciseAmount = try #require(Decimal(string: "1234567890.123456789012345678"))
        let updated = try makeBudget(id: id, limitAmount: preciseAmount)

        try await repository.save(original)
        try await repository.save(updated)

        let fetchedBudget = try #require(try await repository.fetchBudget(id: id))
        #expect(fetchedBudget.limit.amount == preciseAmount)
        #expect(fetchedBudget == updated)
    }

    @Test func updatedPeriodPersists() async throws {
        let repository = try makeRepository()
        let id = BudgetID()
        let original = try makeBudget(id: id)
        let updatedPeriod = try makePeriod(
            startDate: Date(timeIntervalSince1970: 1_791_264_000),
            endDate: Date(timeIntervalSince1970: 1_793_856_000)
        )
        let updated = try makeBudget(id: id, period: updatedPeriod)

        try await repository.save(original)
        try await repository.save(updated)

        let fetchedBudget = try #require(try await repository.fetchBudget(id: id))
        #expect(fetchedBudget.period == updatedPeriod)
        #expect(fetchedBudget == updated)
    }

    @Test func deleteRemovesExistingBudget() async throws {
        let repository = try makeRepository()
        let budget = try makeBudget()

        try await repository.save(budget)
        try await repository.deleteBudget(id: budget.id)

        let fetchedBudget = try await repository.fetchBudget(id: budget.id)
        #expect(fetchedBudget == nil)
        #expect(try await repository.fetchBudgets() == [])
    }

    @Test func deleteMissingBudgetIsNoOp() async throws {
        let repository = try makeRepository()

        try await repository.deleteBudget(id: BudgetID())

        #expect(try await repository.fetchBudgets() == [])
    }

    @Test func repositoryPreservesBudgetID() async throws {
        let repository = try makeRepository()
        let id = BudgetID(rawValue: try #require(UUID(uuidString: "86A05998-7658-4F15-AB03-A8E8C84986A3")))
        let budget = try makeBudget(id: id)

        try await repository.save(budget)

        let fetchedBudget = try #require(try await repository.fetchBudget(id: id))
        #expect(fetchedBudget.id == id)
    }

    @Test func repositoryPreservesCategoryID() async throws {
        let repository = try makeRepository()
        let categoryID = CategoryID(rawValue: try #require(UUID(uuidString: "5247E263-4B6E-4D35-856C-80EDCC27808C")))
        let budget = try makeBudget(categoryID: categoryID)

        try await repository.save(budget)

        let fetchedBudget = try #require(try await repository.fetchBudget(id: budget.id))
        #expect(fetchedBudget.categoryID == categoryID)
    }

    @Test func invalidPersistedBudgetRecordFailsMapping() async throws {
        let container = try makeInMemoryModelContainer()
        let insertContext = ModelContext(container)
        insertContext.insert(BudgetRecord(
            id: BudgetID().rawValue,
            categoryID: CategoryID().rawValue,
            limitAmount: "12abc",
            currencyCode: "GBP",
            startDate: Date(timeIntervalSince1970: 1_786_080_000),
            endDate: Date(timeIntervalSince1970: 1_788_672_000)
        ))
        try insertContext.save()

        let repository = SwiftDataBudgetRepository(modelContainer: container)

        await #expect(throws: BudgetRecordMappingError.invalidLimitAmount("12abc")) {
            try await repository.fetchBudgets()
        }
    }

    private func makeRepository() throws -> SwiftDataBudgetRepository {
        try SwiftDataBudgetRepository(modelContainer: makeInMemoryModelContainer())
    }

    private func makeInMemoryModelContainer() throws -> ModelContainer {
        let schema = Schema([
            BudgetRecord.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func makeBudget(
        id: BudgetID = BudgetID(),
        categoryID: CategoryID = CategoryID(),
        limitAmount: Decimal = 250,
        currencyCode: String = "GBP",
        period: BudgetPeriod? = nil
    ) throws -> Budget {
        try Budget(
            id: id,
            categoryID: categoryID,
            limit: Money(
                amount: limitAmount,
                currencyCode: currencyCode
            ),
            period: period ?? makePeriod()
        )
    }

    private func makePeriod(
        startDate: Date = Date(timeIntervalSince1970: 1_786_080_000),
        endDate: Date = Date(timeIntervalSince1970: 1_788_672_000)
    ) throws -> BudgetPeriod {
        try BudgetPeriod(
            startDate: startDate,
            endDate: endDate
        )
    }
}
