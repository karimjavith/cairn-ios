//
//  AccountsStore.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class AccountsStore {
    enum BalanceState: Equatable {
        case loading
        case loaded(Money)
        case failed(String)
    }

    enum Route: Hashable {
        case detail(AccountID)
    }

    enum FeatureError: Error, Equatable {
        case accountHasTransactions(AccountID)
    }

    private let accountRepository: any AccountRepository
    private let transactionRepository: any TransactionRepository
    private let calculateAccountBalance: CalculateAccountBalance
    private let locale: Locale

    private(set) var accounts: [Account] = []
    private(set) var balances: [AccountID: BalanceState] = [:]
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var featureError: FeatureError?
    var editor: AccountEditorState?
    var pendingDeletion: Account?
    var route: Route?

    init(
        accountRepository: any AccountRepository,
        transactionRepository: any TransactionRepository,
        calculateAccountBalance: CalculateAccountBalance,
        locale: Locale = .current
    ) {
        self.accountRepository = accountRepository
        self.transactionRepository = transactionRepository
        self.calculateAccountBalance = calculateAccountBalance
        self.locale = locale
    }

    var isEmpty: Bool {
        !isLoading && accounts.isEmpty && errorMessage == nil
    }

    var hasLoadFailed: Bool {
        !isLoading && accounts.isEmpty && errorMessage != nil
    }

    func loadAccounts() async {
        isLoading = true
        errorMessage = nil
        balances = [:]

        do {
            let loadedAccounts = try await accountRepository.fetchAccounts()
            accounts = loadedAccounts
            isLoading = false
            await loadBalances(for: loadedAccounts)
        } catch {
            accounts = []
            isLoading = false
            errorMessage = "Accounts could not be loaded."
        }
    }

    func startCreateAccount() {
        editor = AccountEditorState(account: nil, locale: locale)
    }

    func startEditing(_ account: Account) {
        editor = AccountEditorState(account: account, locale: locale)
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
            let account = try editor.makeAccount()
            try await accountRepository.save(account)
            self.editor = nil
            await loadAccounts()
        } catch AccountMoneyTextParser.Error.empty {
            editor.isSaving = false
            editor.errorMessage = "Enter an opening balance."
        } catch AccountMoneyTextParser.Error.malformed {
            editor.isSaving = false
            editor.errorMessage = "Enter a valid opening balance."
        } catch {
            editor.isSaving = false
            editor.errorMessage = "Account could not be saved."
        }
    }

    func requestDelete(_ account: Account) {
        pendingDeletion = account
    }

    func cancelDelete() {
        pendingDeletion = nil
    }

    func confirmDelete() async {
        guard let account = pendingDeletion else {
            return
        }

        await confirmDelete(account)
    }

    func confirmDelete(_ account: Account) async {
        pendingDeletion = nil
        featureError = nil

        do {
            let transactions = try await transactionRepository.fetchTransactions(accountID: account.id)

            guard transactions.isEmpty else {
                featureError = .accountHasTransactions(account.id)
                errorMessage = "Account cannot be deleted while it has transactions."
                return
            }

            try await accountRepository.deleteAccount(id: account.id)
            route = nil
            await loadAccounts()
        } catch {
            errorMessage = "Account could not be deleted."
        }
    }

    func selectDetail(accountID: AccountID) {
        route = .detail(accountID)
    }

    func account(id: AccountID) -> Account? {
        accounts.first { $0.id == id }
    }

    private func loadBalances(for accounts: [Account]) async {
        for account in accounts {
            balances[account.id] = .loading

            do {
                balances[account.id] = .loaded(try await calculateAccountBalance(accountID: account.id))
            } catch {
                balances[account.id] = .failed("Current balance could not be calculated.")
            }
        }
    }
}

@MainActor
@Observable
final class AccountEditorState: Identifiable {
    enum Mode: Equatable {
        case create
        case edit
    }

    let id: AccountID
    let mode: Mode
    private let locale: Locale
    var name: String
    var type: AccountType
    var openingBalanceText: String
    var currencyCode: String
    var isSaving = false
    var errorMessage: String?

    init(account: Account?, locale: Locale = .current) {
        self.locale = locale

        if let account {
            id = account.id
            mode = .edit
            name = account.name
            type = account.type
            openingBalanceText = AccountMoneyFormatter.decimalText(account.openingBalance.amount, locale: locale)
            currencyCode = account.currencyCode
        } else {
            id = AccountID()
            mode = .create
            name = ""
            type = .checking
            openingBalanceText = ""
            currencyCode = locale.currency?.identifier ?? "GBP"
        }
    }

    var title: String {
        switch mode {
        case .create:
            "New Account"
        case .edit:
            "Edit Account"
        }
    }

    func makeAccount() throws -> Account {
        let amount = try AccountMoneyTextParser.parse(openingBalanceText, locale: locale)
        let money = try Money(amount: amount, currencyCode: currencyCode)

        return try Account(
            id: id,
            name: name,
            type: type,
            currencyCode: currencyCode,
            openingBalance: money
        )
    }
}
