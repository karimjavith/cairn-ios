//
//  AppDependencies.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

struct AppDependencies {
    let accountRepository: any AccountRepository
    let categoryRepository: any CategoryRepository
    let transactionRepository: any TransactionRepository
    let budgetRepository: any BudgetRepository
    let goalRepository: any GoalRepository
    let calculateAccountBalance: CalculateAccountBalance
    let calculateBudgetProgress: CalculateBudgetProgress
    let calculateGoalProgress: CalculateGoalProgress
    let createTransaction: CreateTransaction

    init(
        accountRepository: any AccountRepository,
        categoryRepository: any CategoryRepository,
        transactionRepository: any TransactionRepository,
        budgetRepository: any BudgetRepository,
        goalRepository: any GoalRepository
    ) {
        self.accountRepository = accountRepository
        self.categoryRepository = categoryRepository
        self.transactionRepository = transactionRepository
        self.budgetRepository = budgetRepository
        self.goalRepository = goalRepository
        calculateAccountBalance = CalculateAccountBalance(
            accountRepository: accountRepository,
            transactionRepository: transactionRepository
        )
        calculateBudgetProgress = CalculateBudgetProgress(
            budgetRepository: budgetRepository,
            transactionRepository: transactionRepository
        )
        calculateGoalProgress = CalculateGoalProgress()
        createTransaction = CreateTransaction(
            accountRepository: accountRepository,
            transactionRepository: transactionRepository
        )
    }
}
