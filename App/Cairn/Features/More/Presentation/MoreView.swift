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
    let creditScoreRepository: any CreditScoreRepository
    let calculateGoalProgress: CalculateGoalProgress
    let recurringTransactionCalendar: Calendar

    var body: some View {
        ZStack {
            CairnColor.canvas
                .ignoresSafeArea()

            List {
                ForEach(MoreDestination.allCases) { destination in
                    NavigationLink(value: destination) {
                        HStack(spacing: CairnSpacing.medium) {
                            Image(systemName: destination.systemImage)
                                .font(.body.weight(.medium))
                                .foregroundStyle(CairnColor.plum)
                                .frame(width: 28)
                                .accessibilityHidden(true)

                            Text(destination.title)
                                .font(.body.weight(.medium))
                                .foregroundStyle(CairnColor.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                    .accessibilityLabel(destination.title)
                    .listRowInsets(EdgeInsets(
                        top: CairnSpacing.small,
                        leading: CairnSpacing.extraLarge,
                        bottom: CairnSpacing.small,
                        trailing: CairnSpacing.extraLarge
                    ))
                    .listRowBackground(CairnColor.canvas)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("More")
        .tint(CairnColor.plum)
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
        case .creditScore:
            CreditScoresView(repository: creditScoreRepository)
        }
    }
}
