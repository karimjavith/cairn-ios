//
//  AppDependencies.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

struct AppDependencies {
    let accountRepository: any AccountRepository
    let transactionRepository: any TransactionRepository
    let calculateAccountBalance: CalculateAccountBalance

    init(
        accountRepository: any AccountRepository,
        transactionRepository: any TransactionRepository
    ) {
        self.accountRepository = accountRepository
        self.transactionRepository = transactionRepository
        calculateAccountBalance = CalculateAccountBalance(
            accountRepository: accountRepository,
            transactionRepository: transactionRepository
        )
    }
}
