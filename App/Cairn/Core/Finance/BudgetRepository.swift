//
//  BudgetRepository.swift
//  Cairn
//
//  Created by Karim Sheikh on 08/08/2026.
//

protocol BudgetRepository: Sendable {
    func fetchBudgets() async throws -> [Budget]
    func fetchBudget(id: BudgetID) async throws -> Budget?
    func save(_ budget: Budget) async throws
    func deleteBudget(id: BudgetID) async throws
}
