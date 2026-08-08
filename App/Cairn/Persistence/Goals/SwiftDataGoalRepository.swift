//
//  SwiftDataGoalRepository.swift
//  Cairn
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import SwiftData

@ModelActor
actor SwiftDataGoalRepository: GoalRepository {

    func fetchGoals() async throws -> [Goal] {
        var descriptor = FetchDescriptor<GoalRecord>()
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor)
            .map { try $0.goal() }
            .sortedByGoalOrdering()
    }

    func fetchGoal(id: GoalID) async throws -> Goal? {
        try fetchRecord(id: id)?.goal()
    }

    func save(_ goal: Goal) async throws {
        if let existingRecord = try fetchRecord(id: goal.id) {
            existingRecord.applyPersistedValues(from: goal)
        } else {
            modelContext.insert(GoalRecord(goal: goal))
        }

        try modelContext.save()
    }

    func deleteGoal(id: GoalID) async throws {
        guard let record = try fetchRecord(id: id) else {
            return
        }

        modelContext.delete(record)
        try modelContext.save()
    }

    private func fetchRecord(id: GoalID) throws -> GoalRecord? {
        let rawID = id.rawValue
        var descriptor = FetchDescriptor<GoalRecord>(
            predicate: #Predicate { record in
                record.id == rawID
            }
        )
        descriptor.fetchLimit = 1
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor).first
    }
}

private extension Array where Element == Goal {
    func sortedByGoalOrdering() -> [Goal] {
        sorted { lhs, rhs in
            switch (lhs.targetDate, rhs.targetDate) {
            case let (lhsDate?, rhsDate?) where lhsDate != rhsDate:
                return lhsDate < rhsDate
            case (.some, nil):
                return true
            case (nil, .some):
                return false
            default:
                if lhs.name != rhs.name {
                    return lhs.name < rhs.name
                }

                return lhs.id.rawValue.uuidString < rhs.id.rawValue.uuidString
            }
        }
    }
}

private extension GoalRecord {
    func applyPersistedValues(from goal: Goal) {
        let updatedRecord = GoalRecord(goal: goal)

        id = updatedRecord.id
        name = updatedRecord.name
        targetAmount = updatedRecord.targetAmount
        targetCurrencyCode = updatedRecord.targetCurrencyCode
        currentAmount = updatedRecord.currentAmount
        currentCurrencyCode = updatedRecord.currentCurrencyCode
        targetDate = updatedRecord.targetDate
    }
}
