//
//  GoalTests.swift
//  CairnTests
//
//  Created by Karim Sheikh on 08/08/2026.
//

import Foundation
import Testing
@testable import Cairn

struct GoalTests {

    @Test func goalIDIsCodable() throws {
        let id = GoalID(rawValue: try #require(UUID(uuidString: "3F8D4182-F8C7-44CB-8594-377117D3293E")))

        let encoded = try JSONEncoder().encode(id)
        let decoded = try JSONDecoder().decode(GoalID.self, from: encoded)

        #expect(decoded == id)
    }

    @Test func initializationStoresValues() throws {
        let id = GoalID(rawValue: try #require(UUID(uuidString: "3F8D4182-F8C7-44CB-8594-377117D3293E")))
        let targetAmount = try Money(amount: 1_000, currencyCode: "GBP")
        let currentAmount = try Money(amount: 250, currencyCode: "GBP")
        let targetDate = Date(timeIntervalSince1970: 1_788_672_000)

        let goal = try Goal(
            id: id,
            name: "Emergency fund",
            targetAmount: targetAmount,
            currentAmount: currentAmount,
            targetDate: targetDate
        )

        #expect(goal.id == id)
        #expect(goal.name == "Emergency fund")
        #expect(goal.targetAmount == targetAmount)
        #expect(goal.currentAmount == currentAmount)
        #expect(goal.targetDate == targetDate)
    }

    @Test func initializationTrimsName() throws {
        let goal = try makeGoal(name: "  Holiday\n")

        #expect(goal.name == "Holiday")
    }

    @Test func initializationRejectsEmptyName() {
        #expect(throws: Goal.ValidationError.emptyName) {
            try makeGoal(name: "")
        }
    }

    @Test func initializationRejectsWhitespaceOnlyName() {
        #expect(throws: Goal.ValidationError.emptyName) {
            try makeGoal(name: " \n\t ")
        }
    }

    @Test func initializationAcceptsZeroTargetAndCurrentAmounts() throws {
        let targetAmount = try Money(amount: 0, currencyCode: "GBP")
        let currentAmount = try Money(amount: 0, currencyCode: "GBP")

        let goal = try makeGoal(
            targetAmount: targetAmount,
            currentAmount: currentAmount
        )

        #expect(goal.targetAmount.amount == 0)
        #expect(goal.currentAmount.amount == 0)
    }

    @Test func initializationRejectsZeroTargetAmountWithPositiveCurrentAmount() throws {
        let targetAmount = try Money(amount: 0, currencyCode: "GBP")
        let currentAmount = try Money(amount: 1, currencyCode: "GBP")

        #expect(throws: Goal.ValidationError.currentAmountExceedsTargetAmount) {
            try makeGoal(
                targetAmount: targetAmount,
                currentAmount: currentAmount
            )
        }
    }

    @Test func initializationRejectsNegativeTargetAmount() throws {
        let targetAmount = try Money(amount: -1, currencyCode: "GBP")
        let currentAmount = try Money(amount: 0, currencyCode: "GBP")

        #expect(throws: Goal.ValidationError.negativeTargetAmount) {
            try makeGoal(
                targetAmount: targetAmount,
                currentAmount: currentAmount
            )
        }
    }

    @Test func initializationRejectsNegativeCurrentAmount() throws {
        let targetAmount = try Money(amount: 1_000, currencyCode: "GBP")
        let currentAmount = try Money(amount: -1, currencyCode: "GBP")

        #expect(throws: Goal.ValidationError.negativeCurrentAmount) {
            try makeGoal(
                targetAmount: targetAmount,
                currentAmount: currentAmount
            )
        }
    }

    @Test func initializationRejectsCurrencyMismatch() throws {
        let targetAmount = try Money(amount: 1_000, currencyCode: "GBP")
        let currentAmount = try Money(amount: 250, currencyCode: "EUR")

        #expect(
            throws: Goal.ValidationError.currencyMismatch(
                targetCurrencyCode: "GBP",
                currentCurrencyCode: "EUR"
            )
        ) {
            try makeGoal(
                targetAmount: targetAmount,
                currentAmount: currentAmount
            )
        }
    }

    @Test func initializationRejectsCurrentAmountGreaterThanTargetAmount() throws {
        let targetAmount = try Money(amount: 1_000, currencyCode: "GBP")
        let currentAmount = try Money(amount: 1_001, currencyCode: "GBP")

        #expect(throws: Goal.ValidationError.currentAmountExceedsTargetAmount) {
            try makeGoal(
                targetAmount: targetAmount,
                currentAmount: currentAmount
            )
        }
    }

    @Test func initializationAcceptsCurrentAmountEqualToTargetAmount() throws {
        let targetAmount = try Money(amount: 1_000, currencyCode: "GBP")
        let currentAmount = try Money(amount: 1_000, currencyCode: "GBP")

        let goal = try makeGoal(
            targetAmount: targetAmount,
            currentAmount: currentAmount
        )

        #expect(goal.currentAmount == goal.targetAmount)
    }

    @Test func initializationAcceptsOptionalTargetDate() throws {
        let undatedGoal = try makeGoal(targetDate: nil)
        let targetDate = Date(timeIntervalSince1970: 1_788_672_000)
        let datedGoal = try makeGoal(targetDate: targetDate)

        #expect(undatedGoal.targetDate == nil)
        #expect(datedGoal.targetDate == targetDate)
    }

    @Test func initializationAcceptsPastTargetDate() throws {
        let targetDate = Date(timeIntervalSince1970: 0)

        let goal = try makeGoal(targetDate: targetDate)

        #expect(goal.targetDate == targetDate)
    }

    @Test func equalityUsesAllStoredValues() throws {
        let id = GoalID(rawValue: try #require(UUID(uuidString: "3F8D4182-F8C7-44CB-8594-377117D3293E")))
        let targetAmount = try Money(amount: 1_000, currencyCode: "GBP")
        let currentAmount = try Money(amount: 250, currencyCode: "GBP")
        let first = try Goal(
            id: id,
            name: "Emergency fund",
            targetAmount: targetAmount,
            currentAmount: currentAmount
        )
        let same = try Goal(
            id: id,
            name: "Emergency fund",
            targetAmount: targetAmount,
            currentAmount: currentAmount
        )
        let different = try Goal(
            id: id,
            name: "Holiday",
            targetAmount: targetAmount,
            currentAmount: currentAmount
        )

        #expect(first == same)
        #expect(first != different)
    }

    @Test func hashableUsesStoredValues() throws {
        let goal = try makeGoal()
        let same = try makeGoal(id: goal.id)

        #expect(Set([goal, same]).count == 1)
    }

    @Test func goalIsCodable() throws {
        let goal = try makeGoal(targetDate: Date(timeIntervalSince1970: 1_788_672_000))

        let encoded = try JSONEncoder().encode(goal)
        let decoded = try JSONDecoder().decode(Goal.self, from: encoded)

        #expect(decoded == goal)
    }

    @Test func goalCodableAppliesValidationWhenDecodingInvalidState() throws {
        let goal = try makeGoal()
        let encoded = try JSONEncoder().encode(goal)
        var json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        json["currentAmount"] = 1_001
        let data = try JSONSerialization.data(withJSONObject: json)

        #expect(throws: Goal.ValidationError.currentAmountExceedsTargetAmount) {
            try JSONDecoder().decode(Goal.self, from: data)
        }
    }

    @Test func goalCodableAppliesCurrencyValidationWhenDecoding() throws {
        let goal = try makeGoal()
        let encoded = try JSONEncoder().encode(goal)
        var json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        json["currentCurrencyCode"] = "EUR"
        let data = try JSONSerialization.data(withJSONObject: json)

        #expect(
            throws: Goal.ValidationError.currencyMismatch(
                targetCurrencyCode: "GBP",
                currentCurrencyCode: "EUR"
            )
        ) {
            try JSONDecoder().decode(Goal.self, from: data)
        }
    }

    @Test func goalIsSendable() throws {
        let goal = try makeGoal()

        requireSendable(goal)
    }

    private func makeGoal(
        id: GoalID? = nil,
        name: String = "Emergency fund",
        targetAmount: Money? = nil,
        currentAmount: Money? = nil,
        targetDate: Date? = nil
    ) throws -> Goal {
        let defaultID = GoalID(rawValue: try #require(UUID(uuidString: "3F8D4182-F8C7-44CB-8594-377117D3293E")))

        return try Goal(
            id: id ?? defaultID,
            name: name,
            targetAmount: targetAmount ?? Money(amount: 1_000, currencyCode: "GBP"),
            currentAmount: currentAmount ?? Money(amount: 250, currencyCode: "GBP"),
            targetDate: targetDate
        )
    }

    private func requireSendable<T: Sendable>(_ value: T) {
        _ = value
    }
}
