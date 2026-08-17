//
//  DashboardView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import Foundation
import SwiftUI

struct DashboardView: View {
    @State private var store: DashboardStore

    init(
        accountRepository: any AccountRepository,
        budgetRepository: any BudgetRepository,
        goalRepository: any GoalRepository,
        categoryRepository: any CategoryRepository,
        transactionRepository: any TransactionRepository,
        calculateAccountBalance: CalculateAccountBalance,
        calculateBudgetProgress: CalculateBudgetProgress,
        calculateGoalProgress: CalculateGoalProgress,
        calculateCashFlowSummary: CalculateCashFlowSummary,
        calendar: Calendar
    ) {
        _store = State(wrappedValue: DashboardStore(
            accountRepository: accountRepository,
            budgetRepository: budgetRepository,
            goalRepository: goalRepository,
            categoryRepository: categoryRepository,
            transactionRepository: transactionRepository,
            calculateAccountBalance: { accountID in
                try await calculateAccountBalance(accountID: accountID)
            },
            calculateBudgetProgress: { budgetID in
                try await calculateBudgetProgress(budgetID: budgetID)
            },
            calculateGoalProgress: { goal in
                try calculateGoalProgress(goal: goal)
            },
            calculateCashFlowSummary: { start, end, currencyCode in
                try await calculateCashFlowSummary(
                    start: start,
                    end: end,
                    currencyCode: currencyCode
                )
            },
            calendar: calendar
        ))
    }

    var body: some View {
        Group {
            if store.isLoading {
                ProgressView("Loading dashboard")
            } else if let errorMessage = store.errorMessage {
                LoadFailureView(
                    title: "Dashboard Unavailable",
                    message: errorMessage,
                    retry: {
                        Task {
                            await store.loadDashboard()
                        }
                    }
                )
            } else if let snapshot = store.snapshot {
                dashboardContent(snapshot)
            } else {
                ProgressView("Loading dashboard")
            }
        }
        .navigationTitle("Dashboard")
        .task {
            await store.loadDashboard()
        }
    }

    private func dashboardContent(_ snapshot: DashboardSnapshot) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if store.hasLoadedEmptyDashboard {
                    ContentUnavailableView(
                        "No Dashboard Data",
                        systemImage: "gauge",
                        description: Text("Add accounts, transactions, budgets, or goals to build your overview.")
                    )
                }

                accountsSection(snapshot)
                cashFlowSection(snapshot)
                budgetsSection(snapshot)
                goalsSection(snapshot)
                recentTransactionsSection(snapshot)
            }
            .padding()
        }
    }

    private func accountsSection(_ snapshot: DashboardSnapshot) -> some View {
        GroupBox("Accounts") {
            VStack(alignment: .leading, spacing: 12) {
                if let netWorth = snapshot.singleCurrencyNetWorth {
                    LabeledContent("Net Worth", value: DashboardMoneyFormatter.currency(netWorth))
                } else if snapshot.currencyTotals.count > 1 {
                    Text("Net worth is shown by currency because Cairn does not convert currencies.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if snapshot.currencyTotals.isEmpty {
                    Text("No accounts yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(snapshot.currencyTotals, id: \.currencyCode) { total in
                        LabeledContent(
                            "\(total.currencyCode) Total",
                            value: DashboardMoneyFormatter.currency(total.total)
                        )
                    }
                }

                Divider()

                if snapshot.accountBalances.isEmpty {
                    Text("Account balances will appear here.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(snapshot.accountBalances, id: \.account.id) { accountBalance in
                        VStack(alignment: .leading, spacing: 2) {
                            LabeledContent(
                                accountBalance.account.name,
                                value: DashboardMoneyFormatter.currency(accountBalance.balance)
                            )
                            Text(accountBalance.account.type.displayName)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    private func cashFlowSection(_ snapshot: DashboardSnapshot) -> some View {
        GroupBox("Cash Flow") {
            VStack(alignment: .leading, spacing: 12) {
                Text(DashboardDateFormatter.period(snapshot.cashFlowPeriod))
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if snapshot.cashFlowSummaries.isEmpty {
                    Text("Cash flow appears after an account currency is available.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(snapshot.cashFlowSummaries, id: \.summary.totalInflows.currencyCode) { cashFlow in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(cashFlow.summary.totalInflows.currencyCode)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            LabeledContent("Inflows", value: DashboardMoneyFormatter.currency(cashFlow.summary.totalInflows))
                            LabeledContent("Outflows", value: DashboardMoneyFormatter.currency(cashFlow.summary.totalOutflows))
                            LabeledContent("Net", value: DashboardMoneyFormatter.currency(cashFlow.summary.netCashFlow))
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    private func budgetsSection(_ snapshot: DashboardSnapshot) -> some View {
        GroupBox("Budgets") {
            VStack(alignment: .leading, spacing: 12) {
                if snapshot.budgetProgress.isEmpty {
                    Text("No budgets yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(snapshot.budgetProgress, id: \.progress.budget.id) { status in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(status.categoryName)
                                .font(.body)
                            LabeledContent("Limit", value: DashboardMoneyFormatter.currency(status.progress.budget.limit))
                            LabeledContent("Spent", value: DashboardMoneyFormatter.currency(status.progress.spent))
                            LabeledContent("Remaining", value: DashboardMoneyFormatter.currency(status.progress.remaining))
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    private func goalsSection(_ snapshot: DashboardSnapshot) -> some View {
        GroupBox("Goals") {
            VStack(alignment: .leading, spacing: 12) {
                if snapshot.goalProgress.isEmpty {
                    Text("No goals yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(snapshot.goalProgress, id: \.progress.goal.id) { status in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(status.progress.goal.name)
                                .font(.body)
                            Text(status.progress.isCompleted ? "Completed" : "In Progress")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            LabeledContent("Current", value: DashboardMoneyFormatter.currency(status.progress.goal.currentAmount))
                            LabeledContent("Target", value: DashboardMoneyFormatter.currency(status.progress.goal.targetAmount))
                            LabeledContent("Remaining", value: DashboardMoneyFormatter.currency(status.progress.remainingAmount))
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    private func recentTransactionsSection(_ snapshot: DashboardSnapshot) -> some View {
        GroupBox("Recent Transactions") {
            VStack(alignment: .leading, spacing: 12) {
                if snapshot.recentTransactions.isEmpty {
                    Text("No transactions in the current month.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(snapshot.recentTransactions, id: \.transaction.id) { recentTransaction in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .firstTextBaseline) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(recentTransaction.transaction.direction.displayName)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text(recentTransaction.accountName)
                                }

                                Spacer(minLength: 16)

                                Text(DashboardMoneyFormatter.currency(recentTransaction.transaction.amount))
                                    .font(.body.monospacedDigit())
                                    .multilineTextAlignment(.trailing)
                            }

                            Text(DashboardDateFormatter.dateTime(recentTransaction.transaction.occurredAt))
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            if let memo = recentTransaction.transaction.memo {
                                Text(memo)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }
}
