//
//  SwiftDataCategoryRepositoryTests.swift
//  CairnTests
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import SwiftData
import Testing
@testable import Cairn

struct SwiftDataCategoryRepositoryTests {

    @Test func fetchCategoriesOnEmptyStoreReturnsEmptyArray() async throws {
        let repository = try makeRepository()

        let categories = try await repository.fetchCategories()

        #expect(categories == [])
    }

    @Test func saveInsertsCategory() async throws {
        let repository = try makeRepository()
        let category = try makeCategory(name: "Groceries")

        try await repository.save(category)

        let categories = try await repository.fetchCategories()
        #expect(categories == [category])
    }

    @Test func fetchCategoryReturnsSavedCategory() async throws {
        let repository = try makeRepository()
        let category = try makeCategory(name: "Groceries")

        try await repository.save(category)

        let fetchedCategory = try await repository.fetchCategory(id: category.id)
        #expect(fetchedCategory == category)
    }

    @Test func fetchCategoryReturnsNilWhenMissing() async throws {
        let repository = try makeRepository()

        let fetchedCategory = try await repository.fetchCategory(id: CategoryID())

        #expect(fetchedCategory == nil)
    }

    @Test func fetchCategoriesReturnsAllSavedCategories() async throws {
        let repository = try makeRepository()
        let groceries = try makeCategory(name: "Groceries", kind: .expense)
        let salary = try makeCategory(name: "Salary", kind: .income)

        try await repository.save(salary)
        try await repository.save(groceries)

        let categories = try await repository.fetchCategories()
        #expect(categories == [groceries, salary])
    }

    @Test func fetchCategoriesOrdersByNameAscending() async throws {
        let repository = try makeRepository()
        let zeta = try makeCategory(name: "Zeta")
        let alpha = try makeCategory(name: "Alpha")
        let groceries = try makeCategory(name: "Groceries")

        try await repository.save(zeta)
        try await repository.save(groceries)
        try await repository.save(alpha)

        let categories = try await repository.fetchCategories()
        #expect(categories == [alpha, groceries, zeta])
    }

    @Test func fetchCategoriesUsesStableCategoryIDOrderingWhenNamesAreEqual() async throws {
        let repository = try makeRepository()
        let first = try makeCategory(
            id: CategoryID(rawValue: try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))),
            name: "Groceries"
        )
        let second = try makeCategory(
            id: CategoryID(rawValue: try #require(UUID(uuidString: "22222222-2222-2222-2222-222222222222"))),
            name: "Groceries"
        )
        let third = try makeCategory(
            id: CategoryID(rawValue: try #require(UUID(uuidString: "33333333-3333-3333-3333-333333333333"))),
            name: "Groceries"
        )

        try await repository.save(third)
        try await repository.save(first)
        try await repository.save(second)

        let categories = try await repository.fetchCategories()
        #expect(categories == [first, second, third])
    }

    @Test func repeatedSaveWithSameCategoryIDUpdatesWithoutCreatingDuplicates() async throws {
        let repository = try makeRepository()
        let id = CategoryID()
        let original = try makeCategory(id: id, name: "Food")
        let updated = try makeCategory(id: id, name: "Groceries")

        try await repository.save(original)
        try await repository.save(updated)

        let categories = try await repository.fetchCategories()
        #expect(categories == [updated])
    }

    @Test func updatedNamePersists() async throws {
        let repository = try makeRepository()
        let id = CategoryID()
        let original = try makeCategory(id: id, name: "Food")
        let updated = try makeCategory(id: id, name: "  Groceries\n")

        try await repository.save(original)
        try await repository.save(updated)

        let fetchedCategory = try #require(try await repository.fetchCategory(id: id))
        #expect(fetchedCategory.name == "Groceries")
        #expect(fetchedCategory == updated)
    }

    @Test func updatedKindPersists() async throws {
        let repository = try makeRepository()
        let id = CategoryID()
        let original = try makeCategory(id: id, name: "Refund", kind: .expense)
        let updated = try makeCategory(id: id, name: "Refund", kind: .income)

        try await repository.save(original)
        try await repository.save(updated)

        let fetchedCategory = try #require(try await repository.fetchCategory(id: id))
        #expect(fetchedCategory.kind == .income)
        #expect(fetchedCategory == updated)
    }

    @Test func deleteRemovesExistingCategory() async throws {
        let repository = try makeRepository()
        let category = try makeCategory(name: "Groceries")

        try await repository.save(category)
        try await repository.deleteCategory(id: category.id)

        let fetchedCategory = try await repository.fetchCategory(id: category.id)
        #expect(fetchedCategory == nil)
        #expect(try await repository.fetchCategories() == [])
    }

    @Test func deleteMissingCategoryIsNoOp() async throws {
        let repository = try makeRepository()

        try await repository.deleteCategory(id: CategoryID())

        #expect(try await repository.fetchCategories() == [])
    }

    @Test func repositoryPreservesCategoryID() async throws {
        let repository = try makeRepository()
        let id = CategoryID(rawValue: try #require(UUID(uuidString: "983BC794-756A-4441-A98A-B35D3F8E532D")))
        let category = try makeCategory(id: id, name: "Groceries")

        try await repository.save(category)

        let fetchedCategory = try #require(try await repository.fetchCategory(id: id))
        #expect(fetchedCategory.id == id)
    }

    @Test func invalidPersistedCategoryRecordFailsMapping() async throws {
        let container = try makeInMemoryModelContainer()
        let insertContext = ModelContext(container)
        insertContext.insert(CategoryRecord(
            id: CategoryID().rawValue,
            name: "Groceries",
            kind: "transfer"
        ))
        try insertContext.save()

        let repository = await SwiftDataCategoryRepository(modelContainer: container)

        await #expect(throws: CategoryRecordMappingError.invalidKind("transfer")) {
            try await repository.fetchCategories()
        }
    }

    private func makeRepository() throws -> SwiftDataCategoryRepository {
        try SwiftDataCategoryRepository(modelContainer: makeInMemoryModelContainer())
    }

    private func makeInMemoryModelContainer() throws -> ModelContainer {
        let schema = Schema([
            CategoryRecord.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func makeCategory(
        id: CategoryID = CategoryID(),
        name: String,
        kind: CategoryKind = .expense
    ) throws -> Cairn.Category {
        try Category(
            id: id,
            name: name,
            kind: kind
        )
    }
}
