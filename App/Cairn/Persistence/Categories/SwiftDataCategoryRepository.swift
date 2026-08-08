//
//  SwiftDataCategoryRepository.swift
//  Cairn
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import SwiftData

@ModelActor
actor SwiftDataCategoryRepository: CategoryRepository {

    func fetchCategories() async throws -> [Category] {
        var descriptor = FetchDescriptor<CategoryRecord>(
            sortBy: [
                SortDescriptor(\.name),
                SortDescriptor(\.id)
            ]
        )
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor).map { try $0.category() }
    }

    func fetchCategory(id: CategoryID) async throws -> Category? {
        try fetchRecord(id: id)?.category()
    }

    func save(_ category: Category) async throws {
        if let existingRecord = try fetchRecord(id: category.id) {
            existingRecord.applyPersistedValues(from: category)
        } else {
            modelContext.insert(CategoryRecord(category: category))
        }

        try modelContext.save()
    }

    func deleteCategory(id: CategoryID) async throws {
        guard let record = try fetchRecord(id: id) else {
            return
        }

        modelContext.delete(record)
        try modelContext.save()
    }

    private func fetchRecord(id: CategoryID) throws -> CategoryRecord? {
        let rawID = id.rawValue
        var descriptor = FetchDescriptor<CategoryRecord>(
            predicate: #Predicate { record in
                record.id == rawID
            }
        )
        descriptor.fetchLimit = 1
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor).first
    }
}

private extension CategoryRecord {
    func applyPersistedValues(from category: Category) {
        let updatedRecord = CategoryRecord(category: category)

        id = updatedRecord.id
        name = updatedRecord.name
        kind = updatedRecord.kind
    }
}
