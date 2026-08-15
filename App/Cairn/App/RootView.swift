//
//  RootView.swift
//  Cairn
//
//  Created by Karim Sheikh on 07/08/2026.
//

import SwiftUI

struct RootView: View {
    let dependencies: AppDependencies

    var body: some View {
        TabView {
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
    }

    @ViewBuilder
    private func destination(for tab: AppTab) -> some View {
        switch tab {
        case .dashboard:
            DashboardView()
        case .accounts:
            AccountsView(
                accountRepository: dependencies.accountRepository,
                transactionRepository: dependencies.transactionRepository,
                calculateAccountBalance: dependencies.calculateAccountBalance
            )
        case .transactions:
            TransactionsView(
                transactionRepository: dependencies.transactionRepository,
                accountRepository: dependencies.accountRepository,
                categoryRepository: dependencies.categoryRepository,
                createTransaction: dependencies.createTransaction
            )
        case .budgets:
            BudgetsView(
                budgetRepository: dependencies.budgetRepository,
                categoryRepository: dependencies.categoryRepository,
                calculateBudgetProgress: dependencies.calculateBudgetProgress
            )
        case .more:
            MoreView(
                categoryRepository: dependencies.categoryRepository,
                transactionRepository: dependencies.transactionRepository,
                budgetRepository: dependencies.budgetRepository
            )
        }
    }
}
