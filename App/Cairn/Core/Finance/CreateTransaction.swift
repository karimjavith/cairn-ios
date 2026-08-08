//
//  CreateTransaction.swift
//  Cairn
//
//  Created by Codex on 08/08/2026.
//

import Foundation

nonisolated struct CreateTransaction: Sendable {
    let accountRepository: any AccountRepository
    let transactionRepository: any TransactionRepository

    init(
        accountRepository: any AccountRepository,
        transactionRepository: any TransactionRepository
    ) {
        self.accountRepository = accountRepository
        self.transactionRepository = transactionRepository
    }

    func callAsFunction(
        id: TransactionID,
        accountID: AccountID,
        direction: TransactionDirection,
        amount: Money,
        occurredAt: Date,
        categoryID: CategoryID? = nil,
        memo: String? = nil
    ) async throws -> Transaction {
        guard let account = try await accountRepository.fetchAccount(id: accountID) else {
            throw Error.accountNotFound(accountID)
        }

        guard amount.currencyCode == account.currencyCode else {
            throw Error.currencyMismatch(
                accountCurrencyCode: account.currencyCode,
                transactionCurrencyCode: amount.currencyCode
            )
        }

        guard try await transactionRepository.fetchTransaction(id: id) == nil else {
            throw Error.duplicateTransactionID(id)
        }

        let transaction = try Transaction(
            id: id,
            accountID: accountID,
            direction: direction,
            amount: amount,
            occurredAt: occurredAt,
            categoryID: categoryID,
            memo: memo
        )

        try await transactionRepository.save(transaction)

        return transaction
    }
}

nonisolated extension CreateTransaction {
    enum Error: Swift.Error, Equatable, Sendable {
        case accountNotFound(AccountID)
        case currencyMismatch(
            accountCurrencyCode: String,
            transactionCurrencyCode: String
        )
        case duplicateTransactionID(TransactionID)
    }
}
