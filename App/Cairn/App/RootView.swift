//
//  RootView.swift
//  Cairn
//
//  Created by Karim Sheikh on 07/08/2026.
//

import SwiftUI

struct RootView: View {
    let dependencies: AppDependencies
    @State private var selectedTab: AppTab = .dashboard
    @State private var accountCreationRequest: UUID?

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                NavigationStack {
                    destination(for: tab)
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.systemImage)
                }
                .tag(tab)
                .accessibilityLabel(tab.title)
            }
        }
        .tint(CairnColor.plum)
    }

    @ViewBuilder
    private func destination(for tab: AppTab) -> some View {
        switch tab {
        case .dashboard:
            DashboardView(
                accountRepository: dependencies.accountRepository,
                budgetRepository: dependencies.budgetRepository,
                goalRepository: dependencies.goalRepository,
                categoryRepository: dependencies.categoryRepository,
                transactionRepository: dependencies.transactionRepository,
                calculateAccountBalance: dependencies.calculateAccountBalance,
                calculateBudgetProgress: dependencies.calculateBudgetProgress,
                calculateGoalProgress: dependencies.calculateGoalProgress,
                calculateCashFlowSummary: dependencies.calculateCashFlowSummary,
                calendar: dependencies.dashboardCalendar,
                selectTab: { selectedTab = $0 },
                startAccountCreation: {
                    selectedTab = .accounts
                    accountCreationRequest = UUID()
                }
            )
        case .accounts:
            AccountsView(
                accountRepository: dependencies.accountRepository,
                transactionRepository: dependencies.transactionRepository,
                calculateAccountBalance: dependencies.calculateAccountBalance,
                createAccountRequest: accountCreationRequest
            )
        case .transactions:
            TransactionsView(
                transactionRepository: dependencies.transactionRepository,
                accountRepository: dependencies.accountRepository,
                categoryRepository: dependencies.categoryRepository,
                createTransaction: dependencies.createTransaction,
                startAccountCreation: {
                    selectedTab = .accounts
                    accountCreationRequest = UUID()
                }
            )
        case .budgets:
            BudgetsView(
                budgetRepository: dependencies.budgetRepository,
                categoryRepository: dependencies.categoryRepository,
                calculateBudgetProgress: dependencies.calculateBudgetProgress
            )
        case .more:
            MoreView(
                accountRepository: dependencies.accountRepository,
                categoryRepository: dependencies.categoryRepository,
                transactionRepository: dependencies.transactionRepository,
                budgetRepository: dependencies.budgetRepository,
                goalRepository: dependencies.goalRepository,
                recurringTransactionRepository: dependencies.recurringTransactionRepository,
                calculateGoalProgress: dependencies.calculateGoalProgress,
                recurringTransactionCalendar: dependencies.recurringTransactionCalendar
            )
        }
    }
}
