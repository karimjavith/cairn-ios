//
//  CalculateAccountBalance.swift
//  Cairn
//
//  Created by Codex on 08/08/2026.
//

nonisolated struct CalculateAccountBalance: Sendable {
    let accountRepository: any AccountRepository
    let transactionRepository: any TransactionRepository

    init(
        accountRepository: any AccountRepository,
        transactionRepository: any TransactionRepository
    ) {
        self.accountRepository = accountRepository
        self.transactionRepository = transactionRepository
    }

    func callAsFunction(accountID: AccountID) async throws -> Money {
        guard let account = try await accountRepository.fetchAccount(id: accountID) else {
            throw Error.accountNotFound(accountID)
        }

        let transactions = try await transactionRepository.fetchTransactions(accountID: accountID)
        var balance = account.openingBalance

        for transaction in transactions {
            guard transaction.amount.currencyCode == account.openingBalance.currencyCode else {
                throw Error.transactionCurrencyMismatch(
                    accountCurrencyCode: account.openingBalance.currencyCode,
                    transactionCurrencyCode: transaction.amount.currencyCode
                )
            }

            switch transaction.direction {
            case .inflow:
                balance = try balance.adding(transaction.amount)
            case .outflow:
                balance = try balance.subtracting(transaction.amount)
            }
        }

        return balance
    }
}

nonisolated extension CalculateAccountBalance {
    enum Error: Swift.Error, Equatable, Sendable {
        case accountNotFound(AccountID)
        case transactionCurrencyMismatch(
            accountCurrencyCode: String,
            transactionCurrencyCode: String
        )
    }
}
