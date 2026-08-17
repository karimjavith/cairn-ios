//
//  RecurringTransactionsStore.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import Foundation
import Observation

typealias RecurringTransactionNextOccurrenceProvider = @Sendable (RecurringTransaction, Calendar, Date) throws -> Date?

@MainActor
@Observable
final class RecurringTransactionsStore {
    enum Route: Hashable {
        case detail(RecurringTransactionID)
    }

    private let recurringTransactionRepository: any RecurringTransactionRepository
    private let accountRepository: any AccountRepository
    private let calendar: Calendar
    private let nextOccurrenceProvider: RecurringTransactionNextOccurrenceProvider
    private let referenceDate: @MainActor @Sendable () -> Date
    private let locale: Locale

    private(set) var recurringTransactions: [RecurringTransaction] = []
    private(set) var accounts: [Account] = []
    private(set) var nextOccurrenceByRecurringTransactionID: [RecurringTransactionID: Date] = [:]
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    var editor: RecurringTransactionEditorState?
    var pendingDeletion: RecurringTransaction?
    var route: Route?

    init(
        recurringTransactionRepository: any RecurringTransactionRepository,
        accountRepository: any AccountRepository,
        calendar: Calendar,
        nextOccurrenceProvider: @escaping RecurringTransactionNextOccurrenceProvider = { recurringTransaction, calendar, referenceDate in
            try RecurringTransactionSchedule(
                recurringTransaction: recurringTransaction,
                calendar: calendar
            ).nextOccurrence(after: referenceDate)
        },
        referenceDate: @escaping @MainActor @Sendable () -> Date = { Date() },
        locale: Locale = .current
    ) {
        self.recurringTransactionRepository = recurringTransactionRepository
        self.accountRepository = accountRepository
        self.calendar = calendar
        self.nextOccurrenceProvider = nextOccurrenceProvider
        self.referenceDate = referenceDate
        self.locale = locale
    }

    var isEmpty: Bool {
        !isLoading && recurringTransactions.isEmpty && errorMessage == nil
    }

    var hasLoadFailed: Bool {
        !isLoading
            && recurringTransactions.isEmpty
            && accounts.isEmpty
            && nextOccurrenceByRecurringTransactionID.isEmpty
            && errorMessage != nil
    }

    func loadRecurringTransactions() async {
        isLoading = true
        errorMessage = nil

        do {
            let loadedAccounts = try await accountRepository.fetchAccounts()
            let loadedRecurringTransactions = try await recurringTransactionRepository.fetchRecurringTransactions()
            let referenceDate = referenceDate()
            var loadedNextOccurrences: [RecurringTransactionID: Date] = [:]

            for recurringTransaction in loadedRecurringTransactions {
                loadedNextOccurrences[recurringTransaction.id] = try nextOccurrenceProvider(
                    recurringTransaction,
                    calendar,
                    referenceDate
                )
            }

            accounts = loadedAccounts
            recurringTransactions = loadedRecurringTransactions
            nextOccurrenceByRecurringTransactionID = loadedNextOccurrences
            isLoading = false
        } catch {
            accounts = []
            recurringTransactions = []
            nextOccurrenceByRecurringTransactionID = [:]
            isLoading = false
            errorMessage = "Recurring transactions could not be loaded."
        }
    }

    func startCreateRecurringTransaction() {
        editor = RecurringTransactionEditorState(
            recurringTransaction: nil,
            accounts: accounts,
            locale: locale
        )
    }

    func startEditing(_ recurringTransaction: RecurringTransaction) {
        editor = RecurringTransactionEditorState(
            recurringTransaction: recurringTransaction,
            accounts: accounts,
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
            let recurringTransaction = try editor.makeRecurringTransaction()
            try await recurringTransactionRepository.save(recurringTransaction)
            self.editor = nil
            await loadRecurringTransactions()
        } catch RecurringTransactionMoneyTextParser.Error.empty {
            editor.isSaving = false
            editor.errorMessage = "Enter an amount."
        } catch RecurringTransactionMoneyTextParser.Error.malformed {
            editor.isSaving = false
            editor.errorMessage = "Enter a valid amount."
        } catch RecurringTransactionEditorState.ValidationError.missingAccount {
            editor.isSaving = false
            editor.errorMessage = "Select an account."
        } catch MoneyError.invalidCurrencyCode {
            editor.isSaving = false
            editor.errorMessage = "Selected account has an invalid currency."
        } catch RecurringTransaction.ValidationError.negativeAmount {
            editor.isSaving = false
            editor.errorMessage = "Amount cannot be negative."
        } catch RecurringTransaction.ValidationError.invalidDateRange {
            editor.isSaving = false
            editor.errorMessage = "End date must be after the start date."
        } catch {
            editor.isSaving = false
            editor.errorMessage = "Recurring transaction could not be saved."
        }
    }

    func requestDelete(_ recurringTransaction: RecurringTransaction) {
        pendingDeletion = recurringTransaction
    }

    func cancelDelete() {
        pendingDeletion = nil
    }

    func confirmDelete(_ recurringTransaction: RecurringTransaction) async {
        pendingDeletion = nil
        errorMessage = nil

        do {
            try await recurringTransactionRepository.deleteRecurringTransaction(id: recurringTransaction.id)
            route = nil
            await loadRecurringTransactions()
        } catch {
            errorMessage = "Recurring transaction could not be deleted."
        }
    }

    func selectDetail(recurringTransactionID: RecurringTransactionID) {
        route = .detail(recurringTransactionID)
    }

    func recurringTransaction(id: RecurringTransactionID) -> RecurringTransaction? {
        recurringTransactions.first { $0.id == id }
    }

    func accountName(for accountID: AccountID) -> String {
        accounts.first { $0.id == accountID }?.name ?? "Unknown Account"
    }

    func nextOccurrence(for recurringTransactionID: RecurringTransactionID) -> Date? {
        nextOccurrenceByRecurringTransactionID[recurringTransactionID]
    }
}

@MainActor
@Observable
final class RecurringTransactionEditorState: Identifiable {
    enum Mode: Equatable {
        case create
        case edit
    }

    enum ValidationError: Error, Equatable {
        case missingAccount
    }

    let id: RecurringTransactionID
    let mode: Mode
    let accounts: [Account]
    private let locale: Locale
    var selectedAccountID: AccountID?
    var direction: TransactionDirection
    var amountText: String
    var frequency: RecurrenceFrequency
    var startDate: Date
    var hasEndDate: Bool
    var endDate: Date
    var memo: String
    var isSaving = false
    var errorMessage: String?

    init(
        recurringTransaction: RecurringTransaction?,
        accounts: [Account],
        locale: Locale = .current
    ) {
        self.accounts = accounts
        self.locale = locale

        if let recurringTransaction {
            id = recurringTransaction.id
            mode = .edit
            selectedAccountID = recurringTransaction.accountID
            direction = recurringTransaction.direction
            amountText = RecurringTransactionMoneyFormatter.decimalText(
                recurringTransaction.amount.amount,
                locale: locale
            )
            frequency = recurringTransaction.frequency
            startDate = recurringTransaction.startDate
            hasEndDate = recurringTransaction.endDate != nil
            endDate = recurringTransaction.endDate ?? recurringTransaction.startDate
            memo = recurringTransaction.memo ?? ""
        } else {
            let defaultDate = Date()

            id = RecurringTransactionID()
            mode = .create
            selectedAccountID = accounts.first?.id
            direction = .outflow
            amountText = ""
            frequency = .monthly
            startDate = defaultDate
            hasEndDate = false
            endDate = defaultDate
            memo = ""
        }
    }

    var title: String {
        switch mode {
        case .create:
            "New Recurring Transaction"
        case .edit:
            "Edit Recurring Transaction"
        }
    }

    func makeRecurringTransaction() throws -> RecurringTransaction {
        guard let selectedAccountID,
              let account = accounts.first(where: { $0.id == selectedAccountID }) else {
            throw ValidationError.missingAccount
        }

        let amount = try RecurringTransactionMoneyTextParser.parse(amountText, locale: locale)
        let money = try Money(amount: amount, currencyCode: account.currencyCode)

        return try RecurringTransaction(
            id: id,
            accountID: account.id,
            direction: direction,
            amount: money,
            frequency: frequency,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            memo: memo
        )
    }
}
