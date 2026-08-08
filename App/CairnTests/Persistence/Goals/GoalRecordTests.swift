//
//  GoalRecordTests.swift
//  CairnTests
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import SwiftData
import Testing
@testable import Cairn

struct GoalRecordTests {

    @Test func goalToRecordPreservesPersistedValues() throws {
        let id = GoalID(rawValue: try #require(UUID(uuidString: "748C4BA3-E8BE-434A-8CDB-30B781761694")))
        let targetAmount = try #require(Decimal(string: "1234567890.123456789"))
        let currentAmount = try #require(Decimal(string: "987654321.987654321"))
        let targetDate = Date(timeIntervalSince1970: 1_788_672_000)
        let goal = try Goal(
            id: id,
            name: "  Emergency fund\n",
            targetAmount: Money(amount: targetAmount, currencyCode: "gbp"),
            currentAmount: Money(amount: currentAmount, currencyCode: "gbp"),
            targetDate: targetDate
        )

        let record = GoalRecord(goal: goal)

        #expect(record.id == id.rawValue)
        #expect(record.name == "Emergency fund")
        #expect(record.targetAmount == "1234567890.123456789")
        #expect(record.targetCurrencyCode == "GBP")
        #expect(record.currentAmount == "987654321.987654321")
        #expect(record.currentCurrencyCode == "GBP")
        #expect(record.targetDate == targetDate)
    }

    @Test func recordToGoalReconstructsEquivalentDomainGoal() throws {
        let id = try #require(UUID(uuidString: "4E4AAAC1-0127-4C78-A02E-EA1F47CCB5B1"))
        let targetAmount = try #require(Decimal(string: "42.01"))
        let currentAmount = try #require(Decimal(string: "12.34"))
        let targetDate = Date(timeIntervalSince1970: 1_788_672_000)
        let record = GoalRecord(
            id: id,
            name: "Holiday",
            targetAmount: "42.01",
            targetCurrencyCode: "EUR",
            currentAmount: "12.34",
            currentCurrencyCode: "EUR",
            targetDate: targetDate
        )

        let goal = try record.goal()
        let expectedGoal = try Goal(
            id: GoalID(rawValue: id),
            name: "Holiday",
            targetAmount: Money(amount: targetAmount, currencyCode: "EUR"),
            currentAmount: Money(amount: currentAmount, currencyCode: "EUR"),
            targetDate: targetDate
        )

        #expect(goal == expectedGoal)
    }

    @Test func goalIDSurvivesCompleteMappingRoundTrip() throws {
        let id = GoalID(rawValue: try #require(UUID(uuidString: "8E5F8228-0FBC-40E2-A720-01D82F44728D")))
        let goal = try makeGoal(id: id)

        let roundTrippedGoal = try GoalRecord(goal: goal).goal()

        #expect(roundTrippedGoal.id == id)
    }

    @Test func normalizedNameSurvivesMappingRoundTrip() throws {
        let goal = try makeGoal(name: "  Emergency fund\n")

        let roundTrippedGoal = try GoalRecord(goal: goal).goal()

        #expect(roundTrippedGoal.name == "Emergency fund")
    }

    @Test func highPrecisionTargetAmountSurvivesMappingRoundTrip() throws {
        let amount = try #require(Decimal(string: "1234567890.123456789012345678"))
        let goal = try makeGoal(
            targetAmount: Money(amount: amount, currencyCode: "GBP"),
            currentAmount: Money(amount: 1, currencyCode: "GBP")
        )

        let roundTrippedGoal = try GoalRecord(goal: goal).goal()

        #expect(roundTrippedGoal.targetAmount.amount == amount)
    }

    @Test func highPrecisionCurrentAmountSurvivesMappingRoundTrip() throws {
        let amount = try #require(Decimal(string: "1234567890.123456789012345678"))
        let goal = try makeGoal(
            targetAmount: Money(amount: amount, currencyCode: "GBP"),
            currentAmount: Money(amount: amount, currencyCode: "GBP")
        )

        let roundTrippedGoal = try GoalRecord(goal: goal).goal()

        #expect(roundTrippedGoal.currentAmount.amount == amount)
    }

    @Test func targetCurrencySurvivesMappingRoundTrip() throws {
        let goal = try makeGoal(
            targetAmount: Money(amount: 100, currencyCode: "eur"),
            currentAmount: Money(amount: 10, currencyCode: "eur")
        )

        let roundTrippedGoal = try GoalRecord(goal: goal).goal()

        #expect(roundTrippedGoal.targetAmount.currencyCode == "EUR")
    }

    @Test func currentCurrencySurvivesMappingRoundTrip() throws {
        let goal = try makeGoal(
            targetAmount: Money(amount: 100, currencyCode: "usd"),
            currentAmount: Money(amount: 10, currencyCode: "usd")
        )

        let roundTrippedGoal = try GoalRecord(goal: goal).goal()

        #expect(roundTrippedGoal.currentAmount.currencyCode == "USD")
    }

    @Test func nilTargetDateSurvivesMappingRoundTrip() throws {
        let goal = try makeGoal(targetDate: nil)

        let roundTrippedGoal = try GoalRecord(goal: goal).goal()

        #expect(roundTrippedGoal.targetDate == nil)
    }

    @Test func nonNilTargetDateSurvivesMappingRoundTrip() throws {
        let targetDate = Date(timeIntervalSince1970: 1_788_672_000)
        let goal = try makeGoal(targetDate: targetDate)

        let roundTrippedGoal = try GoalRecord(goal: goal).goal()

        #expect(roundTrippedGoal.targetDate == targetDate)
    }

    @Test func pastTargetDateSurvivesMappingRoundTrip() throws {
        let targetDate = Date(timeIntervalSince1970: 0)
        let goal = try makeGoal(targetDate: targetDate)

        let roundTrippedGoal = try GoalRecord(goal: goal).goal()

        #expect(roundTrippedGoal.targetDate == targetDate)
    }

    @Test func zeroTargetAndCurrentSurvivesMappingRoundTrip() throws {
        let goal = try makeGoal(
            targetAmount: Money(amount: 0, currencyCode: "GBP"),
            currentAmount: Money(amount: 0, currencyCode: "GBP")
        )

        let roundTrippedGoal = try GoalRecord(goal: goal).goal()

        #expect(roundTrippedGoal.targetAmount.amount == 0)
        #expect(roundTrippedGoal.currentAmount.amount == 0)
    }

    @Test func invalidPersistedTargetDecimalFailsReconstruction() {
        let record = makeRecord(targetAmount: "not-a-decimal")

        #expect(throws: GoalRecordMappingError.invalidTargetAmount("not-a-decimal")) {
            try record.goal()
        }
    }

    @Test func invalidPersistedCurrentDecimalFailsReconstruction() {
        let record = makeRecord(currentAmount: "not-a-decimal")

        #expect(throws: GoalRecordMappingError.invalidCurrentAmount("not-a-decimal")) {
            try record.goal()
        }
    }

    @Test func dotDecimalPersistedTargetAmountReconstructsExactly() throws {
        let record = makeRecord(targetAmount: "42.01", currentAmount: "12.34")
        let expectedAmount = try #require(
            Decimal(string: "42.01", locale: Locale(identifier: "en_US_POSIX"))
        )

        let goal = try record.goal()

        #expect(goal.targetAmount.amount == expectedAmount)
    }

    @Test func dotDecimalPersistedCurrentAmountReconstructsExactly() throws {
        let record = makeRecord(targetAmount: "42.01", currentAmount: "12.34")
        let expectedAmount = try #require(
            Decimal(string: "12.34", locale: Locale(identifier: "en_US_POSIX"))
        )

        let goal = try record.goal()

        #expect(goal.currentAmount.amount == expectedAmount)
    }

    @Test func exponentPersistedGoalAmountsReconstructExactly() throws {
        let record = makeRecord(targetAmount: "1.23e2", currentAmount: "1.2e1")
        let expectedTargetAmount = try #require(
            Decimal(string: "123", locale: Locale(identifier: "en_US_POSIX"))
        )
        let expectedCurrentAmount = try #require(
            Decimal(string: "12", locale: Locale(identifier: "en_US_POSIX"))
        )

        let goal = try record.goal()

        #expect(goal.targetAmount.amount == expectedTargetAmount)
        #expect(goal.currentAmount.amount == expectedCurrentAmount)
    }

    @Test(arguments: ["12abc", "1,23", "not-a-number"])
    func malformedPersistedTargetDecimalFailsReconstruction(value: String) {
        let record = makeRecord(targetAmount: value)

        #expect(throws: GoalRecordMappingError.invalidTargetAmount(value)) {
            try record.goal()
        }
    }

    @Test(arguments: ["12abc", "1,23", "not-a-number"])
    func malformedPersistedCurrentDecimalFailsReconstruction(value: String) {
        let record = makeRecord(currentAmount: value)

        #expect(throws: GoalRecordMappingError.invalidCurrentAmount(value)) {
            try record.goal()
        }
    }

    @Test func negativePersistedTargetFailsThroughGoalValidation() {
        let record = makeRecord(targetAmount: "-1", currentAmount: "0")

        #expect(throws: Goal.ValidationError.negativeTargetAmount) {
            try record.goal()
        }
    }

    @Test func emptyPersistedNameFailsThroughGoalValidation() {
        let record = makeRecord(name: " \n\t ")

        #expect(throws: Goal.ValidationError.emptyName) {
            try record.goal()
        }
    }

    @Test func negativePersistedCurrentFailsThroughGoalValidation() {
        let record = makeRecord(targetAmount: "100", currentAmount: "-1")

        #expect(throws: Goal.ValidationError.negativeCurrentAmount) {
            try record.goal()
        }
    }

    @Test func currencyMismatchFailsThroughGoalValidation() {
        let record = makeRecord(
            targetCurrencyCode: "GBP",
            currentCurrencyCode: "EUR"
        )

        #expect(
            throws: Goal.ValidationError.currencyMismatch(
                targetCurrencyCode: "GBP",
                currentCurrencyCode: "EUR"
            )
        ) {
            try record.goal()
        }
    }

    @Test func currentAmountGreaterThanTargetAmountFailsThroughGoalValidation() {
        let record = makeRecord(targetAmount: "100", currentAmount: "100.01")

        #expect(throws: Goal.ValidationError.currentAmountExceedsTargetAmount) {
            try record.goal()
        }
    }

    @Test func swiftDataPersistenceRoundTripPreservesGoalValues() throws {
        let id = GoalID(rawValue: try #require(UUID(uuidString: "BDE30E88-71A6-40E8-95E6-E529614A92F3")))
        let targetAmount = try #require(Decimal(string: "1234567890.123456789012345678"))
        let currentAmount = try #require(Decimal(string: "987654321.987654321012345678"))
        let targetDate = Date(timeIntervalSince1970: 1_788_672_000)
        let goal = try Goal(
            id: id,
            name: "  High Precision Goal\n",
            targetAmount: Money(amount: targetAmount, currencyCode: "gbp"),
            currentAmount: Money(amount: currentAmount, currencyCode: "gbp"),
            targetDate: targetDate
        )
        let container = try makeInMemoryModelContainer()
        let insertContext = ModelContext(container)

        insertContext.insert(GoalRecord(goal: goal))
        try insertContext.save()

        let fetchContext = ModelContext(container)
        let descriptor = FetchDescriptor<GoalRecord>()
        let fetchedRecord = try #require(try fetchContext.fetch(descriptor).first)
        let fetchedGoal = try fetchedRecord.goal()

        #expect(fetchedGoal.id == id)
        #expect(fetchedGoal.name == "High Precision Goal")
        #expect(fetchedGoal.targetAmount.amount == targetAmount)
        #expect(fetchedGoal.targetAmount.currencyCode == "GBP")
        #expect(fetchedGoal.currentAmount.amount == currentAmount)
        #expect(fetchedGoal.currentAmount.currencyCode == "GBP")
        #expect(fetchedGoal.targetDate == targetDate)
    }

    private func makeGoal(
        id: GoalID? = nil,
        name: String = "Emergency fund",
        targetAmount: Money? = nil,
        currentAmount: Money? = nil,
        targetDate: Date? = nil
    ) throws -> Goal {
        let defaultID = GoalID(rawValue: try #require(UUID(uuidString: "748C4BA3-E8BE-434A-8CDB-30B781761694")))

        return try Goal(
            id: id ?? defaultID,
            name: name,
            targetAmount: targetAmount ?? Money(amount: 1_000, currencyCode: "GBP"),
            currentAmount: currentAmount ?? Money(amount: 250, currencyCode: "GBP"),
            targetDate: targetDate
        )
    }

    private func makeRecord(
        name: String = "Emergency fund",
        targetAmount: String = "100",
        targetCurrencyCode: String = "GBP",
        currentAmount: String = "25",
        currentCurrencyCode: String = "GBP",
        targetDate: Date? = nil
    ) -> GoalRecord {
        GoalRecord(
            id: UUID(),
            name: name,
            targetAmount: targetAmount,
            targetCurrencyCode: targetCurrencyCode,
            currentAmount: currentAmount,
            currentCurrencyCode: currentCurrencyCode,
            targetDate: targetDate
        )
    }

    private func makeInMemoryModelContainer() throws -> ModelContainer {
        let schema = Schema([
            GoalRecord.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
