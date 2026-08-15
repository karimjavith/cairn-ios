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
    let calculateAccountBalance: CalculateAccountBalance

    init(
        accountRepository: any AccountRepository,
        categoryRepository: any CategoryRepository,
        transactionRepository: any TransactionRepository,
        budgetRepository: any BudgetRepository
    ) {
        self.accountRepository = accountRepository
        self.categoryRepository = categoryRepository
        self.transactionRepository = transactionRepository
        self.budgetRepository = budgetRepository
        calculateAccountBalance = CalculateAccountBalance(
            accountRepository: accountRepository,
            transactionRepository: transactionRepository
        )
    }
}
