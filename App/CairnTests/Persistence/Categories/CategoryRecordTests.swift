//
//  CategoryRecordTests.swift
//  CairnTests
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import SwiftData
import Testing
@testable import Cairn

struct CategoryRecordTests {

    @Test func categoryToRecordPreservesPersistedValues() throws {
        let id = CategoryID(rawValue: try #require(UUID(uuidString: "B14F7964-7FF1-4671-A460-88D4B393C98A")))
        let category = try Category(
            id: id,
            name: "  Groceries\n",
            kind: .expense
        )

        let record = CategoryRecord(category: category)

        #expect(record.id == id.rawValue)
        #expect(record.name == "Groceries")
        #expect(record.kind == "expense")
    }

    @Test func recordToCategoryReconstructsEquivalentDomainCategory() throws {
        let id = try #require(UUID(uuidString: "4E4AAAC1-0127-4C78-A02E-EA1F47CCB5B1"))
        let record = CategoryRecord(
            id: id,
            name: "Salary",
            kind: "income"
        )

        let category = try record.category()
        let expectedCategory = try Category(
            id: CategoryID(rawValue: id),
            name: "Salary",
            kind: .income
        )

        #expect(category == expectedCategory)
    }

    @Test func categoryIDSurvivesCompleteMappingRoundTrip() throws {
        let id = CategoryID(rawValue: try #require(UUID(uuidString: "F82163F3-E6C7-474A-BF6D-E1017E6E5C67")))
        let category = try Category(
            id: id,
            name: "Groceries",
            kind: .expense
        )

        let roundTrippedCategory = try CategoryRecord(category: category).category()

        #expect(roundTrippedCategory.id == id)
    }

    @Test func normalizedCategoryNameSurvivesMappingRoundTrip() throws {
        let category = try Category(
            name: "  Groceries\n",
            kind: .expense
        )

        let roundTrippedCategory = try CategoryRecord(category: category).category()

        #expect(roundTrippedCategory.name == "Groceries")
    }

    @Test func incomeKindSurvivesMappingRoundTrip() throws {
        let category = try Category(
            name: "Salary",
            kind: .income
        )

        let roundTrippedCategory = try CategoryRecord(category: category).category()

        #expect(roundTrippedCategory.kind == .income)
    }

    @Test func expenseKindSurvivesMappingRoundTrip() throws {
        let category = try Category(
            name: "Groceries",
            kind: .expense
        )

        let roundTrippedCategory = try CategoryRecord(category: category).category()

        #expect(roundTrippedCategory.kind == .expense)
    }

    @Test func invalidPersistedKindFailsReconstruction() {
        let record = CategoryRecord(
            id: CategoryID().rawValue,
            name: "Groceries",
            kind: "transfer"
        )

        #expect(throws: CategoryRecordMappingError.invalidKind("transfer")) {
            try record.category()
        }
    }

    @Test func invalidPersistedNameFailsThroughDomainValidation() {
        let record = CategoryRecord(
            id: CategoryID().rawValue,
            name: " \n\t ",
            kind: "expense"
        )

        #expect(throws: Category.ValidationError.emptyName) {
            try record.category()
        }
    }

    @Test func swiftDataPersistenceRoundTripPreservesCategoryValues() throws {
        let id = CategoryID(rawValue: try #require(UUID(uuidString: "8E5F8228-0FBC-40E2-A720-01D82F44728D")))
        let category = try Category(
            id: id,
            name: "  Salary\n",
            kind: .income
        )
        let container = try makeInMemoryModelContainer()
        let insertContext = ModelContext(container)

        insertContext.insert(CategoryRecord(category: category))
        try insertContext.save()

        let fetchContext = ModelContext(container)
        let descriptor = FetchDescriptor<CategoryRecord>()
        let fetchedRecord = try #require(try fetchContext.fetch(descriptor).first)
        let fetchedCategory = try fetchedRecord.category()

        #expect(fetchedCategory.id == id)
        #expect(fetchedCategory.name == "Salary")
        #expect(fetchedCategory.kind == .income)
    }

    private func makeInMemoryModelContainer() throws -> ModelContainer {
        let schema = Schema([
            CategoryRecord.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
