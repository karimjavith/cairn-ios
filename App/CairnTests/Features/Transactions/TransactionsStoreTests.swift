//
//  TransactionsStoreTests.swift
//  CairnTests
//
//  Created by Codex on 15/08/2026.
//

import Foundation
import Testing
@testable import Cairn

@MainActor
struct TransactionsStoreTests {
    private let dotDecimalLocale = Locale(identifier: "en_GB")
    private let commaDecimalLocale = Locale(identifier: "de_DE")

    @Test func loadsTransactionsPreservingRepositoryOrder() async throws {
        let account = try makeAccount()
        let newest = try makeTransaction(accountID: account.id, occurredAt: date(2_000), memo: "Newest")
        let oldest = try makeTransaction(accountID: account.id, occurredAt: date(1_000), memo: "Oldest")
        let transactionRepository = TransactionsFeatureTransactionRepository(transactions: [newest, oldest])
        let store = makeStore(
            transactionRepository: transactionRepository,
            accountRepository: TransactionsFeatureAccountRepository(accounts: [account])
        )

        await store.loadTransactions()

        #expect(store.transactions == [newest, oldest])
        #expect(store.isEmpty == false)
        let requestedRange = try #require(await transactionRepository.fetchDateRanges().first)
        #expect(requestedRange.start == .distantPast)
        #expect(requestedRange.end == .distantFuture)
    }

    @Test func emptyRepositoryProducesEmptyState() async {
        let store = makeStore()

        await store.loadTransactions()

        #expect(store.transactions == [])
        #expect(store.isEmpty)
        #expect(store.errorMessage == nil)
    }

    @Test func repositoryLoadFailureIsSurfaced() async {
        let transactionRepository = TransactionsFeatureTransactionRepository(fetchDateRangeError: TransactionsFeatureRepositoryError.fetchFailed)
        let store = makeStore(transactionRepository: transactionRepository)

        await store.loadTransactions()

        #expect(store.transactions == [])
        #expect(store.errorMessage != nil)
        #expect(store.hasLoadFailed)
    }

    @Test func retryAfterLoadFailureRerunsLoad() async {
        let transactionRepository = TransactionsFeatureTransactionRepository(
            fetchDateRangeError: TransactionsFeatureRepositoryError.fetchFailed
        )
        let store = makeStore(transactionRepository: transactionRepository)

        await store.loadTransactions()
        await store.loadTransactions()

        #expect(await transactionRepository.fetchDateRanges().count == 2)
        #expect(store.hasLoadFailed)
    }

    @Test func accountAndCategoryDisplayMetadataResolveCorrectly() async throws {
        let account = try makeAccount(name: "Everyday")
        let category = try makeCategory(name: "Groceries")
        let transaction = try makeTransaction(accountID: account.id, categoryID: category.id)
        let store = makeStore(
            transactionRepository: TransactionsFeatureTransactionRepository(transactions: [transaction]),
            accountRepository: TransactionsFeatureAccountRepository(accounts: [account]),
            categoryRepository: TransactionsFeatureCategoryRepository(categories: [category])
        )

        await store.loadTransactions()

        #expect(store.accountName(for: account.id) == "Everyday")
        #expect(store.categoryName(for: category.id) == "Groceries")
        #expect(store.categoryName(for: nil) == "Uncategorized")
    }

    @Test func validTransactionIsCreatedThroughCreateTransaction() async throws {
        let account = try makeAccount()
        let transactionRepository = TransactionsFeatureTransactionRepository()
        let store = makeStore(
            transactionRepository: transactionRepository,
            accountRepository: TransactionsFeatureAccountRepository(accounts: [account])
        )

        await store.loadTransactions()
        store.startCreateTransaction()
        let editor = try #require(store.editor)
        let transactionID = editor.id
        editor.selectedAccountID = account.id
        editor.direction = .outflow
        editor.amountText = "10.25"
        editor.occurredAt = date(1_500)
        editor.memo = "  Lunch\n"

        await store.saveEditor()

        let savedTransaction = try #require(await transactionRepository.savedTransactions().first)
        #expect(savedTransaction.id == transactionID)
        #expect(savedTransaction.accountID == account.id)
        #expect(savedTransaction.amount == (try Money(amount: try decimal("10.25"), currencyCode: "GBP")))
        #expect(savedTransaction.memo == "Lunch")
        #expect(await transactionRepository.fetchTransactionIDs() == [transactionID])
        #expect(store.editor == nil)
    }

    @Test func createPreservesSelectedCategory() async throws {
        let account = try makeAccount()
        let category = try makeCategory()
        let transactionRepository = TransactionsFeatureTransactionRepository()
        let store = makeStore(
            transactionRepository: transactionRepository,
            accountRepository: TransactionsFeatureAccountRepository(accounts: [account]),
            categoryRepository: TransactionsFeatureCategoryRepository(categories: [category])
        )

        await store.loadTransactions()
        store.startCreateTransaction()
        let editor = try #require(store.editor)
        editor.amountText = "10"
        editor.selectedCategoryID = category.id

        await store.saveEditor()

        let savedTransaction = try #require(await transactionRepository.savedTransactions().first)
        #expect(savedTransaction.categoryID == category.id)
    }

    @Test func createPreservesNilCategory() async throws {
        let account = try makeAccount()
        let transactionRepository = TransactionsFeatureTransactionRepository()
        let store = makeStore(
            transactionRepository: transactionRepository,
            accountRepository: TransactionsFeatureAccountRepository(accounts: [account])
        )

        await store.loadTransactions()
        store.startCreateTransaction()
        let editor = try #require(store.editor)
        editor.amountText = "10"
        editor.selectedCategoryID = nil

        await store.saveEditor()

        let savedTransaction = try #require(await transactionRepository.savedTransactions().first)
        #expect(savedTransaction.categoryID == nil)
    }

    @Test func localizedFractionalAmountIsAcceptedOnCreate() async throws {
        let account = try makeAccount(currencyCode: "EUR")
        let transactionRepository = TransactionsFeatureTransactionRepository()
        let store = makeStore(
            transactionRepository: transactionRepository,
            accountRepository: TransactionsFeatureAccountRepository(accounts: [account]),
            locale: commaDecimalLocale
        )

        await store.loadTransactions()
        store.startCreateTransaction()
        let editor = try #require(store.editor)
        editor.amountText = "10,25"

        await store.saveEditor()

        let savedTransaction = try #require(await transactionRepository.savedTransactions().first)
        #expect(savedTransaction.amount == (try Money(amount: try decimal("10.25"), currencyCode: "EUR")))
    }

    @Test func invalidCreateInputDoesNotSave() async throws {
        let account = try makeAccount()
        let transactionRepository = TransactionsFeatureTransactionRepository()
        let store = makeStore(
            transactionRepository: transactionRepository,
            accountRepository: TransactionsFeatureAccountRepository(accounts: [account])
        )

        await store.loadTransactions()
        store.startCreateTransaction()
        let editor = try #require(store.editor)
        editor.amountText = "bad amount"

        await store.saveEditor()

        #expect(await transactionRepository.savedTransactions() == [])
        #expect(editor.errorMessage != nil)
        #expect(store.editor != nil)
    }

    @Test func createTransactionFailureSurfaces() async throws {
        let account = try makeAccount()
        let transactionRepository = TransactionsFeatureTransactionRepository(saveError: TransactionsFeatureRepositoryError.saveFailed)
        let store = makeStore(
            transactionRepository: transactionRepository,
            accountRepository: TransactionsFeatureAccountRepository(accounts: [account])
        )

        await store.loadTransactions()
        store.startCreateTransaction()
        let editor = try #require(store.editor)
        editor.amountText = "10"

        await store.saveEditor()

        #expect(editor.errorMessage != nil)
        #expect(store.editor != nil)
    }

    @Test func editPreservesTransactionIDAndPersistsSupportedChanges() async throws {
        let oldAccount = try makeAccount(name: "Old", currencyCode: "GBP")
        let newAccount = try makeAccount(name: "New", currencyCode: "EUR")
        let oldCategory = try makeCategory(name: "Old Category")
        let newCategory = try makeCategory(name: "New Category")
        let transaction = try makeTransaction(
            accountID: oldAccount.id,
            direction: .outflow,
            amount: Money(amount: 1, currencyCode: "GBP"),
            occurredAt: date(1_000),
            categoryID: oldCategory.id,
            memo: "Old memo"
        )
        let transactionRepository = TransactionsFeatureTransactionRepository(transactions: [transaction])
        let store = makeStore(
            transactionRepository: transactionRepository,
            accountRepository: TransactionsFeatureAccountRepository(accounts: [oldAccount, newAccount]),
            categoryRepository: TransactionsFeatureCategoryRepository(categories: [oldCategory, newCategory]),
            locale: dotDecimalLocale
        )

        await store.loadTransactions()
        store.startEditing(transaction)
        let editor = try #require(store.editor)
        editor.selectedAccountID = newAccount.id
        editor.selectedCategoryID = newCategory.id
        editor.direction = .inflow
        editor.amountText = "123.456"
        editor.occurredAt = date(2_000)
        editor.memo = "New memo"

        await store.saveEditor()

        let savedTransaction = try #require(await transactionRepository.savedTransactions().last)
        #expect(savedTransaction.id == transaction.id)
        #expect(savedTransaction.accountID == newAccount.id)
        #expect(savedTransaction.categoryID == newCategory.id)
        #expect(savedTransaction.direction == .inflow)
        #expect(savedTransaction.amount == (try Money(amount: try decimal("123.456"), currencyCode: "EUR")))
        #expect(savedTransaction.occurredAt == date(2_000))
        #expect(savedTransaction.memo == "New memo")
    }

    @Test func editCanChangeCategoryToNil() async throws {
        let account = try makeAccount()
        let category = try makeCategory()
        let transaction = try makeTransaction(accountID: account.id, categoryID: category.id)
        let transactionRepository = TransactionsFeatureTransactionRepository(transactions: [transaction])
        let store = makeStore(
            transactionRepository: transactionRepository,
            accountRepository: TransactionsFeatureAccountRepository(accounts: [account]),
            categoryRepository: TransactionsFeatureCategoryRepository(categories: [category])
        )

        await store.loadTransactions()
        store.startEditing(transaction)
        let editor = try #require(store.editor)
        editor.selectedCategoryID = nil

        await store.saveEditor()

        let savedTransaction = try #require(await transactionRepository.savedTransactions().last)
        #expect(savedTransaction.id == transaction.id)
        #expect(savedTransaction.categoryID == nil)
    }

    @Test func failedEditUpdateSurfaces() async throws {
        let account = try makeAccount()
        let transaction = try makeTransaction(accountID: account.id)
        let transactionRepository = TransactionsFeatureTransactionRepository(
            transactions: [transaction],
            saveError: TransactionsFeatureRepositoryError.saveFailed
        )
        let store = makeStore(
            transactionRepository: transactionRepository,
            accountRepository: TransactionsFeatureAccountRepository(accounts: [account])
        )

        await store.loadTransactions()
        store.startEditing(transaction)
        let editor = try #require(store.editor)
        editor.memo = "Updated"

        await store.saveEditor()

        #expect(editor.errorMessage != nil)
        #expect(store.editor != nil)
        #expect(await transactionRepository.savedTransactions() == [transaction])
    }

    @Test func confirmedDeleteCallsRepository() async throws {
        let account = try makeAccount()
        let transaction = try makeTransaction(accountID: account.id)
        let transactionRepository = TransactionsFeatureTransactionRepository(transactions: [transaction])
        let store = makeStore(
            transactionRepository: transactionRepository,
            accountRepository: TransactionsFeatureAccountRepository(accounts: [account])
        )

        store.requestDelete(transaction)
        await store.confirmDelete(transaction)

        #expect(await transactionRepository.deletedTransactionIDs() == [transaction.id])
        #expect(await transactionRepository.deleteCallCount() == 1)
        #expect(store.pendingDeletion == nil)
    }

    @Test func confirmedDeleteUsesCapturedTransactionAfterDialogStateClears() async throws {
        let account = try makeAccount()
        let transaction = try makeTransaction(accountID: account.id)
        let transactionRepository = TransactionsFeatureTransactionRepository(transactions: [transaction])
        let store = makeStore(
            transactionRepository: transactionRepository,
            accountRepository: TransactionsFeatureAccountRepository(accounts: [account])
        )

        store.requestDelete(transaction)
        let confirmedTransaction = try #require(store.pendingDeletion)
        store.cancelDelete()
        await store.confirmDelete(confirmedTransaction)

        #expect(await transactionRepository.deletedTransactionIDs() == [transaction.id])
        #expect(await transactionRepository.deleteCallCount() == 1)
        #expect(store.pendingDeletion == nil)
    }

    @Test func cancelledDeleteDoesNotDelete() async throws {
        let transactionRepository = TransactionsFeatureTransactionRepository()
        let transaction = try makeTransaction()
        let store = makeStore(transactionRepository: transactionRepository)

        store.requestDelete(transaction)
        store.cancelDelete()

        #expect(await transactionRepository.deletedTransactionIDs() == [])
        #expect(await transactionRepository.deleteCallCount() == 0)
        #expect(store.pendingDeletion == nil)
    }

    @Test func deleteFailureSurfaces() async throws {
        let transaction = try makeTransaction()
        let transactionRepository = TransactionsFeatureTransactionRepository(
            transactions: [transaction],
            deleteError: TransactionsFeatureRepositoryError.deleteFailed
        )
        let store = makeStore(transactionRepository: transactionRepository)

        store.requestDelete(transaction)
        await store.confirmDelete(transaction)

        #expect(store.errorMessage != nil)
        #expect(await transactionRepository.deletedTransactionIDs() == [])
        #expect(await transactionRepository.deleteCallCount() == 1)
    }

    @Test func selectingTransactionReachesDetailState() async throws {
        let account = try makeAccount()
        let category = try makeCategory()
        let transaction = try makeTransaction(accountID: account.id, categoryID: category.id)
        let store = makeStore(
            transactionRepository: TransactionsFeatureTransactionRepository(transactions: [transaction]),
            accountRepository: TransactionsFeatureAccountRepository(accounts: [account]),
            categoryRepository: TransactionsFeatureCategoryRepository(categories: [category])
        )

        await store.loadTransactions()
        store.selectDetail(transactionID: transaction.id)

        #expect(store.route == .detail(transaction.id))
        #expect(store.transaction(id: transaction.id) == transaction)
        #expect(store.accountName(for: transaction.accountID) == account.name)
        #expect(store.categoryName(for: transaction.categoryID) == category.name)
    }

    private func makeStore(
        transactionRepository: TransactionsFeatureTransactionRepository = TransactionsFeatureTransactionRepository(),
        accountRepository: TransactionsFeatureAccountRepository = TransactionsFeatureAccountRepository(),
        categoryRepository: TransactionsFeatureCategoryRepository = TransactionsFeatureCategoryRepository(),
        locale: Locale = Locale(identifier: "en_GB")
    ) -> TransactionsStore {
        TransactionsStore(
            transactionRepository: transactionRepository,
            accountRepository: accountRepository,
            categoryRepository: categoryRepository,
            createTransaction: CreateTransaction(
                accountRepository: accountRepository,
                transactionRepository: transactionRepository
            ),
            locale: locale
        )
    }

    private func makeAccount(
        id: AccountID = AccountID(),
        name: String = "Everyday",
        currencyCode: String = "GBP"
    ) throws -> Account {
        try Account(
            id: id,
            name: name,
            type: .checking,
            currencyCode: currencyCode,
            openingBalance: Money(amount: 100, currencyCode: currencyCode)
        )
    }

    private func makeCategory(
        id: CategoryID = CategoryID(),
        name: String = "Groceries"
    ) throws -> Cairn.Category {
        try Cairn.Category(
            id: id,
            name: name,
            kind: .expense
        )
    }

    private func makeTransaction(
        id: TransactionID = TransactionID(),
        accountID: AccountID = AccountID(),
        direction: TransactionDirection = .outflow,
        amount: Money? = nil,
        occurredAt: Date = Date(timeIntervalSince1970: 1_786_080_000),
        categoryID: CategoryID? = nil,
        memo: String? = "Lunch"
    ) throws -> Transaction {
        try Transaction(
            id: id,
            accountID: accountID,
            direction: direction,
            amount: amount ?? Money(amount: 10, currencyCode: "GBP"),
            occurredAt: occurredAt,
            categoryID: categoryID,
            memo: memo
        )
    }

    private func date(_ timeIntervalSince1970: TimeInterval) -> Date {
        Date(timeIntervalSince1970: timeIntervalSince1970)
    }

    private func decimal(_ text: String) throws -> Decimal {
        try #require(Decimal(string: text, locale: Locale(identifier: "en_US_POSIX")))
    }
}

private enum TransactionsFeatureRepositoryError: Error, Equatable, Sendable {
    case fetchFailed
    case saveFailed
    case deleteFailed
}

private actor TransactionsFeatureTransactionRepository: TransactionRepository {
    private var transactions: [Transaction]
    private var deletedIDs: [TransactionID] = []
    private var deleteCount = 0
    private var fetchDateRangeRequests: [(start: Date, end: Date)] = []
    private var fetchTransactionRequests: [TransactionID] = []
    private let fetchDateRangeError: Error?
    private let saveError: Error?
    private let deleteError: Error?

    init(
        transactions: [Transaction] = [],
        fetchDateRangeError: Error? = nil,
        saveError: Error? = nil,
        deleteError: Error? = nil
    ) {
        self.transactions = transactions
        self.fetchDateRangeError = fetchDateRangeError
        self.saveError = saveError
        self.deleteError = deleteError
    }

    func fetchTransactions(accountID: AccountID) async throws -> [Transaction] {
        transactions.filter { $0.accountID == accountID }
    }

    func fetchTransactions(categoryID: CategoryID) async throws -> [Transaction] {
        transactions.filter { $0.categoryID == categoryID }
    }

    func fetchTransactions(occurredFrom start: Date, occurredBefore end: Date) async throws -> [Transaction] {
        fetchDateRangeRequests.append((start, end))

        if let fetchDateRangeError {
            throw fetchDateRangeError
        }

        return transactions
    }

    func fetchTransaction(id: TransactionID) async throws -> Transaction? {
        fetchTransactionRequests.append(id)

        return transactions.first { $0.id == id }
    }

    func save(_ transaction: Transaction) async throws {
        if let saveError {
            throw saveError
        }

        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[index] = transaction
        } else {
            transactions.append(transaction)
        }
    }

    func deleteTransaction(id: TransactionID) async throws {
        deleteCount += 1

        if let deleteError {
            throw deleteError
        }

        deletedIDs.append(id)
        transactions.removeAll { $0.id == id }
    }

    func savedTransactions() -> [Transaction] {
        transactions
    }

    func deletedTransactionIDs() -> [TransactionID] {
        deletedIDs
    }

    func deleteCallCount() -> Int {
        deleteCount
    }

    func fetchDateRanges() -> [(start: Date, end: Date)] {
        fetchDateRangeRequests
    }

    func fetchTransactionIDs() -> [TransactionID] {
        fetchTransactionRequests
    }
}

private actor TransactionsFeatureAccountRepository: AccountRepository {
    private var accounts: [Account]
    private let fetchError: Error?

    init(accounts: [Account] = [], fetchError: Error? = nil) {
        self.accounts = accounts
        self.fetchError = fetchError
    }

    func fetchAccounts() async throws -> [Account] {
        if let fetchError {
            throw fetchError
        }

        return accounts
    }

    func fetchAccount(id: AccountID) async throws -> Account? {
        if let fetchError {
            throw fetchError
        }

        return accounts.first { $0.id == id }
    }

    func save(_ account: Account) async throws {
        accounts.append(account)
    }

    func deleteAccount(id: AccountID) async throws {
        accounts.removeAll { $0.id == id }
    }
}

private actor TransactionsFeatureCategoryRepository: CategoryRepository {
    private var categories: [Cairn.Category]
    private let fetchError: Error?

    init(categories: [Cairn.Category] = [], fetchError: Error? = nil) {
        self.categories = categories
        self.fetchError = fetchError
    }

    func fetchCategories() async throws -> [Cairn.Category] {
        if let fetchError {
            throw fetchError
        }

        return categories
    }

    func fetchCategory(id: CategoryID) async throws -> Cairn.Category? {
        categories.first { $0.id == id }
    }

    func save(_ category: Cairn.Category) async throws {
        categories.append(category)
    }

    func deleteCategory(id: CategoryID) async throws {
        categories.removeAll { $0.id == id }
    }
}
