//
//  AccountsStoreTests.swift
//  CairnTests
//
//  Created by Codex on 15/08/2026.
//

import Foundation
import Testing
@testable import Cairn

@MainActor
struct AccountsStoreTests {
    private let dotDecimalLocale = Locale(identifier: "en_GB")
    private let commaDecimalLocale = Locale(identifier: "de_DE")

    @Test func dotDecimalInputUnderDotDecimalLocaleSucceeds() throws {
        let amount = try AccountMoneyTextParser.parse("10.25", locale: dotDecimalLocale)

        #expect(amount == (try decimal("10.25")))
    }

    @Test func commaDecimalInputUnderCommaDecimalLocaleSucceeds() throws {
        let amount = try AccountMoneyTextParser.parse("10,25", locale: commaDecimalLocale)

        #expect(amount == (try decimal("10.25")))
    }

    @Test func localizedFractionalValueIsPreservedExactly() throws {
        let amount = try AccountMoneyTextParser.parse("1234567890,123456789", locale: commaDecimalLocale)

        #expect(amount == (try decimal("1234567890.123456789")))
    }

    @Test func malformedLocalizedInputIsRejected() {
        #expect(throws: AccountMoneyTextParser.Error.malformed) {
            try AccountMoneyTextParser.parse("10,,25", locale: commaDecimalLocale)
        }
    }

    @Test func trailingGarbageIsRejected() {
        #expect(throws: AccountMoneyTextParser.Error.malformed) {
            try AccountMoneyTextParser.parse("10,25abc", locale: commaDecimalLocale)
        }
    }

    @Test func wrongDecimalSeparatorForLocaleIsRejected() {
        #expect(throws: AccountMoneyTextParser.Error.malformed) {
            try AccountMoneyTextParser.parse("10.25", locale: commaDecimalLocale)
        }
    }

    @Test func loadsAccountsPreservingRepositoryOrder() async throws {
        let zeta = try makeAccount(name: "Zeta")
        let alpha = try makeAccount(name: "Alpha")
        let accountRepository = AccountsFeatureAccountRepository(accounts: [zeta, alpha])
        let store = makeStore(accountRepository: accountRepository)

        await store.loadAccounts()

        #expect(store.accounts == [zeta, alpha])
        #expect(store.isEmpty == false)
    }

    @Test func emptyRepositoryProducesEmptyState() async {
        let store = makeStore()

        await store.loadAccounts()

        #expect(store.accounts == [])
        #expect(store.isEmpty)
        #expect(store.errorMessage == nil)
    }

    @Test func repositoryLoadFailureIsSurfaced() async {
        let accountRepository = AccountsFeatureAccountRepository(fetchAccountsError: AccountsFeatureRepositoryError.fetchFailed)
        let store = makeStore(accountRepository: accountRepository)

        await store.loadAccounts()

        #expect(store.accounts == [])
        #expect(store.errorMessage != nil)
        #expect(store.hasLoadFailed)
    }

    @Test func derivedBalancesAreRequestedAndCalculated() async throws {
        let account = try makeAccount(openingBalanceAmount: 100)
        let transaction = try makeTransaction(accountID: account.id, direction: .inflow, amount: 25)
        let accountRepository = AccountsFeatureAccountRepository(accounts: [account])
        let transactionRepository = AccountsFeatureTransactionRepository(transactionsByAccountID: [
            account.id: [transaction]
        ])
        let store = makeStore(accountRepository: accountRepository, transactionRepository: transactionRepository)

        await store.loadAccounts()

        #expect(store.balances[account.id] == .loaded(try Money(amount: 125, currencyCode: "GBP")))
        #expect(await transactionRepository.fetchTransactionsCallCount(accountID: account.id) == 1)
    }

    @Test func balanceFailureIsSurfaced() async throws {
        let account = try makeAccount(openingBalanceAmount: 100)
        let accountRepository = AccountsFeatureAccountRepository(accounts: [account])
        let transactionRepository = AccountsFeatureTransactionRepository(fetchTransactionsError: AccountsFeatureRepositoryError.fetchFailed)
        let store = makeStore(accountRepository: accountRepository, transactionRepository: transactionRepository)

        await store.loadAccounts()

        if case .failed = store.balances[account.id] {
            #expect(true)
        } else {
            Issue.record("Expected balance failure to be surfaced.")
        }
    }

    @Test func validCreatedAccountIsSavedWithEditorAccountID() async throws {
        let accountRepository = AccountsFeatureAccountRepository()
        let store = makeStore(accountRepository: accountRepository)

        store.startCreateAccount()
        let editor = try #require(store.editor)
        let createdID = editor.id
        editor.name = "Everyday"
        editor.type = .checking
        editor.openingBalanceText = "10.25"
        editor.currencyCode = "gbp"

        await store.saveEditor()

        let savedAccount = try #require(await accountRepository.savedAccounts().first)
        #expect(savedAccount.id == createdID)
        #expect(savedAccount.name == "Everyday")
        #expect(savedAccount.openingBalance == (try Money(amount: try decimal("10.25"), currencyCode: "GBP")))
        #expect(store.editor == nil)
    }

    @Test func validCreatedAccountCanSaveLocalizedFractionalOpeningBalance() async throws {
        let accountRepository = AccountsFeatureAccountRepository()
        let store = makeStore(accountRepository: accountRepository, locale: commaDecimalLocale)

        store.startCreateAccount()
        let editor = try #require(store.editor)
        editor.name = "Everyday"
        editor.type = .checking
        editor.openingBalanceText = "10,25"
        editor.currencyCode = "eur"

        await store.saveEditor()

        let savedAccount = try #require(await accountRepository.savedAccounts().first)
        #expect(savedAccount.openingBalance == (try Money(amount: try decimal("10.25"), currencyCode: "EUR")))
        #expect(store.editor == nil)
    }

    @Test func invalidCreateInputDoesNotSave() async throws {
        let accountRepository = AccountsFeatureAccountRepository()
        let store = makeStore(accountRepository: accountRepository)

        store.startCreateAccount()
        let editor = try #require(store.editor)
        editor.name = "Everyday"
        editor.openingBalanceText = "bad amount"
        editor.currencyCode = "GBP"

        await store.saveEditor()

        #expect(await accountRepository.savedAccounts() == [])
        #expect(editor.errorMessage != nil)
        #expect(store.editor != nil)
    }

    @Test func repositorySaveFailureIsSurfaced() async throws {
        let accountRepository = AccountsFeatureAccountRepository(saveError: AccountsFeatureRepositoryError.saveFailed)
        let store = makeStore(accountRepository: accountRepository)

        store.startCreateAccount()
        let editor = try #require(store.editor)
        editor.name = "Everyday"
        editor.openingBalanceText = "10"
        editor.currencyCode = "GBP"

        await store.saveEditor()

        #expect(editor.errorMessage != nil)
        #expect(store.editor != nil)
    }

    @Test func editingPreservesAccountIDAndPersistsChanges() async throws {
        let account = try makeAccount(name: "Old Name", openingBalanceAmount: 1)
        let accountRepository = AccountsFeatureAccountRepository(accounts: [account])
        let store = makeStore(accountRepository: accountRepository)

        store.startEditing(account)
        let editor = try #require(store.editor)
        editor.name = "New Name"
        editor.type = .savings
        editor.openingBalanceText = "99"
        editor.currencyCode = "GBP"

        await store.saveEditor()

        let savedAccount = try #require(await accountRepository.savedAccounts().first)
        #expect(savedAccount.id == account.id)
        #expect(savedAccount.name == "New Name")
        #expect(savedAccount.type == .savings)
        #expect(savedAccount.openingBalance == (try Money(amount: 99, currencyCode: "GBP")))
    }

    @Test func editedAccountCanSaveLocalizedFractionalOpeningBalance() async throws {
        let account = try makeAccount(openingBalanceAmount: try decimal("10.25"), currencyCode: "EUR")
        let accountRepository = AccountsFeatureAccountRepository(accounts: [account])
        let store = makeStore(accountRepository: accountRepository, locale: commaDecimalLocale)

        store.startEditing(account)
        let editor = try #require(store.editor)
        #expect(editor.openingBalanceText == "10,25")
        editor.openingBalanceText = "20,75"

        await store.saveEditor()

        let savedAccount = try #require(await accountRepository.savedAccounts().first)
        #expect(savedAccount.id == account.id)
        #expect(savedAccount.openingBalance == (try Money(amount: try decimal("20.75"), currencyCode: "EUR")))
    }

    @Test func failedEditSaveDoesNotPretendSuccess() async throws {
        let account = try makeAccount(name: "Everyday")
        let accountRepository = AccountsFeatureAccountRepository(accounts: [account], saveError: AccountsFeatureRepositoryError.saveFailed)
        let store = makeStore(accountRepository: accountRepository)

        store.startEditing(account)
        let editor = try #require(store.editor)
        editor.name = "Renamed"
        await store.saveEditor()

        #expect(editor.errorMessage != nil)
        #expect(store.editor != nil)
        #expect(await accountRepository.savedAccounts() == [])
    }

    @Test func accountWithNoTransactionsCanBeDeleted() async throws {
        let account = try makeAccount(name: "Everyday")
        let accountRepository = AccountsFeatureAccountRepository(accounts: [account])
        let transactionRepository = AccountsFeatureTransactionRepository()
        let store = makeStore(
            accountRepository: accountRepository,
            transactionRepository: transactionRepository
        )

        store.requestDelete(account)
        await store.confirmDelete()

        #expect(await accountRepository.deletedAccountIDs() == [account.id])
        #expect(await transactionRepository.fetchTransactionsCallCount(accountID: account.id) == 1)
        #expect(store.featureError == nil)
    }

    @Test func confirmedDeleteUsesCapturedAccountAfterPresentationStateClears() async throws {
        let account = try makeAccount(name: "Everyday")
        let accountRepository = AccountsFeatureAccountRepository(accounts: [account])
        let transactionRepository = AccountsFeatureTransactionRepository()
        let store = makeStore(
            accountRepository: accountRepository,
            transactionRepository: transactionRepository
        )

        store.requestDelete(account)
        store.cancelDelete()
        await store.confirmDelete(account)

        #expect(await accountRepository.deletedAccountIDs() == [account.id])
        #expect(await transactionRepository.fetchTransactionsCallCount(accountID: account.id) == 1)
        #expect(store.pendingDeletion == nil)
    }

    @Test func accountWithExistingTransactionsCannotBeDeleted() async throws {
        let account = try makeAccount(name: "Everyday")
        let transaction = try makeTransaction(accountID: account.id, direction: .outflow, amount: 10)
        let accountRepository = AccountsFeatureAccountRepository(accounts: [account])
        let transactionRepository = AccountsFeatureTransactionRepository(transactionsByAccountID: [
            account.id: [transaction]
        ])
        let store = makeStore(
            accountRepository: accountRepository,
            transactionRepository: transactionRepository
        )

        store.requestDelete(account)
        await store.confirmDelete()

        #expect(await accountRepository.deletedAccountIDs() == [])
        #expect(try await accountRepository.fetchAccount(id: account.id) == account)
        #expect(await transactionRepository.transactions(accountID: account.id) == [transaction])
        #expect(await transactionRepository.savedTransactions() == [])
        #expect(await transactionRepository.deletedTransactionIDs() == [])
        #expect(store.featureError == .accountHasTransactions(account.id))
        #expect(store.errorMessage != nil)
    }

    @Test func failedDeleteIsSurfaced() async throws {
        let account = try makeAccount(name: "Everyday")
        let accountRepository = AccountsFeatureAccountRepository(
            accounts: [account],
            deleteError: AccountsFeatureRepositoryError.deleteFailed
        )
        let transactionRepository = AccountsFeatureTransactionRepository()
        let store = makeStore(
            accountRepository: accountRepository,
            transactionRepository: transactionRepository
        )

        store.requestDelete(account)
        await store.confirmDelete()

        #expect(store.errorMessage != nil)
        #expect(await transactionRepository.fetchTransactionsCallCount(accountID: account.id) == 1)
        #expect(await accountRepository.deletedAccountIDs() == [])
    }

    @Test func transactionFetchFailureDuringDeleteIsSurfaced() async throws {
        let account = try makeAccount(name: "Everyday")
        let accountRepository = AccountsFeatureAccountRepository(accounts: [account])
        let transactionRepository = AccountsFeatureTransactionRepository(
            fetchTransactionsError: AccountsFeatureRepositoryError.fetchFailed
        )
        let store = makeStore(
            accountRepository: accountRepository,
            transactionRepository: transactionRepository
        )

        store.requestDelete(account)
        await store.confirmDelete()

        #expect(store.errorMessage != nil)
        #expect(await transactionRepository.fetchTransactionsCallCount(accountID: account.id) == 1)
        #expect(await accountRepository.deletedAccountIDs() == [])
        #expect(try await accountRepository.fetchAccount(id: account.id) == account)
    }

    @Test func cancelledDeletePerformsNoRepositoryCalls() async throws {
        let account = try makeAccount(name: "Everyday")
        let accountRepository = AccountsFeatureAccountRepository(accounts: [account])
        let transactionRepository = AccountsFeatureTransactionRepository()
        let store = makeStore(
            accountRepository: accountRepository,
            transactionRepository: transactionRepository
        )

        store.requestDelete(account)
        store.cancelDelete()
        await store.confirmDelete()

        #expect(await accountRepository.deletedAccountIDs() == [])
        #expect(await transactionRepository.fetchTransactionsCallCount(accountID: account.id) == 0)
    }

    @Test func selectingAccountReachesDetailState() async throws {
        let account = try makeAccount(name: "Everyday")
        let store = makeStore(accountRepository: AccountsFeatureAccountRepository(accounts: [account]))

        await store.loadAccounts()
        store.selectDetail(accountID: account.id)

        #expect(store.route == .detail(account.id))
        #expect(store.account(id: account.id) == account)
    }

    @Test func detailBalanceIsDerivedRatherThanStoredOnAccount() async throws {
        let account = try makeAccount(openingBalanceAmount: 100)
        let transaction = try makeTransaction(accountID: account.id, direction: .outflow, amount: 40)
        let accountRepository = AccountsFeatureAccountRepository(accounts: [account])
        let transactionRepository = AccountsFeatureTransactionRepository(transactionsByAccountID: [
            account.id: [transaction]
        ])
        let store = makeStore(accountRepository: accountRepository, transactionRepository: transactionRepository)

        await store.loadAccounts()

        #expect(store.account(id: account.id)?.openingBalance == account.openingBalance)
        #expect(store.balances[account.id] == .loaded(try Money(amount: 60, currencyCode: "GBP")))
    }

    private func makeStore(
        accountRepository: AccountsFeatureAccountRepository = AccountsFeatureAccountRepository(),
        transactionRepository: AccountsFeatureTransactionRepository = AccountsFeatureTransactionRepository(),
        locale: Locale = Locale(identifier: "en_GB")
    ) -> AccountsStore {
        AccountsStore(
            accountRepository: accountRepository,
            transactionRepository: transactionRepository,
            calculateAccountBalance: CalculateAccountBalance(
                accountRepository: accountRepository,
                transactionRepository: transactionRepository
            ),
            locale: locale
        )
    }

    private func makeAccount(
        id: AccountID = AccountID(),
        name: String = "Everyday",
        type: AccountType = .checking,
        openingBalanceAmount: Decimal = 10,
        currencyCode: String = "GBP"
    ) throws -> Account {
        try Account(
            id: id,
            name: name,
            type: type,
            currencyCode: currencyCode,
            openingBalance: Money(amount: openingBalanceAmount, currencyCode: currencyCode)
        )
    }

    private func makeTransaction(
        accountID: AccountID,
        direction: TransactionDirection,
        amount: Decimal
    ) throws -> Transaction {
        try Transaction(
            accountID: accountID,
            direction: direction,
            amount: Money(amount: amount, currencyCode: "GBP"),
            occurredAt: Date(timeIntervalSince1970: 1_786_080_000)
        )
    }

    private func decimal(_ text: String) throws -> Decimal {
        try #require(Decimal(string: text, locale: Locale(identifier: "en_US_POSIX")))
    }
}

private enum AccountsFeatureRepositoryError: Error {
    case fetchFailed
    case saveFailed
    case deleteFailed
}

private actor AccountsFeatureAccountRepository: AccountRepository {
    private var accounts: [Account]
    private var saved: [Account] = []
    private var deletedIDs: [AccountID] = []
    private let fetchAccountsError: Error?
    private let saveError: Error?
    private let deleteError: Error?

    init(
        accounts: [Account] = [],
        fetchAccountsError: Error? = nil,
        saveError: Error? = nil,
        deleteError: Error? = nil
    ) {
        self.accounts = accounts
        self.fetchAccountsError = fetchAccountsError
        self.saveError = saveError
        self.deleteError = deleteError
    }

    func fetchAccounts() async throws -> [Account] {
        if let fetchAccountsError {
            throw fetchAccountsError
        }

        return accounts
    }

    func fetchAccount(id: AccountID) async throws -> Account? {
        accounts.first { $0.id == id }
    }

    func save(_ account: Account) async throws {
        if let saveError {
            throw saveError
        }

        saved.append(account)

        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
        } else {
            accounts.append(account)
        }
    }

    func deleteAccount(id: AccountID) async throws {
        if let deleteError {
            throw deleteError
        }

        deletedIDs.append(id)
        accounts.removeAll { $0.id == id }
    }

    func savedAccounts() -> [Account] {
        saved
    }

    func deletedAccountIDs() -> [AccountID] {
        deletedIDs
    }
}

private actor AccountsFeatureTransactionRepository: TransactionRepository {
    private let transactionsByAccountID: [AccountID: [Transaction]]
    private let fetchTransactionsError: Error?
    private var fetchTransactionCounts: [AccountID: Int] = [:]
    private var saved: [Transaction] = []
    private var deletedIDs: [TransactionID] = []

    init(
        transactionsByAccountID: [AccountID: [Transaction]] = [:],
        fetchTransactionsError: Error? = nil
    ) {
        self.transactionsByAccountID = transactionsByAccountID
        self.fetchTransactionsError = fetchTransactionsError
    }

    func fetchTransactions(accountID: AccountID) async throws -> [Transaction] {
        fetchTransactionCounts[accountID, default: 0] += 1

        if let fetchTransactionsError {
            throw fetchTransactionsError
        }

        return transactionsByAccountID[accountID] ?? []
    }

    func fetchTransactions(categoryID: CategoryID) async throws -> [Transaction] {
        []
    }

    func fetchTransactions(occurredFrom start: Date, occurredBefore end: Date) async throws -> [Transaction] {
        []
    }

    func fetchTransaction(id: TransactionID) async throws -> Transaction? {
        nil
    }

    func save(_ transaction: Transaction) async throws {
        saved.append(transaction)
    }

    func deleteTransaction(id: TransactionID) async throws {
        deletedIDs.append(id)
    }

    func fetchTransactionsCallCount(accountID: AccountID) -> Int {
        fetchTransactionCounts[accountID, default: 0]
    }

    func transactions(accountID: AccountID) -> [Transaction] {
        transactionsByAccountID[accountID] ?? []
    }

    func savedTransactions() -> [Transaction] {
        saved
    }

    func deletedTransactionIDs() -> [TransactionID] {
        deletedIDs
    }
}
