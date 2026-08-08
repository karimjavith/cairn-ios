//
//  CalculateBudgetProgress.swift
//  Cairn
//
//  Created by Codex on 08/08/2026.
//

import Foundation

nonisolated struct BudgetProgress: Equatable, Sendable {
    let budget: Budget
    let spent: Money
    let remaining: Money
}

nonisolated struct CalculateBudgetProgress: Sendable {
    let budgetRepository: any BudgetRepository
    let transactionRepository: any TransactionRepository

    init(
        budgetRepository: any BudgetRepository,
        transactionRepository: any TransactionRepository
    ) {
        self.budgetRepository = budgetRepository
        self.transactionRepository = transactionRepository
    }

    func callAsFunction(budgetID: BudgetID) async throws -> BudgetProgress {
        guard let budget = try await budgetRepository.fetchBudget(id: budgetID) else {
            throw Error.budgetNotFound(budgetID)
        }

        let transactions = try await transactionRepository.fetchTransactions(categoryID: budget.categoryID)
        var spent = try Money(amount: 0, currencyCode: budget.limit.currencyCode)

        for transaction in transactions where transactionQualifies(transaction, for: budget) {
            guard transaction.amount.currencyCode == budget.limit.currencyCode else {
                throw Error.transactionCurrencyMismatch(
                    budgetCurrencyCode: budget.limit.currencyCode,
                    transactionCurrencyCode: transaction.amount.currencyCode
                )
            }

            spent = try spent.adding(transaction.amount)
        }

        return try BudgetProgress(
            budget: budget,
            spent: spent,
            remaining: budget.limit.subtracting(spent)
        )
    }

    private func transactionQualifies(_ transaction: Transaction, for budget: Budget) -> Bool {
        transaction.direction == .outflow
            && transaction.categoryID == budget.categoryID
            && contains(transaction.occurredAt, in: budget.period)
    }

    private func contains(_ date: Date, in period: BudgetPeriod) -> Bool {
        // Budget periods are start-inclusive and end-exclusive.
        period.startDate <= date && date < period.endDate
    }
}

nonisolated extension CalculateBudgetProgress {
    enum Error: Swift.Error, Equatable, Sendable {
        case budgetNotFound(BudgetID)
        case transactionCurrencyMismatch(
            budgetCurrencyCode: String,
            transactionCurrencyCode: String
        )
    }
}
