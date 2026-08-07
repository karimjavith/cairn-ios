//
//  CategoryTests.swift
//  CairnTests
//
//  Created by Karim Sheikh on 07/08/2026.
//

import Foundation
import Testing
@testable import Cairn

struct CategoryTests {

    @Test func initializationStoresValues() throws {
        let id = CategoryID(rawValue: try #require(UUID(uuidString: "B14F7964-7FF1-4671-A460-88D4B393C98A")))

        let category = try Category(
            id: id,
            name: "Groceries",
            kind: .expense
        )

        #expect(category.id == id)
        #expect(category.name == "Groceries")
        #expect(category.kind == .expense)
    }

    @Test func initializationTrimsName() throws {
        let category = try Category(
            name: "  Salary\n",
            kind: .income
        )

        #expect(category.name == "Salary")
    }

    @Test func initializationRejectsEmptyName() {
        #expect(throws: Category.ValidationError.emptyName) {
            try Category(name: "", kind: .expense)
        }
    }

    @Test func initializationRejectsWhitespaceOnlyName() {
        #expect(throws: Category.ValidationError.emptyName) {
            try Category(name: " \n\t ", kind: .income)
        }
    }

    @Test func incomeCategoryStoresKind() throws {
        let category = try Category(name: "Salary", kind: .income)

        #expect(category.kind == .income)
    }

    @Test func expenseCategoryStoresKind() throws {
        let category = try Category(name: "Groceries", kind: .expense)

        #expect(category.kind == .expense)
    }

    @Test func equalityUsesAllStoredValues() throws {
        let id = CategoryID(rawValue: try #require(UUID(uuidString: "B14F7964-7FF1-4671-A460-88D4B393C98A")))
        let first = try Category(id: id, name: "Salary", kind: .income)
        let same = try Category(id: id, name: "Salary", kind: .income)
        let different = try Category(id: id, name: "Salary", kind: .expense)

        #expect(first == same)
        #expect(first != different)
    }

    @Test func hashableUsesStoredValues() throws {
        let category = try makeCategory()
        let same = try makeCategory(id: category.id)

        #expect(Set([category, same]).count == 1)
    }

    @Test func categoryIDDefaultsToUniqueUUIDBackedValues() {
        let first = CategoryID()
        let second = CategoryID()

        #expect(first != second)
    }

    @Test func categoryIDIsCodable() throws {
        let id = CategoryID(rawValue: try #require(UUID(uuidString: "B14F7964-7FF1-4671-A460-88D4B393C98A")))

        let encoded = try JSONEncoder().encode(id)
        let decoded = try JSONDecoder().decode(CategoryID.self, from: encoded)

        #expect(decoded == id)
    }

    @Test func categoryKindIsCodable() throws {
        let kind = CategoryKind.expense

        let encoded = try JSONEncoder().encode(kind)
        let decoded = try JSONDecoder().decode(CategoryKind.self, from: encoded)

        #expect(decoded == kind)
    }

    @Test func categoryIsCodable() throws {
        let category = try makeCategory()

        let encoded = try JSONEncoder().encode(category)
        let decoded = try JSONDecoder().decode(Category.self, from: encoded)

        #expect(decoded == category)
    }

    @Test func categoryCodableAppliesValidationWhenDecoding() throws {
        let category = try makeCategory()
        let encoded = try JSONEncoder().encode(category)
        var json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        json["name"] = " \n\t "
        let data = try JSONSerialization.data(withJSONObject: json)

        #expect(throws: Category.ValidationError.emptyName) {
            try JSONDecoder().decode(Category.self, from: data)
        }
    }

    @Test func categoryIsSendable() throws {
        let category = try makeCategory()

        requireSendable(category)
    }

    private func makeCategory(
        id: CategoryID? = nil,
        name: String = "Groceries",
        kind: CategoryKind = .expense
    ) throws -> Cairn.Category {
        let defaultID = CategoryID(rawValue: try #require(UUID(uuidString: "B14F7964-7FF1-4671-A460-88D4B393C98A")))

        return try Category(
            id: id ?? defaultID,
            name: name,
            kind: kind
        )
    }

    private func requireSendable<T: Sendable>(_ value: T) {
        _ = value
    }
}
