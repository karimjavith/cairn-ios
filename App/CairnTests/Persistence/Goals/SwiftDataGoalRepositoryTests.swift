//
//  SwiftDataGoalRepositoryTests.swift
//  CairnTests
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import SwiftData
import Testing
@testable import Cairn

struct SwiftDataGoalRepositoryTests {

    @Test func fetchGoalsOnEmptyStoreReturnsEmptyArray() async throws {
        let repository = try makeRepository()

        let goals = try await repository.fetchGoals()

        #expect(goals == [])
    }

    @Test func saveInsertsGoal() async throws {
        let repository = try makeRepository()
        let goal = try makeGoal(name: "Emergency fund")

        try await repository.save(goal)

        let goals = try await repository.fetchGoals()
        #expect(goals == [goal])
    }

    @Test func fetchGoalReturnsSavedGoal() async throws {
        let repository = try makeRepository()
        let goal = try makeGoal(name: "Emergency fund")

        try await repository.save(goal)

        let fetchedGoal = try await repository.fetchGoal(id: goal.id)
        #expect(fetchedGoal == goal)
    }

    @Test func fetchGoalReturnsNilWhenMissing() async throws {
        let repository = try makeRepository()

        let fetchedGoal = try await repository.fetchGoal(id: GoalID())

        #expect(fetchedGoal == nil)
    }

    @Test func fetchGoalsReturnsAllSavedGoals() async throws {
        let repository = try makeRepository()
        let emergencyFund = try makeGoal(name: "Emergency fund")
        let holiday = try makeGoal(name: "Holiday")

        try await repository.save(holiday)
        try await repository.save(emergencyFund)

        let goals = try await repository.fetchGoals()
        #expect(goals == [emergencyFund, holiday])
    }

    @Test func fetchGoalsOrdersNonNilTargetDatesAscendingBeforeNilTargetDates() async throws {
        let repository = try makeRepository()
        let nilTargetDate = try makeGoal(name: "No target", targetDate: nil)
        let later = try makeGoal(
            name: "Later",
            targetDate: Date(timeIntervalSince1970: 1_791_264_000)
        )
        let earlier = try makeGoal(
            name: "Earlier",
            targetDate: Date(timeIntervalSince1970: 1_788_672_000)
        )

        try await repository.save(nilTargetDate)
        try await repository.save(later)
        try await repository.save(earlier)

        let goals = try await repository.fetchGoals()
        #expect(goals == [earlier, later, nilTargetDate])
    }

    @Test func fetchGoalsOrdersByNameAscendingWhenTargetDatesAreEqual() async throws {
        let repository = try makeRepository()
        let targetDate = Date(timeIntervalSince1970: 1_788_672_000)
        let zeta = try makeGoal(name: "Zeta", targetDate: targetDate)
        let alpha = try makeGoal(name: "Alpha", targetDate: targetDate)
        let middle = try makeGoal(name: "Middle", targetDate: targetDate)

        try await repository.save(zeta)
        try await repository.save(alpha)
        try await repository.save(middle)

        let goals = try await repository.fetchGoals()
        #expect(goals == [alpha, middle, zeta])
    }

    @Test func fetchGoalsUsesStableGoalIDOrderingWhenTargetDatesAndNamesAreEqual() async throws {
        let repository = try makeRepository()
        let targetDate = Date(timeIntervalSince1970: 1_788_672_000)
        let first = try makeGoal(
            id: GoalID(rawValue: try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))),
            name: "Holiday",
            targetDate: targetDate
        )
        let second = try makeGoal(
            id: GoalID(rawValue: try #require(UUID(uuidString: "22222222-2222-2222-2222-222222222222"))),
            name: "Holiday",
            targetDate: targetDate
        )
        let third = try makeGoal(
            id: GoalID(rawValue: try #require(UUID(uuidString: "33333333-3333-3333-3333-333333333333"))),
            name: "Holiday",
            targetDate: targetDate
        )

        try await repository.save(third)
        try await repository.save(first)
        try await repository.save(second)

        let goals = try await repository.fetchGoals()
        #expect(goals == [first, second, third])
    }

    @Test func repeatedSaveWithSameGoalIDUpdatesWithoutCreatingDuplicates() async throws {
        let repository = try makeRepository()
        let id = GoalID()
        let original = try makeGoal(id: id, name: "Holiday", targetAmount: 100, currentAmount: 50)
        let updated = try makeGoal(id: id, name: "Holiday", targetAmount: 200, currentAmount: 50)

        try await repository.save(original)
        try await repository.save(updated)

        let goals = try await repository.fetchGoals()
        #expect(goals == [updated])
    }

    @Test func updatedNamePersists() async throws {
        let repository = try makeRepository()
        let id = GoalID()
        let original = try makeGoal(id: id, name: "Holiday")
        let updated = try makeGoal(id: id, name: "Emergency fund")

        try await repository.save(original)
        try await repository.save(updated)

        let fetchedGoal = try #require(try await repository.fetchGoal(id: id))
        #expect(fetchedGoal.name == "Emergency fund")
        #expect(fetchedGoal == updated)
    }

    @Test func updatedTargetAmountPersistsWithDecimalPrecision() async throws {
        let repository = try makeRepository()
        let id = GoalID()
        let original = try makeGoal(id: id, targetAmount: 100, currentAmount: 0)
        let preciseAmount = try #require(Decimal(string: "1234567890.123456789012345678"))
        let updated = try makeGoal(id: id, targetAmount: preciseAmount, currentAmount: 1)

        try await repository.save(original)
        try await repository.save(updated)

        let fetchedGoal = try #require(try await repository.fetchGoal(id: id))
        #expect(fetchedGoal.targetAmount.amount == preciseAmount)
        #expect(fetchedGoal == updated)
    }

    @Test func updatedCurrentAmountPersistsWithDecimalPrecision() async throws {
        let repository = try makeRepository()
        let id = GoalID()
        let original = try makeGoal(id: id, targetAmount: 100, currentAmount: 0)
        let preciseAmount = try #require(Decimal(string: "1234567890.123456789012345678"))
        let updated = try makeGoal(id: id, targetAmount: preciseAmount, currentAmount: preciseAmount)

        try await repository.save(original)
        try await repository.save(updated)

        let fetchedGoal = try #require(try await repository.fetchGoal(id: id))
        #expect(fetchedGoal.currentAmount.amount == preciseAmount)
        #expect(fetchedGoal == updated)
    }

    @Test func updatedTargetDatePersists() async throws {
        let repository = try makeRepository()
        let id = GoalID()
        let originalDate = Date(timeIntervalSince1970: 1_788_672_000)
        let updatedDate = Date(timeIntervalSince1970: 1_791_264_000)
        let original = try makeGoal(id: id, targetDate: originalDate)
        let updated = try makeGoal(id: id, targetDate: updatedDate)

        try await repository.save(original)
        try await repository.save(updated)

        let fetchedGoal = try #require(try await repository.fetchGoal(id: id))
        #expect(fetchedGoal.targetDate == updatedDate)
        #expect(fetchedGoal == updated)
    }

    @Test func targetDateCanChangeFromNonNilToNil() async throws {
        let repository = try makeRepository()
        let id = GoalID()
        let original = try makeGoal(
            id: id,
            targetDate: Date(timeIntervalSince1970: 1_788_672_000)
        )
        let updated = try makeGoal(id: id, targetDate: nil)

        try await repository.save(original)
        try await repository.save(updated)

        let fetchedGoal = try #require(try await repository.fetchGoal(id: id))
        #expect(fetchedGoal.targetDate == nil)
        #expect(fetchedGoal == updated)
    }

    @Test func targetDateCanChangeFromNilToNonNil() async throws {
        let repository = try makeRepository()
        let id = GoalID()
        let updatedDate = Date(timeIntervalSince1970: 1_788_672_000)
        let original = try makeGoal(id: id, targetDate: nil)
        let updated = try makeGoal(id: id, targetDate: updatedDate)

        try await repository.save(original)
        try await repository.save(updated)

        let fetchedGoal = try #require(try await repository.fetchGoal(id: id))
        #expect(fetchedGoal.targetDate == updatedDate)
        #expect(fetchedGoal == updated)
    }

    @Test func deleteRemovesExistingGoal() async throws {
        let repository = try makeRepository()
        let goal = try makeGoal(name: "Emergency fund")

        try await repository.save(goal)
        try await repository.deleteGoal(id: goal.id)

        let fetchedGoal = try await repository.fetchGoal(id: goal.id)
        #expect(fetchedGoal == nil)
        #expect(try await repository.fetchGoals() == [])
    }

    @Test func deleteMissingGoalIsNoOp() async throws {
        let repository = try makeRepository()

        try await repository.deleteGoal(id: GoalID())

        #expect(try await repository.fetchGoals() == [])
    }

    @Test func repositoryPreservesGoalID() async throws {
        let repository = try makeRepository()
        let id = GoalID(rawValue: try #require(UUID(uuidString: "86A05998-7658-4F15-AB03-A8E8C84986A3")))
        let goal = try makeGoal(id: id, name: "Emergency fund")

        try await repository.save(goal)

        let fetchedGoal = try #require(try await repository.fetchGoal(id: id))
        #expect(fetchedGoal.id == id)
    }

    @Test func repositoryPreservesHighPrecisionMonetaryValues() async throws {
        let repository = try makeRepository()
        let targetAmount = try #require(Decimal(string: "1234567890.123456789012345678"))
        let currentAmount = try #require(Decimal(string: "987654321.987654321012345678"))
        let goal = try makeGoal(
            name: "High precision",
            targetAmount: targetAmount,
            currentAmount: currentAmount
        )

        try await repository.save(goal)

        let fetchedGoal = try #require(try await repository.fetchGoal(id: goal.id))
        #expect(fetchedGoal.targetAmount.amount == targetAmount)
        #expect(fetchedGoal.currentAmount.amount == currentAmount)
        #expect(fetchedGoal == goal)
    }

    @Test func invalidPersistedGoalRecordFailsMapping() async throws {
        let container = try makeInMemoryModelContainer()
        let insertContext = ModelContext(container)
        insertContext.insert(GoalRecord(
            id: GoalID().rawValue,
            name: "Emergency fund",
            targetAmount: "12abc",
            targetCurrencyCode: "GBP",
            currentAmount: "25",
            currentCurrencyCode: "GBP",
            targetDate: nil
        ))
        try insertContext.save()

        let repository = await SwiftDataGoalRepository(modelContainer: container)

        await #expect(throws: GoalRecordMappingError.invalidTargetAmount("12abc")) {
            try await repository.fetchGoals()
        }
    }

    private func makeRepository() throws -> SwiftDataGoalRepository {
        try SwiftDataGoalRepository(modelContainer: makeInMemoryModelContainer())
    }

    private func makeInMemoryModelContainer() throws -> ModelContainer {
        let schema = Schema([
            GoalRecord.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func makeGoal(
        id: GoalID = GoalID(),
        name: String = "Emergency fund",
        targetAmount: Decimal = 1_000,
        currentAmount: Decimal = 250,
        currencyCode: String = "GBP",
        targetDate: Date? = nil
    ) throws -> Goal {
        try Goal(
            id: id,
            name: name,
            targetAmount: Money(
                amount: targetAmount,
                currencyCode: currencyCode
            ),
            currentAmount: Money(
                amount: currentAmount,
                currencyCode: currencyCode
            ),
            targetDate: targetDate
        )
    }
}
