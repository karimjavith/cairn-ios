//
//  CalculateGoalProgress.swift
//  Cairn
//
//  Created by Codex on 08/08/2026.
//

import Foundation

nonisolated struct GoalProgress: Equatable, Sendable {
    let goal: Goal
    let remainingAmount: Money
    let isCompleted: Bool
    let progressRatio: Decimal
}

nonisolated struct CalculateGoalProgress: Sendable {

    func callAsFunction(goal: Goal) throws -> GoalProgress {
        GoalProgress(
            goal: goal,
            remainingAmount: try goal.targetAmount.subtracting(goal.currentAmount),
            isCompleted: goal.currentAmount == goal.targetAmount,
            progressRatio: progressRatio(for: goal)
        )
    }

    private func progressRatio(for goal: Goal) -> Decimal {
        guard goal.targetAmount.amount > 0 else {
            return 1
        }

        return goal.currentAmount.amount / goal.targetAmount.amount
    }
}
