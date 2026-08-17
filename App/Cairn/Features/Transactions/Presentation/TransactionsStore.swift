//
//  TransactionsStore.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class TransactionsStore {
    enum Route: Hashable {
        case detail(TransactionID)
    }

    private let transactionRepository: any TransactionRepository
    private let accountRepository: any AccountRepository
    private let categoryRepository: any CategoryRepository
    private let createTransaction: CreateTransaction
    private let locale: Locale

    private(set) var transactions: [Transaction] = []
    private(set) var accounts: [Account] = []
    private(set) var categories: [Category] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    var editor: TransactionEditorState?
    var pendingDeletion: Transaction?
    var route: Route?

    init(
        transactionRepository: any TransactionRepository,
        accountRepository: any AccountRepository,
        categoryRepository: any CategoryRepository,
        createTransaction: CreateTransaction,
        locale: Locale = .current
    ) {
        self.transactionRepository = transactionRepository
        self.accountRepository = accountRepository
        self.categoryRepository = categoryRepository
        self.createTransaction = createTransaction
        self.locale = locale
    }

    var isEmpty: Bool {
        !isLoading && transactions.isEmpty && errorMessage == nil
    }

    var hasLoadFailed: Bool {
        !isLoading && transactions.isEmpty && accounts.isEmpty && categories.isEmpty && errorMessage != nil
    }

    func loadTransactions() async {
        isLoading = true
        errorMessage = nil

        do {
            accounts = try await accountRepository.fetchAccounts()
            categories = try await categoryRepository.fetchCategories()
            transactions = try await transactionRepository.fetchTransactions(
                occurredFrom: .distantPast,
                occurredBefore: .distantFuture
            )
            isLoading = false
        } catch {
            transactions = []
            accounts = []
            categories = []
            isLoading = false
            errorMessage = "Transactions could not be loaded."
        }
    }

    func startCreateTransaction() {
        editor = TransactionEditorState(
            transaction: nil,
            accounts: accounts,
            categories: categories,
            locale: locale
        )
    }

    func startEditing(_ transaction: Transaction) {
        editor = TransactionEditorState(
            transaction: transaction,
            accounts: accounts,
            categories: categories,
            locale: locale
        )
    }

    func dismissEditor() {
        editor = nil
    }

    func saveEditor() async {
        guard let editor else {
            return
        }

        editor.isSaving = true
        editor.errorMessage = nil

        do {
            let draft = try editor.makeDraft()

            switch editor.mode {
            case .create:
                _ = try await createTransaction(
                    id: draft.id,
                    accountID: draft.account.id,
                    direction: draft.direction,
                    amount: draft.money,
                    occurredAt: draft.occurredAt,
                    categoryID: draft.categoryID,
                    memo: draft.memo
                )
            case .edit:
                let transaction = try Transaction(
                    id: draft.id,
                    accountID: draft.account.id,
                    direction: draft.direction,
                    amount: draft.money,
                    occurredAt: draft.occurredAt,
                    categoryID: draft.categoryID,
                    memo: draft.memo
                )
                try await transactionRepository.save(transaction)
            }

            self.editor = nil
            await loadTransactions()
        } catch TransactionMoneyTextParser.Error.empty {
            editor.isSaving = false
            editor.errorMessage = "Enter an amount."
        } catch TransactionMoneyTextParser.Error.malformed {
            editor.isSaving = false
            editor.errorMessage = "Enter a valid amount."
        } catch TransactionEditorState.ValidationError.missingAccount {
            editor.isSaving = false
            editor.errorMessage = "Select an account."
        } catch TransactionEditorState.ValidationError.invalidCategory {
            editor.isSaving = false
            editor.errorMessage = "Select a valid category."
        } catch CreateTransaction.Error.accountNotFound {
            editor.isSaving = false
            editor.errorMessage = "Selected account is unavailable."
        } catch CreateTransaction.Error.currencyMismatch {
            editor.isSaving = false
            editor.errorMessage = "Transaction currency must match the selected account."
        } catch {
            editor.isSaving = false
            editor.errorMessage = "Transaction could not be saved."
        }
    }

    func requestDelete(_ transaction: Transaction) {
        pendingDeletion = transaction
    }

    func cancelDelete() {
        pendingDeletion = nil
    }

    func confirmDelete(_ transaction: Transaction) async {
        pendingDeletion = nil
        errorMessage = nil

        do {
            try await transactionRepository.deleteTransaction(id: transaction.id)
            route = nil
            await loadTransactions()
        } catch {
            errorMessage = "Transaction could not be deleted."
        }
    }

    func selectDetail(transactionID: TransactionID) {
        route = .detail(transactionID)
    }

    func transaction(id: TransactionID) -> Transaction? {
        transactions.first { $0.id == id }
    }

    func accountName(for accountID: AccountID) -> String {
        accounts.first { $0.id == accountID }?.name ?? "Unknown Account"
    }

    func categoryName(for categoryID: CategoryID?) -> String {
        guard let categoryID else {
            return "Uncategorized"
        }

        return categories.first { $0.id == categoryID }?.name ?? "Unknown Category"
    }
}

@MainActor
@Observable
final class TransactionEditorState: Identifiable {
    enum Mode: Equatable {
        case create
        case edit
    }

    enum ValidationError: Error, Equatable {
        case missingAccount
        case invalidCategory
    }

    struct Draft: Equatable {
        let id: TransactionID
        let account: Account
        let direction: TransactionDirection
        let money: Money
        let occurredAt: Date
        let categoryID: CategoryID?
        let memo: String
    }

    let id: TransactionID
    let mode: Mode
    let accounts: [Account]
    let categories: [Category]
    private let locale: Locale
    var selectedAccountID: AccountID?
    var direction: TransactionDirection
    var amountText: String
    var occurredAt: Date
    var selectedCategoryID: CategoryID?
    var memo: String
    var isSaving = false
    var errorMessage: String?

    init(
        transaction: Transaction?,
        accounts: [Account],
        categories: [Category],
        locale: Locale = .current
    ) {
        self.accounts = accounts
        self.categories = categories
        self.locale = locale

        if let transaction {
            id = transaction.id
            mode = .edit
            selectedAccountID = transaction.accountID
            direction = transaction.direction
            amountText = TransactionMoneyFormatter.decimalText(transaction.amount.amount, locale: locale)
            occurredAt = transaction.occurredAt
            selectedCategoryID = transaction.categoryID
            memo = transaction.memo ?? ""
        } else {
            id = TransactionID()
            mode = .create
            selectedAccountID = accounts.first?.id
            direction = .outflow
            amountText = ""
            occurredAt = Date()
            selectedCategoryID = nil
            memo = ""
        }
    }

    var title: String {
        switch mode {
        case .create:
            "New Transaction"
        case .edit:
            "Edit Transaction"
        }
    }

    func makeDraft() throws -> Draft {
        guard let selectedAccountID,
              let account = accounts.first(where: { $0.id == selectedAccountID }) else {
            throw ValidationError.missingAccount
        }

        if let selectedCategoryID,
           !categories.contains(where: { $0.id == selectedCategoryID }) {
            throw ValidationError.invalidCategory
        }

        let amount = try TransactionMoneyTextParser.parse(amountText, locale: locale)
        let money = try Money(amount: amount, currencyCode: account.currencyCode)

        return Draft(
            id: id,
            account: account,
            direction: direction,
            money: money,
            occurredAt: occurredAt,
            categoryID: selectedCategoryID,
            memo: memo
        )
    }
}
