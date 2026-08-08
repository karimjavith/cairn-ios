//
//  GoalRepository.swift
//  Cairn
//
//  Created by Karim Sheikh on 08/08/2026.
//

protocol GoalRepository: Sendable {
    func fetchGoals() async throws -> [Goal]
    func fetchGoal(id: GoalID) async throws -> Goal?
    func save(_ goal: Goal) async throws
    func deleteGoal(id: GoalID) async throws
}
