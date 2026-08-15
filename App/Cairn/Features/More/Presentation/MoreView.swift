//
//  MoreView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct MoreView: View {
    let accountRepository: any AccountRepository
    let categoryRepository: any CategoryRepository
    let transactionRepository: any TransactionRepository
    let budgetRepository: any BudgetRepository
    let goalRepository: any GoalRepository
    let recurringTransactionRepository: any RecurringTransactionRepository
    let calculateGoalProgress: CalculateGoalProgress
    let recurringTransactionCalendar: Calendar

    var body: some View {
        List {
            ForEach(MoreDestination.allCases) { destination in
                NavigationLink(value: destination) {
                    Label(destination.title, systemImage: destination.systemImage)
                }
            }
        }
        .navigationTitle("More")
        .navigationDestination(for: MoreDestination.self) { destination in
            moreDestinationView(for: destination)
        }
    }

    @ViewBuilder
    private func moreDestinationView(for destination: MoreDestination) -> some View {
        switch destination {
        case .goals:
            GoalsView(
                goalRepository: goalRepository,
                calculateGoalProgress: calculateGoalProgress
            )
        case .categories:
            CategoriesView(
                categoryRepository: categoryRepository,
                transactionRepository: transactionRepository,
                budgetRepository: budgetRepository
            )
        case .recurringTransactions:
            RecurringTransactionsView(
                recurringTransactionRepository: recurringTransactionRepository,
                accountRepository: accountRepository,
                calendar: recurringTransactionCalendar
            )
        }
    }
}
