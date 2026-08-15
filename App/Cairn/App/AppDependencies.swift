//
//  AppDependencies.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import Foundation

struct AppDependencies {
    let accountRepository: any AccountRepository
    let categoryRepository: any CategoryRepository
    let transactionRepository: any TransactionRepository
    let budgetRepository: any BudgetRepository
    let goalRepository: any GoalRepository
    let recurringTransactionRepository: any RecurringTransactionRepository
    let recurringTransactionCalendar: Calendar
    let dashboardCalendar: Calendar
    let calculateAccountBalance: CalculateAccountBalance
    let calculateBudgetProgress: CalculateBudgetProgress
    let calculateGoalProgress: CalculateGoalProgress
    let calculateCashFlowSummary: CalculateCashFlowSummary
    let createTransaction: CreateTransaction

    init(
        accountRepository: any AccountRepository,
        categoryRepository: any CategoryRepository,
        transactionRepository: any TransactionRepository,
        budgetRepository: any BudgetRepository,
        goalRepository: any GoalRepository,
        recurringTransactionRepository: any RecurringTransactionRepository,
        recurringTransactionCalendar: Calendar,
        dashboardCalendar: Calendar
    ) {
        self.accountRepository = accountRepository
        self.categoryRepository = categoryRepository
        self.transactionRepository = transactionRepository
        self.budgetRepository = budgetRepository
        self.goalRepository = goalRepository
        self.recurringTransactionRepository = recurringTransactionRepository
        self.recurringTransactionCalendar = recurringTransactionCalendar
        self.dashboardCalendar = dashboardCalendar
        calculateAccountBalance = CalculateAccountBalance(
            accountRepository: accountRepository,
            transactionRepository: transactionRepository
        )
        calculateBudgetProgress = CalculateBudgetProgress(
            budgetRepository: budgetRepository,
            transactionRepository: transactionRepository
        )
        calculateGoalProgress = CalculateGoalProgress()
        calculateCashFlowSummary = CalculateCashFlowSummary(
            transactionRepository: transactionRepository
        )
        createTransaction = CreateTransaction(
            accountRepository: accountRepository,
            transactionRepository: transactionRepository
        )
    }
}
