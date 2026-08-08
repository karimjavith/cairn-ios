//
//  SwiftDataBudgetRepository.swift
//  Cairn
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import SwiftData

@ModelActor
actor SwiftDataBudgetRepository: BudgetRepository {

    func fetchBudgets() async throws -> [Budget] {
        var descriptor = FetchDescriptor<BudgetRecord>(
            sortBy: [
                SortDescriptor(\.startDate, order: .reverse),
                SortDescriptor(\.endDate, order: .reverse),
                SortDescriptor(\.id)
            ]
        )
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor).map { try $0.budget() }
    }

    func fetchBudget(id: BudgetID) async throws -> Budget? {
        try fetchRecord(id: id)?.budget()
    }

    func save(_ budget: Budget) async throws {
        if let existingRecord = try fetchRecord(id: budget.id) {
            existingRecord.applyPersistedValues(from: budget)
        } else {
            modelContext.insert(BudgetRecord(budget: budget))
        }

        try modelContext.save()
    }

    func deleteBudget(id: BudgetID) async throws {
        guard let record = try fetchRecord(id: id) else {
            return
        }

        modelContext.delete(record)
        try modelContext.save()
    }

    private func fetchRecord(id: BudgetID) throws -> BudgetRecord? {
        let rawID = id.rawValue
        var descriptor = FetchDescriptor<BudgetRecord>(
            predicate: #Predicate { record in
                record.id == rawID
            }
        )
        descriptor.fetchLimit = 1
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor).first
    }
}

private extension BudgetRecord {
    func applyPersistedValues(from budget: Budget) {
        let updatedRecord = BudgetRecord(budget: budget)

        id = updatedRecord.id
        categoryID = updatedRecord.categoryID
        limitAmount = updatedRecord.limitAmount
        currencyCode = updatedRecord.currencyCode
        startDate = updatedRecord.startDate
        endDate = updatedRecord.endDate
    }
}
