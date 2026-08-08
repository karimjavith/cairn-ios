//
//  CalculateGoalProgressTests.swift
//  CairnTests
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import Testing
@testable import Cairn

struct CalculateGoalProgressTests {

    @Test func zeroCurrentAmountReturnsFullTargetRemaining() throws {
        let goal = try makeGoal(
            targetAmount: Money(amount: 1_000, currencyCode: "GBP"),
            currentAmount: Money(amount: 0, currencyCode: "GBP")
        )

        let progress = try CalculateGoalProgress()(goal: goal)

        #expect(progress.goal == goal)
        try expectMoney(progress.remainingAmount, amount: 1_000, currencyCode: "GBP")
    }

    @Test func partialProgressReturnsCorrectRemaining() throws {
        let goal = try makeGoal(
            targetAmount: Money(amount: 1_000, currencyCode: "GBP"),
            currentAmount: Money(amount: 375, currencyCode: "GBP")
        )

        let progress = try CalculateGoalProgress()(goal: goal)

        try expectMoney(progress.remainingAmount, amount: 625, currencyCode: "GBP")
    }

    @Test func completedGoalReturnsZeroRemaining() throws {
        let goal = try makeGoal(
            targetAmount: Money(amount: 1_000, currencyCode: "GBP"),
            currentAmount: Money(amount: 1_000, currencyCode: "GBP")
        )

        let progress = try CalculateGoalProgress()(goal: goal)

        try expectMoney(progress.remainingAmount, amount: 0, currencyCode: "GBP")
    }

    @Test func highPrecisionDecimalRemainingIsPreserved() throws {
        let goal = try makeGoal(
            targetAmount: Money(amount: decimal("1.000000000000000006"), currencyCode: "GBP"),
            currentAmount: Money(amount: decimal("0.000000000000000005"), currencyCode: "GBP")
        )

        let progress = try CalculateGoalProgress()(goal: goal)

        try expectMoney(progress.remainingAmount, amount: decimal("1.000000000000000001"), currencyCode: "GBP")
    }

    @Test func currentLessThanTargetIsNotCompleted() throws {
        let goal = try makeGoal(
            targetAmount: Money(amount: 1_000, currencyCode: "GBP"),
            currentAmount: Money(amount: 999, currencyCode: "GBP")
        )

        let progress = try CalculateGoalProgress()(goal: goal)

        #expect(progress.isCompleted == false)
    }

    @Test func currentEqualToTargetIsCompleted() throws {
        let goal = try makeGoal(
            targetAmount: Money(amount: 1_000, currencyCode: "GBP"),
            currentAmount: Money(amount: 1_000, currencyCode: "GBP")
        )

        let progress = try CalculateGoalProgress()(goal: goal)

        #expect(progress.isCompleted)
    }

    @Test func zeroTargetAndZeroCurrentIsCompleted() throws {
        let goal = try makeGoal(
            targetAmount: Money(amount: 0, currencyCode: "GBP"),
            currentAmount: Money(amount: 0, currencyCode: "GBP")
        )

        let progress = try CalculateGoalProgress()(goal: goal)

        #expect(progress.isCompleted)
        try expectMoney(progress.remainingAmount, amount: 0, currencyCode: "GBP")
    }

    @Test func nilTargetDateDoesNotAffectResult() throws {
        let goal = try makeGoal(targetDate: nil)
        let withoutDate = try CalculateGoalProgress()(goal: goal)
        let sameAmounts = try makeGoal(targetDate: Date(timeIntervalSince1970: 2_000_000_000))
        let withFutureDate = try CalculateGoalProgress()(goal: sameAmounts)

        #expect(withoutDate.remainingAmount == withFutureDate.remainingAmount)
        #expect(withoutDate.isCompleted == withFutureDate.isCompleted)
        #expect(withoutDate.progressRatio == withFutureDate.progressRatio)
    }

    @Test func futureTargetDateDoesNotAffectCompletion() throws {
        let goal = try makeGoal(
            targetAmount: Money(amount: 500, currencyCode: "GBP"),
            currentAmount: Money(amount: 500, currencyCode: "GBP"),
            targetDate: Date(timeIntervalSince1970: 2_000_000_000)
        )

        let progress = try CalculateGoalProgress()(goal: goal)

        #expect(progress.isCompleted)
    }

    @Test func pastTargetDateDoesNotAffectCompletion() throws {
        let goal = try makeGoal(
            targetAmount: Money(amount: 500, currencyCode: "GBP"),
            currentAmount: Money(amount: 100, currencyCode: "GBP"),
            targetDate: Date(timeIntervalSince1970: 0)
        )

        let progress = try CalculateGoalProgress()(goal: goal)

        #expect(progress.isCompleted == false)
    }

    @Test func returnedRemainingAmountPreservesGoalCurrency() throws {
        let goal = try makeGoal(
            targetAmount: Money(amount: 1_000, currencyCode: "eur"),
            currentAmount: Money(amount: 250, currencyCode: " EUR\n")
        )

        let progress = try CalculateGoalProgress()(goal: goal)

        #expect(progress.remainingAmount.currencyCode == "EUR")
    }

    @Test func calculationDoesNotMutateGoal() throws {
        let goal = try makeGoal(
            targetAmount: Money(amount: 1_000, currencyCode: "GBP"),
            currentAmount: Money(amount: 250, currencyCode: "GBP"),
            targetDate: Date(timeIntervalSince1970: 1_800_000_000)
        )
        let original = goal

        _ = try CalculateGoalProgress()(goal: goal)

        #expect(goal == original)
    }

    @Test func zeroProgressRatioIsZero() throws {
        let goal = try makeGoal(
            targetAmount: Money(amount: 1_000, currencyCode: "GBP"),
            currentAmount: Money(amount: 0, currencyCode: "GBP")
        )

        let progress = try CalculateGoalProgress()(goal: goal)

        #expect(progress.progressRatio == 0)
    }

    @Test func partialProgressRatioUsesDecimalDivision() throws {
        let goal = try makeGoal(
            targetAmount: Money(amount: 1_000, currencyCode: "GBP"),
            currentAmount: Money(amount: 250, currencyCode: "GBP")
        )

        let progress = try CalculateGoalProgress()(goal: goal)
        let expected = try decimal("0.25")

        #expect(progress.progressRatio == expected)
    }

    @Test func completeProgressRatioIsOne() throws {
        let goal = try makeGoal(
            targetAmount: Money(amount: 1_000, currencyCode: "GBP"),
            currentAmount: Money(amount: 1_000, currencyCode: "GBP")
        )

        let progress = try CalculateGoalProgress()(goal: goal)

        #expect(progress.progressRatio == 1)
    }

    @Test func zeroTargetProgressRatioUsesCompletedSemantics() throws {
        let goal = try makeGoal(
            targetAmount: Money(amount: 0, currencyCode: "GBP"),
            currentAmount: Money(amount: 0, currencyCode: "GBP")
        )

        let progress = try CalculateGoalProgress()(goal: goal)

        #expect(progress.progressRatio == 1)
    }

    @Test func exactDecimalProgressRatioIsPreserved() throws {
        let goal = try makeGoal(
            targetAmount: Money(amount: decimal("3.0"), currencyCode: "GBP"),
            currentAmount: Money(amount: decimal("1.5"), currencyCode: "GBP")
        )

        let progress = try CalculateGoalProgress()(goal: goal)
        let expected = try decimal("0.5")

        #expect(progress.progressRatio == expected)
    }

    @Test func progressRatioDoesNotProduceNanOrInfinity() throws {
        let goals = try [
            makeGoal(
                targetAmount: Money(amount: 1_000, currencyCode: "GBP"),
                currentAmount: Money(amount: 250, currencyCode: "GBP")
            ),
            makeGoal(
                targetAmount: Money(amount: 0, currencyCode: "GBP"),
                currentAmount: Money(amount: 0, currencyCode: "GBP")
            )
        ]

        for goal in goals {
            let progress = try CalculateGoalProgress()(goal: goal)

            #expect(!progress.progressRatio.isNaN)
        }
    }

    @Test func goalProgressResultIsSendable() throws {
        let goal = try makeGoal()
        let progress = GoalProgress(
            goal: goal,
            remainingAmount: try Money(amount: 750, currencyCode: "GBP"),
            isCompleted: false,
            progressRatio: try decimal("0.25")
        )

        requireSendable(progress)
    }

    @Test func calculateGoalProgressIsSendable() {
        requireSendable(CalculateGoalProgress())
    }

    private func makeGoal(
        id: GoalID? = nil,
        name: String = "Emergency fund",
        targetAmount: Money? = nil,
        currentAmount: Money? = nil,
        targetDate: Date? = nil
    ) throws -> Goal {
        try Goal(
            id: id ?? GoalID(rawValue: try #require(UUID(uuidString: "3F8D4182-F8C7-44CB-8594-377117D3293E"))),
            name: name,
            targetAmount: targetAmount ?? Money(amount: 1_000, currencyCode: "GBP"),
            currentAmount: currentAmount ?? Money(amount: 250, currencyCode: "GBP"),
            targetDate: targetDate
        )
    }

    private func decimal(_ value: String) throws -> Decimal {
        try #require(Decimal(string: value))
    }

    private func expectMoney(
        _ actual: Money,
        amount: Decimal,
        currencyCode: String,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        let expected = try Money(amount: amount, currencyCode: currencyCode)

        #expect(actual == expected, sourceLocation: sourceLocation)
    }

    private func requireSendable<T: Sendable>(_ value: T) {
        _ = value
    }
}
